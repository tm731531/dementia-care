# 白板 OCR 紀錄 Bot — 長照自動化工具

> 一位很 I 的軟體工程師，不想每天花 5 分鐘手打白板紀錄到 iDempiere，所以做了這個 Telegram bot。
> 拍張照傳出去，剩下的交給它。人只負責驗證。

Python 專案、人在迴圈（human-in-the-loop）、免費 Gemini API、寧缺勿錯。

---

## 這個工具做什麼

每天晚上 8 點，你拍一張照護員交班白板的照片，傳給 Telegram bot。Bot 會：

1. 用 **Gemini 3 Flash Preview** 視覺辨識 12 個追蹤項目（夜間活動、睡眠、三餐、活動、外出、陪伴、排泄、洗澡…）
2. 把磁鐵壓在哪一格轉成選項代碼
3. 寫入 iDempiere 自訂表 `Z_momSystem`，一天一筆
4. 把原始照片當附件存進同一筆紀錄
5. 居服員在 LINE 的白天即時回報，也可以直接轉傳給 bot，會自動加時間戳（早/晚/大夜班）貼到備註欄

月底回診時，你在 iDempiere 打開那張表，直接給醫生看一整個月的趨勢。

> **💡 配合 [就診小幫手](../mom-clinic-companion/) 更完整**：這個 bot 把資料寫進 iDempiere，「就診小幫手」就從 iDempiere 讀出來做歸納分析（趨勢異常、症狀關鍵字、跨欄位組合），回診前打開手機就是今天要問醫生的 3 件事。兩個工具一起用才是完整的失智照護資料閉環。

---

## 先試玩不安裝

直接用瀏覽器打開 `index.html`，就是一個純前端 demo：

- 模擬 Telegram bot 對話介面
- 按「📸 拍照」可開啟手機相機拍張白板
- 模擬 OCR 過程（真實版本會呼叫 Gemini API）
- 顯示一筆「模擬寫入」的紀錄

適合給想先看看體驗再決定要不要部署的人。不需要安裝任何東西、不需要網路、不傳任何資料出去。

---

## 為什麼做這個

照顧失智家人是一場資料追蹤戰。睡眠品質、食慾、躁動、情緒、排便，每天都有十幾個小觀察。這些資料對醫生調藥**很關鍵**，但平常很難收集：

- 每天手工打字到病歷系統 → 不切實際
- 拜託家人幫忙 → 靠別人的流程遲早斷掉
- 純 OCR 手寫中文白板 → 準度很難做到完美
- 完全放棄數位化 → 回診只剩口述記憶，失去趨勢資訊

這個工具選擇了一個折衷：**把最吃力的「打字、歸檔、附照片」交給 bot，最重要的「驗證對錯」留給你自己**。你本來拍照的那一瞬間就已經看過白板內容了，所以你就是最終的驗證人。Bot 只是幫你省 5 分鐘工時。

---

## 核心設計理念

### 1. Human-as-verifier，不是 human-out-of-loop
醫療資料裡，**錯的資料比缺的資料更危險**（會誤導醫生調藥）。所以 bot 只寫入「高信心」的欄位，其餘欄位保留空白，由你每晚回 iDempiere 補。寧缺勿錯。

### 2. Schema-constrained prompting
Prompt 直接告訴 Gemini「每個項目的選項方格順序是什麼」，模型只需要回答「磁鐵在第幾格」（1/2/3/4 或 null），不需要做手寫中文字元辨識。這是我們跟低解析度打交道的關鍵。

### 3. Find-or-Create
同一天多次拍照會更新同一筆紀錄（而不是建新的）。早上拍一次補前 6 項、晚上拍一次補後 6 項、都貢獻到同一列乾淨的日紀錄。

### 4. 零人工依賴（除了你自己）
不依賴妹妹幫忙拍、不依賴居服員用 App、不依賴雲端同步。只依賴「你每天拿手機拍一張」這一個動作。

---

## 快速開始（實際部署）

### 你需要

- **Python 3.10+**
- **Gemini API key**（免費版 20 次/天就夠用，取得：<https://aistudio.google.com/apikey>）
- **Telegram bot token**（透過 `@BotFather` 建立）
- **iDempiere 實例**（有 REST API plugin + 一張自訂的每日紀錄表）
- **一塊實體白板 + 一組彩色磁鐵**（物理存在，居服員每天填）

