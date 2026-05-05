# companion_call — Phase 狀態（2026-05-05 update）

## 現況

| Phase | 內容 | 狀態 |
|---|---|---|
| **A 自動撥電話** (twilio_functions/) | mini PC 排程 → Twilio Functions 接 TwiML → 撥媽媽 SIM → 媽媽接 → 聽錄音陪聊 | **Deferred**：成本太高（Twilio paid $20 升級費 + ~$200/月）+ 台灣 carrier DTMF/警示音導致 trial 不可用 |
| **B 手動撥電話** | Tom 手機 calendar reminder → 自己撥媽媽 4G 桌上電話 → 真人陪聊 | **進行中**：等 4G 桌上電話到貨 + SIM 物理切換 |
| **C 廣播站** (broadcast/) | 樓下 i3 Windows + Task Scheduler → 排程到時 i3 喇叭直接播 prompt_01-12 → 媽媽聽 | **進行中**：等 Tom 把 wav 同步到 i3 + 跑 setup_tasks.ps1 |

## Phase A 留下了什麼

- Twilio Functions 仍 deploy 在 cloud（free tier 內，不刪）
- mini PC scheduler systemd 沒裝，所以不會自動 trigger
- `scheduled_call.py` 仍可手動跑 (`python -m companion_call.scheduled_call`) 撥一通給 Tom 自驗
- 12 段 wav 同時用於 Phase A (Twilio Assets) 跟 Phase C (i3 喇叭)
- iDempiere `Z_momSystem` 寫入 helper (shared.py) 仍可用，未來 Phase A 重啟可立刻接

## Phase B 設定（在你手機上做）

- iOS Calendar / Google Calendar
- 加 5 個 weekly events:
  - 週二/四/日 09:00 — 「打給媽媽」
  - 同上 10:00, 11:00, 15:00, 16:00
- 響鈴提醒
- 跟 Phase C 廣播站時段交錯（見 broadcast/README.md 表格）

## Phase C 部署（在 i3 Windows 做）

見 `broadcast/README.md`。一句話 SOP：

```
1. 建 C:\companion-broadcast\audio\
2. Google Drive 同步 12 個 wav 到那
3. 拷貝 play_session.ps1 + setup_tasks.ps1 到 C:\companion-broadcast\
4. powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\setup_tasks.ps1
5. 測試一次：powershell -ExecutionPolicy Bypass -File C:\companion-broadcast\play_session.ps1
```

## 為什麼跳過 Phase A

驗證紀錄：
- Twilio paid $20 升級費 + ~$200/月，5 年 ~NT$10,800
- Trial 撥到台灣手機觸發 carrier 警示語音 + Trial warning 雙重 → 通話前 12-30s 都浪費
- 台灣手機 DTMF 回 Twilio 不穩，按鍵 bypass trial 不可靠
- Tom 評估：成本壓力 > 自動化必要性 → 改 B + C 混搭手動 + 本地廣播

未來若 Tom 想升級到 Phase A：
- 升 Twilio paid（$20 一次）
- mini PC `bash companion_call/install_systemd.sh` 啟動 scheduler
- iDempiere `Z_momSystem` 自動 log

## Spec / Plan 對應

- `docs/superpowers/specs/2026-05-05-mom-companion-call-design.md` 寫的是 Phase A 設計
- 該 spec 的 §13 milestones M1-M7 對應 Phase A，目前停在 M5 (Phase 1 受控觀察)
- Phase B/C 沒寫進 spec — 算 spec 的 alternative path，新增 footnote 即可（不重寫 spec）

## 紀錄寫入 Z_momSystem

| Phase | 寫入方式 |
|---|---|
| A | `scheduled_call.py` 自動寫 `[date|time] 陪聊 XXs` |
| B | Tom 自己手動撥完，**目前不寫**（沒 trigger）。如果未來想記錄，可以加一個 Telegram bot 「我打過了」按鈕 |
| C | 廣播站只寫 local `session.log`，**不寫 iDempiere**（沒互動 = 沒「媽媽接聽率」這種趨勢數據） |
