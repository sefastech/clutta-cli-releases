param([switch]$Live)
$ErrorActionPreference = 'Stop'
$Release = Invoke-RestMethod 'https://api.github.com/repos/sefastech/clutta-cli-releases/releases/latest'
if ($Release.prerelease -or $Release.draft) { throw 'Expected stable release' }
$Root = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
$OriginalPath = $env:Path
$OriginalUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
try {
    $env:CLUTTA_INSTALL_DIR = Join-Path $Root 'bin'
    $env:CLUTTA_NO_PATH_UPDATE = '1'
    $env:CLUTTA_VERSION = ''
    $Script = Get-Content "$PSScriptRoot/../install.ps1" -Raw
    if ($Live) {
        $Script = (Invoke-WebRequest 'https://clutta.io/install.ps1' -UseBasicParsing).Content
        if ($Script -match 'Add-MpPreference|Set-MpPreference') { throw 'Live installer still changes endpoint protection' }
    }
    Invoke-Expression $Script
    $Binary = Join-Path $env:CLUTTA_INSTALL_DIR 'clutta.exe'
    if (-not (Test-Path $Binary)) { throw 'Binary missing from expected directory' }
    $Version = & $Binary version
    if ($LASTEXITCODE -ne 0 -or ($Version -join "`n") -notmatch [regex]::Escape($Release.tag_name.TrimStart('v'))) { throw "Unexpected version: $Version" }
    & $Binary --help
    if ($LASTEXITCODE -ne 0) { throw 'CLI help failed' }
    if ($env:Path -ne $OriginalPath -or [Environment]::GetEnvironmentVariable('Path', 'User') -ne $OriginalUserPath) { throw 'Smoke test changed PATH' }
    Write-Host "PASS: installed and executed $($Release.tag_name) from $Binary"
} finally {
    if (Test-Path $Root) { Remove-Item -LiteralPath $Root -Recurse -Force }
}
