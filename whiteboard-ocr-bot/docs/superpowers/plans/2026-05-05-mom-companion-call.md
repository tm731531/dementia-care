# Mom Companion Call Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 實作 spec `2026-05-05-mom-companion-call-design.md` 定義的失智母親排程陪聊外撥系統。

**Architecture:** Twilio Programmable Voice 撥出 + FastAPI 回 TwiML 指令 + systemd 常駐 scheduler 讀 `schedule.yaml` + 通話結束寫 iDempiere `Z_momSystem.Description`。寄居在既有 `whiteboard-ocr-bot/` Python venv，不動既有 OCR pipeline。

**Tech Stack:** Python 3.x（既有 venv）、twilio SDK、FastAPI、uvicorn、python-dotenv、PyYAML、pytest、ffmpeg、cloudflared、systemd。

---

## Spec Reference

完整需求見 `docs/superpowers/specs/2026-05-05-mom-companion-call-design.md`。本 plan 不重複 spec 內容，只給實作步驟。

## Task Type Legend

- 🔧 **Code task** — 寫 Python，TDD（先 fail test → 實作 → pass → commit）
- 📋 **Setup task** — 系統設定/配置（systemd / cloudflared / .env）
- 👤 **Tom task** — Tom 親自操作（rotate token、錄音 mapping、SIM 號碼）
- ✅ **Verification task** — 手動驗收 + log 確認

---

## Prerequisites (在開始 Task 1 前 Tom 必須完成)

- [x] 4G 桌上電話採購完成
- [x] 12 段錄音檔放在 `/home/tom/Desktop/recordings/voice_472115.aac` ~ `voice_472126.aac`
- [ ] **🔴 CRITICAL: 舊 Twilio API Key（SID 開頭 `SK40af228896...`）在 Twilio Console 已 Delete**
- [ ] **🔴 CRITICAL: 新 Twilio credentials 由 Tom 在 mini PC 親手 `nano .env` 填，從不透過 chat 傳值**
- [ ] 4G SIM 卡號碼（媽媽那台）Tom 知道
- [ ] cloudflared 二進位已裝在 mini PC（`which cloudflared` 應顯示路徑）

## File Structure

新增/修改檔案總覽：

```
whiteboard-ocr-bot/
├── .gitignore                  ← 已修改（companion-call secrets ignored）✓
├── config.py                   ← 不動（companion-call 用獨立 .env）
├── requirements.txt            ← 修改：append twilio/fastapi/uvicorn/python-dotenv/pyyaml
└── companion-call/             ← 全新
    ├── __init__.py             ← 空檔（讓它是 Python package）
    ├── .env.example            ← Tom 複製成 .env 後填值
    ├── README.md               ← 啟動 / 維護指引
    ├── schedule.yaml           ← Tom 可編輯排程
    ├── companion-call.service  ← systemd unit 檔
    ├── shared.py               ← iDempiere REST helper（auth + upsert）
    ├── audio_convert.py        ← ffmpeg wrapper：任意輸入 → 8kHz mu-law wav
    ├── twilio_app.py           ← FastAPI server（4 endpoints）
    ├── scheduled_call.py       ← Twilio outbound caller
    ├── companion_scheduler.py  ← systemd daemon entry
    ├── audio/                  ← 12 句 wav（gitignored）
    │   ├── prompt_01.wav
    │   ├── ... (12 files)
    │   └── README.md           ← 錄音規格說明
    └── tests/
        ├── __init__.py
        ├── conftest.py         ← pytest fixtures
        ├── test_shared.py
        ├── test_audio_convert.py
        ├── test_twilio_app.py
        ├── test_scheduled_call.py
        └── test_scheduler.py
```

---

## Task 1: Scaffold companion-call/ skeleton 🔧

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/__init__.py` (empty)
- Create: `whiteboard-ocr-bot/companion-call/.env.example`
- Create: `whiteboard-ocr-bot/companion-call/README.md`
- Create: `whiteboard-ocr-bot/companion-call/audio/.gitkeep`
- Create: `whiteboard-ocr-bot/companion-call/audio/README.md`
- Create: `whiteboard-ocr-bot/companion-call/tests/__init__.py`
- Create: `whiteboard-ocr-bot/companion-call/tests/conftest.py`
- Modify: `whiteboard-ocr-bot/requirements.txt` (append)

- [ ] **Step 1: Create `companion-call/__init__.py` (empty file)**

```bash
mkdir -p whiteboard-ocr-bot/companion-call/audio whiteboard-ocr-bot/companion-call/tests
touch whiteboard-ocr-bot/companion-call/__init__.py
touch whiteboard-ocr-bot/companion-call/tests/__init__.py
touch whiteboard-ocr-bot/companion-call/audio/.gitkeep
```

- [ ] **Step 2: Create `companion-call/.env.example` with placeholder values**

```bash
# Companion Call configuration — copy this to .env and fill real values
# .env is gitignored, .env.example IS committed (no secrets, only structure)

# ===== Twilio =====
TWILIO_ACCOUNT_SID=AC_replace_with_yours
TWILIO_AUTH_TOKEN=replace_with_yours
TWILIO_FROM_NUMBER=+1XXXXXXXXXX

# ===== 媽媽端電話（Phase 1 = Tom 自己手機，Phase 2 = 媽媽 SIM）=====
MOM_PHONE_NUMBER=+886XXXXXXXXX

# ===== Public webhook URL（cloudflared tunnel 給的）=====
COMPANION_CALL_PUBLIC_URL=https://example.cfargotunnel.com

# ===== iDempiere（共用既有 OCR pipeline 的設定，可從 config.py 撈）=====
IDEMPIERE_BASE_URL=http://192.168.0.93:8080/api/v1
IDEMPIERE_USERNAME=Tom
IDEMPIERE_PASSWORD=replace_with_yours
IDEMPIERE_CLIENT_ID=1000000
IDEMPIERE_ROLE_ID=1000000
IDEMPIERE_ORGANIZATION_ID=0
IDEMPIERE_WAREHOUSE_ID=0

# ===== 全域行為 =====
COMPANION_CALL_DURATION_SEC=90
COMPANION_CALL_END_TRIGGER_SEC=80   # 累計達此秒數切換結束語
LOG_LEVEL=INFO
```

- [ ] **Step 3: Create `companion-call/README.md`**

```markdown
# companion-call — 失智母親排程陪聊外撥

## 啟動

\`\`\`bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot
source venv/bin/activate
cp companion-call/.env.example companion-call/.env
nano companion-call/.env       # 自己填值，不要透過 AI chat 貼
\`\`\`

## 改排程
編輯 `schedule.yaml`，systemd service 每分鐘自動 reload。

## 測試（不打真電話）
\`\`\`bash
pytest companion-call/tests/ -v
\`\`\`

## 手動觸發一通（Phase 1 自驗用）
\`\`\`bash
python -m companion_call.scheduled_call
\`\`\`

## 看 service log
\`\`\`bash
journalctl -u companion-call -f
\`\`\`

## 維運
- 暫停服務：`sudo systemctl stop companion-call`
- 啟動服務：`sudo systemctl start companion-call`
- 查狀態：`systemctl status companion-call`
\`\`\`
```

- [ ] **Step 4: Create `companion-call/audio/README.md`**

```markdown
# Recording specs

- **Format**: any input (m4a/aac/mp3/wav) — `audio_convert.py` 會轉成 8kHz mu-law wav
- **Filename**: `prompt_01.wav` ~ `prompt_12.wav`（轉檔後）
- **Length**: 1-3 seconds per clip
- **Tone**: 自然語氣，不要播報腔
- **Environment**: 安靜、無風扇雜音

## Prompt content（可以自然口氣，不必逐字）

| # | Role | 大致內容 |
|---|---|---|
| 01 | 開場 | 媽，怎麼了？ |
| 02-10, 12 | 輪播 | 各種「怎麼了」「什麼事」「我聽你說」變體 |
| 11 | 結束（特殊位置） | 媽，我先去忙喔，等等再打給你 |

`*.wav` 在 .gitignore，不會推上 GitHub。
```

- [ ] **Step 5: Create `companion-call/tests/conftest.py` with pytest fixtures**

