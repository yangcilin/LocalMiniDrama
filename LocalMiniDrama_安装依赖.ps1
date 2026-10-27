param(
    [ValidateSet('backend-node', 'frontweb')]
    [string[]]$Component = @('backend-node', 'frontweb')
)

$ErrorActionPreference = 'Continue'
$projectRoot = Join-Path $PSScriptRoot 'LocalMiniDrama'
$nodeDir = 'C:\Users\yangc\AppData\AppSetup\Nodejs\nvm\v22.13.0'
$logDir = Join-Path $PSScriptRoot 'LocalMiniDrama_install_logs'
$env:Path = $nodeDir + ';' + $env:Path
$env:npm_config_cache = Join-Path $logDir 'npm-cache'
$npmExe = Join-Path $nodeDir 'npm.cmd'
$nodeExe = Join-Path $nodeDir 'node.exe'
$results = @()

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $logDir ('install_' + $runId + '.log')
$statusFile = Join-Path $logDir ('status_' + $runId + '.json')
Start-Transcript -Path $logFile -Force | Out-Null
$Host.UI.RawUI.WindowTitle = 'LocalMiniDrama - Install dependencies (Node 22.13.0)'
Write-Host ('Project: ' + $projectRoot) -ForegroundColor Cyan
Write-Host ('Log: ' + $logFile)
& $nodeExe --version
& $npmExe --version

foreach ($componentName in $Component) {
    $componentPath = Join-Path $projectRoot $componentName
    Write-Host ('Installing ' + $componentName + ' ...') -ForegroundColor Cyan
    Set-Location -LiteralPath $componentPath -ErrorAction Stop
    & $npmExe ci --no-audit --no-fund
    $installCode = $LASTEXITCODE
    $verifyCode = $null
    if ($installCode -eq 0) {
        if ($componentName -eq 'backend-node') {
            & $nodeExe -e "require('better-sqlite3')(':memory:').close(); require('sharp'); Promise.all([import('@mastra/core/agent'), import('@mastra/libsql'), import('@mastra/memory')]).then(() => console.log('Backend native modules and AI assistant dependencies OK')).catch(e => { console.error(e); process.exitCode = 1; });"
        } else {
            & $npmExe run build
        }
        $verifyCode = $LASTEXITCODE
    }
    $results += [pscustomobject]@{
        component = $componentName
        installExitCode = $installCode
        verificationExitCode = $verifyCode
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statusFile -Encoding UTF8
}

Set-Location -LiteralPath (Join-Path $projectRoot 'backend-node')
$results | Format-Table -AutoSize
$failed = @($results | Where-Object { $_.installExitCode -ne 0 -or $_.verificationExitCode -ne 0 })
if ($failed.Count -eq 0) {
    Write-Host 'INSTALLATION AND VERIFICATION COMPLETE.' -ForegroundColor Green
    Write-Host 'This PowerShell session uses the existing Node 22.13.0.'
    Write-Host 'Backend is not started. Start it here with: npm.cmd run dev'
} else {
    Write-Host 'INSTALLATION OR VERIFICATION FAILED. Check the log.' -ForegroundColor Red
}
Write-Host ('Status file: ' + $statusFile)
Stop-Transcript | Out-Null
