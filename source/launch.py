import sys
import subprocess
import os
import platform
import traceback
import datetime
import importlib.util
import shutil

from paths import ensure_project_cwd

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
VENV_DIR = os.path.join(PROJECT_DIR, "venv")
LAUNCH_PATH = os.path.abspath(__file__)
LOG_PATH = os.path.join(PROJECT_DIR, "launch.log")
IS_WIN = platform.system() == 'Windows'
PYTHON_RUN = sys.executable

PYTHON_TARGET_VERSION = "3.14.3"
QT_PACKAGE = "PySide6"
QT_VER = "PySide6==6.10.2"
BOOTSTRAP_PACKAGES = ["packaging==24.2"]


def qt_version_matches_target():
    try:
        from PySide6.QtCore import Qt  # noqa: F401
        return True
    except Exception:
        return False


MISSING_QT = not qt_version_matches_target()


def log(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{timestamp}] {message}"
    print(line)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def get_env():
    env = {k:v for k,v in os.environ.items() if not k.startswith("QT") and not k.startswith("PIP") and not k.startswith("PYTHON")}
    env["VIRTUAL_ENV"] = VENV_DIR
    env["PIP_CACHE_DIR"] = os.path.join(VENV_DIR, "cache")
    env["PIP_CONFIG_FILE"] = os.devnull
    current_path = env.get("PATH", "")
    if IS_WIN:
        env["PATH"] = VENV_DIR+"\\Scripts;" + current_path
    else:
        env["PATH"] = VENV_DIR+"/bin:" + current_path
    
    if not IS_WIN and not "HSA_OVERRIDE_GFX_VERSION" in env:
        env["HSA_OVERRIDE_GFX_VERSION"] = "10.3.0"
    if not IS_WIN and not "MIOPEN_LOG_LEVEL" in env:
        env["MIOPEN_LOG_LEVEL"] = "4"
    return env

def restart():
    venv_python = get_venv_python(gui=IS_WIN)
    if not os.path.exists(venv_python):
        raise FileNotFoundError(f"Missing venv python executable: {venv_python}")

    command = [venv_python, LAUNCH_PATH] + sys.argv[1:]
    log(f"RESTARTING VIA: {' '.join(command)}")
    if IS_WIN:
        subprocess.Popen(command, env=get_env(), creationflags=0x00000008 | 0x00000200)
    else:
        subprocess.Popen(command, env=get_env())
    exit()

def get_venv_python(gui=False):
    if IS_WIN:
        candidates = [
            "pythonw.exe" if gui else "python.exe",
            "python3.14w.exe" if gui else "python3.14.exe",
            "python3w.exe" if gui else "python3.exe"
        ]
        scripts_dir = os.path.join(VENV_DIR, "Scripts")
    else:
        candidates = ["python3.14", "python3", "python"]
        scripts_dir = os.path.join(VENV_DIR, "bin")

    for executable in candidates:
        candidate_path = os.path.join(scripts_dir, executable)
        if os.path.exists(candidate_path):
            return candidate_path

    return os.path.join(scripts_dir, candidates[-1])

def install_venv():
    log(f"CREATING VENV... ({VENV_DIR})")
    subprocess.run([PYTHON_RUN, "-m", "venv", VENV_DIR], check=True)

def venv_version_matches_target():
    cfg = os.path.join(VENV_DIR, "pyvenv.cfg")
    if not os.path.exists(cfg):
        return False

    try:
        with open(cfg, "r", encoding="utf-8") as f:
            for raw in f:
                line = raw.strip().lower()
                if line.startswith("version") and "=" in line:
                    version = line.split("=", 1)[1].strip()
                    return version.startswith(PYTHON_TARGET_VERSION)
    except Exception:
        return False

    return False

def install_qt():
    log("INSTALLING PySide6...")
    subprocess.run([get_venv_python(), "-m", "pip", "install", "--ignore-requires-python", "--force-reinstall", QT_VER], env=get_env(), check=True)


def install_bootstrap_package(package):
    log(f"INSTALLING BOOTSTRAP PACKAGE {package}...")
    subprocess.run([get_venv_python(), "-m", "pip", "install", "-U", package], env=get_env(), check=True)


def ensure_bootstrap_packages():
    for package in BOOTSTRAP_PACKAGES:
        module_name = package.split("=", 1)[0].strip().replace("-", "_")
        if not importlib.util.find_spec(module_name):
            install_bootstrap_package(package)

def exceptHook(exc_type, exc_value, exc_tb):
    tb = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
    crash_path = os.path.join(PROJECT_DIR, "crash.log")
    with open(crash_path, "a", encoding='utf-8') as f:
        f.write(f"LAUNCH {datetime.datetime.now()}\n{tb}\n")
    print(tb)
    print(f"TRACEBACK SAVED: {crash_path}")

    if not "pythonw" in PYTHON_RUN:
        input("PRESS ENTER TO CLOSE")

if __name__ == "__main__":
    ensure_project_cwd()
    sys.excepthook = exceptHook
    log(f"LAUNCH START cwd={os.getcwd()} project={PROJECT_DIR} python={PYTHON_RUN}")

    if sys.version_info < (3, 14):
        print(f"Python 3.14 or greater is required. Have Python {sys.version_info[0]}.{sys.version_info[1]}.")
        input()
        exit()
    if not importlib.util.find_spec("pip"):
        print("PIP module is required.")
        input()
        exit()
    if not importlib.util.find_spec("venv"):
        print("VENV module is required.")
        input()
        exit()
    
    invalid = ''.join([c for c in VENV_DIR if ord(c) > 127])
    if invalid:
        print(f"PATH INVALID ({VENV_DIR}) CONTAINS UNICODE ({invalid})")
        if IS_WIN:
            VENV_DIR = os.getcwd()[0]+":\\qDiffusion"
            print(f"USING {VENV_DIR} INSTEAD")
        else:
            print("FAILED")
            input()
            exit()

    inside_venv = VENV_DIR in sys.executable and VENV_DIR in os.environ.get("PATH", "") and VENV_DIR == os.environ.get("VIRTUAL_ENV", "")
    missing_venv = not os.path.exists(VENV_DIR)
    stale_venv = (not missing_venv) and (not venv_version_matches_target())

    if stale_venv:
        log(f"REMOVING STALE VENV (expected Python {PYTHON_TARGET_VERSION})...")
        shutil.rmtree(VENV_DIR, ignore_errors=True)
        missing_venv = True

    if not inside_venv:
        if missing_venv:
            install_venv()
            install_qt()
            log("DONE.")
        restart()
    elif inside_venv and MISSING_QT:
        install_qt()

    ensure_bootstrap_packages()

    import main
    main.main()
