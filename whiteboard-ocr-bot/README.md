# Caregiver Whiteboard OCR Bot

A Telegram bot that turns a daily caregiver handoff whiteboard into structured records in **iDempiere**, using **Gemini 3 Flash Preview** for OCR. Designed for families managing long-term home care (in my case, dementia care) who want a zero-friction way to capture daily caregiver reports for monthly medical review.

## What it does

1. You photograph a wall-mounted whiteboard every evening (the one your caregivers use for shift handoff)
2. You share the photo with a private Telegram bot
3. The bot runs Gemini 3 Flash Preview OCR, maps magnet positions on the whiteboard to structured enum values, and writes a record into the iDempiere `Z_momSystem` table (one row per day)
4. The original photo is attached to the record as an audit trail
5. LINE caregiver text reports can also be forwarded to the bot — they get appended to the record's `Description` field with a `[SHIFT|HH:MM]` prefix (DAY/NIGHT/GRAVEYARD based on time)
6. At the end of the month, you open iDempiere and show the doctor the trend

## Why?

Caring for a parent with dementia requires tracking dozens of small daily observations — sleep quality, appetite, behavior, excretion, bathing, etc. These observations are usually written on a whiteboard by the caregiver for shift handoff, but getting them into a longitudinal record for medical review is painful:

- Manual data entry every day is unrealistic
- OCR on photos is unreliable for tiny handwritten Chinese labels
- Asking family members to do it consistently fails
- But the data matters — it guides medication adjustments and care decisions

This project is a **human-in-the-loop** design: the bot handles the tedious parts (OCR, data entry, file storage, shift-tagging), and the human does what only a human can do (verify by eye, correct OCR errors in iDempiere, spot concerning patterns).

The key design decision is that **the photographer is the verifier**. When you take the photo, you already know what the whiteboard says. The bot just saves you 5 minutes of manual data entry per day.

## Architecture

```
 ┌──────────────┐       ┌─────────────────┐
 │  Phone       │──────▶│ Telegram bot    │
 │  (you)       │ photo │  long polling   │
 └──────────────┘       └────────┬────────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ Gemini 3 Flash │
                        │ schema-const.  │
                        │ OCR (box idx)  │
                        └────────┬───────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ whiteboard →   │
                        │ iDempiere enum │
                        │ mapping        │
                        └────────┬───────┘
                                 │
                                 ▼
                        ┌────────────────┐        ┌────────────────┐
                        │ iDempiere REST │◀──────▶│ Z_momSystem    │
                        │ find-or-create │        │ (+ attachment) │
                        └────────────────┘        └────────────────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ Reply to user  │
                        │ with parsed    │
                        │ record summary │
                        └────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `telegram_bot.py` | Long-polling Telegram bot, routes photo/text messages |
| `ocr_pipeline.py` | Core logic: Gemini OCR → mapping → iDempiere REST write |
| `whiteboard_layout.py` | Authoritative whiteboard layout + iDempiere enum mapping (customize for your own whiteboard) |
| `ptz_test.py` | Optional helper for TAPO C200 PTZ control via ONVIF (we ended up not needing this path) |
| `config.py.example` | Template config file — copy to `config.py` and fill in real values |

## Installation

```bash
git clone https://github.com/<your>/caregiver-whiteboard-ocr-bot.git
cd caregiver-whiteboard-ocr-bot

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp config.py.example config.py
# Edit config.py with your real values (see below)

# Create your whiteboard_layout.py — adjust WHITEBOARD_LAYOUT and WB_TO_IDEMPIERE for your DB

# Test the OCR pipeline (dry-run — won't write to iDempiere)
DRY_RUN=1 python ocr_pipeline.py path/to/sample_whiteboard.jpg

