param(
    [string]$QtRoot,
    [ValidateSet('Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel')]
    [string]$Configuration = 'Release',
    [string]$NinjaPath = 'C:\Qt\Qt6\Tools\Ninja\ninja.exe',
    [int]$Jobs = 8
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$dependencyRoot = Join-Path $projectRoot '.deps'
if (!$QtRoot) { $QtRoot = Join-Path $dependencyRoot 'Qt\5.15.2\msvc2019_64' }
$qtVersion = & "$QtRoot\bin\qmake.exe" -query QT_VERSION
if ($LASTEXITCODE -ne 0 -or $qtVersion -notmatch '^5\.15\.') { throw "Qt 5.15 MSVC x64 is required: $QtRoot" }
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

# Install a matching VTK/Qt bridge: a Release bridge would load Release Qt
# inside a Debug application, creating two independent Qt runtimes.
Invoke-Checked 'cmake' @(
    '-S', "$projectRoot/cmake/vtk-qt", '-B', "$dependencyRoot/vtk-qt-build-$Configuration", '-G', 'Ninja',
    "-DCMAKE_MAKE_PROGRAM=$NinjaPath", "-DCMAKE_BUILD_TYPE=$Configuration",
    '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL',
    "-DCMAKE_PREFIX_PATH=$QtRoot", '-DVTK_QT_VERSION=5',
    "-DVTK_SOURCE_DIR=$dependencyRoot/vtk-qt-source",
    "-DVTK_DIR=$dependencyRoot/PCL/3rdParty/VTK/lib/cmake/vtk-9.3",
    "-DCMAKE_INSTALL_PREFIX=$dependencyRoot/vtk-qt-install"
) "configure-vtk-qt-$Configuration.log"
Invoke-Checked 'cmake' @('--build', "$dependencyRoot/vtk-qt-build-$Configuration", '--parallel', "$Jobs") "build-vtk-qt-$Configuration.log"
Invoke-Checked 'cmake' @('--install', "$dependencyRoot/vtk-qt-build-$Configuration") "install-vtk-qt-$Configuration.log"

Invoke-Checked 'cmake' @(
    '--fresh', '-S', $projectRoot, '-B', "$projectRoot/build", '-G', 'Ninja',
    "-DCMAKE_MAKE_PROGRAM=$NinjaPath", "-DCMAKE_BUILD_TYPE=$Configuration",
    '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL',
    "-DCMAKE_TRY_COMPILE_CONFIGURATION=$Configuration",
    "-DCMAKE_PREFIX_PATH=$QtRoot;$dependencyRoot/vtk-qt-install;$dependencyRoot/PCL/3rdParty/Eigen3",
    "-DPCL_DIR=$dependencyRoot/PCL/cmake",
    "-DVTK_DIR=$dependencyRoot/PCL/3rdParty/VTK/lib/cmake/vtk-9.3",
    "-DOpenCV_DIR=$dependencyRoot/opencv-install/x64/vc17/lib",
    '-DBUILD_GUI=ON', '-DBUILD_TEST=OFF', '-DBUILD_PERF=OFF',
    '-DFRAMELESSHELPER_ENABLE_SPECTRE=OFF', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5',
    '-DCMAKE_POLICY_DEFAULT_CMP0167=OLD', '-DFLUENTUI_BUILD_STATIC_LIB=ON',
    '-DQT_DEFAULT_MAJOR_VERSION=5',
    "-DQT_DIR=$QtRoot/lib/cmake/Qt5",
    "-DSLMasterVTKQt_DIR=$dependencyRoot/vtk-qt-install/lib/cmake/SLMasterVTKQt"
) 'configure.log'
Invoke-Checked 'cmake' @('--build', "$projectRoot/build", '--parallel', "$Jobs") 'build.log'
Write-Host "Built: $projectRoot\build\gui\SLMasterGui.exe"