```python
"""Shared pytest fixtures for companion-call tests."""
import os
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parent.parent


@pytest.fixture(autouse=True)
def fake_env(monkeypatch):
    """每個測試自動套假 env vars，避免讀到真值。"""
    monkeypatch.setenv("TWILIO_ACCOUNT_SID", "ACtest_sid")
    monkeypatch.setenv("TWILIO_AUTH_TOKEN", "test_token")
    monkeypatch.setenv("TWILIO_FROM_NUMBER", "+15551234567")
    monkeypatch.setenv("MOM_PHONE_NUMBER", "+886912345678")
    monkeypatch.setenv("COMPANION_CALL_PUBLIC_URL", "https://test.cfargotunnel.com")
    monkeypatch.setenv("IDEMPIERE_BASE_URL", "http://test.example/api/v1")
    monkeypatch.setenv("IDEMPIERE_USERNAME", "test")
    monkeypatch.setenv("IDEMPIERE_PASSWORD", "test")
    monkeypatch.setenv("IDEMPIERE_CLIENT_ID", "1000000")
    monkeypatch.setenv("IDEMPIERE_ROLE_ID", "1000000")
    monkeypatch.setenv("IDEMPIERE_ORGANIZATION_ID", "0")
    monkeypatch.setenv("IDEMPIERE_WAREHOUSE_ID", "0")
    monkeypatch.setenv("COMPANION_CALL_DURATION_SEC", "90")
    monkeypatch.setenv("COMPANION_CALL_END_TRIGGER_SEC", "80")
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")


@pytest.fixture
def base_dir():
    return BASE_DIR
```

- [ ] **Step 6: Append to `whiteboard-ocr-bot/requirements.txt`**

Read existing first to know what's there. Then append:

```
# === companion-call (added 2026-05-05) ===
twilio>=9.0.0
fastapi>=0.110.0
uvicorn[standard]>=0.27.0
python-dotenv>=1.0.0
PyYAML>=6.0
pytest>=8.0
pytest-asyncio>=0.23
httpx>=0.27        # FastAPI test client
freezegun>=1.4     # 測 scheduler 時凍結時間
```

- [ ] **Step 7: Install new deps in venv**

```bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot
source venv/bin/activate
pip install -U -r requirements.txt
```

Expected: 套件安裝成功，既有 OCR 套件不變動（pip 不會降級 google-generativeai）。

- [ ] **Step 8: Verify既有 OCR 還能 import**

```bash
python -c "from ocr_pipeline import *; print('OCR imports OK')"
```

Expected: `OCR imports OK`（既有功能不受影響）。

- [ ] **Step 9: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/__init__.py \
        whiteboard-ocr-bot/companion-call/.env.example \
        whiteboard-ocr-bot/companion-call/README.md \
        whiteboard-ocr-bot/companion-call/audio/.gitkeep \
        whiteboard-ocr-bot/companion-call/audio/README.md \
        whiteboard-ocr-bot/companion-call/tests/__init__.py \
        whiteboard-ocr-bot/companion-call/tests/conftest.py \
        whiteboard-ocr-bot/requirements.txt
git commit -m "feat(companion-call): scaffold subfolder + .env.example + deps"
```

---

## Task 2: Audio conversion utility 🔧 (TDD)

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/audio_convert.py`
- Create: `whiteboard-ocr-bot/companion-call/tests/test_audio_convert.py`

**Purpose:** 把 Tom 手機錄的 .aac 轉成 Twilio 吃的 8kHz mu-law mono wav。

- [ ] **Step 1: Write failing test `test_audio_convert.py`**

```python
"""Test audio conversion: any input → 8kHz mu-law mono wav."""
import subprocess
from pathlib import Path

import pytest

from companion_call.audio_convert import convert_to_twilio_wav


def test_convert_returns_target_path(tmp_path):
    # Create dummy aac via ffmpeg silence
    src = tmp_path / "input.aac"
    subprocess.run([
        "ffmpeg", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-t", "1", "-c:a", "aac", str(src), "-y"
    ], check=True, capture_output=True)
    dst = tmp_path / "output.wav"

    result = convert_to_twilio_wav(src, dst)

    assert result == dst
    assert dst.exists()


def test_convert_output_is_8khz_mulaw(tmp_path):
    src = tmp_path / "input.aac"
    subprocess.run([
        "ffmpeg", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-t", "1", "-c:a", "aac", str(src), "-y"
    ], check=True, capture_output=True)
    dst = tmp_path / "output.wav"

    convert_to_twilio_wav(src, dst)

    # Probe output
    probe = subprocess.run([
        "ffprobe", "-v", "error", "-select_streams", "a:0",
        "-show_entries", "stream=codec_name,sample_rate,channels",
        "-of", "default=noprint_wrappers=1", str(dst)
    ], capture_output=True, text=True, check=True)
    assert "codec_name=pcm_mulaw" in probe.stdout
    assert "sample_rate=8000" in probe.stdout
    assert "channels=1" in probe.stdout


def test_convert_missing_input_raises(tmp_path):
    src = tmp_path / "nonexistent.aac"
    dst = tmp_path / "output.wav"
    with pytest.raises(FileNotFoundError):
        convert_to_twilio_wav(src, dst)
```

- [ ] **Step 2: Run test to verify FAIL**

```bash
cd whiteboard-ocr-bot
pytest companion-call/tests/test_audio_convert.py -v
```

Expected: All 3 tests FAIL with `ModuleNotFoundError: No module named 'companion_call.audio_convert'`.

- [ ] **Step 3: Implement minimal `audio_convert.py`**

```python
"""Convert any audio input to Twilio-compatible 8kHz mu-law mono wav."""
import subprocess
from pathlib import Path


def convert_to_twilio_wav(src: Path, dst: Path) -> Path:
    """ffmpeg wrap: any audio → 8kHz mu-law mono wav (Twilio format).

    Args:
        src: input audio file (m4a/aac/mp3/wav/etc)
        dst: output .wav path

    Returns:
        dst (Path) — confirmed written

    Raises:
        FileNotFoundError if src does not exist
        subprocess.CalledProcessError if ffmpeg fails
    """
    src = Path(src)
    dst = Path(dst)
    if not src.exists():
        raise FileNotFoundError(f"input not found: {src}")

    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "ffmpeg",
        "-i", str(src),
        "-ar", "8000",          # 8 kHz sample rate
        "-ac", "1",             # mono
        "-c:a", "pcm_mulaw",    # mu-law codec
        "-y",                   # overwrite
        str(dst),
    ], check=True, capture_output=True)
    return dst


def batch_convert(src_dir: Path, mapping: dict[str, str], out_dir: Path) -> list[Path]:
    """Convert multiple files via mapping.

    Args:
        src_dir: where source files live
        mapping: {"voice_472115.aac": "prompt_01.wav", ...}
        out_dir: where converted wavs go

    Returns:
        list of output paths
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    outputs = []
    for src_name, dst_name in mapping.items():
        src = src_dir / src_name
        dst = out_dir / dst_name
        convert_to_twilio_wav(src, dst)
        outputs.append(dst)
    return outputs
```

- [ ] **Step 4: Run tests to verify PASS**

```bash
pytest companion-call/tests/test_audio_convert.py -v
```

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/audio_convert.py \
        whiteboard-ocr-bot/companion-call/tests/test_audio_convert.py
