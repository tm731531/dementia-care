"""Test audio conversion: any input → 8kHz mu-law mono wav."""
import subprocess

import pytest

from companion_call.audio_convert import convert_to_twilio_wav


def _make_silent_aac(path, seconds=1):
    subprocess.run(
        [
            "ffmpeg", "-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono",
            "-t", str(seconds), "-c:a", "aac", str(path), "-y",
        ],
        check=True,
        capture_output=True,
    )


def test_convert_returns_target_path(tmp_path):
    src = tmp_path / "input.aac"
    _make_silent_aac(src)
    dst = tmp_path / "output.wav"

    result = convert_to_twilio_wav(src, dst)

    assert result == dst
    assert dst.exists()
    assert dst.stat().st_size > 0


def test_convert_output_is_8khz_mulaw(tmp_path):
    src = tmp_path / "input.aac"
    _make_silent_aac(src)
    dst = tmp_path / "output.wav"

    convert_to_twilio_wav(src, dst)

    probe = subprocess.run(
        [
            "ffprobe", "-v", "error", "-select_streams", "a:0",
            "-show_entries", "stream=codec_name,sample_rate,channels",
            "-of", "default=noprint_wrappers=1", str(dst),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    assert "codec_name=pcm_mulaw" in probe.stdout
    assert "sample_rate=8000" in probe.stdout
    assert "channels=1" in probe.stdout


def test_convert_missing_input_raises(tmp_path):
    src = tmp_path / "nonexistent.aac"
    dst = tmp_path / "output.wav"
    with pytest.raises(FileNotFoundError):
        convert_to_twilio_wav(src, dst)


def test_batch_convert_renames_per_mapping(tmp_path):
    from companion_call.audio_convert import batch_convert

    src_dir = tmp_path / "src"
    src_dir.mkdir()
    for name in ("a.aac", "b.aac"):
        _make_silent_aac(src_dir / name)

    out_dir = tmp_path / "out"
    mapping = {"a.aac": "prompt_01.wav", "b.aac": "prompt_02.wav"}

    outputs = batch_convert(src_dir=src_dir, mapping=mapping, out_dir=out_dir)

    assert len(outputs) == 2
    assert (out_dir / "prompt_01.wav").exists()
    assert (out_dir / "prompt_02.wav").exists()
