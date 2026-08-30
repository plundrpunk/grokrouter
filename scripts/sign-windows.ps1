$ErrorActionPreference = "Stop"

if (-not $env:ROUTER_WINDOWS_SIGN_PFX -or -not $env:ROUTER_WINDOWS_SIGN_PASSWORD -or -not $env:ROUTER_WINDOWS_SIGN_TARGET) {
    throw "Windows signing requires ROUTER_WINDOWS_SIGN_PFX, ROUTER_WINDOWS_SIGN_PASSWORD, and ROUTER_WINDOWS_SIGN_TARGET."
}

$kitsRoot = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
$signTool = Get-ChildItem -Path $kitsRoot -Filter signtool.exe -Recurse |
    Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $signTool) {
    throw "signtool.exe was not found in the Windows SDK."
}

$target = Get-Item $env:ROUTER_WINDOWS_SIGN_TARGET
$executables = if ($target.PSIsContainer) {
    Get-ChildItem -Path $target.FullName -Filter *.exe -File -Recurse | Sort-Object FullName
} else {
    @($target)
}
if (-not $executables) { throw "No Windows executables were found to sign." }

foreach ($executable in $executables) {
    & $signTool.FullName sign `
        /f $env:ROUTER_WINDOWS_SIGN_PFX `
        /p $env:ROUTER_WINDOWS_SIGN_PASSWORD `
        /fd SHA256 `
        /tr "http://timestamp.digicert.com" `
        /td SHA256 `
        $executable.FullName
    if ($LASTEXITCODE -ne 0) { throw "Authenticode signing failed for $($executable.Name)." }

    & $signTool.FullName verify /pa /all $executable.FullName
    if ($LASTEXITCODE -ne 0) { throw "Authenticode verification failed for $($executable.Name)." }
}
