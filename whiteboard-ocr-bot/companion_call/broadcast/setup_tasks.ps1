# Setup Windows Task Scheduler entries for companion broadcast.
#
# Run once on i3 Windows:
#   powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
#
# Creates 5 weekly tasks (Tue/Thu/Sun) for slots 09/10/11/15/16.

$ErrorActionPreference = "Stop"

$scriptPath = "C:\companion-broadcast\play_session.ps1"
$taskBaseName = "CompanionBroadcast"
$daysOfWeek = "Tuesday", "Thursday", "Sunday"
$times = @("09:00", "10:00", "11:00", "15:00", "16:00")

if (-not (Test-Path $scriptPath)) {
    Write-Error "play_session.ps1 not found at $scriptPath. Place it there first."
    exit 1
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

foreach ($time in $times) {
    $taskName = "$taskBaseName-$time"

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek $daysOfWeek `
        -At $time

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Companion broadcast session at $time on Tue/Thu/Sun" `
        -RunLevel Limited | Out-Null

    Write-Host "✓ Registered: $taskName"
}

Write-Host ""
Write-Host "All 5 tasks installed. View them:"
Write-Host "  Get-ScheduledTask -TaskName 'CompanionBroadcast-*'"
Write-Host ""
Write-Host "Test play right now (don't wait for schedule):"
Write-Host "  powershell -ExecutionPolicy Bypass -File $scriptPath"
Write-Host ""
Write-Host "Remove all tasks if you want:"
Write-Host "  Get-ScheduledTask -TaskName 'CompanionBroadcast-*' | Unregister-ScheduledTask -Confirm:`$false"
