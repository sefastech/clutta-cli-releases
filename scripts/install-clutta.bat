@echo off
setlocal enabledelayedexpansion

:: Clutta CLI Windows Installation Script
set "REPO=sefastech/clutta-cli-releases"

:: Step 1: Input parsing - No CLI version specified
if "%~1" == "" (
    call :fetch_latest_version
    call :install_binary !VERSION!
    exit /b
)

:: Step 2: Input parsing - CLI version provided
if "%~1" == "-v" (
    if not "%~2" == "" (
        set "VERSION=%~2"
        echo Version: !VERSION!
        call :install_binary !VERSION!
        exit /b
    ) else (
        echo Error: Version number is not given.
        call :usage
        exit /b 1
    )
) else (
    call :usage
)

:: Function Definitions

:: Function to display usage information
:usage
echo Usage: %~nx0 [-v version]
echo -v version   Specify the version to install (e.g., v1.0.0). Defaults to the latest version if not specified.
exit /b 1

:: Function to fetch the latest CLI version from GitHub API
:fetch_latest_version
for /f "delims=" %%i in ('curl -s -k "https://api.github.com/repos/%REPO%/releases/latest" ^| jq -r ".tag_name"') do (
    set "VERSION=%%i"
)
exit /b

:: Function to install the specified version of Clutta CLI
:install_binary
if "%~1" == "" (
    echo No Clutta CLI version found.
    call :usage
    exit /b 1
)

:: Step a: Get OS architecture
call :get_os_architecture

:: Step b: Set download variables
set "FILENAME=clutta-cli_windows_!ARCH!.exe"
set "DOWNLOAD_URL=https://github.com/!REPO!/releases/download/%~1/!FILENAME!"

:: Step c: Download the file
call :download_from_url !DOWNLOAD_URL!

exit /b

:: Function to get OS architecture
:get_os_architecture
set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=arm64"
)
exit /b

:: Function to download Clutta CLI from a given URL
:download_from_url
echo Downloading Clutta CLI from: %~1
curl -k -L -o clutta.exe %~1

:: Step d: Verify if the download was successful
if %ERRORLEVEL% neq 0 (
    echo Error: Download failed.
    exit /b 1
)

:: Step e: Move the binary to a directory in the system PATH
move /y clutta.exe "%SystemRoot%\System32\clutta.exe"
if %ERRORLEVEL% neq 0 (
    echo Failed to move clutta.exe to %SystemRoot%\System32.
    del clutta.exe
    exit /b 1
)

echo Clutta CLI version %VERSION% installed successfully!
exit /b
