# Mom Companion Call — 失智母親排程陪聊外撥系統

**日期**: 2026-05-05
**作者**: Tom (with Claude brainstorming)
**狀態**: Draft（待 Tom 審核）
**位置**: `whiteboard-ocr-bot/companion_call/`（既有 sub-project 內擴充）

---

## 1. 背景與目標

### 1.1 媽媽現況
- 玉美阿嬤失智狀態：講不出名字、地址、金流，已無法主動構句對話
- 但會「罵」、會發出零碎反應；情緒性表達仍存在
- 手機接聽困難（小按鍵、滑動解鎖障礙），市話形狀的大按鍵電話容易接

### 1.1.1 媽媽每週生活節奏（決定排程）

| 星期 | 安排 | 媽媽是否獨處 |
|---|---|---|
| 一 / 三 / 五 | 日照中心 | 否（被照顧） |
| 六 | Tom 帶她外出 | 否（兒子陪） |
| **二 / 四 / 日** | **獨自在家** | **✅ 是 → 排程目標** |

**結論**：陪聊外撥只在「她獨自在家」的二/四/日跑。其他天她有實體陪伴，不需要外撥刺激。

### 1.2 為什麼要做
失智照護需要**規律性刺激**讓她有「被在意」的對話經驗。Tom 不在身邊時，她需要一個會定時打給她的「人」，讓她可以罵 1-2 分鐘發洩。

### 1.3 目標
做一個排程系統，每天定時打電話給媽媽家中的市話，接通後播放預錄的關心問句（「媽，怎麼了？」「什麼事？」），用 VAD 偵測她講完話後輪播下一句，1-2 分鐘後溫柔結束。每通通話結束寫一筆紀錄到 iDempiere `Z_momSystem.Description`，月底回診當失智狀況趨勢指標。

### 1.4 不在 scope
- **LLM 即時對話**：媽媽講不出完整句子，STT/LLM 拿不到內容；節奏比語意重要
- **STT 轉錄通話內容**：醫療上看「接聽率 + 通話長度趨勢」就夠
- **照片/影像**：純電話互動
- **多人使用**：只服務媽媽一人

---

## 2. 為什麼選方案 X（預錄 + VAD），不用 LLM Live

評估三條路（X = 預錄 + VAD、Y = Gemini Live、Z = STT+LLM+TTS pipeline）後選擇 X：

| 比較點 | 方案 X | 方案 Y/Z |
|---|---|---|
| 是否需要理解她的話 | 不需要 | 需要 |
| 她能否被理解 | N/A | 否（失語） |
| Latency（她講完到回應） | <0.5s | 2-4s |
| 月成本 | $0 API | $5-30+ |
| 網路斷線可運作 | 是 | 否 |
| Gemini quota 風險 | 無 | 跟 OCR 搶 free tier |
| 過度工程 | 否 | 是（功能用不到） |

**結論**：方案 X 在這個 use case 是「**剛好夠用**」的最小架構。未來若媽媽狀態改變（例如恢復片段對話能力），升級到 Y 只需替換 TwiML 後端，架構是 reusable 的。

---

## 3. 架構

> **2026-05-05 重寫**：原本「mini PC FastAPI + cloudflared tunnel + Twilio webhook」架構，重做成 **Twilio Functions（cloud serverless）+ mini PC poll-only**。砍掉 cloudflared、systemd 從 3 個降到 1 個、port 衝突問題消失。Tom 端 setup 從 ~30 分鐘降到 ~10 分鐘。

### 3.1 資料流

```
[mini PC: systemd service: companion_scheduler.py (daemon)]
         │
         │ 每分鐘讀 schedule.yaml
         ▼
[hit slot → scheduled_call.run_one_call()]
         │
         │ Twilio API: POST /Calls
         ▼
[Twilio Programmable Voice]
         │
         │ 撥媽媽電話
         ▼
   📞 媽媽家 4G 桌上型市話響起
         │
         │ 媽媽接起 → Twilio fetch TwiML
         ▼
[Twilio Functions (cloud serverless)]   ← 12 wav 在 Twilio Assets
   /voice → /next → ... /next → 結束句 + Hangup
   (state via URL query params: start ts + recent picks)
         │
         │ 通話結束
         ▼
[scheduled_call.py 從 Twilio API poll status + duration]
         │
         ▼
[upsert_zmomsystem_description() → iDempiere REST]
   "[2026-05-05|15:03] 陪聊 87s"
```

