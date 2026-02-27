@echo off

IF NOT EXIST "python" (
    cd ..
)

IF NOT EXIST "python" (
    set "PYTHON_URL=https://github.com/indygreg/python-build-standalone/releases/download/20230726/cpython-3.10.12+20230726-x86_64-pc-windows-msvc-shared-install_only.tar.gz"

    echo DOWNLOADING PYTHON...
    bitsadmin.exe /transfer "DOWNLOADING PYTHON 3.10..." "%PYTHON_URL%" "%CD%/python.tar.gz"
    IF ERRORLEVEL 1 (
        echo ERROR: Failed to download bundled Python 3.10 for Windows x86_64.
        echo Tried URL: %PYTHON_URL%
        exit /b 1
    )

    echo EXTRACTING PYTHON...
    tar -xf "python.tar.gz"
    IF ERRORLEVEL 1 (
        echo ERROR: Failed to extract bundled Python archive.
        del /Q "python.tar.gz"
        exit /b 1
    )

    del /Q "python.tar.gz"
)

.\python\python.exe source\launch.py
exit /b %ERRORLEVEL%
