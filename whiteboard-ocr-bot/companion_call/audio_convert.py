"""Convert any audio input to Twilio-compatible 8kHz mu-law mono wav."""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Mapping


def convert_to_twilio_wav(src: Path, dst: Path) -> Path:
    """ffmpeg wrap: any audio → 8 kHz mu-law mono wav (Twilio format).

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
    subprocess.run(
        [
            "ffmpeg",
            "-i", str(src),
            "-ar", "8000",          # 8 kHz sample rate
            "-ac", "1",             # mono
            "-c:a", "pcm_mulaw",    # mu-law codec
            "-y",                   # overwrite
            str(dst),
        ],
        check=True,
        capture_output=True,
    )
    return dst


def batch_convert(
    src_dir: Path,
    mapping: Mapping[str, str],
    out_dir: Path,
) -> list[Path]:
    """Convert multiple files via mapping.

    Args:
        src_dir: where source files live
        mapping: {"voice_472115.aac": "prompt_01.wav", ...}
        out_dir: where converted wavs go

    Returns:
        list of output paths
    """
    src_dir = Path(src_dir)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    outputs = []
    for src_name, dst_name in mapping.items():
        src = src_dir / src_name
        dst = out_dir / dst_name
        convert_to_twilio_wav(src, dst)
        outputs.append(dst)
    return outputs