**關鍵差異**：mini PC 完全沒有 inbound endpoint。所有 TwiML 邏輯都在 Twilio cloud。Mini PC 只 outbound (place call) + poll status。

### 3.2 元件對應

| 層 | 元件 | 角色 |
|---|---|---|
| 觸發 | `companion_scheduler.py` (systemd) | 常駐 daemon，每分鐘讀 `schedule.yaml` 命中即觸發 |
| 設定 | `schedule.yaml` | Tom 直接編輯，改完即時生效 |
| 編排 | `scheduled_call.py::run_one_call()` | place → wait → fetch → log |
| 中介 | Twilio Voice | 電信橋樑 |
| TwiML | Twilio Functions (`voice.js` / `next.js` / `inbound.js`) | 對話流程，state via URL params |
| 資源 | Twilio Assets | 12 句 wav，由 `deploy_functions.sh` 上傳 |
| 落地 | `companion_call.shared.upsert_zmomsystem_description()` | 通話結束寫 Z_momSystem |

### 3.3 排程設定（Tom 可隨時調）

`companion_call/schedule.yaml`（Tom 用文字編輯器改）：

```yaml
# 每週固定排程（24h 制，依台灣時區 Asia/Taipei）
# 為什麼是週二/四/日：媽媽生活節奏 — 一三五日照、週六兒子陪、二四日獨自在家
# 為什麼是 09-11 + 15-16：早上 + 下午醒著的時段，避開午睡（12-14:30）跟黃昏躁動高峰
# Tom 改完不用重啟，service 每分鐘 reload
weekly:
  tuesday:
    - "09:00"
    - "10:00"
    - "11:00"
    - "15:00"
    - "16:00"
  thursday:
    - "09:00"
    - "10:00"
    - "11:00"
    - "15:00"
    - "16:00"
  sunday:
    - "09:00"
    - "10:00"
    - "11:00"
    - "15:00"
    - "16:00"
  monday: []     # 空陣列 = 不打
  wednesday: []
  friday: []
  saturday: []

# 例外日（蓋過 weekly 規則，例如媽媽住院期間）
exceptions:
  # "2026-05-12":
  #   skip: true        # 整天不打
  # "2026-05-15":
  #   override:         # 改成這天打這幾通
  #     - "10:00"
  #     - "14:00"

# 全域設定
defaults:
  call_duration_sec: 90        # 每通通話上限
  retry_after_no_answer: false # 預設關閉（schedule 密集故）；改稀疏排程時可開
  timezone: "Asia/Taipei"
```

**判斷邏輯**：
- `companion_scheduler.py` 每分鐘 wake
- 讀 `schedule.yaml`（每次重讀，改了立即生效）
- 計算當前時間（HH:MM, 整分）+ 星期幾
- 先看 `exceptions[today]`，再 fallback 到 `weekly[星期幾]`
- 命中 → 啟動 `scheduled_call.py`
- 同一分鐘只觸發一次（避免重複）

**改排程的 SOP**：
1. Tom 編輯 `schedule.yaml`
2. 1 分鐘內 service 自動 reload，下個 slot 起套用新規則
3. 無需 systemctl restart、無需重新 install crontab

---

## 4. 檔案結構（delta against 既有 whiteboard-ocr-bot）

