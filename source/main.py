import warnings
warnings.filterwarnings("ignore", category=UserWarning) 
warnings.filterwarnings("ignore", category=DeprecationWarning) 
warnings.filterwarnings("ignore", category=FutureWarning)

import sys
import signal
import traceback
import datetime
import subprocess
import os
import glob
import shutil
import importlib
import json
import hashlib
import argparse
import re
from pathlib import Path
from importlib import metadata

from packaging.requirements import Requirement
from packaging.version import InvalidVersion, Version

import platform
IS_WIN = platform.system() == 'Windows'
IS_MAC = platform.system() == 'Darwin'

from PySide6.QtCore import Signal as pyqtSignal, Slot as pyqtSlot, Property as pyqtProperty, QObject, QUrl, QCoreApplication, Qt, QElapsedTimer, QThread, QTimer, qInstallMessageHandler, QLibraryInfo
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance, qmlRegisterSingletonType, qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon

from translation import Translator
from paths import CRASH_LOG_PATH, ensure_project_cwd, project_path
from qml_compat import register_qml_singleton
from qt_env_report import dump_qt_env

NAME = "qDiffusion"
LAUNCHER = project_path("qDiffusion.exe")
APPID = "arenasys.qdiffusion." + hashlib.md5(LAUNCHER.encode("utf-8")).hexdigest()
ERRORED = False
_qml_warnings = []

class Application(QApplication):
    t = QElapsedTimer()

    def event(self, e):
        return QApplication.event(self, e)
        
def buildQMLRc():
    qml_path = os.path.join("source", "qml")
    qml_rc = os.path.join(qml_path, "qml.qrc")
    if os.path.exists(qml_rc):
        os.remove(qml_rc)

    items = []

    tabs = glob.glob(os.path.join("source", "tabs", "*"))
    for tab in tabs:
        for src in glob.glob(os.path.join(tab, "*.*")):
            if src.split(".")[-1] in {"qml","svg"}:
                dst = os.path.join(qml_path, os.path.relpath(src, "source"))
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy(src, dst)
                items += [dst]

    items += glob.glob(os.path.join(qml_path, "*.qml"))
    items += glob.glob(os.path.join(qml_path, "components", "*.qml"))
    items += glob.glob(os.path.join(qml_path, "style", "*.qml"))
    items += glob.glob(os.path.join(qml_path, "fonts", "*.ttf"))
    items += glob.glob(os.path.join(qml_path, "icons", "*.svg"))

    items = ''.join([f"\t\t<file>{os.path.relpath(f, qml_path )}</file>\n" for f in items])

    contents = f"""<RCC>\n\t<qresource prefix="/">\n{items}\t</qresource>\n</RCC>"""

    with open(qml_rc, "w") as f:
        f.write(contents)

def buildQMLPy():
    qml_path = os.path.join("source", "qml")
    qml_py = os.path.join(qml_path, "qml_rc.py")
    qml_rc = os.path.join(qml_path, "qml.qrc")

    if os.path.exists(qml_py):
        os.remove(qml_py)
    
    startupinfo = None
    if IS_WIN:
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

    status = subprocess.run(["pyside6-rcc", "-o", qml_py, qml_rc], capture_output=True, startupinfo=startupinfo)
    if status.returncode != 0:
        raise Exception(status.stderr.decode("utf-8", errors="replace"))

    shutil.rmtree(os.path.join(qml_path, "tabs"))
    os.remove(qml_rc)

def loadTabs(app, backend):
    tabs = []
    for tab in glob.glob(os.path.join("source", "tabs", "*")):
        tab_name = tab.split(os.path.sep)[-1]
        if tab_name == "editor":
            continue
        tab_name_c = tab_name.capitalize()
        try:
            tab_module = importlib.import_module(f"tabs.{tab_name}.{tab_name}")
            tab_class = getattr(tab_module, tab_name_c)
            tab_instance = tab_class(parent=app)
            tab_instance.source = f"qrc:/tabs/{tab_name}/{tab_name_c}.qml"
            tabs += [tab_instance]
        except Exception as e:
            raise e
            #continue
    for tab in tabs:
        if not hasattr(tab, "priority"):
            tab.priority = len(tabs)
    
    tabs.sort(key=lambda tab: tab.priority)
    backend.registerTabs(tabs)

class Builder(QThread):
    def __init__(self, app, engine):
        super().__init__()
        self.app = app
        self.engine = engine
    
    def run(self):
        buildQMLRc()
        buildQMLPy()

