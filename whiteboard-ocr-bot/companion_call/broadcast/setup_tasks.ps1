# Setup Windows Task Scheduler entries for companion broadcast.
#
# 預設模式：book (Tom 念給女兒的睡前故事，repurpose 給媽媽聽，每段 5-15 分鐘隨機抽)
# 替代模式：chat (1 分鐘陪聊問句，原本的 12 段 prompt) — 用 -Mode chat 切換
#
# 自動找 path：script 所在的資料夾就是 broadcast root
# 部署 C:\companion-broadcast\ 跑：
#   powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
#
# 部署 D:\ 跑：
#   powershell -ExecutionPolicy Bypass -File D:\setup_tasks.ps1
#
# Custom path：
#   powershell -ExecutionPolicy Bypass -File .\setup_tasks.ps1 -BookDir "E:\some\path" -LogFile "E:\session.log"
#
# Creates 5 weekly tasks (Tue/Thu/Sun) for slots 09/10/11/15/16.

param(
    [ValidateSet("book", "chat")]
    [string]$Mode = "book",
    [string]$BookDir = $null,
    [string]$LogFile = $null
)

$ErrorActionPreference = "Stop"

# 自動推算路徑：script 所在資料夾 = broadcast root
$BroadcastDir = $PSScriptRoot
if (-not $BroadcastDir) { $BroadcastDir = (Get-Location).Path }

if (-not $BookDir)  { $BookDir  = Join-Path $BroadcastDir "book" }
if (-not $LogFile)  { $LogFile  = Join-Path $BroadcastDir "session.log" }

if ($Mode -eq "book") {
    $scriptPath = Join-Path $BroadcastDir "play_book.ps1"
    $taskBaseName = "CompanionBook"
    $description = "Companion broadcast - Tom 睡前故事章節隨機"
    $execTimeLimitMin = 25
} elseif ($Mode -eq "chat") {
    $scriptPath = Join-Path $BroadcastDir "play_session.ps1"
    $taskBaseName = "CompanionChat"
    $description = "Companion broadcast - 1 分鐘陪聊問句"
    $execTimeLimitMin = 5
}

if (-not (Test-Path $scriptPath)) {
    Write-Error "$scriptPath not found. Place play_book.ps1 / play_session.ps1 there first."
    exit 1
}

$daysOfWeek = "Tuesday", "Thursday", "Sunday"
$times = @("09:00", "10:00", "11:00", "15:00", "16:00")

# 把 BOOK_DIR / BOOK_LOG env var inline 進 task argument
# (Task Scheduler 跑時是 fresh process，不繼承父 PowerShell env)
$psArg = "-ExecutionPolicy Bypass -Command " +
         "`"`$env:BOOK_DIR='$BookDir'; `$env:BOOK_LOG='$LogFile'; & '$scriptPath'`""

# 不用 -WindowStyle Hidden — hidden window 在 Task Scheduler 跑 SoundPlayer 不出聲
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $psArg

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes $execTimeLimitMin)

# 先清掉同 base name 的舊 task
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
Write-Host "  Script:  $scriptPath"
Write-Host "  BookDir: $BookDir"
Write-Host "  LogFile: $LogFile"
Write-Host ""
Write-Host "View them: Get-ScheduledTask -TaskName '$taskBaseName-*'"
Write-Host "Test now:  powershell -ExecutionPolicy Bypass -Command `"`$env:BOOK_DIR='$BookDir'; `$env:BOOK_LOG='$LogFile'; & '$scriptPath'`""
Write-Host "Remove all: Get-ScheduledTask -TaskName '$taskBaseName-*' | Unregister-ScheduledTask -Confirm:`$false"
