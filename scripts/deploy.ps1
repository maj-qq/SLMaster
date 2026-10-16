param(
    [string]$QtRoot,
    [string]$BuildDirectory,
    [string]$Executable,
    [ValidateSet('Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel')]
    [string]$Configuration
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$dependencyRoot = Join-Path $projectRoot '.deps'
if (!$QtRoot) { $QtRoot = Join-Path $dependencyRoot 'Qt\5.15.2\msvc2019_64' }
if (!$BuildDirectory) { $BuildDirectory = Join-Path $projectRoot 'build' }
$cachePath = Join-Path $BuildDirectory 'CMakeCache.txt'
if (!$Configuration) {
    $buildType = Select-String -LiteralPath $cachePath -Pattern '^CMAKE_BUILD_TYPE:[^=]+=(.+)$'
    if (!$buildType) { throw 'Pass -Configuration for a multi-configuration build.' }
    $Configuration = $buildType.Matches[0].Groups[1].Value
}
if (!$Executable) { $Executable = Join-Path $BuildDirectory 'gui\SLMasterGui.exe' }
$executable = (Resolve-Path -LiteralPath $Executable).Path
$outputRoot = Split-Path $executable -Parent
$qtConfiguration = if ($Configuration -eq 'Debug') { '--debug' } else { '--release' }
. (Join-Path $PSScriptRoot 'msvc-env.ps1')
$env:PATH = "$QtRoot\bin;$env:PATH"
$deployLog = Join-Path $dependencyRoot "deploy-$Configuration.log"
$ErrorActionPreference = 'Continue'
& "$QtRoot\bin\windeployqt.exe" $qtConfiguration --no-translations --no-compiler-runtime --qmldir "$projectRoot\gui\qml" --qmlimport "$projectRoot\gui\thirdParty\FluentUI\src\Qt5\imports" $executable *> $deployLog
$deployExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($deployExit -ne 0) { Get-Content -LiteralPath $deployLog -Tail 20; throw 'Qt deployment failed.' }
# Static FluentUI registers its types in main.cpp and has no plugin DLL.
# Its source qmldir also supports dynamic builds, so adapt the deployed copy.
$fluentQmldir = Join-Path $outputRoot 'FluentUI\qmldir'
if ((Select-String -LiteralPath $cachePath -Pattern '^FLUENTUI_BUILD_STATIC_LIB:BOOL=ON$' -Quiet) -and (Test-Path -LiteralPath $fluentQmldir)) {
    $fluentModule = [IO.File]::ReadAllText($fluentQmldir)
    $fluentModule = [regex]::Replace($fluentModule, '(?m)^plugin\s+fluentuiplugin[^\r\n]*\r?\n?', '')
    [IO.File]::WriteAllText($fluentQmldir, $fluentModule, (New-Object System.Text.UTF8Encoding($false)))
}
Copy-Item -LiteralPath "$QtRoot\qml\QtGraphicalEffects" -Destination $outputRoot -Recurse -Force
Copy-Item -LiteralPath "$projectRoot\src\device\projector\module\projector_dlpc_api\third_party\cyusbserial\cyusbserial.dll" -Destination $outputRoot -Force
# GenICam loads this logging backend dynamically, so dumpbin cannot discover it.
Copy-Item -LiteralPath "$dependencyRoot\sdk-runtime\executable\gui\log4cpp_MD_VC120_v3_0.dll" -Destination $outputRoot -Force
Copy-Item -LiteralPath "$dependencyRoot\sdk-runtime\executable\gui\SDKLOG_default.properties" -Destination $outputRoot -Force

$searchRoots = @(
    "$dependencyRoot\msvc\VC\Redist",
    "$dependencyRoot\vtk-qt-install\bin",
    "$dependencyRoot\opencv-install\x64\vc17\bin",
    "$QtRoot\bin", "$dependencyRoot\PCL\bin", "$dependencyRoot\PCL\3rdParty",
    "$dependencyRoot\sdk-runtime"
)
$dllSources = @{}
foreach ($searchRoot in $searchRoots) {
    if (Test-Path -LiteralPath $searchRoot) {
        foreach ($dll in Get-ChildItem -LiteralPath $searchRoot -Filter '*.dll' -Recurse) {
            if (!$dllSources.ContainsKey($dll.Name)) { $dllSources[$dll.Name] = $dll.FullName }
        }
    }
}
$queue = New-Object 'System.Collections.Generic.Queue[string]'
$queue.Enqueue($executable)
Get-ChildItem -LiteralPath $outputRoot -Filter '*.dll' -Recurse | ForEach-Object { $queue.Enqueue($_.FullName) }
$visited = @{}
while ($queue.Count) {
    $binary = $queue.Dequeue()
    if ($visited.ContainsKey($binary)) { continue }
    $visited[$binary] = $true
    $imports = & dumpbin /DEPENDENTS $binary
    foreach ($line in $imports) {
        if ($line -notmatch '^\s*([\w.-]+\.dll)\s*$') { continue }
        $name = $Matches[1]
        $target = Join-Path $outputRoot $name
        if ($dllSources.ContainsKey($name)) {
            Copy-Item -LiteralPath $dllSources[$name] -Destination $target -Force
            $queue.Enqueue($target)
        } elseif (Test-Path -LiteralPath $target) {
            $queue.Enqueue($target)
        } elseif ($name -notmatch '^(api-ms-|ext-ms-)' -and !(Test-Path -LiteralPath "$env:WINDIR\System32\$name")) {
            $sideBySideRuntime = Get-ChildItem -LiteralPath "$env:WINDIR\WinSxS" -Directory -Filter 'amd64_microsoft.vc*.crt*' |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName $name) } | Select-Object -First 1
            if ($sideBySideRuntime) { continue }
            throw "Missing runtime DLL: $name"
        }
    }
}
Write-Host "Ready ($Configuration): $executable"