def _requirement_satisfied(requirement: Requirement, installed_version: str, enforce_version: bool) -> bool:
    if not enforce_version or not str(requirement.specifier):
        return True

    try:
        return requirement.specifier.contains(Version(installed_version), prereleases=True)
    except InvalidVersion:
        return False


def check(dependancies, enforce_version=True):
    needed = []
    for d in dependancies:
        try:
            requirement = Requirement(d)
        except Exception:
            needed += [d]
            continue

        if requirement.marker and not requirement.marker.evaluate():
            continue

        try:
            installed_version = metadata.version(requirement.name)
        except metadata.PackageNotFoundError:
            needed += [d]
            continue
        except Exception:
            needed += [d]
            continue

        if not _requirement_satisfied(requirement, installed_version, enforce_version):
            needed += [d]

    return needed


def parse_requirements(requirements_path, visited=None):
    requirements = []
    visited = visited or set()

    requirements_path = os.path.abspath(requirements_path)
    if requirements_path in visited or not os.path.exists(requirements_path):
        return requirements
    visited.add(requirements_path)

    with open(requirements_path, "r", encoding="utf-8") as file:
        for raw_line in file:
            line = raw_line.split("#", 1)[0].strip()
            if not line:
                continue

            if line.startswith(("-r", "--requirement")):
                include = line.split(maxsplit=1)
                if len(include) == 2:
                    include_path = include[1].strip()
                    include_path = os.path.join(os.path.dirname(requirements_path), include_path)
                    requirements += parse_requirements(include_path, visited)
                continue

            # pip install options that do not represent packages
            if line.startswith(("-c", "--constraint", "--index-url", "--extra-index-url", "--find-links", "-f", "--pre")):
                continue

            requirements.append(line)

    return requirements


def load_inference_requirements():
    infer_path = os.path.join("source", "sd-inference-server")
    candidates = [
        os.path.join(infer_path, "requirements.txt"),
        os.path.join(infer_path, "requirements_inference.txt"),
        os.path.join(infer_path, "requirements", "requirements.txt"),
        os.path.join(infer_path, "requirements", "requirements_inference.txt"),
        os.path.join(infer_path, "requirements", "inference.txt"),
    ]
    for requirements in candidates:
        if os.path.exists(requirements):
            return parse_requirements(requirements)

    fallback = os.path.join("source", "requirements_inference.txt")
    return parse_requirements(fallback)


TORCH_BUILD_MATRIX = {
    "nvidia": {
        "torch": "2.8.0+cu129",
        "torchvision": "0.23.0+cu129",
        "index": "cu129",
    },
    "amd": {
        "linux": {
            "torch": "2.8.0+rocm6.4",
            "torchvision": "0.23.0+rocm6.4",
            "index": "rocm6.4",
        },
        "windows": {
            # No Python 3.14 torch-directml build is currently available.
            "torch-directml": None,
        },
    },
}

class Installer(QThread):
    output = pyqtSignal(str)
    installing = pyqtSignal(str)
    installed = pyqtSignal(str)
    def __init__(self, parent, packages):
        super().__init__(parent)
        self.packages = packages
        self.proc = None
        self.stopping = False

    def _build_install_args(self, package):
        args = ["pip", "install", "-U", package]
        pkg = package.split("=", 1)[0].strip().lower()
        if pkg == "pyside6":
            args[2:2] = ["--ignore-requires-python", "--force-reinstall"]
        if pkg in {"torch", "torchvision"} and "+" in package:
            build_channel = package.rsplit("+", 1)[-1]
            args += ["--index-url", "https://download.pytorch.org/whl/" + build_channel]
        return [sys.executable.replace("pythonw", "python"), "-m"] + args

    def run(self):
        for p in self.packages:
            self.installing.emit(p)
            args = self._build_install_args(p)

            startupinfo = None
            if IS_WIN:
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

            self.proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=os.environ, startupinfo=startupinfo)

            output = ""
            while self.proc.poll() == None:
                while line := self.proc.stdout.readline():
                    if line:
                        line = line.strip()
                        output += line + "\n"
                        self.output.emit(line)
                    if self.stopping:
                        return
            if self.stopping:
                return
            if self.proc.returncode:
                raise RuntimeError("Failed to install: ", p, "\n", output)
            
            self.installed.emit(p)
        self.proc = None

    @pyqtSlot()
    def stop(self):
        self.stopping = True
        if self.proc:
            self.proc.kill()