git commit -m "feat(companion-call): audio_convert.py — ffmpeg wrap to 8kHz mu-law wav"
```

---

## Task 3: Tom mapping 12 recordings → prompt_NN.wav 👤

**Purpose:** Tom 告訴 plan executor 哪個 voice_*.aac 對應哪個 prompt_NN（spec §6 角色：開場/輪播/結束）。

- [ ] **Step 1: Tom 在 chat 提供 mapping**

Tom needs to fill in this table（**只填檔名跟角色，不需要逐字 transcript**）:

| 來源檔 | 目標 prompt | 角色 |
|---|---|---|
| voice_472115.aac | prompt_NN.wav | 開場 / 輪播 / 結束 |
| voice_472116.aac | prompt_NN.wav | ... |
| ... (12 rows) | | |

**約束**：
- 必須有 1 個「開場」（→ prompt_01.wav）
- 必須有 1 個「結束」（→ prompt_11.wav）
- 其他 10 個都是「輪播」（→ prompt_02-10, prompt_12）

如 Tom 不確定，可以全標「輪播」也行——系統會自己抓 01 當開場、11 當結束。

- [ ] **Step 2: Save mapping as `companion-call/audio/_mapping.yaml` (gitignored, tom 自己決定要不要存)**

範例（Tom 提供後填）:

```yaml
# Mapping from Tom's recordings to prompt_NN slots
# This file is for reference; conversion is parameterized via batch_convert()
mapping:
  voice_472115.aac: prompt_01.wav   # 開場
  voice_472116.aac: prompt_02.wav   # 輪播
  voice_472117.aac: prompt_03.wav   # 輪播
  voice_472118.aac: prompt_04.wav   # 輪播
  voice_472119.aac: prompt_05.wav   # 輪播
  voice_472120.aac: prompt_06.wav   # 輪播
  voice_472121.aac: prompt_07.wav   # 輪播
  voice_472122.aac: prompt_08.wav   # 輪播
  voice_472123.aac: prompt_09.wav   # 輪播
  voice_472124.aac: prompt_10.wav   # 輪播
  voice_472125.aac: prompt_11.wav   # 結束
  voice_472126.aac: prompt_12.wav   # 輪播
```

- [ ] **Step 3: Run batch conversion**

```bash
cd whiteboard-ocr-bot
source venv/bin/activate
python -c "
from pathlib import Path
from companion_call.audio_convert import batch_convert
import yaml

mapping = yaml.safe_load(open('companion-call/audio/_mapping.yaml'))['mapping']
outputs = batch_convert(
    src_dir=Path('/home/tom/Desktop/recordings'),
    mapping=mapping,
    out_dir=Path('companion-call/audio'),
)
print(f'Converted {len(outputs)} files')
"
```

Expected: `Converted 12 files`，`companion-call/audio/` 出現 prompt_01.wav~prompt_12.wav。

- [ ] **Step 4: Verify with ffprobe (one file)**

```bash
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,sample_rate,channels \
  -of default=noprint_wrappers=1 \
  companion-call/audio/prompt_01.wav
```

Expected:
```
codec_name=pcm_mulaw
sample_rate=8000
channels=1
```

- [ ] **Step 5: Verify .gitignore actually ignored these**

```bash
git status --short companion-call/audio/
```

Expected: empty (no `??` or ` M` for *.wav). 如果有 wav 出現在輸出，**立刻停手**檢查 .gitignore。

- [ ] **Step 6: Commit (NOT the wav files, just the mapping reference if保留)**

```bash
# audio/*.wav 不 commit (gitignored)
# 如要保留 mapping yaml 給未來重做，加進 .gitignore exception
echo "!companion-call/audio/_mapping.yaml" >> whiteboard-ocr-bot/.gitignore
git add whiteboard-ocr-bot/.gitignore companion-call/audio/_mapping.yaml
git commit -m "chore(companion-call): mapping reference for Tom's recordings"
```

---

## Task 4: Shared iDempiere helper 🔧 (TDD)

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/shared.py`
- Create: `whiteboard-ocr-bot/companion-call/tests/test_shared.py`

**Purpose:** iDempiere REST 共用 helper（auth + Z_momSystem.Description upsert）。

- [ ] **Step 1: Write failing test `test_shared.py`**

```python
"""Test shared iDempiere helpers."""
from datetime import date
from unittest.mock import patch

import pytest

from companion_call.shared import (
    get_idempiere_token,
    upsert_zmomsystem_description,
)


def test_get_token_cached(monkeypatch):
    """Calling get_token twice should only POST /auth/tokens once."""
    call_count = {"n": 0}

    def fake_post(url, json, **kw):
        call_count["n"] += 1
        class R:
            status_code = 200
            def json(self):
                return {"token": "fake_jwt", "language": "zh_TW"}
        return R()

    with patch("companion_call.shared.requests.post", fake_post):
        t1 = get_idempiere_token()
        t2 = get_idempiere_token()
    assert t1 == t2 == "fake_jwt"
    assert call_count["n"] == 1


def test_upsert_appends_to_existing_description(monkeypatch):
    """Same-day call should PATCH existing record's Description (append \\n)."""
    requests_log = []

    def fake_get(url, headers=None, **kw):
        # Pretend record exists with Description "[2026-05-05|09:01] 陪聊 67s"
        class R:
            status_code = 200
            def json(self):
                return {
                    "records": [{
                        "id": 12345,
                        "Description": "[2026-05-05|09:01] 陪聊 67s",
                    }],
                }
        requests_log.append(("GET", url))
        return R()

    def fake_patch(url, json=None, headers=None, **kw):
        requests_log.append(("PATCH", url, json))
        class R:
            status_code = 200
            def json(self):
                return {"id": 12345}
        return R()

    with patch("companion_call.shared.requests.get", fake_get), \
         patch("companion_call.shared.requests.patch", fake_patch), \
         patch("companion_call.shared.get_idempiere_token", return_value="fake_jwt"):
        upsert_zmomsystem_description(
            date(2026, 5, 5),
            "[2026-05-05|10:01] 陪聊 88s",
        )

    # Verify a PATCH happened with appended Description
    patches = [r for r in requests_log if r[0] == "PATCH"]
    assert len(patches) == 1
    body = patches[0][2]
    assert "[2026-05-05|09:01] 陪聊 67s" in body["Description"]
    assert "[2026-05-05|10:01] 陪聊 88s" in body["Description"]
    assert body["Description"].count("\n") == 1   # split by \n


def test_upsert_creates_new_when_no_record(monkeypatch):
    """No existing record → POST a new one."""
    requests_log = []

    def fake_get(url, headers=None, **kw):
        class R:
            status_code = 200
            def json(self):
                return {"records": []}
        requests_log.append(("GET", url))
        return R()

    def fake_post(url, json=None, headers=None, **kw):
        requests_log.append(("POST", url, json))
        class R:
            status_code = 201
            def json(self):
                return {"id": 99999}
        return R()

    with patch("companion_call.shared.requests.get", fake_get), \
         patch("companion_call.shared.requests.post", fake_post), \
         patch("companion_call.shared.get_idempiere_token", return_value="fake_jwt"):
        upsert_zmomsystem_description(
            date(2026, 5, 5),
            "[2026-05-05|09:01] 陪聊 67s",
        )

    posts = [r for r in requests_log if r[0] == "POST"]
    assert len(posts) == 1
    body = posts[0][2]
    assert body["Description"] == "[2026-05-05|09:01] 陪聊 67s"
```

- [ ] **Step 2: Run test → FAIL**

```bash
pytest companion-call/tests/test_shared.py -v
```

Expected: 3 tests FAIL with `ModuleNotFoundError`.

- [ ] **Step 3: Implement `shared.py`**

