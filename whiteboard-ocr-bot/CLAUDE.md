# 白板 OCR 紀錄 Bot — 開發指引

## 專案簡介
Telegram bot 自動化失智照護白板紀錄：拍照傳給 bot → Gemini 視覺辨識 → 寫入 iDempiere `Z_momSystem`。
人在迴圈（human-in-the-loop）—— bot 省 5 分鐘打字工時，使用者負責驗證正確性。

## 技術架構
- **Python 3** + `python-telegram-bot`
- **OCR**：Gemini 3 Flash Preview（免費額度內）
- **儲存**：iDempiere REST API 寫入 `Z_momSystem` 表
- **前端 demo**：`index.html` 純前端 Telegram bot 對話模擬
- **Favicon（demo）**：SVG inline emoji（📋）

## 元件

### `telegram_bot.py`
主要 bot 邏輯。處理使用者傳來的：
- 📸 照片 → 交給 `ocr_pipeline` 做辨識
- 📝 文字訊息 → 加時間戳（早/晚/大夜班）append 到當天備註欄
- `/status`、`/today` 等指令

### `ocr_pipeline.py`
1. 呼叫 Gemini API 輸入照片 + prompt
2. 解析回傳 JSON 對應 12 個追蹤欄位
3. 磁鐵位置 → 選項代碼
4. 回傳給 bot 請使用者 confirm
5. confirm 後寫 iDempiere REST

### `whiteboard_layout.py`
白板 12 個追蹤項目的空間座標 + 可選項對應。照護員把磁鐵壓在某一格 → 對應選項代碼。

### `config.py`（gitignored）
- Telegram Bot Token
- Gemini API Key
- iDempiere 帳密 + REST endpoint
- Allowed Telegram user IDs（白名單）
- 參考 `config.py.example`

### `allowed_users.txt`
白名單 Telegram user ID，避免陌生人傳圖耗 API quota。

## 12 個追蹤項目
夜間活動 / 睡眠 / 早餐 / 午餐 / 晚餐 / 活動 / 外出 / 陪伴 / 排泄 / 洗澡 / 情緒 / 異常事件

每項目磁鐵選擇轉成一個固定選項代碼（例如：睡眠 A=好、B=普通、C=差）。

## Human-in-the-loop 流程
1. 使用者拍白板傳 bot
2. Bot 回傳 OCR 結果供確認：「看起來是：夜間活動=A、睡眠=B、... 正確嗎？」
3. 使用者回 ✅ 或修正 → 才寫入 iDempiere
4. 錯誤修正時 bot 學不到（純 stateless），但使用者只需改那一欄

**寧缺勿錯原則**：Gemini 拿不定的欄位回 null，不猜。使用者收到「睡眠欄位無法判斷，請手動補」訊息。

## 時間戳邏輯（文字訊息）
居服員在 LINE 白天回報事件 → 轉傳給 bot → 自動判斷：
- 06:00-14:00 → 早班備註
- 14:00-22:00 → 晚班備註
- 22:00-06:00 → 大夜班備註
Append 到當天對應班次備註欄（不覆蓋）。

## iDempiere 寫入
`Z_momSystem` 表每天一筆：
- `Date`：當天日期（同日重複傳會 upsert 覆蓋）
- 12 個選項欄位
- `Notes_Morning` / `Notes_Evening` / `Notes_Night`：班次備註累積
- `Photo`：附件（原始照片 base64 或 attachment）

## 與 mom-clinic-companion 的關係
這個 bot 寫進 iDempiere，`mom-clinic-companion` 從 iDempiere 讀出來做分析。
兩個工具一起組成完整資料閉環：**拍照→記錄→回診歸納**。

## 開發指引
- 改 OCR prompt：改完拿最近 3-5 張白板照片跑 benchmark 驗證
- 改欄位：同步改 iDempiere schema + whiteboard_layout + ocr_pipeline 解析
- Gemini API key 洩漏 → 立刻撤銷（gitignore 檢查）
- 新功能上 prod 前用測試 Telegram ID + 測試 iDempiere instance 驗證

## 踩過的坑
- **Gemini 回傳 JSON 格式不穩** — 偶爾加 markdown fence，要先 strip ```json
- **照護員 LINE 轉傳格式多變** — 有的有「Tom 說：」前綴，有的沒有，要正則容錯
- **iDempiere upsert** — 同日重複傳不能用 create，要先 GET 看有沒有，再 PATCH/POST

## 檔案結構
```
whiteboard-ocr-bot/
  CLAUDE.md
  README.md
  index.html                # 純前端 demo
  telegram_bot.py           # bot 主邏輯
  ocr_pipeline.py           # Gemini OCR
  whiteboard_layout.py      # 白板項目座標
  config.py.example         # 設定模板
  config.py                 # 實際設定（gitignored）
  allowed_users.txt         # Telegram 白名單
  requirements.txt          # Python deps
  inbox/                    # 收到的照片暫存
  pending_notes.json        # 文字訊息暫存（等同日照片來合併）
```

## 依賴
- `python-telegram-bot`
- `google-generativeai`（Gemini）
- `requests`
- `Pillow`

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/idempiere-rest-api.md`
- `~/.claude/projects/-home-tom/memory/brain/python-llm-integration.md`
- `~/.claude/projects/-home-tom/memory/brain/llm-conversation-grounding.md`