```
whiteboard-ocr-bot/
├── telegram_bot.py              ← 既有，不動
├── ocr_pipeline.py              ← 既有，不動
├── whiteboard_layout.py         ← 既有，不動
├── config.py                    ← 既有，append 變數（見 §5）
├── config.py.example            ← 既有，append 範例
├── requirements.txt             ← 既有，append twilio/fastapi/uvicorn
├── venv/                        ← 既有，pip install 新依賴
├── docs/
│   └── superpowers/
│       ├── plans/               ← 既有
│       └── specs/
│           └── 2026-05-05-mom-companion-call-design.md   ← 本文件
└── companion_call/              ← 🆕 新增子模組
    ├── audio/                   （12 句 Tom 錄音的 mu-law wav）
    ├── twilio_functions/        （Twilio Functions cloud 部署）
    │   ├── functions/
    │   │   ├── voice.js
    │   │   ├── next.js
    │   │   └── inbound.js
    │   ├── assets/              （部署時 deploy_functions.sh 拷貝 audio/*.wav）
    │   ├── package.json
    │   └── .twilioserverlessrc
    ├── companion_scheduler.py   （systemd daemon，讀 schedule.yaml）
    ├── scheduled_call.py        （place → wait → fetch → log Z_momSystem）
    ├── shared.py                （iDempiere auth + upsert helper）
    ├── schedule.yaml            （Tom 可編輯的排程表）
    ├── companion-call.service   （systemd unit）
    ├── deploy_functions.sh      （部署 Functions 到 Twilio cloud）
    ├── install_systemd.sh       （安裝 systemd unit）
    └── README.md
```

**保證**：既有 3 個 .py（`telegram_bot.py` / `ocr_pipeline.py` / `whiteboard_layout.py`）零變動。`git diff` 在那 3 支應該完全空。

---

## 5. 設定 (config.py)

既有 config 加 6 個變數（不刪不改既有）：

```python
# === Existing OCR config ===
TELEGRAM_BOT_TOKEN = "..."
GEMINI_API_KEY = "..."
IDEMPIERE_BASE_URL = "..."
# ... etc

# === Companion Call config (added 2026-05-05) ===
TWILIO_ACCOUNT_SID = "AC..."
TWILIO_AUTH_TOKEN = "..."
TWILIO_FROM_NUMBER = "+1..."        # Twilio 美國號碼
MOM_PHONE_NUMBER = "+886..."        # 媽媽家 4G 桌上電話 SIM
TWILIO_FUNCTIONS_BASE_URL = "https://companion-call-XXXX-dev.twil.io"
COMPANION_CALL_DURATION_SEC = 90    # 通話總時長上限
```

`config.py.example` 同步加範例值（不含真實 token）。

---

## 6. 12 句預錄音檔規格

Tom 親自錄音，**自然口氣不要播報腔**，安靜環境。

| # | 檔名 | 內容 | 用途 |
|---|---|---|---|
| 01 | `prompt_01.wav` | 媽，怎麼了？ | 開場 + 輪播 |
| 02 | `prompt_02.wav` | 怎麼了嗎？ | 輪播 |
| 03 | `prompt_03.wav` | 什麼事？ | 輪播 |
| 04 | `prompt_04.wav` | 媽，你還好嗎？ | 輪播 |
| 05 | `prompt_05.wav` | 嗯？怎麼啦？ | 輪播 |
| 06 | `prompt_06.wav` | 媽，發生什麼事？ | 輪播 |
| 07 | `prompt_07.wav` | 啊，怎麼了？ | 輪播 |
| 08 | `prompt_08.wav` | 我聽你說。 | 輪播 |
| 09 | `prompt_09.wav` | 嗯嗯。 | 輪播（短應聲） |
| 10 | `prompt_10.wav` | 好。 | 輪播（短應聲） |
| 11 | `prompt_11.wav` | 媽，我先去忙喔，等等再打給你。 | **結束語**（固定） |
| 12 | `prompt_12.wav` | 媽，吃飯了沒？ | 偶爾插入轉移話題 |

**輪播策略**：
- 第一句固定播 `prompt_01`（開場感）
- 之後從 02-10, 12 隨機抽（不重複連續同一句）
- 累計通話時間 ≥ 80 秒 時，下一句切換為 `prompt_11`（結束語）然後掛斷

**音檔格式**：建議 16kHz mono PCM WAV，Twilio 會自動轉碼成 8kHz mu-law 給電話線路。

---

## 7. iDempiere 整合

### 7.1 寫入位置
`Z_momSystem.Description` 欄位（既有 OCR 也用此欄位累積特殊事件，格式為 `[YYYY-MM-DD|HH:MM]事件內容`）。

### 7.2 寫入格式
```
[2026-05-05|15:03] 陪聊 87s
[2026-05-05|15:03] 陪聊未接              ← 媽媽沒接（busy/no-answer）
[2026-05-05|15:03] 陪聊失敗(twilio 5xx)   ← 系統錯誤
```

