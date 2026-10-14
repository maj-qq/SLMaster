$ErrorActionPreference = 'Stop'
$portableTools = Join-Path (Split-Path $PSScriptRoot -Parent) '.deps\msvc\VC\Tools\MSVC'
if(Test-Path -LiteralPath $portableTools) {
    $vcRoot = (Get-ChildItem -LiteralPath $portableTools -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
} else {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vsRoot = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (!$vsRoot) { throw 'MSVC x64 build tools were not found.' }
    $vcRoot = (Get-ChildItem (Join-Path $vsRoot 'VC\Tools\MSVC') -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
}
$sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'
$sdkVersion = (Get-ChildItem (Join-Path $sdkRoot 'Include') -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
$env:PATH = "$vcRoot\bin\Hostx64\x64;$sdkRoot\bin\$sdkVersion\x64;$env:PATH"
$env:INCLUDE = "$vcRoot\include;$vcRoot\atlmfc\include;$sdkRoot\Include\$sdkVersion\ucrt;$sdkRoot\Include\$sdkVersion\shared;$sdkRoot\Include\$sdkVersion\um;$sdkRoot\Include\$sdkVersion\winrt"
$env:LIB = "$vcRoot\lib\x64;$vcRoot\atlmfc\lib\x64;$sdkRoot\Lib\$sdkVersion\ucrt\x64;$sdkRoot\Lib\$sdkVersion\um\x64"
$env:VCToolsInstallDir = "$vcRoot\"
$env:WindowsSdkDir = "$sdkRoot\"
$env:WindowsSDKVersion = "$sdkVersion\"
$env:VSLANG = '1033'
