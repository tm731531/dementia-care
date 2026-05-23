# companion_call — 失智母親排程陪聊外撥

擴充於 `whiteboard-ocr-bot/`。共用 Python venv 跟 iDempiere REST，**不動既有 OCR pipeline**。

## 架構

```
[mini PC: systemd service: companion_scheduler.py]
        ↓ (每分鐘讀 schedule.yaml)
[hit slot → scheduled_call.run_one_call()]
        ↓ Twilio API
[Twilio Programmable Voice]
        ↓ 撥媽媽電話
   📞 媽媽接起
        ↓ 讀 TwiML
[Twilio Functions (cloud)]      ← 12 wav 在 Twilio Assets
   /voice → /next → ... → /next → 結束句 + Hangup
        ↓
[scheduled_call.py poll Twilio API for status]
        ↓
[寫 iDempiere Z_momSystem.Description]
```

**無 cloudflared / 無 FastAPI / 無對外 endpoint。** Mini PC 只跑一個 daemon。

## 一次性 setup（Tom 親自做，~10 分鐘）

```bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot

# 1) 裝 twilio CLI
npm i -g twilio-cli                                        # 需要 Node 18+
twilio plugins:install @twilio-labs/plugin-serverless

# 2) 登入 Twilio 一次（瀏覽器）
twilio login

# 3) 填 .env
cp companion_call/.env.example companion_call/.env
nano companion_call/.env       # 不透過 chat 給任何人

# 4) 部署 Functions + Assets 到 Twilio
bash companion_call/deploy_functions.sh

# 5) 把第 4 步輸出的 URL 填進 .env 的 TWILIO_FUNCTIONS_BASE_URL，再 nano 一次

# 6) 自驗一通
source venv/bin/activate
python -m companion_call.scheduled_call
# 5 秒內你手機應該響
```

## 跑通後安裝 systemd（讓 schedule.yaml 自動執行）

```bash
bash companion_call/install_systemd.sh
```

之後管理：

```bash
systemctl status companion-call          # 看狀態
journalctl -u companion-call -f          # tail logs
sudo systemctl restart companion-call    # 重啟
```

## 改排程

編輯 `schedule.yaml`，systemd daemon 每分鐘自動 reload，**不用 restart**：

```yaml
weekly:
  tuesday:
    - "09:00"
    - "10:00"
  thursday: ["15:00"]
  monday: []
  ...

exceptions:
  "2026-05-12":
    skip: true       # 整天不打 (媽媽住院)
```

## 測試 (不打真電話)

```bash
source venv/bin/activate
pytest companion_call/tests/ -v
# 27 tests, ~2s
```

## Secrets 鐵律

- **絕不 hardcode** 電話號碼 / Twilio token 進任何 .py / .yaml / commit
- 所有真值放 `.env` (gitignored)
- 改 `.env` 後永遠不 `git add .`，只逐檔 stage
- 詳見 spec §15

## 修改 TwiML 邏輯

JavaScript Functions 在 `twilio_functions/functions/`：
- `voice.js` — 開場句
- `next.js` — 輪播 + 結束邏輯
- `inbound.js` — 反向回撥處理

改完重新部署：

```bash
bash companion_call/deploy_functions.sh
```