### 7.3 同日 upsert 行為
- 既有 OCR 已處理同日 upsert（GET 看有沒有 → PATCH/POST）
- companion-call 共用 `shared.py` 的 helper
- 同一天多通通話（按 schedule 一天最多 5 通）會 append 到同一筆 Description（中間用 `\n` 分隔）

### 7.4 共用 iDempiere 認證
抽 `shared.py`：
- `get_idempiere_token()` — login + cache token
- `upsert_zmomsystem_description(date, line)` — append 到當天 Description
- 既有 `ocr_pipeline.py` 重構時可選擇遷移到 `shared.py`，但**本 spec scope 不含 OCR 重構**

---

## 8. 錯誤處理

| 情境 | 行為 | 紀錄 |
|---|---|---|
| 媽媽不接（no-answer ≥ 30s） | **不另外 retry**（因為下個 slot 30 分鐘後就到，重複 retry 會跟下個 slot 撞） | `陪聊未接` |
| 媽媽接了立刻掛 | 通話 < 5s 視為意外掛斷，不 retry | `陪聊 3s(短)` |
| 通話中她拍掛斷 | 不 retry，照樣寫紀錄 | `陪聊 23s` |
| Twilio API 錯誤 | log 錯誤碼，不 retry，等下個 schedule slot | `陪聊失敗(twilio_xxx)` |
| mini PC 沒網路 | systemd service 偵測到 → 寫 local log + 寄 email 給 Tom | 無 iDempiere 紀錄 |
| iDempiere 寫入失敗 | log 到 `companion_call/failed_writes.log`，下次成功時補寫 | local file |
| poll Twilio 超時 | scheduled_call wait 150s 還沒終態 → 記 `陪聊失敗(timeout)` | iDempiere |
| 媽媽嘗試回撥 Twilio 號碼 | TwiML 回「我有事忙先這樣」直接掛斷（避免 inbound 留言費） | inbound log |

**重要**：因為 schedule slot 已經密（半小時一次），**不做 retry**。沒接就放下，下個 slot 再來。失智長者不該被「同一通沒接連環打 3 次」轟炸。

> **註**：原本 `schedule.yaml` 的 `retry_after_no_answer: true` 預設改為 `false`，留著欄位給未來如果 schedule 變稀疏（例如改成一天 3 通）時可重新啟用。

---

## 9. 測試計畫

### Phase 1: 開發測試（Tom 自己手機當「假媽媽」，1 週）

目標：驗證 pipeline 各環節

| 測項 | 驗證方式 | 通過標準 |
|---|---|---|
| Twilio outbound 撥得通 | 手動跑 `python scheduled_call.py` | 5 秒內手機響 |
| TwiML 流程播放 | 接通後聽 | 12 句都能聽到 |
| VAD 觸發輪播 | 接通後講話、停頓 | 停頓 1-2 秒後跳下一句 |
| 通話時長控制 | 不主動掛斷 | ≤ 100 秒被系統掛 |
| Z_momSystem 寫入 | 通話結束查 iDempiere REST | Description 有正確紀錄 |
| Schedule 觸發 | 把 schedule.yaml 改成「現在後 2 分鐘」測試 slot | systemd service 在指定分鐘觸發 |
| 改 schedule 即時生效 | 改 yaml 後 1 分鐘內看下一個 slot 行為 | 新規則已生效不用 restart |
| 不接掉電話 | 不接電話 ≥ 30 秒 | 系統 log `陪聊未接`，不 retry，等下個 slot |

### Phase 2: 受控正式測試（媽媽端，≥ 2 週，涵蓋週二/四/日）

**設計原則：觀察行為，不錄內容**。Tom 想知道的是媽媽**怎麼用**這個系統，不是她講了什麼（內容他自己撥電話就知道）。

觀察項（全部從 iDempiere `Z_momSystem.Description` 紀錄推算，不需要錄音）：

| 行為指標 | 計算方式 | 趨勢意義 |
|---|---|---|
| 接聽率 | 接通通數 ÷ 撥出通數 | 突降 → 失智惡化 / 體力下降 |
| 平均通話長度 | sum(接通秒數) ÷ 接通通數 | 變短 → 注意力下降 / 倦怠 |
| 接聽時段分布 | 09 / 10 / 11 / 15 / 16 各時段接聽率 | 早晨弱 → sundown 提前 / 起床時段偏移 |
| 「立刻掛斷」比例 | 通話 < 5s 的比例 | 高 → 受到驚嚇 / 不適應該排程 |

