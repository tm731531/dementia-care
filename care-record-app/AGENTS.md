# care-record-app — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列本專案特有的內容。

## Project-Specific Perspective Inventory

| Perspective | Risk (0-3) | Scope (0-3) | Score | Notes |
|--|--|--|--|--|
| 💝 家屬（主要記錄者） | 3 | 3 | 9 | 每天記錄、消滅打字是核心需求；解鎖/匯出摩擦直接影響會不會被用 |
| 👷 外勞/居服員（次記錄 + 攜帶者） | 3 | 2 | 6 | 換手機快、現場零設定、匯入合併要無腦；不會/不願打密碼 |
| 🩺 醫生（最終消費者） | 2 | 2 | 4 | 沒空翻照片，要乾淨文字 + 趨勢；輸出檔要免裝 App 直接開 |
| Security | 3 | 2 | 6 | 特種個資、旁人拿手機威脅、落地加密、ZIP 走 LINE 的殘留風險 |
| Implementer (Flutter) | 2 | 3 | 6 | whisper.cpp 上機、camera、加密儲存、iOS/Android 差異 |
| Architect | 2 | 2 | 4 | 資料模型（union 合併）、匯出/匯入、離線邊界 |
| Tester | 2 | 2 | 4 | 語音轉字準度、合併衝突、解鎖/自動上鎖、換手機路徑 |
| PM | 1 | 2 | 2 | 對齊 mom 線資料閉環；第一版範圍收斂（不做 OCR/雲端/複雜合併） |

**Score = Risk × Scope**：≥6 專屬 agent；3-5 專屬或配對；1-2 折入；0 承認不派。

## Agents（待 writing-plans 後依實作階段細化）

| Agent | Model | Primary Perspectives | Priority |
|--|--|--|--|
| flutter-impl | sonnet | Implementer(Flutter) + Architect | P1 |
| voice-stt | opus | whisper.cpp 上機 / 離線邊界 | P1 |
| security | opus | 生物辨識鎖 / 落地加密 / ZIP 風險 | P2 |
| reviewer | opus | 家屬 + 醫生 + Tester 折入 | P2 |

## Project-Specific Rules

### 寧缺勿錯（沿用主線）
語音轉字不確定的段落標記待確認、不腦補進醫生輸出。錯的資料比缺的危險。

### 零雲端不可破
任何「順手」引入的雲端呼叫（分析、崩潰回報、字型 CDN、遠端 STT）一律拒絕。
資料只出於使用者主動匯出。

### 不做 OCR / 不做帳號後端 / 不做複雜合併（v1）
這三條在 spec §4.7 明列為不做。要加回來需重新走設計。

## Re-Evaluation Triggers
- whisper 端側準度若實機測不如預期 → 重看「語音是否夠用」的設計假設
- 若真出現「多台雙向持續同步」需求 → Security + Architect 分數上調，合併引擎升級為專屬 agent