# Run the bot
python telegram_bot.py
```

## Required setup

### 1. Gemini API key
- Get a free key from <https://aistudio.google.com/apikey>
- `gemini-3-flash-preview` free tier is **20 requests/day**, which is enough for ~1 daily photo + a couple of retries
- If you need more, upgrade to paid tier — ~USD $0.01/month for this usage

### 2. Telegram bot
- Open Telegram, search `@BotFather`
- Send `/newbot`, pick a name and username
- Save the bot token into `config.py`
- Get your own Telegram user ID via `@userinfobot` and add it to `ALLOWED_USER_IDS`

### 3. iDempiere
- You need an iDempiere instance with a custom table for the daily records (in this project, `Z_momSystem`)
- The table should have list-type columns for each tracked item (night activity, sleep, meals, activity, outgoing, excretion, bathing, etc.)
- The REST API plugin must be enabled (`com.trekglobal.idempiere.rest.api`)
- Create an API user and note the role/client IDs

### 4. Whiteboard layout
- Edit `whiteboard_layout.py` to match your physical whiteboard
- Each item key maps to an iDempiere column name
- `WHITEBOARD_LAYOUT` is the left-to-right order of option boxes on your whiteboard
- `WB_TO_IDEMPIERE` maps each whiteboard label to the iDempiere `AD_Ref_List.Value` code
- If your caregivers use different wording than your iDempiere enum, you can map them here (e.g. "情緒不安" → "坐立不安")

### 5. Systemd service (optional, Linux only)

Create `/etc/systemd/system/caregiver-bot.service`:

```ini
[Unit]
Description=Caregiver Whiteboard OCR Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=YOUR_USER
WorkingDirectory=/path/to/caregiver-whiteboard-ocr-bot
ExecStart=/path/to/caregiver-whiteboard-ocr-bot/venv/bin/python telegram_bot.py
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now caregiver-bot
```

## Design principles

### 1. Zero human dependency beyond yourself
The project started with "automate RTSP camera to eliminate the need for anyone to take photos." That failed because of physics (magnets only ~3-5 pixels on RTSP). But the deeper lesson: **don't confuse "no humans" with "only me"**. Asking yourself to do something simple every day is reliable. Asking others is not.

### 2. Human-as-verifier, not human-out-of-loop
OCR has errors. For medical data, **wrong > missing**. The system accepts that errors will happen and puts the human in the verification loop — you visit iDempiere at the end of each day (or before monthly review) and correct any OCR mistakes. The bot's job is to reduce your typing by 95%, not replace you.

### 3. Schema-constrained prompting
Instead of free-form OCR, the prompt gives Gemini the exact option layout and asks it to identify only **which box position** a magnet is in (1/2/3/4 or null). Character recognition is done via lookup table in Python, not by the model. This dodges the hardest part of Chinese handwriting OCR.

### 4. Prefer null over wrong
The system only writes fields with `confidence: high`. Anything uncertain becomes null and you see a "skipped" count in the Telegram reply. Missing values are visible; they don't corrupt the longitudinal trend analysis.

### 5. Find-or-create, not create-always
Same-day photos update the existing record instead of creating new ones. Only non-null OCR outputs override existing values (so morning photo filling the top half, evening photo filling the bottom half, both contribute to one clean daily row).

## What did NOT work (and why)

- **Real-ESRGAN / Lanczos upscaling**: geometric interpolation doesn't add information. A 3-pixel magnet upscaled to 12 pixels is still a blur, not a magnet.
- **Consensus voting across runs**: the models tested (Gemma 4, Gemini 2.5 Flash) have **systematic biases** (they default to "box 1" when uncertain), so running 3 times and taking majority just cements the bias.
- **TAPO C200 PTZ**: ONVIF pan/tilt works via port 2020 with the same RTSP credentials. But the C200 doesn't expose zoom via ONVIF. Without zoom, you can't make the whiteboard bigger in the frame, so the root problem (low pixel density) remains.
- **Gemma 4 / Gemini 2.5 Flash for this task**: these models fake answers (pick a default box) instead of saying "I can't tell." Only Gemini 3 Flash Preview honestly returns null when uncertain, which is the correct behavior for medical data.

## License

MIT — use, modify, share freely. If you improve the prompt or the layout mapping, a PR is welcome.

## Acknowledgements

Built as a practical Vibe Coding experiment — the full design process (failures, pivots, model comparisons, and final architecture) is documented in a companion blog post in Traditional Chinese.

The project is dedicated to caregivers and family members navigating the daily logistics of long-term dementia care. None of this is glamorous, but every saved minute of manual data entry is a minute closer to humane care.
