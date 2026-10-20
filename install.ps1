# Clutta CLI installer for Windows x64. No administrator access required.
# Usage: iwr -useb https://clutta.io/install.ps1 | iex
# CLUTTA_VERSION optionally selects an explicit stable or prerelease tag.
# CLUTTA_INSTALL_DIR optionally selects a user-writable installation directory.
# CLUTTA_NO_PATH_UPDATE=1 leaves persistent and process PATH unchanged.
# A terminating error is catchable and does not exit the interactive host shell.
& {
    $ErrorActionPreference = 'Stop'
    $Repo = 'sefastech/clutta-cli-releases'
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw 'Unsupported architecture. Clutta for Windows supports x64 PowerShell only.'
    }
    $Asset = 'clutta-windows-amd64.exe'
    if ($env:CLUTTA_VERSION) {
        $Version = $env:CLUTTA_VERSION.Trim()
        if ($Version -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$') {
            throw 'Invalid CLUTTA_VERSION. Expected vMAJOR.MINOR.PATCH, optionally with a prerelease suffix.'
        }
    } else {
        $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/${Repo}/releases/latest" -TimeoutSec 30
        $Version = $Release.tag_name
        if ($Release.draft -ne $false -or $Release.prerelease -ne $false -or $Version -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$') {
            throw 'No valid stable Clutta release found. No binary was installed.'
        }
    }
    $InstallDir = if ($env:CLUTTA_INSTALL_DIR) { $env:CLUTTA_INSTALL_DIR.Trim() } else { Join-Path $env:USERPROFILE '.clutta\bin' }
    if (-not $InstallDir) { throw 'Installation directory must not be empty.' }
    $TempDir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    $Staged = $null
    try {
        $BaseUrl = "https://github.com/${Repo}/releases/download/${Version}"
        $BinaryPath = Join-Path $TempDir $Asset
        $ChecksumPath = Join-Path $TempDir 'sha256sums.txt'
        Write-Host "Downloading Clutta ${Version} (windows/amd64)..."
        Invoke-WebRequest -Uri "${BaseUrl}/${Asset}" -OutFile $BinaryPath -UseBasicParsing -TimeoutSec 120
        Invoke-WebRequest -Uri "${BaseUrl}/sha256sums.txt" -OutFile $ChecksumPath -UseBasicParsing -TimeoutSec 30
        $Entries = @(Get-Content $ChecksumPath | Where-Object { $_ -cmatch ('^[a-fA-F0-9]{64}\s+\*?' + [regex]::Escape($Asset) + '$') })
        if ($Entries.Count -ne 1) { throw 'Expected exactly one valid checksum entry for the Windows binary.' }
        $Expected = ($Entries[0] -split '\s+')[0].ToLowerInvariant()
        $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $BinaryPath).Hash.ToLowerInvariant()
        if ($Actual -ne $Expected) { throw 'Checksum verification failed. Existing installation was not changed.' }
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        $Destination = Join-Path $InstallDir 'clutta.exe'
        $Staged = Join-Path $InstallDir ([IO.Path]::GetRandomFileName())
        Copy-Item -LiteralPath $BinaryPath -Destination $Staged
        if (Test-Path -LiteralPath $Destination) {
            [IO.File]::Replace($Staged, $Destination, [NullString]::Value)
        } else {
            [IO.File]::Move($Staged, $Destination)
        }
        if ($env:CLUTTA_NO_PATH_UPDATE -ne '1') {
            $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            if (@($UserPath -split ';') -notcontains $InstallDir) {
                [Environment]::SetEnvironmentVariable('Path', "${UserPath};${InstallDir}", 'User')
            }
            if (@($env:Path -split ';') -notcontains $InstallDir) { $env:Path = "${env:Path};${InstallDir}" }
        }
        Write-Host "Installed Clutta ${Version} to ${Destination}. Run 'clutta --help'."
    } catch {
        throw "Clutta installation failed: $($_.Exception.Message) If endpoint protection blocked a file, stop and ask your security administrator or Clutta support to investigate. Do not disable protection or add exclusions."
    } finally {
        if ($Staged -and (Test-Path -LiteralPath $Staged)) { Remove-Item -LiteralPath $Staged -Force -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