### 安裝

```bash
cd whiteboard-ocr-bot
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 複製範本並填入自己的值
cp config.py.example config.py
vim config.py

# 白名單：寫入你自己的 Telegram user ID（用 @userinfobot 查）
echo "YOUR_TELEGRAM_USER_ID" > allowed_users.txt

# 啟動 bot（長輪詢模式，Ctrl-C 停止）
python telegram_bot.py
```

### 讓 bot 開機自動啟動（Linux systemd）

```ini
[Unit]
Description=Whiteboard OCR Bot
After=network-online.target

[Service]
Type=simple
User=YOUR_USER
WorkingDirectory=/path/to/whiteboard-ocr-bot
ExecStart=/path/to/whiteboard-ocr-bot/venv/bin/python telegram_bot.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now whiteboard-bot
```

---

## 白板 Layout 客製化

`whiteboard_layout.py` 裡面有兩個字典：

- `WHITEBOARD_LAYOUT`：每個追蹤項目的選項方格順序（由左到右）
- `WB_TO_IDEMPIERE`：每個白板標籤對應的 iDempiere `AD_Ref_List.Value` 代碼

你家的白板可能跟我的不一樣 —— 項目可能少幾項、選項文字可能不同（例如「煩躁」vs「躁動」）。直接改這兩個字典就好。

如果居服員習慣用跟 DB 不一樣的詞（我就遇到過「情緒不安」被用來代替 DB 的「坐立不安」），可以在 `WB_TO_IDEMPIERE` 做語意映射，無需改白板也無需改 DB。

---

## 檔案結構

| 檔案 | 說明 |
|------|------|
| `index.html` | 純前端 demo，單檔打開就能試玩 bot 對話流程（無需 Python、無需 iDempiere） |
| `telegram_bot.py` | Telegram long-polling bot，處理照片 + 文字訊息 |
| `ocr_pipeline.py` | OCR 流程：Gemini 呼叫 → 白板映射 → iDempiere REST 寫入 → 附件上傳 |
| `whiteboard_layout.py` | 白板 layout 跟 enum 映射的權威版本 |
| `ptz_test.py` | （可選）TAPO C200 ONVIF PTZ 控制工具 |
| `config.py.example` | 設定檔範本 |
| `requirements.txt` | Python 依賴 |

---

## 成本

**每天用量**：
- 晚上 8 點拍一次照片 = 1 次 Gemini API 呼叫
- 白天 LINE 文字回報 = 0 次（不用 vision，只是 prepend 到備註欄）
- 合計：**1~2 次/天**

**Gemini 3 Flash Preview 免費 tier 每天 20 次**，完全夠用。

Debug 期間可能會爆免費額度，建議開發階段暫時升級付費（一個月 < USD $0.10），上線後再取消。

---

## 已知限制

1. **手寫中文字元 OCR 仍然容易出錯**。這就是為什麼我們用 box-index 策略（只判斷磁鐵在第幾格）+ 查表對應到中文，繞過字元辨識。
2. **低解析度（< 1 MP）下準度會降**。手機近拍是最好的輸入來源；RTSP 攝影機遠距離視角下，Gemini 會誠實回 null 而不是硬填。
3. **只支援 iDempiere REST API**。理論上可以改成寫入其他資料庫，但需要改 `ocr_pipeline.py` 的寫入函式。

---

## 作者

**Tom Ting** — 一位為了照顧失智家人而寫 bot 的後端工程師 [blog.tomting.com](https://blog.tomting.com/)

完整的開發歷程（從 RTSP 撞牆、ONVIF PTZ、模型賽馬、到 Telegram bot 上線的 36 小時實戰）記錄在部落格的配套文章。

---

## 相關閱讀（失智照顧系列）

- [失智家人確診後的第一週，先做這 5 件事](https://blog.tomting.com/2026/04/23/dementia-first-week-5-things/) — 法律 / 醫療 / 防走失 完整清單
- [失智照顧半年的三個誤會](https://blog.tomting.com/2026/04/22/dementia-care-three-misunderstandings/)
- [失智長輩為什麼一直到處走](https://blog.tomting.com/2026/04/22/dementia-mother-finding-home/)

---

## 授權

MIT — 自由使用、修改、分享。如果你改善了 prompt 或 layout，歡迎發 PR。
