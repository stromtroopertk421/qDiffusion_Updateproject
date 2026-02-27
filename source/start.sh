#!/bin/bash

SCRIPT=$(realpath "$0")
SCRIPT_DIR=$(realpath $(dirname "$0"))

cd "$SCRIPT_DIR"

echo "[Desktop Entry]
Exec=$SCRIPT %u
Name=qDiffusion
Icon=$SCRIPT_DIR/launcher/icon.png
MimeType=application/x-qdiffusion;x-scheme-handler/qdiffusion;
Type=Application
StartupNotify=false
Terminal=false" > qDiffusion-handler.desktop
xdg-desktop-menu install qDiffusion-handler.desktop
xdg-mime default qDiffusion-handler.desktop x-scheme-handler/qdiffusion
rm qDiffusion-handler.desktop
chmod +x $SCRIPT

cd ..

python_version_ok=""
if [ -x "./python/bin/python3" ]; then
    python_version_ok=$(./python/bin/python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || true)
    if [ "$python_version_ok" != "3.14" ]; then
        rm -rf ./python
    fi
fi

if [ ! -d "./python" ]
then
    flags=$(grep flags /proc/cpuinfo)
    arch="x86_64"
    if [[ $flags == *"sse4"* ]]; then
        arch="x86_64_v2"
    fi
    if [[ $flags == *"avx2"* ]]; then
        arch="x86_64_v3"
    fi
    if [[ $flags == *"avx512"* ]]; then
        arch="x86_64_v4"
    fi

    artifact_arch="$arch"
    if [[ "$artifact_arch" == "x86_64_v4" ]]; then
        artifact_arch="x86_64_v3"
    fi

    python_url="https://github.com/astral-sh/python-build-standalone/releases/download/20260211/cpython-3.14.3+20260211-$artifact_arch-unknown-linux-gnu-install_only.tar.gz"

    echo "DOWNLOADING PYTHON ($arch -> $artifact_arch)..."
    if ! curl -fL --progress-bar "$python_url" -o "python.tar.gz"; then
        echo "ERROR: Failed to download bundled Python 3.14 for Linux architecture '$arch'."
        echo "Tried URL: $python_url"
        exit 1
    fi

    echo "EXTRACTING PYTHON..."
    if ! tar -xf "python.tar.gz"; then
        echo "ERROR: Failed to extract bundled Python archive."
        rm -f "python.tar.gz"
        exit 1
    fi
    rm "python.tar.gz"
fi
./python/bin/python3 source/launch.py "$@"
