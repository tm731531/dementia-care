# Companion Broadcast — 播放一章 Tom 的睡前故事 (5-15 分鐘)
# 隨機從 C:\companion-broadcast\book\ 抽一個 book_*.wav 完整播放。
#
# 跟 play_session.ps1 (1 分鐘陪聊問句) 是兩種模式，視 Task Scheduler 接哪個而定。
#
# 部署位置：C:\companion-broadcast\play_book.ps1
# 章節位置：C:\companion-broadcast\book\book_001.wav ~ book_NNN.wav
# 手動測試：powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\play_book.ps1

$ErrorActionPreference = "Stop"

$bookDir = "C:\companion-broadcast\book"
$logFile = "C:\companion-broadcast\session.log"

if (-not (Test-Path $bookDir)) {
    Write-Error "Book directory not found: $bookDir"
    exit 1
}

$wavs = @(Get-ChildItem $bookDir -Filter "book_*.wav" -File)
if ($wavs.Count -eq 0) {
    Write-Error "No book_*.wav found in $bookDir"
    exit 1
}

$pick = $wavs | Get-Random
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "$timestamp  book start: $($pick.Name) ($([math]::Round($pick.Length/1MB,1)) MB)"

# 用 Windows Media Player COM 而非 SoundPlayer (後者對 5-15 分鐘長檔不穩)
$wmp = New-Object -ComObject WMPlayer.OCX
$wmp.URL = $pick.FullName
$wmp.settings.autoStart = $true
$wmp.controls.play()

# Wait for playback to finish (with safety timeout 20 min)
$timeout = (Get-Date).AddMinutes(20)
while ((Get-Date) -lt $timeout) {
    Start-Sleep -Seconds 5
    # playState: 1=stopped, 3=playing, 6=buffering, 8=mediaEnded
    $state = $wmp.playState
    if ($state -in @(1, 8)) { break }
}

$wmp.close()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "$timestamp  book end: $($pick.Name)"
