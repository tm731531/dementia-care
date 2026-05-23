# Companion Broadcast — 播放一章 Tom 的睡前故事 (5-15 分鐘)
# 隨機從 book/ 抽一個 book_*.wav 完整播放。
#
# 不用 WMP COM (在 hidden window / Task Scheduler 不出聲)。
# 改用 .NET SoundPlayer + 必要時 fallback 到 wmplayer.exe。
#
# 部署位置：C:\companion-broadcast\play_book.ps1
# 章節位置：C:\companion-broadcast\book\book_001.wav ~ book_NNN.wav
# 手動測試：powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\play_book.ps1

$ErrorActionPreference = "Stop"

# 路徑可由環境變數 override (e.g. $env:BOOK_DIR = "D:\book")
$bookDir = if ($env:BOOK_DIR) { $env:BOOK_DIR } else { "C:\companion-broadcast\book" }
$logFile = if ($env:BOOK_LOG)  { $env:BOOK_LOG } else { "C:\companion-broadcast\session.log" }

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
$msg = "$timestamp  book start: $($pick.Name) ($([math]::Round($pick.Length/1MB,1)) MB)"
Add-Content -Path $logFile -Value $msg
Write-Host $msg

# === 試 1: System.Media.SoundPlayer (.NET 標準，PCM wav 直接支援) ===
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $player = New-Object System.Media.SoundPlayer $pick.FullName
    $player.Load()
    $player.PlaySync()   # blocking, 完整播完才 return
    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  book end (SoundPlayer): $($pick.Name)"
    Add-Content -Path $logFile -Value $msg
    Write-Host $msg
    exit 0
} catch {
    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  SoundPlayer failed: $_"
    Add-Content -Path $logFile -Value $msg
    Write-Warning $msg
}

# === 試 2: Fallback — Start-Process wmplayer.exe ===
try {
    $wmpExe = $null
    foreach ($p in @(
        "${env:ProgramFiles(x86)}\Windows Media Player\wmplayer.exe",
        "${env:ProgramFiles}\Windows Media Player\wmplayer.exe"
    )) {
        if (Test-Path $p) { $wmpExe = $p; break }
    }

    if ($wmpExe) {
        $proc = Start-Process -FilePath $wmpExe -ArgumentList "`"$($pick.FullName)`"" -PassThru
        # 等播完 (用檔案 duration 推估，加 buffer)
        $estSec = [math]::Min(1200, [math]::Round($pick.Length / 88200) + 30)
        Start-Sleep -Seconds $estSec
        if (-not $proc.HasExited) { $proc.Kill() }
        $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  book end (wmplayer): $($pick.Name)"
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg
    } else {
        $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  ERR: 兩種播放方式都失敗"
        Add-Content -Path $logFile -Value $msg
        Write-Error $msg
    }
} catch {
    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  wmplayer fallback err: $_"
    Add-Content -Path $logFile -Value $msg
    Write-Error $msg
}