class Coordinator(QObject):
    ready = pyqtSignal()
    show = pyqtSignal()
    proceed = pyqtSignal()
    cancel = pyqtSignal()

    output = pyqtSignal(str)

    updated = pyqtSignal()
    installedUpdated = pyqtSignal()
    def __init__(self, app, engine):
        super().__init__(app)
        self.app = app
        self.engine = engine
        self.builder = Builder(app, engine)
        self.builder.finished.connect(self.loaded)
        self.installer = None

        self._needRestart = False
        self._installed = []
        self._installing = ""

        self._modes = ["nvidia", "amd", "remote"]

        self._mode = 0
        self.in_venv = "VIRTUAL_ENV" in os.environ

        self.venv_cache = None
        if self.in_venv:
            self.venv_cache = os.path.join(os.environ["VIRTUAL_ENV"], "cache")
            if "PIP_CONFIG_FILE" in os.environ and not "PIP_CACHE_DIR" in os.environ:
                os.environ["PIP_CACHE_DIR"] = self.venv_cache

        self.override = False

        self.enforce = True

        try:
            with open("config.json", "r", encoding="utf-8") as f:
                cfg = json.load(f)
                if "show_installer" in cfg:
                    self.override = cfg["show_installer"]
                if "enforce_versions" in cfg:
                    self.enforce = cfg["enforce_versions"]
                mode = self._modes.index(cfg["mode"].lower())
                self._mode = mode
        except Exception:
            pass

        self.required = parse_requirements(os.path.join("source", "requirements_gui.txt"))
        self.optional = load_inference_requirements()

        self.find_needed()

        qmlRegisterSingletonInstance(Coordinator, "gui", 1, 0, "COORDINATOR", self)

    def find_needed(self):
        self.install_blocker = ""
        self.torch_version = ""
        self.torchvision_version = ""
        self.directml_version = ""

        try:
            self.torch_version = metadata.version("torch")
        except Exception:
            pass

        try:
            self.torchvision_version = metadata.version("torchvision")
        except Exception:
            pass

        try:
            self.directml_version = metadata.version("torch-directml")
        except Exception:
            pass

        nvidia_cfg = TORCH_BUILD_MATRIX["nvidia"]
        amd_cfg = TORCH_BUILD_MATRIX["amd"]

        self.nvidia_torch_version = nvidia_cfg["torch"]
        self.nvidia_torchvision_version = nvidia_cfg["torchvision"]

        self.amd_torch_version = amd_cfg["linux"]["torch"]
        self.amd_torchvision_version = amd_cfg["linux"]["torchvision"]

        self.amd_torch_directml_version = amd_cfg["windows"]["torch-directml"]
        
        self.required_need = check(self.required, self.enforce)
        self.optional_need = check(self.optional, self.enforce)
    
    @pyqtProperty(list, constant=True)
    def modes(self):
        return ["Nvidia", "AMD", "Remote"]

    @pyqtProperty(int, notify=updated)
    def mode(self):
        return self._mode
    
    @mode.setter
    def mode(self, mode):
        self._mode = mode
        self.writeMode()
        self.updated.emit()

    def writeMode(self):
        cfg = {}
        try:
            with open("config.json", "r", encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception as e:
            pass
        cfg['mode'] = self._modes[self._mode]
        with open("config.json", "w", encoding="utf-8") as f:
            json.dump(cfg, f, indent=4)
    
    def clearCache(self):
        # if the cache is ours then clear it
        if os.environ.get("PIP_CACHE_DIR") == self.venv_cache:
            shutil.rmtree(self.venv_cache, ignore_errors=True)

    @pyqtProperty(bool, notify=updated)
    def enforceVersions(self):
        return self.enforce
    
    @enforceVersions.setter
    def enforceVersions(self, enforce):
        self.enforce = enforce
        self.find_needed()
        self.updated.emit()

    @pyqtProperty(list, notify=updated)
    def packages(self):
        return self.get_needed()
    
    @pyqtProperty(list, notify=installedUpdated)
    def installed(self):
        return self._installed
    
    @pyqtProperty(str, notify=installedUpdated)
    def installing(self):
        return self._installing
    
    @pyqtProperty(bool, notify=installedUpdated)
    def disable(self):
        return self.installer != None
    
    @pyqtProperty(bool, notify=updated)
    def needRestart(self):
        return self._needRestart

    def get_needed(self):
        mode = self._modes[self._mode]
        needed = []

        def _has_variant(version, variant):
            return "+" in version and version.rsplit("+", 1)[-1].startswith(variant)

        self.install_blocker = ""
        if mode == "nvidia":
            if not _has_variant(self.torch_version, "cu"):
                needed += ["torch=="+self.nvidia_torch_version]
            if not _has_variant(self.torchvision_version, "cu"):
                needed += ["torchvision=="+self.nvidia_torchvision_version]
            needed += self.optional_need
        if mode == "amd":
            if IS_WIN:
                if self.amd_torch_directml_version is None:
                    self.install_blocker = (
                        "No compatible torch-directml package is currently available for this Python version on Windows. "
                        "Use Remote mode, switch to Nvidia mode, or use a Python version supported by torch-directml."
                    )
                elif not self.directml_version:
                    needed += ["torch-directml==" + self.amd_torch_directml_version]
            else:
                if not _has_variant(self.torch_version, "rocm"):
                    needed += ["torch=="+self.amd_torch_version]
                if not _has_variant(self.torchvision_version, "rocm"):
                    needed += ["torchvision=="+self.amd_torchvision_version]
            needed += self.optional_need

        needed += self.required_need

        if needed:
            needed = list(dict.fromkeys(needed))

            # PyQt5 is not supported in this codebase. Remove any stale PyQt5
            # entries and enforce the project's PySide6 runtime pin.
            needed = [package for package in needed if not package.lower().startswith("pyqt5")]
            pyside_pin = next((pkg for pkg in self.required if pkg.lower().startswith("pyside6")), "PySide6==6.10.2")
            if not any(pkg.lower().startswith("pyside6") for pkg in needed):
                needed.append(pyside_pin)

            needed = ["pip", "wheel"] + needed

        return needed

    @pyqtSlot()
    def load(self):
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        icon = os.path.join(root, "source", "qml", "icons", "placeholder.svg")
        self.app.setWindowIcon(QIcon(icon))
        QTimer.singleShot(0, self.loaded)

    @pyqtSlot()
    def loaded(self):
        ready()
        self.ready.emit()

        if self.override or (self.in_venv and self.packages):
            self.show.emit()
        else:
            self.done()
        
    @pyqtSlot()
    def done(self):
        start(self.engine, self.app)
        self.proceed.emit()

    @pyqtSlot()
    def install(self):
        if self.installer:
            self.cancel.emit()
            return
        if self.install_blocker:
            self.output.emit("Installer blocked: " + self.install_blocker)
            raise RuntimeError(self.install_blocker)
        packages = self.packages
        if not packages:
            self.done()
            return
        self.installer = Installer(self, packages)
        self.installer.installed.connect(self.onInstalled)
        self.installer.installing.connect(self.onInstalling)
        self.installer.output.connect(self.onOutput)
        self.installer.finished.connect(self.doneInstalling)
        self.app.aboutToQuit.connect(self.installer.stop)
        self.cancel.connect(self.installer.stop)
        self.installer.start()
        self.installedUpdated.emit()

    @pyqtSlot(str)
    def onInstalled(self, package):
        self._installed += [package]
        self.installedUpdated.emit()
    
    @pyqtSlot(str)
    def onInstalling(self, package):
        self._installing = package
        self.installedUpdated.emit()
    
    @pyqtSlot(str)
    def onOutput(self, out):
        self.output.emit(out)
    
    @pyqtSlot()
    def doneInstalling(self):
        self.writeMode()
        self.clearCache()

        self._installing = ""
        self.installer = None
        self.installedUpdated.emit()
        self.find_needed()
        if not self.packages:
            self.done()
            return
        self.installer = None
        self.installedUpdated.emit()
        if all([p in self._installed for p in self.packages]):
            self._needRestart = True
            self.updated.emit()

    @pyqtProperty(float, constant=True)
    def scale(self):
        if IS_WIN:
            factor = round(QApplication.primaryScreen().logicalDotsPerInchX()*(100/96))
            if factor == 125:
                return 0.82
        if IS_MAC:
            factor = round(QApplication.primaryScreen().logicalDotsPerInchX()*(100/96))
            if factor == 75:
                return 1.25
        return 1.0


def _on_qml_warnings(warnings):
    for w in warnings:
        warning = f"QML WARNING: {w.toString()}"
        _qml_warnings.append(warning)
        print(warning, file=sys.stderr, flush=True)
        with open(CRASH_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"GUI {datetime.datetime.now()}\n{warning}\n")


def _qt_env_logger(line):
    text = str(line)
    print(text, file=sys.stderr, flush=True)
    with open(CRASH_LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"{text}\n")


def _force_qt_runtime_paths():
    for env_var in (
        "QML_IMPORT_PATH",
        "QML2_IMPORT_PATH",
        "QML_PLUGIN_PATH",
        "QT_PLUGIN_PATH",
        "QT_QPA_PLATFORM_PLUGIN_PATH",
    ):
        os.environ.pop(env_var, None)

    plugins = QLibraryInfo.path(QLibraryInfo.LibraryPath.PluginsPath)
    qml = QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath)
    return plugins, qml


