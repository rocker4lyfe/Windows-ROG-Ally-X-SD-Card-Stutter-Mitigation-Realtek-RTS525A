# SD Card Keep-Alive Installer
# ROG Ally X – Realtek RTS525A

$ErrorActionPreference = "Stop"

$TaskName = "SD Card Keep-Alive"
$InstallDir = "$env:USERPROFILE\SDKeepAlive"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = "$InstallDir\sd_keepalive.ps1"
$VbsPath = "$InstallDir\sd_keepalive_launcher.vbs"

Write-Host "Installing SD Card Keep-Alive..." -ForegroundColor Cyan

# Create installation directory
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# Copy keep-alive script
Write-Host "Copying keep-alive script..."
Copy-Item `
    "$ScriptDir\sd_keepalive.ps1" `
    $ScriptPath `
    -Force

# Write a VBScript launcher. wscript.exe reliably creates zero visible
# window, unlike "powershell.exe -WindowStyle Hidden", which Windows
# Terminal (the Windows 11 default) can ignore and show anyway.
Write-Host "Writing hidden launcher..."
$VbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""$ScriptPath""", 0, False
"@
Set-Content -Path $VbsPath -Value $VbsContent -Encoding ASCII -Force

# Create scheduled task action - launch the VBS wrapper, not PowerShell directly
$Action = New-ScheduledTaskAction `
    -Execute "wscript.exe" `
    -Argument "`"$VbsPath`""

# Start at user logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Keep running on battery, restart if it stops, and never time out
# (default task time limit is 3 days, which would kill this task)
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

# Run with the logged-on user's normal privileges (no admin needed)
$Principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

# Remove an existing task if present
Unregister-ScheduledTask `
    -TaskName $TaskName `
    -Confirm:$false `
    -ErrorAction SilentlyContinue

# Register the task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal | Out-Null

# Confirm registration actually happened before doing anything else
$Registered = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $Registered) {
    Write-Host ""
    Write-Host "FAILED: task was not registered. See the error above." -ForegroundColor Red
    exit 1
}

# Start immediately
Start-ScheduledTask -TaskName $TaskName

# Confirm it's actually running before declaring success.
# Note: the task's own State goes back to "Ready" almost immediately,
# because the VBS launcher hands off to a detached PowerShell process
# and exits right away - that's expected. What actually matters is
# whether that detached process exists.
Start-Sleep -Seconds 2
$RunningProc = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and $_.CommandLine -like "*sd_keepalive.ps1*" }

if (-not $RunningProc) {
    Write-Host ""
    Write-Host "FAILED: keep-alive process is not running." -ForegroundColor Red
    Write-Host "Check: Get-ScheduledTaskInfo -TaskName `"$TaskName`""
    exit 1
}

Write-Host ""
Write-Host "SD keep-alive installed and started successfully." -ForegroundColor Green
Write-Host ""
Write-Host "SD card: D:"
Write-Host "Interval: 3 seconds"
Write-Host "Keep-alive file: D:\.sd_keepalive"
Write-Host ""
Write-Host "The keep-alive will automatically start when you log into Windows."
Write-Host ""
Write-Host "To remove it, run:"
Write-Host "  remove_sd_keepalive.ps1"
Write-Host ""
