import os
import sys
from typing import Callable, Iterable, Optional

from PySide6 import __file__ as pyside6_file
from PySide6.QtCore import QCoreApplication, QLibraryInfo


def _safe_call(callable_obj, default="<unavailable>"):
    try:
        return callable_obj()
    except Exception as exc:
        return f"<error: {exc}>"


def _qlibraryinfo_path(path_enum) -> str:
    try:
        return QLibraryInfo.path(path_enum)
    except Exception:
        # Compatibility with older bindings that still expose location().
        return QLibraryInfo.location(path_enum)


def _iter_candidate_paths(*groups: Iterable[str]) -> Iterable[str]:
    for group in groups:
        for value in group:
            if value:
                yield value


def _collect_red_flags(paths: Iterable[str]) -> list[str]:
    warnings = []
    suspicious_tokens = (
        r"\\qt\\",
        r"/qt/",
        r":\\qt\\",
        r"qt\\6.",
        r"qt/6.",
    )

    for raw_path in paths:
        normalized = str(raw_path).lower().replace("/", "\\")
        if any(token in normalized for token in suspicious_tokens):
            warnings.append(f"Potential global Qt SDK path detected: {raw_path}")

    return warnings


def dump_qt_env(
    logger: Callable[[str], None],
    app: Optional[QCoreApplication] = None,
    engine=None,
    path_preview_limit: int = 50,
) -> None:
    """Write a Qt/QML environment diagnostic report through `logger`."""
    logger("=" * 80)
    logger("Qt/QML Environment Report")
    logger("=" * 80)

    logger(f"sys.executable: {sys.executable}")
    logger(f"sys.prefix: {sys.prefix}")
    logger("sys.path (first 10):")
    for i, p in enumerate(sys.path[:10]):
        logger(f"  [{i}] {p}")

    pyside6_base = os.path.dirname(os.path.abspath(pyside6_file))
    logger(f"PySide6.__file__: {pyside6_file}")
    logger(f"Derived PySide6 base directory: {pyside6_base}")

    library_paths = {
        "PluginsPath": _safe_call(lambda: _qlibraryinfo_path(QLibraryInfo.LibraryPath.PluginsPath)),
        "QmlImportsPath": _safe_call(lambda: _qlibraryinfo_path(QLibraryInfo.LibraryPath.QmlImportsPath)),
        "LibrariesPath": _safe_call(lambda: _qlibraryinfo_path(QLibraryInfo.LibraryPath.LibrariesPath)),
        "BinariesPath": _safe_call(lambda: _qlibraryinfo_path(QLibraryInfo.LibraryPath.BinariesPath)),
    }
    logger("QLibraryInfo paths:")
    for key, value in library_paths.items():
        logger(f"  {key}: {value}")

    effective_app = app or QCoreApplication.instance()
    if effective_app is None:
        logger("QCoreApplication.libraryPaths(): <app not created yet>")
        app_library_paths = []
    else:
        app_library_paths = list(QCoreApplication.libraryPaths())
        logger("QCoreApplication.libraryPaths():")
        for p in app_library_paths:
            logger(f"  {p}")

    if engine is None:
        logger("engine.importPathList(): <engine not created yet>")
        import_paths = []
    else:
        import_paths = _safe_call(lambda: list(engine.importPathList()), default=[])
        logger("engine.importPathList():")
        for p in import_paths:
            logger(f"  {p}")

    logger("Environment variables:")
    tracked_vars = [
        "QT_PLUGIN_PATH",
        "QT_QPA_PLATFORM_PLUGIN_PATH",
        "QML_IMPORT_PATH",
        "QML2_IMPORT_PATH",
        "QML_PLUGIN_PATH",
    ]
    for key in tracked_vars:
        value = os.environ.get(key)
        logger(f"  {key}: {value if value else '<not set>'}")

    path_value = os.environ.get("PATH")
    if path_value:
        if len(path_value) > path_preview_limit * 10:
            preview = path_value[: path_preview_limit * 10]
            logger(f"  PATH (truncated): {preview}... [len={len(path_value)}]")
        else:
            logger(f"  PATH: {path_value}")
    else:
        logger("  PATH: <not set>")

    logger("-" * 80)
    logger("Red Flags")
    logger("-" * 80)

    red_flag_inputs = list(
        _iter_candidate_paths(
            [sys.executable, sys.prefix, pyside6_file, pyside6_base],
            sys.path[:10],
            library_paths.values(),
            app_library_paths,
            import_paths,
            [os.environ.get(var, "") for var in tracked_vars],
            [path_value or ""],
        )
    )
    warnings = _collect_red_flags(red_flag_inputs)
    if warnings:
        for warning in warnings:
            logger(f"WARNING: {warning}")
    else:
        logger("No obvious global Qt SDK contamination tokens found in inspected paths.")

    logger("=" * 80)


def dump_qt_env_to_file(path: str, app: Optional[QCoreApplication] = None, engine=None) -> None:
    with open(path, "a", encoding="utf-8") as report_file:
        dump_qt_env(lambda line: report_file.write(f"{line}\n"), app=app, engine=engine)