```python
"""Shared helpers for companion-call → iDempiere REST."""
from __future__ import annotations

import logging
import os
from datetime import date
from typing import Optional

import requests

logger = logging.getLogger(__name__)

_token_cache: dict[str, str] = {}


def get_idempiere_token() -> str:
    """Login to iDempiere REST and cache token for the process lifetime.

    Returns: JWT token string

    Raises: RuntimeError if login fails
    """
    if "token" in _token_cache:
        return _token_cache["token"]

    url = f"{os.environ['IDEMPIERE_BASE_URL']}/auth/tokens"
    payload = {
        "userName": os.environ["IDEMPIERE_USERNAME"],
        "password": os.environ["IDEMPIERE_PASSWORD"],
        "parameters": {
            "clientId": int(os.environ["IDEMPIERE_CLIENT_ID"]),
            "roleId": int(os.environ["IDEMPIERE_ROLE_ID"]),
            "organizationId": int(os.environ["IDEMPIERE_ORGANIZATION_ID"]),
            "warehouseId": int(os.environ["IDEMPIERE_WAREHOUSE_ID"]),
            "language": "zh_TW",
        },
    }
    r = requests.post(url, json=payload, timeout=10)
    if r.status_code != 200:
        raise RuntimeError(f"iDempiere login failed: {r.status_code} {r.text}")
    token = r.json()["token"]
    _token_cache["token"] = token
    logger.info("iDempiere token cached")
    return token


def _find_zmomsystem_record(target_date: date, token: str) -> Optional[dict]:
    """GET Z_momSystem record for a date. Returns the record dict or None."""
    base = os.environ["IDEMPIERE_BASE_URL"]
    url = f"{base}/models/Z_momSystem"
    params = {
        "$filter": f"DateDoc eq '{target_date.isoformat()}'",
        "$select": "id,Description,DateDoc",
    }
    r = requests.get(url, params=params,
                     headers={"Authorization": f"Bearer {token}"},
                     timeout=10)
    if r.status_code != 200:
        raise RuntimeError(f"GET Z_momSystem failed: {r.status_code} {r.text}")
    records = r.json().get("records", [])
    return records[0] if records else None


def upsert_zmomsystem_description(target_date: date, line: str) -> None:
    """Append a line to Z_momSystem.Description for given date.

    If a record for target_date exists, PATCH (append \\n + line).
    Else POST a new record.
    """
    token = get_idempiere_token()
    base = os.environ["IDEMPIERE_BASE_URL"]
    record = _find_zmomsystem_record(target_date, token)

    if record is None:
        # Create new
        url = f"{base}/models/Z_momSystem"
        body = {
            "DateDoc": target_date.isoformat(),
            "Description": line,
        }
        r = requests.post(url, json=body,
                          headers={"Authorization": f"Bearer {token}"},
                          timeout=10)
        if r.status_code not in (200, 201):
            raise RuntimeError(f"POST Z_momSystem failed: {r.status_code} {r.text}")
        logger.info("Created Z_momSystem record for %s", target_date)
        return

    # Append
    existing = record.get("Description") or ""
    new_desc = f"{existing}\n{line}" if existing else line
    rid = record["id"]
    url = f"{base}/models/Z_momSystem/{rid}"
    body = {"Description": new_desc}
    r = requests.patch(url, json=body,
                       headers={"Authorization": f"Bearer {token}"},
                       timeout=10)
    if r.status_code != 200:
        raise RuntimeError(f"PATCH Z_momSystem failed: {r.status_code} {r.text}")
    logger.info("Appended to Z_momSystem record %s", rid)
```

- [ ] **Step 4: Run tests → PASS**

```bash
pytest companion-call/tests/test_shared.py -v
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/shared.py \
        whiteboard-ocr-bot/companion-call/tests/test_shared.py
git commit -m "feat(companion-call): shared.py — iDempiere auth + Z_momSystem upsert"
```

---

## Task 5: TwiML voice server 🔧 (TDD)

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/twilio_app.py`
- Create: `whiteboard-ocr-bot/companion-call/tests/test_twilio_app.py`

**Purpose:** FastAPI server，Twilio webhook 來時回 TwiML 指令。輪播狀態存在 Twilio call SID-keyed dict (in-memory)。

- [ ] **Step 1: Write failing tests**

```python
"""Test FastAPI TwiML server."""
from xml.etree import ElementTree as ET

import pytest
from fastapi.testclient import TestClient

from companion_call.twilio_app import app, _state


@pytest.fixture(autouse=True)
def reset_state():
    _state.clear()
    yield
    _state.clear()


@pytest.fixture
def client():
    return TestClient(app)


def parse_twiml(text: str) -> ET.Element:
    return ET.fromstring(text)


def test_voice_endpoint_plays_opener(client):
    """First Twilio webhook returns TwiML with prompt_01 + redirect to /next."""
    r = client.post("/voice", data={"CallSid": "CAtest1"})
    assert r.status_code == 200
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    assert "prompt_01.wav" in plays[0].text
    redirects = twiml.findall("Redirect")
    assert len(redirects) == 1
    assert "/next" in redirects[0].text


def test_voice_initializes_state(client):
    client.post("/voice", data={"CallSid": "CAtest1"})
    assert "CAtest1" in _state
    assert _state["CAtest1"]["played_count"] == 1
    assert _state["CAtest1"]["start_time"] > 0


def test_next_endpoint_plays_random_middle_prompt(client):
    client.post("/voice", data={"CallSid": "CAtest2"})
    r = client.post("/next", data={"CallSid": "CAtest2"})
    assert r.status_code == 200
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    # Should be one of prompt_02..10 or prompt_12 (middle)
    text = plays[0].text
    assert "prompt_01.wav" not in text   # not opener
    assert "prompt_11.wav" not in text   # not closer


def test_next_switches_to_closer_after_threshold(client):
    """After accumulated time ≥ END_TRIGGER_SEC, must play prompt_11 + Hangup."""
    client.post("/voice", data={"CallSid": "CAtest3"})
    # Force accumulated time over threshold
    _state["CAtest3"]["start_time"] -= 100   # 100s ago

    r = client.post("/next", data={"CallSid": "CAtest3"})
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    assert "prompt_11.wav" in plays[0].text
    assert twiml.find("Hangup") is not None


def test_call_ended_logs_to_idempiere(client, monkeypatch):
    """call-ended webhook should call upsert_zmomsystem_description."""
    captured = []

    def fake_upsert(d, line):
        captured.append((d, line))

    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description",
        fake_upsert,
    )

    # Pre-populate state
    _state["CAtestEnd"] = {"played_count": 5, "start_time": 1700000000.0}

    r = client.post("/call-ended", data={
        "CallSid": "CAtestEnd",
        "CallStatus": "completed",
        "CallDuration": "67",
    })
    assert r.status_code == 200
    assert len(captured) == 1
    line = captured[0][1]
    assert "陪聊" in line
    assert "67s" in line


def test_call_ended_no_answer(client, monkeypatch):
    captured = []
    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description",
        lambda d, line: captured.append((d, line)),
    )

    r = client.post("/call-ended", data={
        "CallSid": "CAnoans",
        "CallStatus": "no-answer",
        "CallDuration": "0",
    })
    assert r.status_code == 200
    assert "陪聊未接" in captured[0][1]


def test_inbound_hangs_up(client):
    """If mom calls back the Twilio number, hang up immediately."""
    r = client.post("/inbound", data={"CallSid": "CAinbound"})
    twiml = parse_twiml(r.text)
    # Either Hangup directly or short message + hangup
    assert twiml.find("Hangup") is not None
```

- [ ] **Step 2: Run → FAIL**

```bash
pytest companion-call/tests/test_twilio_app.py -v
```

Expected: 7 tests FAIL with import errors.

- [ ] **Step 3: Implement `twilio_app.py`**

```python
"""FastAPI TwiML server for companion-call."""
from __future__ import annotations

import logging
import os
import random
import time
from datetime import datetime
from typing import Any

from fastapi import FastAPI, Form
from fastapi.responses import Response

from companion_call.shared import upsert_zmomsystem_description

logger = logging.getLogger(__name__)
app = FastAPI(title="companion-call TwiML server")

# In-memory state: CallSid → {played_count, start_time, played_indices}
_state: dict[str, dict[str, Any]] = {}

OPENER = "prompt_01.wav"
CLOSER = "prompt_11.wav"
MIDDLE = [f"prompt_{i:02d}.wav" for i in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]]


def _audio_url(filename: str) -> str:
    base = os.environ["COMPANION_CALL_PUBLIC_URL"].rstrip("/")
    return f"{base}/audio/{filename}"


def _twiml_response(body: str) -> Response:
    xml = f'<?xml version="1.0" encoding="UTF-8"?><Response>{body}</Response>'
    return Response(content=xml, media_type="application/xml")


def _elapsed(call_sid: str) -> float:
    return time.time() - _state[call_sid]["start_time"]


@app.post("/voice")
async def voice(CallSid: str = Form(...)) -> Response:
    """Mom answers — play opener and start state."""
    _state[CallSid] = {
        "played_count": 1,
        "start_time": time.time(),
        "played_indices": {1},
    }
    body = f'<Play>{_audio_url(OPENER)}</Play>'
    body += f'<Pause length="3"/>'
    body += '<Redirect>/next</Redirect>'
    return _twiml_response(body)


