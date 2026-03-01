from __future__ import annotations

import os
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def _iter_qrc_inputs(qrc_path: Path) -> list[Path]:
    """
    Returns qrc_path + every <file> referenced inside it, resolved to absolute paths.
    """
    try:
        tree = ET.parse(qrc_path)
    except Exception as exc:
        raise RuntimeError(f"Failed to parse QRC XML: {qrc_path}") from exc

    base = qrc_path.parent
    inputs: list[Path] = [qrc_path]

    for file_el in tree.findall(".//file"):
        rel = (file_el.text or "").strip()
        if not rel:
            continue
        inputs.append((base / rel).resolve())

    return inputs


def _latest_mtime(paths: list[Path]) -> float:
    newest = 0.0
    for p in paths:
        try:
            newest = max(newest, p.stat().st_mtime)
        except FileNotFoundError:
            # Force rebuild if something referenced is missing;
            # pyside6-rcc will then error with a precise path.
            newest = max(newest, time.time())
    return newest


def _find_pyside6_rcc() -> str:
    """
    Find pyside6-rcc inside the current interpreter's environment (venv).
    """
    prefix = Path(sys.prefix)
    candidates: list[Path] = []

    if os.name == "nt":
        candidates += [
            prefix / "Scripts" / "pyside6-rcc.exe",
            prefix / "Scripts" / "pyside6-rcc.bat",
            prefix / "Scripts" / "pyside6-rcc",
        ]
    else:
        candidates += [
            prefix / "bin" / "pyside6-rcc",
            prefix / "Scripts" / "pyside6-rcc",
        ]

    for c in candidates:
        if c.exists():
            return str(c)

    # Fallback: PATH lookup
    for name in ("pyside6-rcc.exe", "pyside6-rcc"):
        hit = shutil.which(name)
        if hit:
            return hit

    raise FileNotFoundError(
        "Could not find 'pyside6-rcc'. PySide6 may not be installed in this environment."
    )


def ensure_qml_resources(force: bool = False) -> bool:
    """
    Regenerate source/qml/qml_rc.py if it is missing or older than qml.qrc / referenced files.

    Returns:
        True if rebuilt, False if already up-to-date.

    Env toggles:
        QDIFFUSION_SKIP_QML_RCC=1   -> never rebuild
        QDIFFUSION_FORCE_QML_RCC=1  -> rebuild every run
    """
    if os.environ.get("QDIFFUSION_SKIP_QML_RCC") == "1":
        return False

    force = force or (os.environ.get("QDIFFUSION_FORCE_QML_RCC") == "1")

    qml_dir = Path(__file__).resolve().parent
    qrc_path = qml_dir / "qml.qrc"
    out_py = qml_dir / "qml_rc.py"

    if not qrc_path.exists():
        raise FileNotFoundError(f"Missing qml.qrc: {qrc_path}")

    inputs = _iter_qrc_inputs(qrc_path)
    newest_input = _latest_mtime(inputs)
    out_mtime = out_py.stat().st_mtime if out_py.exists() else 0.0

    if not force and out_mtime >= newest_input:
        return False

    rcc = _find_pyside6_rcc()
    cmd = [rcc, str(qrc_path), "-o", str(out_py)]

    # Avoid popping a console window on Windows when running under pythonw.exe
    creationflags = 0
    if os.name == "nt":
        creationflags = 0x08000000  # CREATE_NO_WINDOW

    subprocess.run(
        cmd,
        cwd=str(qml_dir),          # Important: makes relative <file> paths resolve correctly
        check=True,
        creationflags=creationflags,
    )
    return True
