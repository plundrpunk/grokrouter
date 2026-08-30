$ErrorActionPreference = "Stop"

if (-not $env:ROUTER_WINDOWS_SIGN_PFX -or -not $env:ROUTER_WINDOWS_SIGN_PASSWORD -or -not $env:ROUTER_WINDOWS_EXE) {
    throw "Windows signing requires ROUTER_WINDOWS_SIGN_PFX, ROUTER_WINDOWS_SIGN_PASSWORD, and ROUTER_WINDOWS_EXE."
}

$kitsRoot = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
$signTool = Get-ChildItem -Path $kitsRoot -Filter signtool.exe -Recurse |
    Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $signTool) {
    throw "signtool.exe was not found in the Windows SDK."
}

& $signTool.FullName sign `
    /f $env:ROUTER_WINDOWS_SIGN_PFX `
    /p $env:ROUTER_WINDOWS_SIGN_PASSWORD `
    /fd SHA256 `
    /tr "http://timestamp.digicert.com" `
    /td SHA256 `
    $env:ROUTER_WINDOWS_EXE
if ($LASTEXITCODE -ne 0) { throw "Authenticode signing failed." }

& $signTool.FullName verify /pa /all $env:ROUTER_WINDOWS_EXE
if ($LASTEXITCODE -ne 0) { throw "Authenticode verification failed." }
