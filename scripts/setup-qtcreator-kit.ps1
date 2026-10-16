param(
    [string]$SdkTool = 'C:\Qt\Qt6\Tools\sdktool\bin\sdktool.exe'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$dependencyRoot = Join-Path $projectRoot '.deps'
$qtRoot = Join-Path $dependencyRoot 'Qt\5.15.2\msvc2019_64'
$sdkConfig = 'C:\Qt\Qt6\Tools\sdktool\share\qtcreator\QtProject\qtcreator'
$cmake = 'C:\Qt\Qt6\Tools\CMake_64\bin\cmake.exe'
$ninja = 'C:/Qt/Qt6/Tools/Ninja/ninja.exe'

foreach ($path in @($SdkTool, "$qtRoot\bin\qmake.exe", $cmake, "$projectRoot\scripts\qtcreator-msvc.bat")) {
    if (!(Test-Path -LiteralPath $path)) { throw "Required tool was not found: $path" }
}

$backup = Join-Path $dependencyRoot ("qtcreator-settings-backup\" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath "$sdkConfig\profiles.xml", "$sdkConfig\toolchains.xml", "$sdkConfig\qtversion.xml", "$sdkConfig\cmaketools.xml" -Destination $backup

function Remove-SdkEntry([string]$operation, [string]$id) {
    & $SdkTool $operation --id $id *> $null
}

Remove-SdkEntry rmKit 'slmaster.qt5.msvc.kit'
Remove-SdkEntry rmQt 'slmaster.qt5.15.2.msvc2019'
Remove-SdkEntry rmTC 'ProjectExplorer.ToolChain.Msvc:slmaster.qt5.v143.C'
Remove-SdkEntry rmTC 'ProjectExplorer.ToolChain.Msvc:slmaster.qt5.v143.Cxx'
Remove-SdkEntry rmCMake 'slmaster.cmake'

$compiler = "$dependencyRoot\msvc\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe"
foreach ($language in @('C', 'Cxx')) {
    & $SdkTool addTC --id "ProjectExplorer.ToolChain.Msvc:slmaster.qt5.v143.$language" `
        --language $language --name "SLMaster Qt 5 MSVC 2022 ($language x64)" `
        --path $compiler --abi x86-windows-msvc2019-pe-64bit `
        --supportedAbis x86-windows-msvc2019-pe-64bit `
        ProjectExplorer.MsvcToolChain.SupportedAbi QString:x86-windows-msvc2019-pe-64bit `
        ProjectExplorer.MsvcToolChain.VarsBat "QString:$projectRoot\scripts\qtcreator-msvc.bat" `
        ProjectExplorer.MsvcToolChain.VarsBatArg QString:amd64
    if ($LASTEXITCODE -ne 0) { throw "Failed to register the $language compiler." }
}

& $SdkTool addQt --id slmaster.qt5.15.2.msvc2019 `
    --name 'SLMaster Qt 5.15.2 MSVC x64' `
    --qmake "$qtRoot\bin\qmake.exe" --type Qt4ProjectManager.QtVersion.Desktop
if ($LASTEXITCODE -ne 0) { throw 'Failed to register Qt.' }

& $SdkTool addCMake --id slmaster.cmake --name 'SLMaster CMake' --path $cmake
if ($LASTEXITCODE -ne 0) { throw 'Failed to register CMake.' }

$root = $projectRoot.Replace('\', '/')
& $SdkTool addKit --id slmaster.qt5.msvc.kit `
    --name 'SLMaster Qt 5.15.2 MSVC x64' --devicetype Desktop `
    --Ctoolchain ProjectExplorer.ToolChain.Msvc:slmaster.qt5.v143.C `
    --Cxxtoolchain ProjectExplorer.ToolChain.Msvc:slmaster.qt5.v143.Cxx `
    --qt slmaster.qt5.15.2.msvc2019 --mkspec win32-msvc `
    --cmake slmaster.cmake --cmake-generator 'Ninja:::' `
    --cmake-config "CMAKE_MAKE_PROGRAM:FILEPATH=$ninja" `
    --cmake-config "CMAKE_PREFIX_PATH:STRING=$root/.deps/Qt/5.15.2/msvc2019_64;$root/.deps/vtk-qt-install;$root/.deps/PCL/3rdParty/Eigen3" `
    --cmake-config "QT_DIR:PATH=$root/.deps/Qt/5.15.2/msvc2019_64/lib/cmake/Qt5" `
    --cmake-config "SLMasterVTKQt_DIR:PATH=$root/.deps/vtk-qt-install/lib/cmake/SLMasterVTKQt" `
    --cmake-config "PCL_DIR:PATH=$root/.deps/PCL/cmake" `
    --cmake-config "VTK_DIR:PATH=$root/.deps/PCL/3rdParty/VTK/lib/cmake/vtk-9.3" `
    --cmake-config "OpenCV_DIR:PATH=$root/.deps/opencv-install/x64/vc17/lib" `
    --cmake-config BUILD_TEST:BOOL=OFF --cmake-config BUILD_PERF:BOOL=OFF `
    --cmake-config FRAMELESSHELPER_ENABLE_SPECTRE:BOOL=OFF `
    --cmake-config CMAKE_POLICY_VERSION_MINIMUM:STRING=3.5 `
    --cmake-config CMAKE_POLICY_DEFAULT_CMP0167:STRING=OLD `
    --cmake-config FLUENTUI_BUILD_STATIC_LIB:BOOL=ON `
    --cmake-config QT_DEFAULT_MAJOR_VERSION:STRING=5 `
    --cmake-config 'CMAKE_MSVC_RUNTIME_LIBRARY:STRING=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL'
if ($LASTEXITCODE -ne 0) { throw 'Failed to register the Qt Creator kit.' }

Write-Host 'Registered: SLMaster Qt 5.15.2 MSVC x64'
Write-Host 'Restart Qt Creator, select this kit, and use the project build directory.'