def _is_truthy_env(value):
    if value is None:
        return False
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _is_within_root(path_text, root):
    if not path_text:
        return False
    try:
        path_obj = Path(path_text).resolve(strict=False)
        path_obj.relative_to(root)
        return True
    except Exception:
        return False


def _collect_external_qt_paths(engine_import_paths=None):
    runtime_root = Path(sys.prefix).resolve(strict=False)
    suspicious = []

    def _looks_like_qt_sdk_path(path_text):
        normalized = path_text.replace("/", "\\")
        return bool(re.search(r"(^|\\)Qt([\\]|$)", normalized, flags=re.IGNORECASE))

    path_value = os.environ.get("PATH", "")
    for raw_entry in path_value.split(os.pathsep):
        entry = raw_entry.strip().strip('"')
        if not entry:
            continue

        if _looks_like_qt_sdk_path(entry):
            if not _is_within_root(entry, runtime_root):
                suspicious.append(("PATH", entry))

    qlibrary_candidates = {
        "QLibraryInfo.PluginsPath": QLibraryInfo.path(QLibraryInfo.LibraryPath.PluginsPath),
        "QLibraryInfo.QmlImportsPath": QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath),
        "QLibraryInfo.LibrariesPath": QLibraryInfo.path(QLibraryInfo.LibraryPath.LibrariesPath),
        "QLibraryInfo.BinariesPath": QLibraryInfo.path(QLibraryInfo.LibraryPath.BinariesPath),
    }
    for source, candidate in qlibrary_candidates.items():
        if candidate and not _is_within_root(candidate, runtime_root):
            suspicious.append((source, candidate))

    for candidate in engine_import_paths or []:
        if candidate and _looks_like_qt_sdk_path(candidate) and not _is_within_root(candidate, runtime_root):
            suspicious.append(("engine.importPathList()", candidate))

    deduped = []
    seen = set()
    for source, candidate in suspicious:
        key = (source, os.path.normcase(candidate))
        if key in seen:
            continue
        seen.add(key)
        deduped.append((source, candidate))
    return deduped


