param(
    [string]$QtRoot,
    [string]$NinjaPath = 'C:\Qt\Qt6\Tools\Ninja\ninja.exe',
    [int]$Jobs = 8
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$dependencyRoot = Join-Path $projectRoot '.deps'
if (!$QtRoot) { $QtRoot = Join-Path $dependencyRoot 'Qt\6.8.3\msvc2022_64' }
. (Join-Path $PSScriptRoot 'msvc-env.ps1')
$env:PATH = "$QtRoot\bin;$env:PATH"

function Invoke-Checked([string]$Program, [string[]]$Arguments, [string]$LogName) {
    $logPath = Join-Path $dependencyRoot $LogName
    $ErrorActionPreference = 'Continue'
    & $Program @Arguments *> $logPath
    $result = $LASTEXITCODE
    if ($result -ne 0) {
        Get-Content -LiteralPath $logPath -Tail 30
        throw "$Program failed ($result). See $logPath"
    }
}

Invoke-Checked 'cmake' @(
    '--fresh', '-S', $projectRoot, '-B', "$projectRoot/build", '-G', 'Ninja',
    "-DCMAKE_MAKE_PROGRAM=$NinjaPath", '-DCMAKE_BUILD_TYPE=Release',
    '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL',
    '-DCMAKE_TRY_COMPILE_CONFIGURATION=Release',
    "-DCMAKE_PREFIX_PATH=$QtRoot;$dependencyRoot/vtk-qt6-install;$dependencyRoot/PCL/3rdParty/Eigen3",
    "-DPCL_DIR=$dependencyRoot/PCL/cmake",
    "-DVTK_DIR=$dependencyRoot/PCL/3rdParty/VTK/lib/cmake/vtk-9.3",
    "-DOpenCV_DIR=$dependencyRoot/opencv-install/x64/vc17/lib",
    '-DBUILD_GUI=ON', '-DBUILD_TEST=OFF', '-DBUILD_PERF=OFF',
    '-DFRAMELESSHELPER_ENABLE_SPECTRE=OFF', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5',
    '-DCMAKE_POLICY_DEFAULT_CMP0167=OLD', '-DFLUENTUI_BUILD_STATIC_LIB=ON',
    '-DQT_DEFAULT_MAJOR_VERSION=6'
) 'configure.log'
Invoke-Checked 'cmake' @('--build', "$projectRoot/build", '--parallel', "$Jobs") 'build.log'
Write-Host "Built: $projectRoot\build\gui\SLMasterGui.exe"
