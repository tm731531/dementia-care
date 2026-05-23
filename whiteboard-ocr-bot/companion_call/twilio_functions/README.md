# Twilio Functions — TwiML logic for companion-call

跑在 Twilio cloud 上的 serverless functions。取代原本 mini PC FastAPI server + cloudflared tunnel 架構。

## 部署一次（Tom 在 mini PC 跑）

```bash
# 1) 裝 twilio CLI 跟 serverless plugin
npm i -g twilio-cli                                   # 需要 Node 18+
twilio plugins:install @twilio-labs/plugin-serverless

# 2) 登入 (瀏覽器，一次)
twilio login

# 3) 把 12 段 wav 拷貝到 assets/
cp ../audio/prompt_*.wav assets/

# 4) 部署
cd <whiteboard-ocr-bot>/companion_call/twilio_functions
twilio serverless:deploy --runtime node18

# 5) 看部署輸出，記下 URL，例如：
#    https://companion-call-1234-dev.twil.io
#    把這個值填進 ../.env 的 TWILIO_FUNCTIONS_BASE_URL
```

## Endpoints

| Path | When | Returns |
|---|---|---|
| `/voice` | Mom 接起電話時，Twilio 叫這個拿 TwiML | `<Play prompt_01><Pause><Redirect /next>` |
| `/next` | 媽媽講完話 (VAD 觸發) | 隨機 rotation 句 OR 結束句 + Hangup |
| `/inbound` | Mom 反向回撥時 | 客氣掛斷 |

State (start time, recent picks) 透過 URL query params 在 redirect 之間傳遞 — Functions 是 stateless 的，不能用 module-level dict。

## 修改後重新部署

```bash
twilio serverless:deploy --runtime node18
```

---

## 為什麼用 Functions 不是自架 server

| | Functions | 自架 (FastAPI + cloudflared) |
|---|---|---|
| 對外 URL | 內建 (twil.io) | 需 cloudflared tunnel |
| Hosting cost | 免費 10K 次/月 | 自己 mini PC |
| 部署 | `twilio serverless:deploy` | systemd × 3 + sudo |
| Audio 管理 | Twilio Assets (上傳) | StaticFiles mount |

每月通話量 ~60 通 × 5 endpoint hits = 300 次，遠低於 free tier 10000。
