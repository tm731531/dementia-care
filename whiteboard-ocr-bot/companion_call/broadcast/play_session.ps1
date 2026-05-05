# Companion Broadcast — 播放一輪陪聊 session (~60 秒)
# 由 Task Scheduler 在指定時段觸發。
#
# 流程：
#   prompt_01 (開場 「媽，怎麼了？」)
#   → 8 秒停頓 (讓媽媽反應)
#   → 4 個隨機 middle prompt，每個間隔 8 秒
#   → prompt_11 (結束 「我先去忙，等等再打給你」)
#   total ~58 秒
#
# 部署位置：C:\companion-broadcast\play_session.ps1
# 音檔位置：C:\companion-broadcast\audio\prompt_01.wav ~ prompt_12.wav
# 手動測試：powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\play_session.ps1

$ErrorActionPreference = "Stop"

$audioDir = "C:\companion-broadcast\audio"

if (-not (Test-Path $audioDir)) {
    Write-Error "Audio directory not found: $audioDir"
    exit 1
}

$opener = Join-Path $audioDir "prompt_01.wav"
$closer = Join-Path $audioDir "prompt_11.wav"
$middleNumbers = @(2, 3, 4, 5, 6, 7, 8, 9, 10, 12)
$middlePaths = $middleNumbers | ForEach-Object {
    Join-Path $audioDir ("prompt_{0:D2}.wav" -f $_)
}

function Play-Wav {
    param([string]$path)
    if (-not (Test-Path $path)) {
        Write-Warning "Missing audio file: $path"
        return
    }
    $player = New-Object Media.SoundPlayer $path
    $player.PlaySync()
}

# Log session start to local log (gitignored)
$logFile = "C:\companion-broadcast\session.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "$timestamp  session start"

# Opener
Play-Wav $opener
Start-Sleep -Seconds 8

# 4 random middle prompts (no repeats within session)
$selected = $middlePaths | Get-Random -Count 4
foreach ($wav in $selected) {
    Play-Wav $wav
    Start-Sleep -Seconds 8
}

# Closer
Play-Wav $closer

Add-Content -Path $logFile -Value "$timestamp  session end"