@app.post("/next")
async def next_prompt(CallSid: str = Form(...)) -> Response:
    """After mom finishes talking — play next prompt or close."""
    if CallSid not in _state:
        # Stale call sid — close gracefully
        return _twiml_response(f'<Play>{_audio_url(CLOSER)}</Play><Hangup/>')

    end_trigger = float(os.environ["COMPANION_CALL_END_TRIGGER_SEC"])
    if _elapsed(CallSid) >= end_trigger:
        body = f'<Play>{_audio_url(CLOSER)}</Play><Hangup/>'
        return _twiml_response(body)

    # Pick a middle prompt not recently played (best effort)
    state = _state[CallSid]
    candidates = [
        idx for idx in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]
        if idx not in state.get("recent", set())
    ]
    if not candidates:
        candidates = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]
    pick_idx = random.choice(candidates)
    pick = f"prompt_{pick_idx:02d}.wav"
    state.setdefault("recent", set()).add(pick_idx)
    if len(state["recent"]) >= 3:
        # forget oldest by clearing — keep last 2-3 unique
        state["recent"] = {pick_idx}
    state["played_count"] += 1

    body = f'<Play>{_audio_url(pick)}</Play>'
    body += '<Pause length="3"/>'
    body += '<Redirect>/next</Redirect>'
    return _twiml_response(body)


@app.post("/call-ended")
async def call_ended(
    CallSid: str = Form(...),
    CallStatus: str = Form(...),
    CallDuration: str = Form(default="0"),
) -> dict:
    """Twilio call-ended webhook → log to iDempiere."""
    today = datetime.now().date()
    hh_mm = datetime.now().strftime("%H:%M")
    duration = int(CallDuration or 0)

    if CallStatus == "completed" and duration > 0:
        if duration < 5:
            line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {duration}s(短)"
        else:
            line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {duration}s"
    elif CallStatus in ("no-answer", "busy"):
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊未接"
    elif CallStatus == "failed":
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊失敗(twilio_failed)"
    else:
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {CallStatus}"

    try:
        upsert_zmomsystem_description(today, line)
    except Exception as e:
        logger.exception("Failed to log to iDempiere: %s", e)
        # Write to local fallback log
        with open("companion-call/failed_writes.log", "a") as f:
            f.write(f"{datetime.now().isoformat()}\t{line}\n")

    _state.pop(CallSid, None)
    return {"ok": True}


@app.post("/inbound")
async def inbound(CallSid: str = Form(...)) -> Response:
    """Mom (or anyone) called back the Twilio number — hang up politely."""
    body = '<Say language="zh-TW" voice="Polly.Hui">我先去忙，先這樣喔。</Say>'
    body += '<Hangup/>'
    return _twiml_response(body)


# Static audio mounting in deployment (not for tests):
# uvicorn config or behind cloudflared with route /audio/* → companion-call/audio/
```

- [ ] **Step 4: Add static audio mount (separate startup script later)**

For tests, the URL is just a string — no actual file fetched. For deployment, audio is served via uvicorn StaticFiles. This is configured in Task 7 (systemd unit / startup).

- [ ] **Step 5: Run tests → PASS**

```bash
pytest companion-call/tests/test_twilio_app.py -v
```

Expected: 7 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/twilio_app.py \
        whiteboard-ocr-bot/companion-call/tests/test_twilio_app.py
git commit -m "feat(companion-call): twilio_app.py — TwiML server with VAD-driven rotation"
```

---

## Task 6: Outbound call client 🔧 (TDD)

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/scheduled_call.py`
- Create: `whiteboard-ocr-bot/companion-call/tests/test_scheduled_call.py`

**Purpose:** 用 Twilio SDK 發起 outbound call，webhook 指 /voice。

- [ ] **Step 1: Write failing tests**

```python
"""Test scheduled_call.py outbound caller."""
from unittest.mock import MagicMock, patch

from companion_call.scheduled_call import place_call


def test_place_call_invokes_twilio_create():
    fake_calls = MagicMock()
    fake_calls.create.return_value = MagicMock(sid="CAtest")
    fake_client = MagicMock()
    fake_client.calls = fake_calls

    with patch("companion_call.scheduled_call.Client", return_value=fake_client):
        sid = place_call()

    assert sid == "CAtest"
    fake_calls.create.assert_called_once()
    kwargs = fake_calls.create.call_args.kwargs
    assert kwargs["from_"] == "+15551234567"          # from fake env
    assert kwargs["to"] == "+886912345678"             # mom number from env
    assert kwargs["url"].endswith("/voice")
    assert "test.cfargotunnel.com" in kwargs["url"]
    assert kwargs["status_callback"].endswith("/call-ended")
    assert kwargs["timeout"] == 30                     # no-answer timeout
```

- [ ] **Step 2: Run → FAIL**

```bash
pytest companion-call/tests/test_scheduled_call.py -v
```

- [ ] **Step 3: Implement `scheduled_call.py`**

```python
"""Outbound caller — entry point triggered by scheduler."""
from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from twilio.rest import Client

# Load .env when run as script
load_dotenv(Path(__file__).resolve().parent / ".env")

logger = logging.getLogger(__name__)


def place_call() -> str:
    """Trigger one outbound call. Returns Twilio Call SID.

    Raises: twilio.base.exceptions.TwilioRestException on failure
    """
    sid = os.environ["TWILIO_ACCOUNT_SID"]
    token = os.environ["TWILIO_AUTH_TOKEN"]
    from_number = os.environ["TWILIO_FROM_NUMBER"]
    to_number = os.environ["MOM_PHONE_NUMBER"]
    public_url = os.environ["COMPANION_CALL_PUBLIC_URL"].rstrip("/")

    client = Client(sid, token)
    call = client.calls.create(
        from_=from_number,
        to=to_number,
        url=f"{public_url}/voice",
        status_callback=f"{public_url}/call-ended",
        status_callback_method="POST",
        status_callback_event=["completed", "no-answer", "failed", "busy"],
        timeout=30,            # ring timeout
        machine_detection="DetectMessageEnd",   # 偵測語音信箱
    )
    logger.info("Placed call %s to %s", call.sid, to_number)
    return call.sid


if __name__ == "__main__":
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
    try:
        sid = place_call()
        print(f"Call placed: {sid}", file=sys.stderr)
    except Exception as e:
        logger.exception("Call failed")
        sys.exit(1)
```

- [ ] **Step 4: Run → PASS**

```bash
pytest companion-call/tests/test_scheduled_call.py -v
```

- [ ] **Step 5: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/scheduled_call.py \
        whiteboard-ocr-bot/companion-call/tests/test_scheduled_call.py
git commit -m "feat(companion-call): scheduled_call.py — Twilio outbound caller"
```

---

## Task 7: Schedule daemon 🔧 (TDD)

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/companion_scheduler.py`
- Create: `whiteboard-ocr-bot/companion-call/schedule.yaml`
- Create: `whiteboard-ocr-bot/companion-call/tests/test_scheduler.py`

**Purpose:** 常駐 daemon，每分鐘讀 `schedule.yaml`，命中 slot 就觸發 `place_call()`。同分鐘只觸發一次。

- [ ] **Step 1: Create initial `schedule.yaml`** (already specified in spec §3.3)

```yaml
weekly:
  tuesday: ["09:00", "10:00", "11:00", "15:00", "16:00"]
  thursday: ["09:00", "10:00", "11:00", "15:00", "16:00"]
  sunday: ["09:00", "10:00", "11:00", "15:00", "16:00"]
  monday: []
  wednesday: []
  friday: []
  saturday: []

exceptions: {}

defaults:
  call_duration_sec: 90
  retry_after_no_answer: false
  timezone: "Asia/Taipei"
```

- [ ] **Step 2: Write failing tests**

```python
"""Test scheduler logic."""
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

import yaml
from freezegun import freeze_time

from companion_call.companion_scheduler import (
    load_schedule,
    is_slot_now,
    SchedulerLoop,
)


SAMPLE_YAML = {
    "weekly": {
        "tuesday": ["09:00", "10:00"],
        "thursday": ["15:00"],
        "monday": [], "wednesday": [], "friday": [], "saturday": [], "sunday": [],
    },
    "exceptions": {
        "2026-05-12": {"skip": True},
        "2026-05-15": {"override": ["10:00", "14:00"]},
    },
    "defaults": {"timezone": "Asia/Taipei"},
}