def _enforce_strict_qt_env(engine_import_paths=None):
    if not _is_truthy_env(os.environ.get("STRICT_QT_ENV")):
        return

    suspicious = _collect_external_qt_paths(engine_import_paths=engine_import_paths)
    if not suspicious:
        return

    details = "\n".join([f"- {source}: {path}" for source, path in suspicious])
    raise RuntimeError(
        "Detected external Qt/QML paths (C:\\Qt...). This app must run using venv PySide6 Qt only. "
        "Remove Qt SDK from PATH or use the launcher.\n"
        f"Detected paths:\n{details}"
    )


def _validate_applicationwindow_content(qml_root):
    qml_root = Path(qml_root)
    violations = []

    for qml_path in sorted(qml_root.rglob("*.qml")):
        try:
            lines = qml_path.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue

        depth = 0
        window_depths = []

        for line_no, line in enumerate(lines, start=1):
            stripped = line.strip()
            line_depth = depth

            if stripped.startswith("ApplicationWindow") and "{" in stripped:
                window_depths.append(line_depth)

            if window_depths and line_depth == window_depths[-1] + 1 and re.match(r"^Component\s*\{", stripped):
                violations.append(f"{qml_path}:{line_no}")

            depth += line.count("{") - line.count("}")
            while window_depths and depth <= window_depths[-1]:
                window_depths.pop()

    if violations:
        details = "\n".join([f"- {item}" for item in violations])
        raise RuntimeError(
            "Found inline Component {} declarations directly under ApplicationWindow. "
            "Use concrete visual items (e.g., Item/Image) or instantiate safely elsewhere.\n"
            f"Violations:\n{details}"
        )


