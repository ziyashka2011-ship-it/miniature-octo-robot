# Monero CPU miner setup — interactive and non-persistent
# Downloads the official XMRig Windows build, asks for your wallet, then runs it in this window.
# It does NOT install a Windows service, add startup entries, or run hidden in the background.

$ErrorActionPreference = 'Stop'

Write-Host "Monero CPU Miner setup (official XMRig)" -ForegroundColor Cyan
Write-Host "This script downloads XMRig from its official GitHub releases and runs it visibly."
Write-Host "It will not configure automatic startup or a Windows service."
Write-Host ""

$wallet = Read-Host "Enter your Monero wallet address"
if ([string]::IsNullOrWhiteSpace($wallet)) {
    throw "Wallet address cannot be empty."
}

$worker = Read-Host "Worker name (press Enter for 'pc1')"
if ([string]::IsNullOrWhiteSpace($worker)) { $worker = "pc1" }

Write-Host ""
Write-Host "Choose a pool endpoint:"
Write-Host "1) gulf.mpool.pro:3333"
Write-Host "2) gulf.mpool.pro:5555"
Write-Host "3) gulf.mpool.pro:7777"
Write-Host "4) de.mpool.pro:3333"
Write-Host "5) de.mpool.pro:5555"
Write-Host "6) de.mpool.pro:7777"
$choice = Read-Host "Enter 1-6"
$poolMap = @{
    "1" = @{ Host = "gulf.mpool.pro"; Port = "3333" }
    "2" = @{ Host = "gulf.mpool.pro"; Port = "5555" }
    "3" = @{ Host = "gulf.mpool.pro"; Port = "7777" }
    "4" = @{ Host = "de.mpool.pro"; Port = "3333" }
    "5" = @{ Host = "de.mpool.pro"; Port = "5555" }
    "6" = @{ Host = "de.mpool.pro"; Port = "7777" }
}
if (-not $poolMap.ContainsKey($choice)) { throw "Invalid pool choice." }
$pool = $poolMap[$choice]
$poolAddress = "$($pool.Host):$($pool.Port)"

$baseDir = Join-Path $env:USERPROFILE "Documents\MoneroMiner"
New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
$zipPath = Join-Path $baseDir "xmrig-windows.zip"
$extractDir = Join-Path $baseDir "xmrig"

Write-Host ""
Write-Host "Fetching the latest official XMRig Windows release..." -ForegroundColor Yellow
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/xmrig/xmrig/releases/latest"
$asset = $release.assets | Where-Object { $_.name -match "msvc-win64\.zip$" } | Select-Object -First 1
if (-not $asset) {
    throw "Could not find the official msvc-win64.zip asset. Open https://github.com/xmrig/xmrig/releases and download the Windows x64 build manually."
}

Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
$xmrig = Get-ChildItem -Path $extractDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
if (-not $xmrig) { throw "xmrig.exe was not found after extracting the official archive." }

Write-Host ""
Write-Host "Starting XMRig visibly. Press Ctrl+C to stop mining." -ForegroundColor Green
Write-Host "Pool: $poolAddress"
Write-Host "Miner folder: $($xmrig.DirectoryName)"
Write-Host "No service or automatic startup entry will be created."
Write-Host ""

& $xmrig.FullName --coin monero --url $poolAddress --user $wallet --pass $worker --cpu-max-threads-hint 75
$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "XMRig exited with code $exitCode."
Write-Host "To remove the downloaded files, delete: $baseDir"
