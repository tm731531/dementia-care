# Family Edition — Offline Caregiving Record App — Design Spec

**Date:** 2026-07-23
**Status:** Design approved (brainstorming) — pending spec review → implementation plan
**Author:** Tom + Claude
**Relation:** Family-facing evolution of `whiteboard-ocr-bot`. NOT the same product as the
personal Telegram bot (that stays Tom-only, writes to iDempiere). This is a standalone,
zero-cloud mobile app for OTHER caregiving families.

---

## 1. Why this exists

`whiteboard-ocr-bot` works for Tom only: it needs a Gemini API key, a Telegram bot token,
and a self-hosted iDempiere instance (see `config.py.example` — 12+ values to fill). A real
caregiver friend TRIED it and WANTED it, but gave up on hearing "Tom made it himself" —
the blocker was **not wanting to burden Tom**, not usability and not distrust.

The fix is a **non-personal entry point**: an app the friend downloads from the store, uses
alone, and never has to contact Tom about. That reframes every design constraint below.

---

## 2. Hard constraints (locked during brainstorming)

| # | Constraint | Rationale |
|---|-----------|-----------|
| C1 | **Fully offline. Zero cloud. No server. No account backend.** | Avoids Taiwan PII law liability (medical = special-category PII, §6). Keeps Tom out of the loop → zero "burden Tom" factor. |
| C2 | **Data lives only on the device.** | Same as C1. The app never uploads. |
| C3 | **Minimise typing.** Voice + tap, not keyboard. | The core user need Tom stated: "reduce the hassle of KEYing text; one-and-done." |
| C4 | **Doctor deliverable = readable text + trends, NOT a stack of photos.** | "The doctor can't flip through photos one by one; reading text is faster." |
| C5 | **Distribution = app stores, self-download.** | Non-personal entry point → zero interpersonal-favour cost. |
| C6 | **Field-practical friction only.** No password typing at handoff, no per-record manual transfer, survives fast 外勞 turnover. | Caregiving reality check. |

---

## 3. Evidence base (measured this session — do not re-derive from theory)

### 3.1 Handwriting OCR is NOT viable for the freeform notes
Tested desktop PP-OCRv6 (optimistic upper bound vs a phone model) on a real handwritten
whiteboard photo, scored against a known-correct transcription.

> Privacy note: the measurement used a real patient's caregiving note. The example below is a
> **synthetic, anonymised stand-in** that reproduces the same failure pattern; the accuracy figure
> is the real measured value.

| Correct text (illustrative) | OCR read | Verdict |
|---|---|---|
| 今天**精神**穩定 | 今天**梢神**穩定 | 1 wrong |
| **午餐**吃一半 | **牛餐**吃一半 | 1 wrong |
| 下午在客廳**走一走** | 下午在客廳**足一足** | keyword collapsed |
| **傍晚**量了**血壓** | **停晚**量了**血座** | collapsed |
| 睡得好 | 睡得好 | ok |

- **~61–67% char accuracy, and the errors land on the everyday content words** that carry the
  clinical meaning (an activity/vital-sign word gets swapped for a visually-similar common word).
- The neat, fixed template text on the SAME photo OCR'd near-perfectly (0.95–0.97 confidence)
  — but that text is identical every day and needs no recognition.
- **Conclusion:** OCR is strongest exactly where it is not needed and weakest exactly where
  it is. It violates the project's existing 寧缺勿錯 principle (README.md:55). **Do not build OCR.**
- Cross-checked by two research agents: Apple Vision and Android ML Kit are both printed-text
  engines; neither officially supports handwritten Chinese. Only PaddleOCR is handwriting-trained,
  and even it is tuned for neat writing.

### 3.2 Offline voice-to-text IS viable
Tested `faster-whisper` on real Taiwan-Mandarin audio from the caregiver-course repo
(`ltc-caregiver-notes-2026`), comparing phone-viable model sizes against the large-model transcript.

| Content type | `base` (smallest) | `small` (phone sweet spot, ~180MB quantised) |
|---|---|---|
| Sentence structure / gist | fully preserved | fully preserved |
| Everyday vocabulary | mostly correct | near-perfect |
| Pronouns | occasionally wrong | correct |
| Obscure proper nouns (school names) | wrong | slightly off |

- The failure mode is **obscure proper nouns**, which caregiving notes do not contain.
  The words that matter (activities, vital signs, symptoms, meals, mood) are everyday vocabulary
  → captured well. The OCR failure mode (picking a visually-similar common word) does not
  exist for clear speech, because the language model has strong priors.
- **Conclusion:** the notes input method is **voice → on-device Whisper (`whisper.cpp`, small)**,
  not OCR.

---

## 4. The design

### 4.1 Platform / substrate
- **Flutter, single codebase, iOS + Android.** Researched: choosing Flutter does NOT drop any
  capability that matters here — the missing capability (offline handwritten-Chinese OCR) is
  absent from native engines too, so two native apps would cost double for the same result.
  `camera` plugin wraps CameraX / AVFoundation (no loss for a "photograph a whiteboard" flow).
- Fully offline, local-only storage, no account backend, no server.
- Published to App Store + Play Store; users self-download.

