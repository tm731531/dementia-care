# companion_call — 失智母親排程陪聊外撥

擴充於 `whiteboard-ocr-bot/`。共用 Python venv 跟 iDempiere 認證，但**不動既有 OCR pipeline**。

## 架構

```
crontab/systemd → companion_scheduler.py (每分鐘讀 schedule.yaml)
              ↓ 命中 slot
            scheduled_call.py
              ↓ Twilio API
            撥打媽媽電話
              ↓ 媽媽接起
            twilio_app.py (FastAPI, 回 TwiML)
              ↓ 12 句 wav 輪播 + VAD + 累計時間
            通話結束 → log_to_idempiere.py → Z_momSystem
```

## 啟動

```bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot
source venv/bin/activate
cp companion_call/.env.example companion_call/.env
nano companion_call/.env       # 自己填值，不要透過 AI chat 貼
```

## 改排程

編輯 `schedule.yaml`，systemd service 每分鐘自動 reload。

```yaml
weekly:
  tuesday:
    - "09:00"
    - "10:00"
  thursday: ["15:00"]
  monday: []
  ...
```

## 測試（不打真電話）

```bash
pytest companion_call/tests/ -v
```

## 手動觸發一通（Phase 1 自驗用）

```bash
python -m companion_call.scheduled_call
```

## 看 service log

```bash
journalctl -u companion-call -f                    # FastAPI server
journalctl -u companion-call-scheduler -f          # scheduler daemon
journalctl -u companion-call-tunnel -f             # cloudflared
```

## 維運

- 暫停服務：`sudo systemctl stop companion-call-scheduler`
- 啟動服務：`sudo systemctl start companion-call-scheduler`
- 查狀態：`systemctl status companion-call companion-call-scheduler companion-call-tunnel`

## Secrets 鐵律

- **絕不 hardcode** 電話號碼、Twilio token 進任何 .py / .yaml / commit
- 所有真值放 `.env`（gitignored）
- 改 `.env` 後永遠不 `git add .`，只逐檔 stage
- 詳見 spec §15
