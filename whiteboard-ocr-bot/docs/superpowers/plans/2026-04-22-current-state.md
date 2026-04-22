# whiteboard-ocr-bot — Current State（2026-04-22）

## 現況：每天固定運作

每天晚上 8 點 Tom 拍照傳 Telegram bot，OCR 後寫進 iDempiere `Z_momSystem`。
居服員白天在 LINE 即時回報也可轉傳 bot，自動加時間戳到備註欄。

## 已完成里程碑

### 核心功能
- [x] Telegram bot 接收照片
- [x] Gemini 3 Flash Preview 做 12 欄位視覺辨識
- [x] human-in-loop：OCR 結果回傳 confirm 才寫 iDempiere
- [x] LINE 轉傳文字訊息自動加時間戳（早/晚/大夜班）→ 對應備註欄 append
- [x] `pending_notes.json` 暫存同日文字訊息等合併

### iDempiere 整合
- [x] REST API 登入 + token
- [x] `Z_momSystem` 同日 upsert（GET → 存在 PATCH / 不存在 POST）
- [x] 原始照片作為 attachment 存進同筆紀錄

### 安全
- [x] `allowed_users.txt` 白名單，陌生人傳圖不回
- [x] `config.py` 列入 gitignore
- [x] `config.py.example` 作為範本

### 前端 demo
- [x] `index.html` 純前端 demo（模擬 Telegram 介面），給想先看體驗的人
- [x] SVG emoji favicon 📋

## 進行中 / 待觀察

- [ ] Gemini 準度追蹤 —— 偶爾某欄位誤判，目前靠 confirm 修正
- [ ] `inbox/` 資料夾照片累積（是否要自動清理）
- [ ] `bot.log` 大小成長（輪替策略待定）

## 優先序待決

### 🟡 若 Gemini 準度下滑
- 用最近 5-10 張白板 benchmark 新版 Gemini
- 回看 prompt 是否該調（加 few-shot examples？）
- 考慮切換 Gemini 版本（目前用 Flash Preview，出 stable 時評估）

### 🟡 若 Telegram 訊息格式再變異
- 居服員換人 / LINE 版本更新可能改變轉傳格式
- 正則要補容錯
- 加測試：`tests/test_forward_parser.py`（目前沒有測試）

### 🟢 Nice-to-have
- `ptz_test.py` 是什麼？（PTZ 攝影機自動拍？）→ 自動化下一步
- Systemd service 讓 bot 自動重啟（目前手動）
- 多家庭支援（朋友也想用時）

## 不做的事
- 不自動修正 OCR 猜不定的欄位 → 寧缺勿錯
- 不打破 human-in-loop → confirm 必要
- 不整合 LLM 分析備註（留給 mom-clinic-companion 做）

## 下一次動工 Trigger
- 新版 Gemini 出來 → 跑 benchmark
- 白板格子調整 → 同步改 `whiteboard_layout.py` + iDempiere schema
- 居服員回報 bot 沒讀到訊息
- 朋友要自己部署 → 寫部署指南 + 抽象化 config

## 快速進場指引
1. 改 Gemini prompt → 跑 benchmark（最近 5 張白板比 before/after）
2. 改 `whiteboard_layout.py` → 同步檢查 iDempiere schema 欄位還在
3. `config.py` 絕對不 commit（每次 `git status` 檢查）
4. OCR 不確定的欄位回 null，不亂猜
5. 外洩 token 立即 revoke：BotFather `/revoke` / Google Cloud Console

## 部署方式
- 目前在 Tom 的機器手動 `python3 telegram_bot.py`
- 未來 systemd service：
  ```
  [Service]
  ExecStart=/path/to/venv/bin/python telegram_bot.py
  Restart=on-failure
  ```

## 外部依賴
- Telegram Bot Token（BotFather）
- Gemini API Key（Google AI Studio）
- iDempiere REST 可連
- Python 3.x + venv
