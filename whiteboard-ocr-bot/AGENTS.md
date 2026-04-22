# whiteboard-ocr-bot — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`。

## Project-Specific Perspective Inventory

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| User（Tom + 居服員）| 2 | 2 | 4 | 每天 1 次固定操作，流程穩 |
| PM（資料閉環）| 3 | 3 | 9 | 上游中斷 → 整條鏈都斷 |
| Tester | 3 | 2 | 6 | OCR 準度 + upsert 邏輯必驗 |
| Implementer (Python) | 2 | 2 | 4 | telegram-bot + gemini + requests |
| Architect | 2 | 2 | 4 | human-in-loop + retry 邏輯 |
| Security | 3 | 3 | 9 | Bot token / Gemini key / iDempiere 密碼全在 `config.py`|
| Domain expert（Gemini prompt）| 3 | 2 | 6 | prompt 寫得好 = OCR 準；寫不好 = 錯誤率高 |
| Domain expert（白板版面）| 2 | 1 | 2 | 12 格固定位置，少變 |

## Agents

| Agent | Model | Memory | Primary | Folded | Priority |
|--|--|--|--|--|--|
| security-arch | opus | 1.0 GB | Security, Architect, PM | - | Security > Arch > PM |
| prompt-engineer | opus | 1.0 GB | Domain(Gemini prompt), Tester | - | Domain > Tester |
| py-impl | sonnet | 0.6 GB | Impl(Python), Domain(白板) | User | Impl > Domain > User |

總計 2.6 GB。

## Project-Specific Rules

### `config.py` 絕對不 commit
gitignore 寫好了，但 review 時每次要檢查 `git log -p -- config.py` 沒動過。
外洩：
1. Telegram Bot Token → 立即 revoke，`@BotFather /revoke`
2. Gemini API Key → 立即 revoke，Google Cloud Console
3. iDempiere 帳密 → 改密碼

### Allowed users 白名單
`allowed_users.txt` 一行一個 Telegram user ID。陌生人傳圖 bot 不回應。
新增前先確認那個人是 Tom 或居服員（避免有人加 Tom 然後瞎傳）。

### human-in-loop 不能跳過
Gemini OCR 出來的結果**必須**讓使用者 confirm 才寫 iDempiere。
即使只有一個欄位拿不定，整張都要重 confirm（不做部分寫入）。

### 寧缺勿錯
Gemini 判斷不出來的欄位回 null，不猜。使用者會收到「睡眠欄位無法判斷，請手動補」。
**禁止**改 prompt 強迫 Gemini 一定要填東西。

### OCR prompt 改動必 benchmark
改完 prompt 後用最近 5 張真實白板照片跑一輪，比較新舊準度。
沒 benchmark 過的 prompt 不合併。

### Telegram 訊息格式容錯
居服員轉傳 LINE 對話到 bot，格式各種：
- 有的有「Tom 說：」前綴
- 有的是圖片 + 文字
- 有的附時間戳「14:23 吃了晚餐」
正則要容錯，別假設單一格式。

### iDempiere upsert 流程
同日 POST 重複會錯。必須：
1. GET 該日期 `Z_momSystem` 看有沒有
2. 有 → PATCH 合併（班次備註 append，12 欄位覆蓋）
3. 沒有 → POST 新建

## Re-Evaluation Triggers
- 新版 Gemini 出來 → prompt-engineer agent 跑 benchmark 決定升不升
- 白板版面改了（多/少一個欄位）→ 同步改 `whiteboard_layout.py` + iDempiere schema + ocr_pipeline
- 居服員回報「bot 沒讀到」→ 排查 allowed_users / token / quota
