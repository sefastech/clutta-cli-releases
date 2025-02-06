@echo off
setlocal enabledelayedexpansion

:: Clutta CLI Windows Installation Script

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

:: Determine the system architecture
set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=arm64"
)

:: Set the GitHub repo
set "REPO=sefastech/clutta-cli-releases"

:: Fetch the latest version if none was specified
if not defined VERSION (
    echo Fetching the latest version...
    for /f "tokens=2 delims=:" %%i in ('curl -s https://api.github.com/repos/%REPO%/releases/latest ^| findstr /i "tag_name"') do (
        set "VERSION=%%i"
    )
    set "VERSION=!VERSION:~2,-1!"
    if not defined VERSION (
        echo Failed to fetch the latest version.
        exit /b 1
    )
)

:: Construct the correct filename based on actual GitHub releases
set "FILENAME=clutta-cli_windows_%ARCH%.exe"
set "URL=https://github.com/%REPO%/releases/download/%VERSION%/%FILENAME%"

:: Debug: Print the URL
echo Downloading Clutta CLI from: %URL%

:: Download the binary
curl -L -o clutta.exe "%URL%"
if errorlevel 1 (
    echo Download failed. Please check the release and filename.
    exit /b 1
)

:: Verify that the downloaded file is an executable
for /f %%i in ('certutil -hashfile clutta.exe MD5') do set "FILE_HASH=%%i"
if "%FILE_HASH%"=="" (
    echo Downloaded file is invalid or corrupted.
    exit /b 1
)

:: Move the binary to a directory in the system PATH
move /y clutta.exe "%SystemRoot%\System32\clutta.exe"
if errorlevel 1 (
    echo Failed to move clutta.exe to %SystemRoot%\System32.
    exit /b 1
)

echo Clutta CLI version %VERSION% installed successfully!
exit /b 0
