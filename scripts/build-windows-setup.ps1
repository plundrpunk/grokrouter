$ErrorActionPreference = "Stop"

if (-not $env:ROUTER_WINDOWS_APP_ROOT -or -not $env:ROUTER_WINDOWS_ARCH -or -not $env:ROUTER_WINDOWS_SETUP_OUTPUT) {
    throw "Windows setup packaging requires ROUTER_WINDOWS_APP_ROOT, ROUTER_WINDOWS_ARCH, and ROUTER_WINDOWS_SETUP_OUTPUT."
}

if ($env:ROUTER_WINDOWS_ARCH -notin @("x64", "arm64")) {
    throw "Windows setup architecture must be x64 or arm64."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$package = Get-Content (Join-Path $projectRoot "package.json") -Raw | ConvertFrom-Json
$appRoot = (Resolve-Path $env:ROUTER_WINDOWS_APP_ROOT).Path
$outputPath = [IO.Path]::GetFullPath($env:ROUTER_WINDOWS_SETUP_OUTPUT)
$outputDirectory = Split-Path -Parent $outputPath
$outputBaseName = [IO.Path]::GetFileNameWithoutExtension($outputPath)
$iconPath = (Resolve-Path (Join-Path $projectRoot "installer\Assets\AppIcon.ico")).Path

$isccCandidates = @(
    $env:ROUTER_INNO_ISCC,
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
) | Where-Object { $_ -and (Test-Path $_) }
$iscc = $isccCandidates | Select-Object -First 1
if (-not $iscc) {
    throw "Inno Setup 6 was not found. Install it or set ROUTER_INNO_ISCC to ISCC.exe."
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$temporary = Join-Path ([IO.Path]::GetTempPath()) ("grokrouter-inno-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temporary | Out-Null

try {
    $issPath = Join-Path $temporary "grokrouter.iss"
    $appSource = $appRoot.Replace('"', '""')
    $installerOutput = $outputDirectory.Replace('"', '""')
$installerIcon = $iconPath.Replace('"', '""')
$version = [string]$package.version
$architectureExpression = if ($env:ROUTER_WINDOWS_ARCH -eq "arm64") { "arm64" } else { "x64compatible" }

    @"
[Setup]
AppId={{957C218D-6A04-48A9-85CF-E9C6E31BC8B4}
AppName=GrokRouter
AppVersion=$version
AppPublisher=GrokRouter
DefaultDirName={localappdata}\Programs\GrokRouter
DefaultGroupName=GrokRouter
DisableProgramGroupPage=yes
OutputDir=$installerOutput
OutputBaseFilename=$outputBaseName
SetupIconFile=$installerIcon
UninstallDisplayIcon={app}\GrokRouter.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no
ArchitecturesAllowed=$architectureExpression
ArchitecturesInstallIn64BitMode=$architectureExpression

[Files]
Source: "$appSource\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\GrokRouter"; Filename: "{app}\GrokRouter.exe"

[Run]
Filename: "{app}\GrokRouter.exe"; Description: "Open GrokRouter"; Flags: nowait postinstall skipifsilent
"@ | Set-Content -Path $issPath -Encoding UTF8

    & $iscc /Qp $issPath
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup packaging failed." }
    if (-not (Test-Path $outputPath)) { throw "Inno Setup did not create $outputPath." }

    Write-Output $outputPath
}
finally {
    Remove-Item -Recurse -Force $temporary -ErrorAction SilentlyContinue
}