def test_load_schedule_reads_yaml(tmp_path):
    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump(SAMPLE_YAML))
    s = load_schedule(f)
    assert s["weekly"]["tuesday"] == ["09:00", "10:00"]


@freeze_time("2026-05-05 09:00:30", tz_offset=8)   # Tue 09:00 Taipei
def test_is_slot_now_hits_tuesday():
    assert is_slot_now(SAMPLE_YAML, datetime.now()) is True


@freeze_time("2026-05-05 09:30:30", tz_offset=8)   # Tue 09:30 (no slot)
def test_is_slot_now_misses_when_no_match():
    assert is_slot_now(SAMPLE_YAML, datetime.now()) is False


@freeze_time("2026-05-12 09:00:30", tz_offset=8)   # Tue but in exceptions skip
def test_is_slot_now_respects_skip_exception():
    assert is_slot_now(SAMPLE_YAML, datetime.now()) is False


@freeze_time("2026-05-15 10:00:30", tz_offset=8)   # Fri (no weekly) but override
def test_is_slot_now_respects_override_exception():
    assert is_slot_now(SAMPLE_YAML, datetime.now()) is True


@freeze_time("2026-05-15 09:00:30", tz_offset=8)   # Fri override 10:00 14:00
def test_is_slot_now_override_only_at_listed_times():
    assert is_slot_now(SAMPLE_YAML, datetime.now()) is False


def test_scheduler_triggers_place_call_once_per_minute(tmp_path):
    """Same minute shouldn't fire twice."""
    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump(SAMPLE_YAML))
    triggers = []

    def fake_place_call():
        triggers.append(datetime.now())
        return "CAxxx"

    loop = SchedulerLoop(schedule_path=f, place_call_fn=fake_place_call)

    with freeze_time("2026-05-05 09:00:10", tz_offset=8):
        loop.tick()
    with freeze_time("2026-05-05 09:00:50", tz_offset=8):
        loop.tick()   # same HH:MM → no second trigger
    with freeze_time("2026-05-05 09:01:10", tz_offset=8):
        loop.tick()   # 09:01 → no slot

    assert len(triggers) == 1


def test_scheduler_reloads_yaml_each_tick(tmp_path):
    """Editing yaml mid-run is picked up next tick."""
    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump({
        "weekly": {"tuesday": ["09:00"], "monday": [], "wednesday": [],
                    "thursday": [], "friday": [], "saturday": [], "sunday": []},
        "exceptions": {},
        "defaults": {"timezone": "Asia/Taipei"},
    }))
    triggers = []
    loop = SchedulerLoop(schedule_path=f,
                         place_call_fn=lambda: (triggers.append(1), "CA")[1])

    # First tick at 10:00 — no slot
    with freeze_time("2026-05-05 10:00:10", tz_offset=8):
        loop.tick()
    assert triggers == []

    # Edit yaml to add 10:00
    f.write_text(yaml.safe_dump({
        "weekly": {"tuesday": ["09:00", "10:00"], "monday": [], "wednesday": [],
                    "thursday": [], "friday": [], "saturday": [], "sunday": []},
        "exceptions": {},
        "defaults": {"timezone": "Asia/Taipei"},
    }))

    with freeze_time("2026-05-05 10:00:50", tz_offset=8):
        loop.tick()
    assert len(triggers) == 1   # picked up
```

- [ ] **Step 3: Run → FAIL**

```bash
pytest companion-call/tests/test_scheduler.py -v
```

- [ ] **Step 4: Implement `companion_scheduler.py`**

```python
"""Scheduler daemon — reads schedule.yaml each tick, fires Twilio call on hit."""
from __future__ import annotations

import logging
import os
import time
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional
from zoneinfo import ZoneInfo

import yaml

logger = logging.getLogger(__name__)

WEEKDAY_NAMES = [
    "monday", "tuesday", "wednesday", "thursday",
    "friday", "saturday", "sunday",
]


def load_schedule(path: Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def is_slot_now(schedule: dict, now: datetime) -> bool:
    """Check if current minute is a scheduled call slot.

    Rules:
    - exceptions[YYYY-MM-DD].skip=True → False regardless of weekly
    - exceptions[YYYY-MM-DD].override=[HH:MM,...] → match against override list
    - else weekly[<day>] match
    """
    tz_name = schedule.get("defaults", {}).get("timezone", "Asia/Taipei")
    local_now = now.astimezone(ZoneInfo(tz_name))
    hh_mm = local_now.strftime("%H:%M")
    date_str = local_now.strftime("%Y-%m-%d")
    weekday = WEEKDAY_NAMES[local_now.weekday()]

    exceptions = schedule.get("exceptions") or {}
    if date_str in exceptions:
        ex = exceptions[date_str]
        if ex.get("skip"):
            return False
        if "override" in ex:
            return hh_mm in ex["override"]

    weekly = schedule.get("weekly", {})
    return hh_mm in (weekly.get(weekday) or [])


class SchedulerLoop:
    def __init__(
        self,
        schedule_path: Path,
        place_call_fn: Optional[Callable[[], str]] = None,
    ):
        self.schedule_path = Path(schedule_path)
        if place_call_fn is None:
            from companion_call.scheduled_call import place_call
            place_call_fn = place_call
        self.place_call_fn = place_call_fn
        self._last_fired_minute: Optional[str] = None

    def tick(self) -> None:
        """One scheduler iteration. Call this every ~30 seconds."""
        try:
            schedule = load_schedule(self.schedule_path)
        except Exception:
            logger.exception("Failed to load schedule, skipping tick")
            return

        now = datetime.now()
        tz_name = schedule.get("defaults", {}).get("timezone", "Asia/Taipei")
        local_now = now.astimezone(ZoneInfo(tz_name))
        minute_key = local_now.strftime("%Y-%m-%d %H:%M")

        if minute_key == self._last_fired_minute:
            return  # already fired this minute

        if is_slot_now(schedule, now):
            try:
                sid = self.place_call_fn()
                logger.info("Slot hit %s, placed call %s", minute_key, sid)
            except Exception:
                logger.exception("place_call failed at slot %s", minute_key)
            finally:
                self._last_fired_minute = minute_key

    def run_forever(self, sleep_sec: int = 30) -> None:
        logger.info("Scheduler loop started (sleep=%ds)", sleep_sec)
        while True:
            self.tick()
            time.sleep(sleep_sec)


def main():
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent / ".env")
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    schedule_path = Path(__file__).resolve().parent / "schedule.yaml"
    loop = SchedulerLoop(schedule_path=schedule_path)
    loop.run_forever(sleep_sec=30)


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: Run → PASS**

```bash
pytest companion-call/tests/test_scheduler.py -v
```

- [ ] **Step 6: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/companion_scheduler.py \
        whiteboard-ocr-bot/companion-call/schedule.yaml \
        whiteboard-ocr-bot/companion-call/tests/test_scheduler.py
git commit -m "feat(companion-call): scheduler daemon + schedule.yaml hot reload"
```

---

## Task 8: Cloudflared tunnel setup 📋 + ✅

**Goal:** 把 mini PC FastAPI（port 8001）暴露給 Twilio 用一個穩定 https URL。Audio 也要從這個 tunnel 提供。

- [ ] **Step 1: Verify cloudflared installed**

```bash
which cloudflared
cloudflared --version
```

If not installed: `sudo apt install cloudflared` (or download from cloudflare).

- [ ] **Step 2: Login & create tunnel**

```bash
cloudflared tunnel login
# follow browser prompt to authorize
cloudflared tunnel create companion-call
# copy the tunnel UUID printed
```

- [ ] **Step 3: Create tunnel config**

Create `~/.cloudflared/companion-call-config.yml`:

```yaml
tunnel: <UUID-from-step-2>
credentials-file: /home/tom/.cloudflared/<UUID-from-step-2>.json

ingress:
  - hostname: companion-call-tom.cfargotunnel.com  # or your custom domain
    service: http://localhost:8001
  - service: http_status:404