**Tom 物理在場前 1-2 通**：純粹確認系統正常運作（媽媽真的接得到、TwiML 流程順、不會卡住）。之後讓系統自己跑，不在現場觀察情緒——避免 Tom 的存在改變媽媽行為。

**調整觸發**：跑 2 週後若某時段接聽率 < 30%，從 schedule 拿掉那個時段。

### Phase 3: 全自動運行

- systemd service 常駐，按 `schedule.yaml` 自動執行（30 通/週）
- Tom 每週看一次 iDempiere `Z_momSystem` 統計：接聽率、平均通話長度
- **趨勢監測**：接聽率突降 → 失智狀況可能惡化 → 帶到回診討論
- 如需臨時跳過（媽媽住院、出國）→ 編輯 `schedule.yaml` 的 `exceptions`

---

## 10. 月成本估算

**前提**：每週 15 通（週二/四/日 各 5 通）= 月 ~60 通，每通 90 秒 = 月 ~90 分鐘。

| 項目 | 月費 (USD) | 月費 (TWD) |
|---|---|---|
| Twilio 美國號碼（不顯示來電的桌上電話無 caller ID 顧慮） | $1.15 | ~$36 |
| Twilio 撥 TW 行動 ($0.05/min × 90 min) | $4.50 | ~$140 |
| 媽媽 4G SIM 預付（只接不打方案） | — | ~$30-100 |
| **總計** | **~$5.7** | **~$210-280** |

一次性硬體：4G 桌上型市話（**不顯示來電款式**）~NT$2,000。

**月費敏感度**：
- 通話實際 90 秒平均（spec 上限），但 VAD 提早收尾常見 → 實際可能 60-80s
- 媽媽不接的通數會減少實際 talk minutes（但維持每分鐘 ~$0.05 的封頂預算才安全）
- **不開 call recording**：節省 ~USD$0.45/月 + 隱私上更乾淨

---

## 11. 採購清單（Tom 動手前）

### 硬體
- [ ] **4G 桌上型無線電話** × 1（中華電信、台灣大、遠傳實體門市試手感）
- [ ] **4G 預付 SIM 卡** × 1（只接不打的 30 元方案）

### 雲端帳號
- [ ] Twilio 帳號註冊（信用卡 verify，送 USD$15 試用金）
- [ ] Twilio 美國號碼購買 ($1.15/月)
- [ ] cloudflared tunnel 設定（如已有可重用）

### 錄音
- [ ] 安靜環境錄 12 句 wav（手機 + Voice Memos / Audacity 都可）

### mini PC 端
- 由我寫，Tom 不用準備

---

## 12. 待 Tom 決定（writing-plans 前）

全部已決定 ✅（2026-05-05 確認）：

- [x] **媽媽號碼**：Phase 1 用 Tom 自己手機測試。**號碼絕對不進 git**（透過 `companion_call/.env` + `.gitignore`，見 §15）。Phase 2 切換時 Tom 把假媽媽號碼填進 `.env`
- [x] **時段**：週二/四/日 09:00 / 10:00 / 11:00 / 15:00 / 16:00 共 5 通/天（1 小時間隔）
- [x] **時段 reason**：週二/四/日 = 媽媽獨自在家的日子（一三五日照、週六兒子陪）。Phase 2 觀察聚焦「她獨處時的接聽行為趨勢」
- [x] **間隔密度**：1 小時間隔（5 通/天）
- [x] **Caller ID**：用 Twilio 美國號碼。媽媽端用「**不顯示來電**」的大按鍵 4G 桌上電話 → 美國號根本不會顯示給她看
- [x] **通話錄音**：**不開**。Tom 要的是行為趨勢（接聽率/通話長度），不是內容。內容由 Tom 親自打電話了解
- [x] **第一週測試手機**：Tom 自己手機。前提是 Phase 1 跑通且**手機號碼確認不在 git**

---

## 13. 開發里程碑（writing-plans 才細拆）

