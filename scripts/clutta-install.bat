:: clutta-install.bat
:: This script installs or updates clutta-cli on Windows systems.

@echo off
setlocal

:: Function to display usage information
:usage
    echo Usage: %~nx0 [-v version]
    echo   -v version   Specify the version to install (e.g., v1.0.0). Defaults to the latest version if not specified.
    exit /b 1

:: Parse command-line options
set "VERSION="
:parse_args
if "%~1"=="" goto args_parsed
if "%~1"=="-v" (
    shift
    set "VERSION=%~1"
) else (
    call :usage
)
shift
goto parse_args
:args_parsed

:: Determine the architecture
set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=arm64"
)

:: Set the download URL
set "REPO=sefastech/clutta-cli-releases"
if not defined VERSION (
    :: Fetch the latest version tag from GitHub API
    for /f "tokens=2 delims=:" %%i in ('curl -s https://api.github.com/repos/%REPO%/releases/latest ^| findstr /i "tag_name"') do (
        set "VERSION=%%i"
    )
    set "VERSION=%VERSION:~2,-1%"
    if not defined VERSION (
        echo Failed to fetch the latest version.
        exit /b 1
    )
)

:: Construct the download URL
set "FILE=clutta-windows-%ARCH%.exe"
set "URL=https://github.com/%REPO%/releases/download/%VERSION%/%FILE%"

:: Download the binary
echo Downloading clutta version %VERSION% for Windows/%ARCH%...
curl -L -o clutta.exe "%URL%"
if errorlevel 1 (
    echo Download failed.
    exit /b 1
)

:: Move the binary to a directory in the system PATH
move /y clutta.exe "%SystemRoot%\System32\clutta.exe"
if errorlevel 1 (
    echo Failed to move clutta.exe to %SystemRoot%\System32.
    exit /b 1
)

echo clutta version %VERSION% installed successfully.