### 4.2 Input — kill typing
- **Event notes → VOICE.** User speaks the day's events; on-device `whisper.cpp` (small model,
  bundled, runs with zero network) transcribes; user may lightly edit. Multiple notes per day allowed.
- **12 structured items** (夜間活動 / 睡眠 / 三餐 / 排泄 …) → **TAP options in-app.** Not typed,
  not OCR'd. 100% accurate, and this structured data is what drives the trend charts for the doctor.
- **Whiteboard photo → OPTIONAL per record**, kept as an audit backup ("phone is big enough").

### 4.3 Data model (makes multi-writer merge trivial)
- **Event notes** = an append-only list of entries, each with `{id, timestamp, author, text, photo?}`.
- **Structured items** = one value per field per date, each tagged `{author, timestamp}`.
- **Photos** = attachments with stable `id`.
- Author tag distinguishes 家屬 vs 外勞 entries so the doctor (and the merge) can tell them apart.

### 4.4 Output
- **① Data file (primary): ZIP export** containing the record JSON + photos.
  - Family taps "export" → OS share sheet / file → user sends it by **whatever channel THEY prefer**
    (LINE / USB / AirDrop — the app does not choose or own the channel).
  - Recipient taps "import" → merges into their local store (see 4.5).
  - Transfer is **occasional (once before a clinic visit)**, NOT per-record. Daily recording is
    purely local with zero transfer.
- **② Doctor file (secondary): single-file HTML (or PDF)** with trend charts + clean notes text +
  photos. Opens in any browser on any device with **no app install** — a fallback for whoever
  ends up in the clinic. (Single-file, offline, zero-dependency — matches the monorepo house style.)

### 4.5 Merge (v1 — light by construction)
The v1 flow: family (primary recorder) → exports ZIP → 外勞 imports into their phone → 外勞's phone
holds family's records + 外勞's own → 外勞 shows the combined view to the doctor. **One-directional**
(family → 外勞); no bidirectional/continuous sync in v1.

Because of the data model:
- **Notes & photos merge by union** (dedup by `id`) — no conflict, this is just concatenation.
- **Structured items**: if both wrote the same field on the same date, **newer timestamp wins**,
  and the author tag is preserved. This one simple rule is the entire conflict logic.
- No heavy conflict-resolution engine. Continuous/bidirectional sync deferred to a later version.

### 4.6 Security (friction-minimal — revised after field-practicality pushback)
Threat model: an opportunistic bystander picks up the phone (e.g. while the owner is away) and
should not see the patient's PII. NOT a forensic nation-state attacker.

- **App unlock = biometric only (Face / fingerprint).** No password typing in daily use (like a
  banking app). App **auto-locks on backgrounding / idle**. This covers the bystander threat.
- **At-rest encryption** of the local DB + photos, keyed by a secret in the OS secure enclave
  (Keychain / Keystore) released by biometric. User never types or manages a password.
- **No server ⇒ no account, no "forgot password", no remote reset.** Because there is no
  user-typed password (biometric + hardware key), there is nothing to forget and no data-loss trap.
- **ZIP export = NOT password-protected by default.** Rationale: (a) no password typing at handoff;
  (b) new 外勞 phones import with zero setup — no pairing to break on fast turnover; (c) the
  transfer channel is the user's own choice (Tom: "sending via LINE is their chosen way; USB is
  fine too; not my call"). Residual accepted risk: a plaintext ZIP passing through LINE is visible
  to LINE. Consistent with the user's data-privacy stance (assume anything sent to a cloud channel
  may be seen). An **optional "encrypt this ZIP" toggle** exists for when extra protection is wanted,
  off by default to keep zero friction.

### 4.7 Explicitly NOT built (discipline)
- No handwriting OCR (measured 61–67%, errors on keywords).
- No cloud, no sync server, no account system.
- No heavy multi-writer conflict engine (data model makes it unnecessary in v1).
- No per-record file transfer; no password typing anywhere.

---

## 5. Open items for the user before/at implementation
- **Sub-project placement — DECIDED (2026-07-23):** lives as monorepo sub-project #16 at
  `dementia-care/care-record-app/`, listed as a card on the monorepo `index.html`. Tom explicitly
  overrode 規則 1's blog-first sub-rule (open now, blog later) — recorded in `dementia-care/CLAUDE.md`
  footnote. It is the monorepo's 2nd technical exception (Flutter native app; the 1st is the Python
  `whiteboard-ocr-bot`). The app itself is NOT deployed by GitHub Pages — only its landing card is.
- **Whisper model size** to bundle: `small` (~180MB quantised) is the recommended sweet spot; can be
  revisited against app-size limits during implementation.

---

## 6. Appendix — reproducing the measurements
- OCR test: `scratchpad/run_ocr_test2.py` (PaddleOCR 3.7.0 / PP-OCRv6, `enable_mkldnn=False`),
  input `/home/tom/.ccbot/images/1784766449_...jpg` (7/21 board), ground truth = iDempiere 7/21 note.
- STT test: `scratchpad/whisper_small_test.py` (`faster-whisper` 1.2.1 at `~/whisper-venv`), input =
  70s clip from `ltc-caregiver-notes-2026/2026-07-19/VOICE/719.4.m4a` (offset 600s), reference =
  `719.4.txt` (large-model transcript).
