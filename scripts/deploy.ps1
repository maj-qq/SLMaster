param([string]$QtRoot)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$dependencyRoot = Join-Path $projectRoot '.deps'
if (!$QtRoot) { $QtRoot = Join-Path $dependencyRoot 'Qt\6.8.3\msvc2022_64' }
. (Join-Path $PSScriptRoot 'msvc-env.ps1')
$outputRoot = Join-Path $projectRoot 'build\gui'
$executable = Join-Path $outputRoot 'SLMasterGui.exe'
$env:PATH = "$QtRoot\bin;$env:PATH"
$ErrorActionPreference = 'Continue'
& "$QtRoot\bin\windeployqt.exe" --release --no-translations --no-compiler-runtime --qmldir "$projectRoot\gui\qml" --qmlimport "$projectRoot\build" $executable *> "$dependencyRoot\deploy.log"
$deployExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($deployExit -ne 0) { Get-Content "$dependencyRoot\deploy.log" -Tail 20; throw 'Qt deployment failed.' }
Copy-Item -LiteralPath "$QtRoot\qml\Qt5Compat" -Destination $outputRoot -Recurse -Force
Copy-Item -LiteralPath "$projectRoot\src\device\projector\module\projector_dlpc_api\third_party\cyusbserial\cyusbserial.dll" -Destination $outputRoot -Force
# GenICam loads this logging backend dynamically, so dumpbin cannot discover it.
Copy-Item -LiteralPath "$dependencyRoot\sdk-runtime\executable\gui\log4cpp_MD_VC120_v3_0.dll" -Destination $outputRoot -Force
Copy-Item -LiteralPath "$dependencyRoot\sdk-runtime\executable\gui\SDKLOG_default.properties" -Destination $outputRoot -Force

$searchRoots = @(
    "$dependencyRoot\msvc\VC\Redist",
    "$dependencyRoot\vtk-qt6-install\bin",
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
Write-Host "Ready: $executable"
