$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$buildDir = "$projectRoot\build"
$QtRoot = "$projectRoot\.deps\Qt\5.15.2\msvc2019_64"

. "$projectRoot\scripts\msvc-env.ps1"
$env:PATH = "$QtRoot\bin;$env:PATH"

cmake --build $buildDir --parallel 8
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build succeeded: $buildDir\gui\SLMasterGui.exe"
} else {
    Write-Error "Build failed with exit code $LASTEXITCODE"
}
