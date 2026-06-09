# Clutta CLI installer for Windows
#
# Usage (PowerShell):
#   iwr -useb https://clutta.io/install.ps1 | iex
#
# Environment variables (all optional):
#   $env:CLUTTA_VERSION     - install a specific version, e.g. "v0.0.1"
#   $env:CLUTTA_INSTALL_DIR - install to a custom directory

# All work happens inside an isolated script block + outer try/catch so the
# documented `iwr ... | iex` invocation cannot leak state into the caller's
# PowerShell session:
#   - `& { ... }` runs in a new scope, so $ErrorActionPreference = 'Stop' set
#     inside stays inside. The user's session keeps its original preference.
#   - `throw` propagates only as far as the outer catch; the user's terminal
#     window survives any install failure. (The previous code used `exit 1`,
#     which is process-level in PowerShell and would close the whole window.)

try {
    & {
        $ErrorActionPreference = 'Stop'

        $Repo   = "sefastech/clutta-cli-releases"
        $Binary = "clutta"

        # ── Architecture detection ────────────────────────────────────────────

        if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
            throw "Unsupported architecture: $($env:PROCESSOR_ARCHITECTURE). Clutta for Windows supports x86_64 only."
        }
        $Asset = "${Binary}-windows-amd64.exe"

        # ── Version resolution ────────────────────────────────────────────────

        if ($env:CLUTTA_VERSION) {
            $Version = $env:CLUTTA_VERSION
        } else {
            try {
                $Releases = Invoke-WebRequest -Uri "https://api.github.com/repos/${Repo}/releases" -UseBasicParsing |
                            ConvertFrom-Json
                $Version  = $Releases[0].tag_name
            } catch {
                throw "Could not determine the latest version. Check your internet connection or set CLUTTA_VERSION."
            }
            if (-not $Version) {
                throw "Could not determine the latest version."
            }
        }

        Write-Host "Installing clutta ${Version} (windows/amd64)..."

        # ── Defender exclusions ───────────────────────────────────────────────
        # Clutta is not yet code-signed. Windows Defender may quarantine the
        # binary during download. We pre-emptively add exclusions for the temp
        # download dir and the install dir. This requires elevation; if it
        # fails we continue and catch the quarantine error below with
        # actionable instructions.

        $InstallDir = if ($env:CLUTTA_INSTALL_DIR) { $env:CLUTTA_INSTALL_DIR } else { Join-Path $env:USERPROFILE ".clutta\bin" }
        $TempDir    = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $TempDir | Out-Null

        try {
            Add-MpPreference -ExclusionPath $TempDir    -ErrorAction Stop | Out-Null
            Add-MpPreference -ExclusionPath $InstallDir -ErrorAction Stop | Out-Null
        } catch {
            # Elevation not available -- continue; quarantine error handled below.
        }

        # ── Download ──────────────────────────────────────────────────────────

        $BaseUrl = "https://github.com/${Repo}/releases/download/${Version}"

        try {
            Write-Host "Downloading binary..."
            $BinaryPath   = Join-Path $TempDir $Asset
            $ChecksumPath = Join-Path $TempDir "sha256sums.txt"

            Invoke-WebRequest -Uri "${BaseUrl}/${Asset}"         -OutFile $BinaryPath   -UseBasicParsing
            Invoke-WebRequest -Uri "${BaseUrl}/sha256sums.txt"   -OutFile $ChecksumPath -UseBasicParsing

            # ── Checksum verification ─────────────────────────────────────────

            Write-Host "Verifying checksum..."

            try {
                $Actual = (Get-FileHash -Algorithm SHA256 $BinaryPath).Hash.ToLower()
            } catch {
                if ($_.Exception.Message -match "virus|unwanted|cannot be read") {
                    Write-Host ""
                    Write-Host "Windows Defender removed the binary during download."
                    Write-Host "This is a false positive. Clutta is not yet code-signed -- a signing"
                    Write-Host "certificate is in progress and will eliminate this in a future release."
                    Write-Host ""
                    Write-Host "To install now, add a Defender exclusion and re-run the installer."
                    Write-Host ""
                    Write-Host "Option 1 -- run this in an elevated PowerShell, then re-run the installer:"
                    Write-Host "  Add-MpPreference -ExclusionPath `"${InstallDir}`""
                    Write-Host ""
                    Write-Host "Option 2 -- via Windows Security UI:"
                    Write-Host "  Virus and threat protection > Manage settings > Exclusions"
                    Write-Host "  Add folder: ${InstallDir}"
                    Write-Host ""
                    throw "Windows Defender removed the binary during download (see instructions above)."
                }
                throw
            }

            $Line     = Get-Content $ChecksumPath | Where-Object { $_ -match [regex]::Escape($Asset) } | Select-Object -First 1
            $Expected = ($Line -split '\s+')[0].ToLower()

            if (-not $Expected) {
                throw "No checksum entry found for ${Asset} in sha256sums.txt."
            }

            if ($Actual -ne $Expected) {
                throw "Checksum verification failed.`n  expected: ${Expected}`n  actual:   ${Actual}"
            }

            Write-Host "Checksum verified."

            # ── Install ───────────────────────────────────────────────────────

            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

            $Destination = Join-Path $InstallDir "${Binary}.exe"
            Move-Item -Path $BinaryPath -Destination $Destination -Force

            # ── PATH ──────────────────────────────────────────────────────────

            $UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            if ($UserPath -notlike "*${InstallDir}*") {
                [System.Environment]::SetEnvironmentVariable("Path", "${UserPath};${InstallDir}", "User")
                $env:Path = "${env:Path};${InstallDir}"
                Write-Host ""
                Write-Host "Added ${InstallDir} to your PATH."
            }

            # ── Done ──────────────────────────────────────────────────────────

            Write-Host ""
            Write-Host "clutta ${Version} installed to ${Destination}"
            Write-Host ""
            Write-Host "Run 'clutta --help' to get started."
            Write-Host ""
            Write-Host "Note: if 'clutta' is not found, restart your terminal."

        } finally {
            Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
        }
    }
} catch {
    # The inner block may have already printed multi-line diagnostics
    # (Defender quarantine instructions, etc.) before throwing. Print a final
    # terse line so the user sees the install did not complete, then return
    # without exiting the host PowerShell session.
    Write-Host ""
    Write-Host "Clutta install did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}