```

If you don't have a custom domain, cloudflared will assign a `*.cfargotunnel.com` automatically — that URL goes into `.env` as `COMPANION_CALL_PUBLIC_URL`.

- [ ] **Step 4: Test tunnel**

```bash
# In one terminal, start a dummy server:
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot
source venv/bin/activate
python -c "
from fastapi import FastAPI
import uvicorn
app = FastAPI()
@app.get('/test')
def t(): return {'ok': True}
uvicorn.run(app, host='0.0.0.0', port=8001)
" &
SERVER_PID=$!

# In another terminal, run tunnel:
cloudflared tunnel --config ~/.cloudflared/companion-call-config.yml run companion-call &
TUNNEL_PID=$!

# Wait a few seconds, then:
curl https://<your-tunnel-url>/test
# Expected: {"ok":true}

kill $SERVER_PID $TUNNEL_PID
```

- [ ] **Step 5: Tom updates `.env`**

```bash
# Tom edits .env (NOT through chat) and sets:
# COMPANION_CALL_PUBLIC_URL=https://<your-tunnel-url>
nano /home/tom/Desktop/dementia-care/whiteboard-ocr-bot/companion-call/.env
```

- [ ] **Step 6: No commit (config is in ~/.cloudflared/, not repo)**

---

## Task 9: Production startup script 🔧

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/run_server.sh`
- Modify: `whiteboard-ocr-bot/companion-call/twilio_app.py` (add static mount)

**Purpose:** 啟動 uvicorn 同時掛 audio static files。

- [ ] **Step 1: Add static audio mount to `twilio_app.py`**

Append at end of file (after all routes):

```python
# Mount audio directory for Twilio to fetch
from fastapi.staticfiles import StaticFiles
from pathlib import Path

_audio_dir = Path(__file__).resolve().parent / "audio"
if _audio_dir.exists():
    app.mount("/audio", StaticFiles(directory=str(_audio_dir)), name="audio")
```

- [ ] **Step 2: Add test for static mount works**

Append to `test_twilio_app.py`:

```python
def test_audio_mount_serves_files(tmp_path, monkeypatch):
    """audio/ files should be served at /audio/<filename>."""
    # The mount happens at import time, so this test is mostly smoke-level.
    # It only verifies the route exists; actual file serving needs a real wav.
    from fastapi.testclient import TestClient
    from companion_call.twilio_app import app

    routes = [r.path for r in app.routes]
    assert "/audio" in routes or any("/audio" in r for r in routes)
```

- [ ] **Step 3: Create `run_server.sh`**

```bash
#!/usr/bin/env bash
# Start companion-call FastAPI server.
# Called by systemd unit; can also run manually.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$(dirname "$HERE")"   # whiteboard-ocr-bot/

source venv/bin/activate

# Load .env so uvicorn child process inherits
set -a
source companion-call/.env
set +a

exec uvicorn companion_call.twilio_app:app \
    --host 0.0.0.0 \
    --port 8001 \
    --log-level "${LOG_LEVEL,,}"
```

```bash
chmod +x whiteboard-ocr-bot/companion-call/run_server.sh
```

- [ ] **Step 4: Run tests**

```bash
pytest companion-call/tests/ -v
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add whiteboard-ocr-bot/companion-call/twilio_app.py \
        whiteboard-ocr-bot/companion-call/run_server.sh \
        whiteboard-ocr-bot/companion-call/tests/test_twilio_app.py
git commit -m "feat(companion-call): static audio mount + run_server.sh"
```

---

## Task 10: systemd service install 📋

**Files:**
- Create: `whiteboard-ocr-bot/companion-call/companion-call.service`
- Create: `whiteboard-ocr-bot/companion-call/companion-call-scheduler.service`
- Create: `whiteboard-ocr-bot/companion-call/companion-call-tunnel.service`

**Purpose:** 三個 systemd service 用 systemctl 管理：FastAPI (`companion-call`)、scheduler daemon (`companion-call-scheduler`)、cloudflared tunnel (`companion-call-tunnel`)。

- [ ] **Step 1: Create FastAPI server unit `companion-call.service`**

```ini
[Unit]
Description=Companion Call TwiML server (FastAPI)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=tom
WorkingDirectory=/home/tom/Desktop/dementia-care/whiteboard-ocr-bot
ExecStart=/home/tom/Desktop/dementia-care/whiteboard-ocr-bot/companion-call/run_server.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: Create scheduler unit `companion-call-scheduler.service`**

```ini
[Unit]
Description=Companion Call scheduler daemon
After=network-online.target companion-call.service
Wants=network-online.target
Requires=companion-call.service

[Service]
Type=simple
User=tom
WorkingDirectory=/home/tom/Desktop/dementia-care/whiteboard-ocr-bot
EnvironmentFile=/home/tom/Desktop/dementia-care/whiteboard-ocr-bot/companion-call/.env
ExecStart=/home/tom/Desktop/dementia-care/whiteboard-ocr-bot/venv/bin/python -m companion_call.companion_scheduler
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 3: Create tunnel unit `companion-call-tunnel.service`**

```ini
[Unit]
Description=Cloudflared tunnel for companion-call
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=tom
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/tom/.cloudflared/companion-call-config.yml run companion-call
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 4: Install all three**

```bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot/companion-call
sudo cp companion-call.service /etc/systemd/system/
sudo cp companion-call-scheduler.service /etc/systemd/system/
sudo cp companion-call-tunnel.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start tunnel first, then server, then scheduler
sudo systemctl enable --now companion-call-tunnel.service
sudo systemctl enable --now companion-call.service
sudo systemctl enable --now companion-call-scheduler.service
```

- [ ] **Step 5: Verify all green**

```bash
systemctl status companion-call-tunnel companion-call companion-call-scheduler
# All should show "active (running)"

# Sample output check:
journalctl -u companion-call -n 20 --no-pager
journalctl -u companion-call-scheduler -n 20 --no-pager
```

- [ ] **Step 6: Smoke test endpoint via tunnel**

```bash
# Get URL from .env
PUB_URL=$(grep COMPANION_CALL_PUBLIC_URL companion-call/.env | cut -d= -f2)
curl -X POST "$PUB_URL/voice" -d "CallSid=CAtest_smoke"
# Expected: TwiML XML with <Play>...prompt_01.wav</Play>
```

- [ ] **Step 7: Commit unit files**

```bash
git add whiteboard-ocr-bot/companion-call/companion-call.service \
        whiteboard-ocr-bot/companion-call/companion-call-scheduler.service \
        whiteboard-ocr-bot/companion-call/companion-call-tunnel.service
git commit -m "feat(companion-call): systemd unit files for server/scheduler/tunnel"
```

---

## Task 11: End-to-end smoke test on Tom's phone ✅

**Purpose:** Phase 1 — Tom 用自己手機驗證整條 pipeline。**這個 Task 不寫 code，只跑 + 檢查**。

**Pre-conditions:**
- [ ] Tasks 1-10 完成
- [ ] Tom 的 `.env` 已有真值（自己 nano 填，未經 chat）
- [ ] `MOM_PHONE_NUMBER` 暫設為 Tom 自己手機
- [ ] Twilio 帳號至少升級到 paid（trial mode 會先念英文）
- [ ] Twilio Geographic Permissions 已開啟 Taiwan

- [ ] **Step 1: Manual single-call test**

```bash
cd /home/tom/Desktop/dementia-care/whiteboard-ocr-bot
source venv/bin/activate
python -m companion_call.scheduled_call
# Expected: 5 秒內你手機響鈴
```

接起來驗證：
- ✅ 聽到 prompt_01（你錄的「媽，怎麼了？」類似句）
- ✅ 你講話 + 停頓 → 聽到下一句不同的輪播
- ✅ 不主動掛斷的話，~90 秒會聽到結束語然後掛斷
- ✅ 通話結束後查 iDempiere 確認 Z_momSystem 寫了一筆

```bash
# Verify iDempiere write
curl -X GET "$IDEMPIERE_BASE_URL/models/Z_momSystem?\$filter=DateDoc%20eq%20'$(date +%Y-%m-%d)'" \
  -H "Authorization: Bearer $IDEMPIERE_TOKEN" | jq '.records[0].Description'
