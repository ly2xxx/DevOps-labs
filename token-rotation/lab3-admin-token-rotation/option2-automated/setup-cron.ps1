# Windows Task Scheduler Setup for Admin Token Rotation
# Automates scheduling of the rotation script
#
# Usage:
#   .\setup-cron.ps1

param(
    [string]$Schedule = "Monthly",  # Monthly, Weekly, or Daily
    [string]$Time = "02:00"         # Time to run (24-hour format)
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   Windows Task Scheduler Setup - Admin Token Rotation" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RotationScript = Join-Path $ScriptDir "rotate-admin-token.py"

if (-not (Test-Path $RotationScript)) {
    Write-Host "❌ rotate-admin-token.py not found in $ScriptDir" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found rotation script: $RotationScript" -ForegroundColor Green
Write-Host ""

# Prepare task details
$TaskName = "VaultAdminTokenRotation"
$Description = "Automatic rotation of GitLab admin token for Vault plugin"
$PythonPath = (Get-Command python).Source
$WorkingDir = $ScriptDir

Write-Host "📋 Task Configuration:" -ForegroundColor Cyan
Write-Host "   Name: $TaskName" -ForegroundColor Gray
Write-Host "   Schedule: $Schedule" -ForegroundColor Gray
Write-Host "   Time: $Time" -ForegroundColor Gray
Write-Host "   Python: $PythonPath" -ForegroundColor Gray
Write-Host "   Script: $RotationScript" -ForegroundColor Gray
Write-Host ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "⚠️ Task '$TaskName' already exists" -ForegroundColor Yellow
    $response = Read-Host "Do you want to replace it? (y/n)"
    
    if ($response -ne 'y') {
        Write-Host "Cancelled by user" -ForegroundColor Yellow
        exit 0
    }
    
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "✅ Removed existing task" -ForegroundColor Green
}

# Create scheduled task action
$action = New-ScheduledTaskAction `
    -Execute $PythonPath `
    -Argument "`"$RotationScript`"" `
    -WorkingDirectory $WorkingDir

# Create trigger based on schedule
switch ($Schedule) {
    "Monthly" {
        $trigger = New-ScheduledTaskTrigger -Monthly -At $Time -DaysOfMonth 1
        Write-Host "📅 Schedule: 1st of every month at $Time" -ForegroundColor Cyan
    }
    "Weekly" {
        $trigger = New-ScheduledTaskTrigger -Weekly -At $Time -DaysOfWeek Sunday
        Write-Host "📅 Schedule: Every Sunday at $Time" -ForegroundColor Cyan
    }
    "Daily" {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        Write-Host "📅 Schedule: Every day at $Time" -ForegroundColor Cyan
    }
    default {
        Write-Host "❌ Invalid schedule: $Schedule" -ForegroundColor Red
        Write-Host "   Use: Monthly, Weekly, or Daily" -ForegroundColor Yellow
        exit 1
    }
}

# Create task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $Description `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -User $env:USERNAME `
        -RunLevel Highest | Out-Null
    
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "   ✅ Task Scheduler Setup Complete!" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Task Details:" -ForegroundColor Cyan
    Write-Host "   Name: $TaskName" -ForegroundColor White
    Write-Host "   Schedule: $Schedule at $Time" -ForegroundColor White
    Write-Host "   Next run: " -NoNewline -ForegroundColor White
    
    $task = Get-ScheduledTask -TaskName $TaskName
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host $taskInfo.NextRunTime -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "💡 Management Commands:" -ForegroundColor Yellow
    Write-Host "   View task:" -ForegroundColor White
    Write-Host "   Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Run now (test):" -ForegroundColor White
    Write-Host "   Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Disable:" -ForegroundColor White
    Write-Host "   Disable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Remove:" -ForegroundColor White
    Write-Host "   Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}
