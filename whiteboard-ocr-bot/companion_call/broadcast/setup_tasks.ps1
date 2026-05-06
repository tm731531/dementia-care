# Setup Windows Task Scheduler entries for companion broadcast.
#
# 預設模式：book (Tom 念給女兒的睡前故事，repurpose 給媽媽聽，每段 5-15 分鐘隨機抽)
# 替代模式：chat (1 分鐘陪聊問句，原本的 12 段 prompt) — 改 $Mode 變數即可
#
# Run once on i3 Windows:
#   powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
#
# Creates 5 weekly tasks (Tue/Thu/Sun) for slots 09/10/11/15/16.

$ErrorActionPreference = "Stop"

# === 模式選擇 ===
$Mode = "book"   # "book" | "chat"

if ($Mode -eq "book") {
    $scriptPath = "C:\companion-broadcast\play_book.ps1"
    $taskBaseName = "CompanionBook"
    $description = "Companion broadcast - Tom 睡前故事章節隨機"
    $execTimeLimitMin = 25     # book 章節最長 ~15 分鐘 + buffer
} elseif ($Mode -eq "chat") {
    $scriptPath = "C:\companion-broadcast\play_session.ps1"
    $taskBaseName = "CompanionChat"
    $description = "Companion broadcast - 1 分鐘陪聊問句"
    $execTimeLimitMin = 5
} else {
    Write-Error "Unknown Mode: $Mode (must be 'book' or 'chat')"
    exit 1
}

$daysOfWeek = "Tuesday", "Thursday", "Sunday"
$times = @("09:00", "10:00", "11:00", "15:00", "16:00")

if (-not (Test-Path $scriptPath)) {
    Write-Error "$scriptPath not found. Place it there first."
    exit 1
}

# 不用 -WindowStyle Hidden — hidden window 在 Task Scheduler 跑 SoundPlayer 不出聲
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes $execTimeLimitMin)

# 先清掉同 base name 的舊 task (避免重裝時殘留)
foreach ($time in $times) {
    $taskName = "$taskBaseName-$time"
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

# Register new tasks
foreach ($time in $times) {
    $taskName = "$taskBaseName-$time"

    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek $daysOfWeek `
        -At $time

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description $description `
        -RunLevel Limited | Out-Null

    Write-Host "✓ Registered: $taskName"
}

Write-Host ""
Write-Host "All 5 tasks installed for mode: $Mode"
Write-Host ""
Write-Host "View them: Get-ScheduledTask -TaskName '$taskBaseName-*'"
Write-Host "Test now: powershell -ExecutionPolicy Bypass -File $scriptPath"
Write-Host "Remove all: Get-ScheduledTask -TaskName '$taskBaseName-*' | Unregister-ScheduledTask -Confirm:`$false"
