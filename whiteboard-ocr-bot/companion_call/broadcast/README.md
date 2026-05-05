# Companion Broadcast — Windows i3 自動播錄音版

不打電話，i3 直接從喇叭播放錄音給媽媽聽。週二/四/日 09:00 / 10:00 / 11:00 / 15:00 / 16:00 各播一輪 ~60 秒 session。

## 前提

- i3 在媽媽聽得到的範圍內（喇叭 ≤ 3 公尺，無大型阻隔物）
- i3 用同一個 Windows user 登入（task 會在這個 session 跑）
- i3 不要進「Sleep」（要的話 Task Scheduler 會嘗試 wake，但不保證）

## 部署 SOP（5 步驟）

### Step 1: 建資料夾
在 i3 開 PowerShell（非 admin OK），執行：

```powershell
New-Item -Path "C:\companion-broadcast\audio" -ItemType Directory -Force
```

### Step 2: 從 Google Drive 把 wav 拷貝到 audio 資料夾
你已經把 12 段 wav 同步到 Google Drive。在 i3 上：

1. 開檔案總管，到 Google Drive 同步資料夾（一般是 `G:\My Drive\` 或 `C:\Users\<你>\Google Drive\My Drive\`）
2. 找你放 wav 的子資料夾
3. 把 12 個 `prompt_01.wav` ~ `prompt_12.wav` 全選複製
4. 貼到 `C:\companion-broadcast\audio\`

驗證：

```powershell
Get-ChildItem C:\companion-broadcast\audio\prompt_*.wav | Measure-Object
# 應該顯示 Count : 12
```

### Step 3: 把 PowerShell 腳本拷貝過去
從 mini PC（或 GitHub）抓這 2 個檔，放 `C:\companion-broadcast\`：
- `play_session.ps1`
- `setup_tasks.ps1`

可以用 Google Drive 同樣 sync 過去。

### Step 4: 安裝 Task Scheduler 排程

```powershell
powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
```

預期看到：
```
✓ Registered: CompanionBroadcast-09:00
✓ Registered: CompanionBroadcast-10:00
✓ Registered: CompanionBroadcast-11:00
✓ Registered: CompanionBroadcast-15:00
✓ Registered: CompanionBroadcast-16:00
```

### Step 5: 測試播放（不等排程）

```powershell
powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\play_session.ps1
```

應該聽到：
- 你錄的「媽，怎麼了？」（prompt_01）
- 8 秒停
- 隨機 4 個 middle prompt（每個之間 8 秒停）
- 你錄的結束句「媽，我先去忙喔」（prompt_11）
- 總時長 ~58 秒

---

## 確認排程跑得起來

```powershell
# 看排程清單
Get-ScheduledTask -TaskName 'CompanionBroadcast-*' | Format-Table TaskName, State, NextRunTime

# 看單一 task 詳細
Get-ScheduledTask -TaskName 'CompanionBroadcast-09:00' | Get-ScheduledTaskInfo
```

`State` 應該是 `Ready`，`NextRunTime` 是下個週二/四/日的對應時間。

## 看播放紀錄

每次 session 跑完會 append 一行到 `C:\companion-broadcast\session.log`：

```
2026-05-07 09:00:01  session start
2026-05-07 09:00:01  session end
```

如果某天時段沒紀錄 → task 沒跑 → 檢查 i3 是不是被休眠 / wifi 斷 / 排程 disable。

## 改時段

編輯 `setup_tasks.ps1` 的 `$times` 陣列，重新跑：

```powershell
powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
```

它會先 unregister 舊的再裝新的。

## 移除所有排程（如果你不想跑了）

```powershell
Get-ScheduledTask -TaskName 'CompanionBroadcast-*' | Unregister-ScheduledTask -Confirm:$false
```

## 物理 setup 提醒

- **喇叭音量**：i3 系統音量 + 喇叭旋鈕都調到媽媽聽得到的響度（事後問她「電話聲音夠大嗎」）
- **喇叭位置**：朝媽媽常坐的位置，不要放電視旁邊（電視會蓋過）
- **i3 不要關機 / 不要進 Sleep**：Power Plan 設「Never sleep」，或排程的「WakeToRun」會試圖喚醒
- **i3 user logged in**：task 在 user session 跑才能輸出音訊。如果 i3 自動鎖屏 OK，但別 log out

## 跟 phone 端的關係

這個廣播站**取代了原本電話陪聊**的設計。媽媽**不會接到電話**，是 i3 喇叭主動播放。

如果你**還是要手動撥電話**（你選 Phase B 那條），建議跟廣播站時段**交錯**避免 overload：

| 時段 | 廣播站 | 你手動撥 |
|---|---|---|
| 09:00 | ✅ | ❌ |
| 10:00 | ❌ | ✅ |
| 11:00 | ✅ | ❌ |
| 15:00 | ❌ | ✅ |
| 16:00 | ✅ | ❌ |

廣播站要拿掉某些時段：編輯 `setup_tasks.ps1` 的 `$times` 改成 `@("09:00", "11:00", "16:00")` 重新跑即可。
