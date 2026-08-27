# SD Card Keep-Alive Removal Script
# ROG Ally X – Realtek RTS525A

$ErrorActionPreference = "SilentlyContinue"

$TaskName = "SD Card Keep-Alive"
$InstallDir = "$env:USERPROFILE\SDKeepAlive"
$ScriptPath = "$InstallDir\sd_keepalive.ps1"
$KeepAliveFile = "D:\.sd_keepalive"

Write-Host "Removing SD Card Keep-Alive..." -ForegroundColor Cyan

# Stop the scheduled task
Write-Host "Stopping SD keep-alive task..."

Stop-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

# Disable the scheduled task
Write-Host "Disabling SD keep-alive task..."

Disable-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

# Remove the scheduled task
Write-Host "Removing scheduled task..."

Unregister-ScheduledTask `
    -TaskName $TaskName `
    -Confirm:$false `
    -ErrorAction SilentlyContinue

# Remove installed keep-alive script
if (Test-Path $ScriptPath) {
    Write-Host "Removing keep-alive script..."
    Remove-Item $ScriptPath -Force
}

# Remove installation directory
if (Test-Path $InstallDir) {
    Write-Host "Removing installation directory..."
    Remove-Item $InstallDir -Recurse -Force
}

# Remove the keep-alive file from the SD card
if (Test-Path $KeepAliveFile) {
    Write-Host "Removing D:\.sd_keepalive..."
    Remove-Item $KeepAliveFile -Force
}

Write-Host ""
Write-Host "SD keep-alive has been completely removed." -ForegroundColor Green
Write-Host ""
Write-Host "The scheduled task, script, installation folder,"
Write-Host "and D:\.sd_keepalive have all been removed."
Write-Host ""
