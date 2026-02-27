@echo off

set "PYTHON_VERSION_OK="

IF NOT EXIST "python" (
    cd ..
)

IF EXIST "python\python.exe" (
    for /f "delims=" %%V in ('python\python.exe -c "import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))" 2^>nul') do set "PYTHON_VERSION_OK=%%V"
    if /I not "%PYTHON_VERSION_OK%"=="3.14" (
        rmdir /S /Q "python"
    )
)

IF NOT EXIST "python" (
    set "PYTHON_URL=https://github.com/indygreg/python-build-standalone/releases/download/20260112/cpython-3.14.0+20260112-x86_64-pc-windows-msvc-shared-install_only.tar.gz"

    echo DOWNLOADING PYTHON...
    bitsadmin.exe /transfer "DOWNLOADING PYTHON 3.14..." "%PYTHON_URL%" "%CD%/python.tar.gz"
    IF ERRORLEVEL 1 (
        echo ERROR: Failed to download bundled Python 3.14 for Windows x86_64.
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
