#!/usr/bin/env bash
# 把 companion_call/book/ 下的 .m4a 章節（Tom 給女兒的睡前故事，repurpose 給媽媽聽）
# 轉成 44.1kHz mono PCM wav，ASCII 命名，給 Windows i3 廣播站播放。
#
# 為什麼要 ASCII 命名：PowerShell 對中文檔名 + 空格的 escape 偶爾會炸。
# 原始中文標題會存在 book_index.json 給 Tom 自己 reference。
#
# 跑：
#   bash companion_call/broadcast/convert_book_for_broadcast.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HERE")")"   # whiteboard-ocr-bot/

SRC_DIR="$PROJECT_DIR/companion_call/book"
OUT_DIR="$HERE/book"
INDEX_FILE="$OUT_DIR/book_index.json"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: source dir not found: $SRC_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"
source venv/bin/activate

mkdir -p "$OUT_DIR"

python3 -c "
import json, subprocess
from pathlib import Path

src_dir = Path('$SRC_DIR')
out_dir = Path('$OUT_DIR')
index_file = Path('$INDEX_FILE')

m4a_files = sorted(src_dir.glob('*.m4a'))
print(f'Found {len(m4a_files)} m4a files')

index = {}
for i, src in enumerate(m4a_files, start=1):
    dst_name = f'book_{i:03d}.wav'
    dst = out_dir / dst_name

    subprocess.run([
        'ffmpeg', '-loglevel', 'error',
        '-i', str(src),
        '-ar', '44100',
        '-ac', '1',
        '-c:a', 'pcm_s16le',
        '-y', str(dst),
    ], check=True)

    # Get duration via ffprobe
    dur = subprocess.run([
        'ffprobe', '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        str(dst),
    ], capture_output=True, text=True, check=True).stdout.strip()

    index[dst_name] = {
        'original_name': src.name,
        'duration_sec': float(dur),
    }
    print(f'  ✓ {src.name[:30]:30s} → {dst_name}  ({float(dur):.0f}s)')

with open(index_file, 'w', encoding='utf-8') as f:
    json.dump(index, f, ensure_ascii=False, indent=2)

print()
print(f'Total: {len(index)} chapters, '
      f'{sum(v[\"duration_sec\"] for v in index.values())/60:.0f} min')
print(f'Index saved: {index_file}')
"

echo
echo "下一步：把 $OUT_DIR/ 整個資料夾同步到 Google Drive，"
echo "      在 i3 上拷貝到 C:\\companion-broadcast\\book\\"