def launch(url):
    import misc

    _qml_warnings.clear()

    prepareQmlResources()

    if url:
        sgnl = misc.Signaller()
        if sgnl.status():
            sgnl.send(url)
            exit()

    if IS_WIN:
        misc.setAppID(APPID)

    plugins, qml = _force_qt_runtime_paths()
    _enforce_strict_qt_env()
    _validate_applicationwindow_content(project_path("source", "qml"))

    QCoreApplication.setAttribute(Qt.AA_UseDesktopOpenGL, True)

    scaling = False
    try:
        if os.path.exists("config.json"):
            with open("config.json", "r") as f:
                scaling = json.load(f)["scaling"]
    except:
        pass

    if scaling:
        QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)

    app = Application([NAME])
    if plugins:
        QCoreApplication.setLibraryPaths([plugins])

    signal.signal(signal.SIGINT, lambda sig, frame: app.quit())
    app.startTimer(100)

    app.setOrganizationName("qDiffusion")
    app.setOrganizationDomain("qDiffusion")
    app.endpoint = url

    engine = QQmlApplicationEngine()
    if qml:
        engine.addImportPath(qml)

    _enforce_strict_qt_env(engine_import_paths=engine.importPathList())

    with open(CRASH_LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"GUI {datetime.datetime.now()}\n")
        f.write(f"FORCED QT PLUGIN PATH: {plugins or '(none)'}\n")
        f.write(f"FORCED QML IMPORT PATH: {qml or '(none)'}\n")

    print(f"FORCED QT PLUGIN PATH: {plugins or '(none)'}", file=sys.stderr, flush=True)
    print(f"FORCED QML IMPORT PATH: {qml or '(none)'}", file=sys.stderr, flush=True)

    dump_qt_env(_qt_env_logger, app=app, engine=engine)

    engine.quit.connect(app.quit)
    engine.warnings.connect(_on_qml_warnings)
    engine.addImportPath(project_path("source", "qml"))
    
    translator = Translator(app)
    coordinator = Coordinator(app, engine)
    misc.registerTypes()

    context = engine.rootContext()
    context.setContextProperty("TRANSLATOR", translator)
    context.setContextProperty("COORDINATOR", coordinator)

    app_qml = QUrl("qrc:/App.qml")
    engine.load(app_qml)

    root_objects = engine.rootObjects()
    if not root_objects:
        warning_text = "\n".join(_qml_warnings) or "(no QML warnings captured)"
        with open(CRASH_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"GUI {datetime.datetime.now()}\nQML ERRORS:\n{warning_text}\n")
        raise RuntimeError(
            f"Failed to load QML root object: {app_qml.toString()}\n{warning_text}"
        )

    if IS_WIN:
        hwnd = root_objects[0].winId()
        misc.setWindowProperties(hwnd, APPID, NAME, LAUNCHER)

    os._exit(app.exec())

def ready():
    qmlRegisterSingletonType(QUrl("qrc:/Common.qml"), "gui", 1, 0, "COMMON")


def prepareQmlResources():
    buildQMLRc()
    buildQMLPy()

    # qml.qml_rc is generated at runtime; import it only after build
    # completion so the current resource bundle is what gets registered.
    import qml.qml_rc

def start(engine, app):
    import gui
    import sql
    import canvas
    import parameters
    import manager

    sql.registerTypes()
    canvas.registerTypes()
    canvas.registerMiscTypes()
    parameters.registerTypes()
    manager.registerTypes()

    backend = gui.GUI(parent=app)

    engine.addImageProvider("sync", backend.thumbnails.sync_provider)
    engine.addImageProvider("async", backend.thumbnails.async_provider)
    engine.addImageProvider("big", backend.thumbnails.big_provider)

    qmlRegisterSingletonInstance(gui.GUI, "gui", 1, 0, "GUI", backend)
    
    loadTabs(backend, backend)

def exceptHook(exc_type, exc_value, exc_tb):
    global ERRORED
    tb = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
    with open(CRASH_LOG_PATH, "a", encoding='utf-8') as f:
        f.write(f"GUI {datetime.datetime.now()}\n{tb}\n")
    print(tb)
    print(f"TRACEBACK SAVED: {CRASH_LOG_PATH}")

    if IS_WIN and os.path.exists(LAUNCHER) and not ERRORED:
        ERRORED = True
        message = f"{tb}\nError saved to {CRASH_LOG_PATH}"
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        subprocess.run([LAUNCHER, "-e", message], startupinfo=startupinfo)

    QApplication.exit(-1)

def main():
    ensure_project_cwd()

    sys.excepthook = exceptHook

    url = None
    try:
        parser = argparse.ArgumentParser(description='qDiffusion')
        parser.add_argument("url", type=str, help="remote endpoint URL", nargs='?')
        url = parser.parse_args().url
    except Exception:
        pass
    
    launch(url)

if __name__ == "__main__":
    main()
