#!/usr/bin/env python3
# ===============================================================
# RC25S_YOUTUBE_REFLECTOR
# ---------------------------------------------------------------
# 🎬 YouTube URL → Whisper (transcription) → RC25S Reflection Engine
# 작동 방식:
#   1. yt-dlp로 영상 또는 자막 자동 다운로드
#   2. Whisper로 음성 → 텍스트 변환
#   3. RC25S LLM (rc25s_openai_wrapper)으로 의미 분석
#   4. insight / emotion / goal / confidence 생성 및 저장
# ===============================================================

import datetime
import json
import os
import subprocess
from pathlib import Path

from rc25s_openai_wrapper import rc25s_chat

BASE_DIR = Path("/srv/repo/vibecoding")
OUT_DIR = BASE_DIR / "memory_store"
OUT_DIR.mkdir(exist_ok=True)


def run_cmd(cmd):
    """시스템 명령어 실행 (출력 캡처 포함)"""
    print(f"[⚙️] Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[❌] Command failed: {result.stderr}")
    return result.stdout.strip()


def download_youtube(url):
    """YouTube 자막 또는 오디오 추출"""
    print(f"[🎬] Fetching YouTube video: {url}")
    run_cmd(
        [
            "yt-dlp",
            "--write-auto-subs",
            "--sub-lang",
            "en,ko",
            "--skip-download",
            "-o",
            "video",
            url,
        ]
    )

    if Path("video.ko.vtt").exists():
        sub_file = "video.ko.vtt"
    elif Path("video.en.vtt").exists():
        sub_file = "video.en.vtt"
    else:
        print("[⚠️] No subtitles found, downloading audio for Whisper...")
        run_cmd(["yt-dlp", "-x", "--audio-format", "mp3", "-o", "audio.mp3", url])
        run_cmd(["whisper", "audio.mp3", "--model", "small", "--output_format", "txt"])
        sub_file = "audio.txt"

    with open(sub_file, "r", encoding="utf-8") as f:
        text = f.read()
    print(f"[🗒️] Transcript length: {len(text)} chars")
    return text


def analyze_with_reflection_engine(text, url):
    """RC25S OpenAI Wrapper를 통해 의미 분석"""
    prompt = f"""
You are RC25S Reflection Engine.
Analyze the following transcript extracted from a YouTube video and return a structured JSON with:
- insight (핵심 통찰)
- emotional_tone (감정 톤)
- improvement_goal (시스템/인간적 개선 포인트)
- confidence (0~1)
- summary (짧은 요약)

Transcript:
{text[:8000]}
"""

    print("[🧠] Sending to RC25S LLM for reflection...")
    response = rc25s_chat(prompt)
    result = {
        "url": url,
        "timestamp": datetime.datetime.now().isoformat(),
        "analysis": response,
    }

    out_file = OUT_DIR / f"youtube_reflection_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"[✅] Reflection saved to {out_file}")
    return out_file


def main():
    import argparse

    parser = argparse.ArgumentParser(description="RC25S YouTube Reflection Engine")
    parser.add_argument("url", help="YouTube video URL")
    args = parser.parse_args()

    text = download_youtube(args.url)
    output = analyze_with_reflection_engine(text, args.url)
    print(f"\n🎯 Done! Insight file: {output}\n")


if __name__ == "__main__":
    main()