# Expected: contains "陪聊 XXs"
```

- [ ] **Step 2: Schedule-trigger test**

編輯 `schedule.yaml` 把當天當前時間後 2 分鐘加進對應星期的列表。例如今天是星期一 14:32：

```yaml
weekly:
  monday: ["14:34"]    # ← 即時改加一個 slot
  ...
```

存檔，等 1-2 分鐘 → systemd scheduler 應該觸發 outbound call。

```bash
journalctl -u companion-call-scheduler -f
# 14:34 應該看到: "Slot hit 2026-05-XX 14:34, placed call CAxxxxxxxx"
```

接通驗證一樣的 4 點。

驗證完移除測試 slot：

```bash
nano companion-call/schedule.yaml
# 把 monday 改回 []
```

- [ ] **Step 3: Edge cases**

| 測項 | 操作 | 通過標準 |
|---|---|---|
| 不接電話 | 系統打來不接，等 30 秒 | iDempiere log `陪聊未接`，不 retry |
| 接了立刻掛 | 接通後 1 秒內掛掉 | iDempiere log `陪聊 1s(短)` |
| 通話 60s 主動掛斷 | 講話到 60s 自己掛斷 | iDempiere log `陪聊 60s` |
| schedule.yaml 改完即時生效 | 改 yaml 加 1 分鐘後的 slot | 該分鐘有撥出 |
| 同分鐘重複 fire 不會發生 | 一分鐘內 2 次 tick | 只發 1 通 |

- [ ] **Step 4: Tom 親耳聽自己錄的 12 句**

如果有任何一句聽起來不自然 / 太短 / 太大聲 / 雜音 → 重錄該句 → 跑 `audio_convert.py` 替換 → 不需要重啟 service（StaticFiles 自動讀新檔）。

- [ ] **Step 5: 記錄 1 週**

讓系統按週一 *測試 slot* 每天打你 1-2 通 1 週，每天看 iDempiere `Z_momSystem.Description` 有沒有正確寫入。

```bash
# Daily check command
curl -s "$IDEMPIERE_BASE_URL/models/Z_momSystem?\$filter=DateDoc%20eq%20'$(date +%Y-%m-%d)'" \
  -H "Authorization: Bearer $IDEMPIERE_TOKEN" | jq -r '.records[0].Description'
```

通過 1 週 = 系統 stable，可以進 Task 12。

- [ ] **Step 6: No commit**（這個 Task 是驗收，不改 code）

---

## Task 12: Phase 2 production rollout 📋 + ✅

**Pre-conditions:**
- [ ] Task 11 完成（Phase 1 1 週驗收通過）
- [ ] 媽媽 4G 桌上電話安裝完成、SIM 卡有訊號

- [ ] **Step 1: Tom 改 `.env`**

```bash
nano /home/tom/Desktop/dementia-care/whiteboard-ocr-bot/companion-call/.env
# MOM_PHONE_NUMBER=+886<媽媽真實號碼>   ← Tom 自己填，不告訴 chat
```

- [ ] **Step 2: 確認 .env 沒進 git diff**

```bash
cd /home/tom/Desktop/dementia-care
git status companion-call/.env
# Expected: nothing (gitignored)

git diff
# Expected: 沒有任何電話號碼出現
```

- [ ] **Step 3: 重啟 scheduler 讀新 .env**

```bash
sudo systemctl restart companion-call-scheduler
systemctl status companion-call-scheduler
```

- [ ] **Step 4: 第一通 Tom 物理在場**

下一個 schedule slot（例如下個週二 09:00），Tom 站在媽媽旁邊。確認：
- 媽媽電話響、她接得起來
- 她聽到 prompt_01 的反應
- 通話自然進行 → 自動掛斷
- iDempiere 寫了一筆

- [ ] **Step 5: 不在場觀察 ≥ 2 週**

至少跑 2 個完整週期（涵蓋週二/四/日各 2-3 次）。每週看 `Z_momSystem.Description` 行為趨勢：

| 指標 | 怎麼算 |
|---|---|
| 接聽率 | grep `陪聊 [0-9]+s` 行數 ÷ grep `陪聊` 總行數 |
| 平均通話長度 | 每行 `陪聊 XXs` 抽出 XX 平均 |
| 時段分布 | 看哪幾個 HH 接聽率最高 |
| 立刻掛斷比例 | grep `陪聊 [1-4]s\(短\)` ÷ 接聽通數 |

- [ ] **Step 6: 月底回診帶數據**

把 `Z_momSystem` 趨勢圖拿給醫生看（可以從 mom-clinic-companion app 直接 render）。

- [ ] **Step 7: 不需要 commit**

Task 12 是 deployment + observation，所有 code 已就位。

---

## Self-Review (plan 寫完後做)

- [x] **Spec coverage**:
  - §1 背景 → 不需 task（context only）
  - §2 方案 X 選擇 → 不需 task
  - §3 架構 → Task 1, 5, 6, 7
  - §4 檔案結構 → Task 1
  - §5 .env → Task 1
  - §6 12 句音檔 → Task 2, 3
  - §7 iDempiere → Task 4
  - §8 錯誤處理 → Task 5 (twilio_app), Task 11 (E2E test)
  - §9 測試計畫 → Task 11 (Phase 1), Task 12 (Phase 2)
  - §10 月成本 → 不需 task
  - §11 採購 → prerequisites
  - §12 Tom 決定 → 全部 ✅
  - §13 milestones → mapped to Tasks 1-12
  - §14 設計原則 → 內建在 task 設計（不錄音、寧缺勿錯）
  - §15 Secrets 不進 git → Task 1 .env.example + .gitignore + Task 11/12 SOP

- [x] **No placeholders**: 全部 step 都有 actual code / commands

- [x] **Type consistency**:
  - `place_call()` 在 Task 6 / Task 7 / Task 11 名稱一致
  - `upsert_zmomsystem_description(date, line)` Task 4 / Task 5 一致
  - `_state` dict in twilio_app.py: keys `played_count` / `start_time` / `played_indices` / `recent` 一致
  - schedule.yaml schema: weekly / exceptions / defaults 在 Task 6 / Task 7 / spec §3.3 一致

---

## Estimated Timeline

| Task | 預估時間 | 屬性 |
|---|---|---|
| Task 1 scaffold | 30 min | 🔧 |
| Task 2 audio_convert | 1 hr | 🔧 |
| Task 3 audio mapping | 30 min (+ Tom mapping 5 min) | 👤+🔧 |
| Task 4 shared.py | 1.5 hr | 🔧 |
| Task 5 twilio_app | 3 hr | 🔧 |
| Task 6 scheduled_call | 1 hr | 🔧 |
| Task 7 scheduler | 2 hr | 🔧 |
| Task 8 tunnel | 1 hr | 📋 |
| Task 9 startup script | 30 min | 🔧 |
| Task 10 systemd | 1 hr | 📋 |
| Task 11 Phase 1 E2E | 1 週驗收 | ✅ |
| Task 12 Phase 2 rollout | 2 週驗收 | ✅+👤 |

**Pure code work**: ~10 hr，可以一個下午 + 一個晚上做完。
**驗收期**: 共 3 週，但 hands-off 的時間。

---

## Notes for Plan Executor

- **Iron rule reminder**: 永遠在 dev branch 工作，不要 push main
- **Commit cap**: Tom 一天 commit ≤ 20 (CLAUDE.md 規則 2)，本 plan ~12 個 commit，分 2 天做完
- **Do not invoke**: frontend-design / mcp-builder / 其他 implementation skill — 只用 subagent-driven-development 或 executing-plans
- **Secrets reminder**: `.env` 永遠不會出現在 staged files。如果 `git status` 看到 `.env` 在 modified → 立刻停手
- **Existing OCR**: 不能動 `telegram_bot.py` / `ocr_pipeline.py` / `whiteboard_layout.py` 任何一行
- **Test isolation**: 所有測試用 mocked Twilio + mocked iDempiere，**absolutely zero 真實 API 呼叫**。Real calls 只在 Task 11/12 manual run

**End of plan.**