1. M1：Twilio + cloudflared tunnel 通了，Tom 自己手機可手動觸發接到
2. M2：12 句 wav 錄好、TwiML 流程能輪播、VAD 觸發正常
3. M3：寫 Z_momSystem 共用 module + 通話紀錄正確寫入
4. M4：companion_scheduler.py 寫好、schedule.yaml 動態 reload、systemd service 安裝
5. M5：Phase 1 測試 1 週（Tom 自己手機，按完整 30 通/週 schedule 跑）
6. M6：切換到媽媽號碼，Phase 2 受控觀察 ≥ 2 週（涵蓋週二/四/日）
7. M7：交付給「全自動」狀態，月底回診帶數據

---

## 14. 設計原則（與既有 OCR 一致）

繼承 `tapo-caregiver` / `whiteboard-ocr-bot` 的鐵律：

- **零人工依賴**：管線不能有「Tom 每天要做 X」這一步
- **寧缺勿錯**：通話失敗就標 fail，不要假裝有打
- **共用資料閉環**：`Z_momSystem` 是唯一真相來源，月底回診帶這個跟醫生討論
- **不錄音**：照護觀察行為趨勢即可（接聽率、通話長度、時段分布）。內容由 Tom 親自撥電話了解，不留錄音 → 隱私乾淨、儲存費省、不需要簽 HIPAA-ish 同意書

---

## 15. Secrets 不進 git（強制）

### 15.1 鐵律
任何**真實電話號碼**（媽媽號碼、Tom 測試號碼、Twilio token、cloudflared tunnel URL 帶 token 的版本）**絕對不進 git**。

### 15.2 實作
- 所有 secrets 放 `companion_call/.env`（python-dotenv 讀）
- `whiteboard-ocr-bot/.gitignore` 已加：
  ```
  companion_call/.env
  companion_call/*.env
  companion_call/audio/*.wav
  companion_call/audio/*.mp3
  companion_call/failed_writes.log
  ```
- Spec 文件、`.env.example`、README 只放 placeholder（`+886-XXX-XXX-XXX`、`AC_xxx`），不放真值
- `audio/*.wav` 也不進 git：Tom 個人錄音雖非 PII，但 public repo 不該有

### 15.3 Phase 1 → Phase 2 切換 SOP
1. Phase 1: `.env` 裡 `MOM_PHONE_NUMBER` 填 Tom 自己手機
2. Pre-Phase 2: Tom 跑 `git status` 確認 `.env` 沒在 modified files 裡
3. Phase 2: Tom 把 `.env` 裡 `MOM_PHONE_NUMBER` 改成假媽媽號碼，仍不 commit
4. 任何時候 Tom 跑 `git diff` 看不到電話號碼

### 15.4 防呆
- pre-commit hook（可選）：grep 任何 staged file 是否有 `09\d{8}` 或 `\+886` pattern → 拒絕 commit
- README 醒目寫：**修改 `.env` 後不要 `git add .` 全部 stage，要逐檔 stage**

---

## 附錄 A：與既有 OCR 共存清單

| 既有元素 | 衝突? | 處理 |
|---|---|---|
| `telegram_bot.py` 運行 | 否 | OCR 是 Telegram 觸發 + 自家排程；companion-call 是 systemd 自家 schedule，兩者獨立 process |
| Gemini API quota | 否 | companion-call 不用 Gemini |
| iDempiere REST token | 否 | 共用 cache，shared.py 統一 |
| `Z_momSystem` 同日 upsert | 否 | 寫不同欄位，merge 不衝突 |
| Python venv 套件 | 否 | pip resolver 獨立解析 |
| `config.py` 變數 | 否 | append 不刪改 |

## 附錄 B：未來擴充點（不在本 spec scope）

- 媽媽主動撥出（off-hook 觸發）→ 需改 Twilio inbound 設定
- 升級到 Gemini Live（如媽媽狀況改善）→ 替換 TwiML 後端
- 與既有 OCR 結果連動（早上 OCR 偵測到「夜間活動 = 抗拒」→ 下午陪聊增加 1 通）
- 多人使用（朋友藥師也想用 / 社區照護）→ 違反 monorepo 規則 5「不主動推工具」

---

**End of spec.**
