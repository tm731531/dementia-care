# Recording specs

- **Format**: any input (m4a / aac / mp3 / wav) — `audio_convert.py` 會轉成 8kHz mu-law wav
- **Filename (after conversion)**: `prompt_01.wav` ~ `prompt_12.wav`
- **Length**: 1-3 seconds per clip
- **Tone**: 自然語氣，不要播報腔
- **Environment**: 安靜、無風扇雜音

## Prompt content (可以自然口氣，不必逐字)

| # | Role | 大致內容 |
|---|---|---|
| 01 | 開場 | 媽，怎麼了？ |
| 02-10, 12 | 輪播 | 各種「怎麼了」「什麼事」「我聽你說」變體 |
| 11 | 結束（特殊位置） | 媽，我先去忙喔，等等再打給你 |

`*.wav` `*.mp3` 在 `.gitignore`，不會推上 GitHub。
