# Clutta CLI installer for Windows
#
# Usage (PowerShell):
#   iwr -useb https://clutta.io/install.ps1 | iex
#
# Environment variables (all optional):
#   $env:CLUTTA_VERSION     - install a specific version, e.g. "v0.0.1"
#   $env:CLUTTA_INSTALL_DIR - install to a custom directory

$ErrorActionPreference = 'Stop'

$Repo   = "sefastech/clutta-cli-releases"
$Binary = "clutta"

# ── Architecture detection ────────────────────────────────────────────────────

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    Write-Error "Unsupported architecture: $($env:PROCESSOR_ARCHITECTURE). Clutta for Windows supports x86_64 only."
    exit 1
}
$Asset = "${Binary}-windows-amd64.exe"

# ── Version resolution ────────────────────────────────────────────────────────

if ($env:CLUTTA_VERSION) {
    $Version = $env:CLUTTA_VERSION
} else {
    try {
        $Releases = Invoke-WebRequest -Uri "https://api.github.com/repos/${Repo}/releases" -UseBasicParsing |
                    ConvertFrom-Json
        $Version  = $Releases[0].tag_name
    } catch {
        Write-Error "Could not determine the latest version. Check your internet connection or set CLUTTA_VERSION."
        exit 1
    }
    if (-not $Version) {
        Write-Error "Could not determine the latest version."
        exit 1
    }
}

Write-Host "Installing clutta ${Version} (windows/amd64)..."

# ── Download ──────────────────────────────────────────────────────────────────

$BaseUrl = "https://github.com/${Repo}/releases/download/${Version}"
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    Write-Host "Downloading binary..."
    $BinaryPath   = Join-Path $TempDir $Asset
    $ChecksumPath = Join-Path $TempDir "sha256sums.txt"

    Invoke-WebRequest -Uri "${BaseUrl}/${Asset}"         -OutFile $BinaryPath   -UseBasicParsing
    Invoke-WebRequest -Uri "${BaseUrl}/sha256sums.txt"   -OutFile $ChecksumPath -UseBasicParsing

    # ── Checksum verification ─────────────────────────────────────────────────

    Write-Host "Verifying checksum..."

    $Actual   = (Get-FileHash -Algorithm SHA256 $BinaryPath).Hash.ToLower()
    $Line     = Get-Content $ChecksumPath | Where-Object { $_ -match [regex]::Escape($Asset) } | Select-Object -First 1
    $Expected = ($Line -split '\s+')[0].ToLower()

    if (-not $Expected) {
        Write-Error "No checksum entry found for ${Asset} in sha256sums.txt."
        exit 1
    }

    if ($Actual -ne $Expected) {
        Write-Error "Checksum verification failed.`n  expected: ${Expected}`n  actual:   ${Actual}"
        exit 1
    }

    Write-Host "Checksum verified."

    # ── Install ───────────────────────────────────────────────────────────────

    if ($env:CLUTTA_INSTALL_DIR) {
        $InstallDir = $env:CLUTTA_INSTALL_DIR
    } else {
        $InstallDir = Join-Path $env:USERPROFILE ".clutta\bin"
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    $Destination = Join-Path $InstallDir "${Binary}.exe"
    Move-Item -Path $BinaryPath -Destination $Destination -Force

    # ── PATH ──────────────────────────────────────────────────────────────────

    $UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*${InstallDir}*") {
        [System.Environment]::SetEnvironmentVariable("Path", "${UserPath};${InstallDir}", "User")
        $env:Path = "${env:Path};${InstallDir}"
        Write-Host ""
        Write-Host "Added ${InstallDir} to your PATH."
    }

    # ── Done ──────────────────────────────────────────────────────────────────

    Write-Host ""
    Write-Host "clutta ${Version} installed to ${Destination}"
    Write-Host ""
    Write-Host "Run 'clutta --help' to get started."
    Write-Host ""
    Write-Host "Note: if 'clutta' is not found, restart your terminal."

} finally {
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
}
