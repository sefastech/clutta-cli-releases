$ErrorActionPreference = 'Stop'
$Installer = Get-Content "$PSScriptRoot/../install.ps1" -Raw
if ($Installer -match 'Add-MpPreference|Set-MpPreference|false positive|exit\s+\d') {
    throw 'Installer must not weaken protection, assert false positives, or exit the interactive host.'
}
$Root = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
New-Item -ItemType Directory $Root | Out-Null
$OriginalArchitecture = $env:PROCESSOR_ARCHITECTURE
$OriginalVersion = $env:CLUTTA_VERSION
$OriginalDirectory = $env:CLUTTA_INSTALL_DIR
$OriginalNoPath = $env:CLUTTA_NO_PATH_UPDATE
$OriginalPath = $env:Path
$OriginalUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$Preference = $ErrorActionPreference
$OriginalProgressPreference = $ProgressPreference
$script:Fixture = 'new fixture binary'
$script:Mode = ''

# Network substitutes are test-local. The installer itself has no alternate
# server override, test bypass, or injected trust configuration.
function Invoke-RestMethod {
    param($Uri, $TimeoutSec)
    if ($Uri -notmatch '/releases/latest$') { throw 'Default must use stable release endpoint' }
    if ($script:Mode -eq 'metadata-failure') { throw 'fixture metadata unavailable' }
    if ($script:Mode -eq 'prerelease') { return @{ tag_name='v1.2.4-rc1'; draft=$false; prerelease=$true } }
    if ($script:Mode -eq 'malformed') { return @{ tag_name='invalid' } }
    return @{ tag_name='v1.2.3'; draft=$false; prerelease=$false }
}
function Invoke-WebRequest {
    param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec)
    if ($script:Mode -eq 'download-failure') { throw 'fixture download blocked' }
    if ($script:Mode -eq 'explicit-rc' -and $Uri -notmatch '/v1.2.4-rc1/') { throw 'Explicit version not honored' }
    if ($Uri -match '/sha256sums.txt$') {
        $Bytes = [Text.Encoding]::UTF8.GetBytes($script:Fixture)
        $Hash = ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($Bytes))).Replace('-', '').ToLower()
        if ($script:Mode -eq 'mismatch') { $Hash = '0' * 64 }
        $Line = "$Hash  clutta-windows-amd64.exe"
        if ($script:Mode -eq 'duplicate') { $Line += "`n$Line" }
        if ($script:Mode -eq 'wrong-asset') { $Line += '.backup' }
        [IO.File]::WriteAllText($OutFile, $Line)
    } else {
        [IO.File]::WriteAllText($OutFile, $script:Fixture, (New-Object Text.UTF8Encoding($false)))
    }
}
try {
    foreach ($Mode in @('stable', 'explicit-rc', 'metadata-failure', 'prerelease', 'malformed', 'download-failure', 'mismatch', 'duplicate', 'wrong-asset', 'unsupported', 'invalid-version')) {
        $script:Mode = $Mode
        $env:PROCESSOR_ARCHITECTURE = if ($Mode -eq 'unsupported') { 'ARM64' } else { 'AMD64' }
        $env:CLUTTA_VERSION = if ($Mode -eq 'explicit-rc') { 'v1.2.4-rc1' } elseif ($Mode -eq 'invalid-version') { '../../bad' } else { '' }
        $env:CLUTTA_INSTALL_DIR = Join-Path $Root $Mode
        $env:CLUTTA_NO_PATH_UPDATE = '1'
        New-Item -ItemType Directory $env:CLUTTA_INSTALL_DIR | Out-Null
        $Destination = Join-Path $env:CLUTTA_INSTALL_DIR 'clutta.exe'
        [IO.File]::WriteAllText($Destination, 'old fixture')
        $Failed = $false
        $FailureMessage = ''
        try { Invoke-Expression $Installer } catch { $Failed = $true; $FailureMessage = $_.Exception.Message }
        $SuccessExpected = $Mode -in @('stable', 'explicit-rc')
        if ($Failed -eq $SuccessExpected) { throw "Unexpected failure result for ${Mode}: $FailureMessage" }
        $Expected = if ($SuccessExpected) { $script:Fixture } else { 'old fixture' }
        if ([IO.File]::ReadAllText($Destination) -ne $Expected) { throw "Existing binary not preserved for $Mode" }
        if ($ErrorActionPreference -ne $Preference) { throw 'Caller error preference changed' }
        if ($ProgressPreference -ne $OriginalProgressPreference) { throw 'Caller progress preference changed' }
        Write-Host "PASS: $Mode"
    }
    if ($env:Path -ne $OriginalPath -or [Environment]::GetEnvironmentVariable('Path', 'User') -ne $OriginalUserPath) { throw 'Test changed PATH' }
    # A saved-script invocation must also fail with a nonzero process status.
    $env:CLUTTA_VERSION = 'invalid'
    $env:PROCESSOR_ARCHITECTURE = 'AMD64'
    $HostExecutable = (Get-Process -Id $PID).Path
    $Child = Start-Process -FilePath $HostExecutable -ArgumentList @('-NoProfile', '-File', ('"{0}/../install.ps1"' -f $PSScriptRoot)) -Wait -PassThru -NoNewWindow -RedirectStandardError (Join-Path $Root 'child-error.txt') -RedirectStandardOutput (Join-Path $Root 'child-output.txt')
    if ($Child.ExitCode -eq 0) { throw 'Failed install returned success to automation' }
    Write-Host 'PASS: saved-script failure returns nonzero'
} finally {
    $env:PROCESSOR_ARCHITECTURE = $OriginalArchitecture
    $env:CLUTTA_VERSION = $OriginalVersion
    $env:CLUTTA_INSTALL_DIR = $OriginalDirectory
    $env:CLUTTA_NO_PATH_UPDATE = $OriginalNoPath
    Remove-Item -LiteralPath $Root -Recurse -Force
}
