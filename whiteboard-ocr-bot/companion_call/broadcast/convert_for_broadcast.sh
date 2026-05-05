#!/usr/bin/env bash
# 把 Tom 原始 .aac 錄音轉成 44.1kHz 16-bit PCM wav (給 Windows SoundPlayer 用)。
# 跟 companion_call/audio/ 下的 8kHz mu-law (Twilio 規格) 不同，這份是高品質喇叭播放規格。
#
# 跑：
#   bash companion_call/broadcast/convert_for_broadcast.sh
#
# 輸出：companion_call/broadcast/audio/prompt_01.wav ~ prompt_12.wav

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HERE")")"   # whiteboard-ocr-bot/

SRC_DIR="${SRC_DIR:-/home/tom/Desktop/recordings}"
MAPPING="$PROJECT_DIR/companion_call/audio/_mapping.yaml"
OUT_DIR="$HERE/audio"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: source dir not found: $SRC_DIR" >&2
    echo "Override with SRC_DIR=/path/to/aac/files bash $0" >&2
    exit 1
fi

if [ ! -f "$MAPPING" ]; then
    echo "ERROR: mapping not found: $MAPPING" >&2
    exit 1
fi

cd "$PROJECT_DIR"
source venv/bin/activate

mkdir -p "$OUT_DIR"

python3 -c "
import subprocess, yaml
from pathlib import Path

src_dir = Path('$SRC_DIR')
out_dir = Path('$OUT_DIR')
mapping = yaml.safe_load(open('$MAPPING'))['mapping']

for src_name, dst_name in mapping.items():
    src = src_dir / src_name
    dst = out_dir / dst_name
    if not src.exists():
        print(f'  ⚠️  skip (missing): {src_name}')
        continue
    subprocess.run([
        'ffmpeg', '-loglevel', 'error',
        '-i', str(src),
        '-ar', '44100',
        '-ac', '1',
        '-c:a', 'pcm_s16le',
        '-y', str(dst),
    ], check=True)
    print(f'  ✓ {src_name} → {dst_name}')
"

echo
echo "Done. Output:"
ls -la "$OUT_DIR"/prompt_*.wav | head -15
echo
echo "下一步: 把 $OUT_DIR/ 整個資料夾同步到 Google Drive，"
echo "      在 i3 上拷貝到 C:\\companion-broadcast\\audio\\"
