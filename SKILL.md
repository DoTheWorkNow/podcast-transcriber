---
name: podcast-transcriber
description: >
  Transcribe podcasts, videos, and audio from any platform into structured Markdown transcripts with speaker diarization.
  Supports Bilibili, YouTube, Xiaoyuzhou FM, and direct audio links. Uses Volcengine BigModel ASR for long audio (over 25MB)
  and speaker diarization, Groq Whisper as free fallback for short audio.

  Triggers: When user shares a podcast/video URL and asks to transcribe, or "转文字", "逐字稿", "文字稿", "转录",
  "把这个播客转成文字", "提取字幕", "做逐字稿".
---

# Podcast Transcriber

一键播客/视频转录，支持说话人分离。

## Quick Start

```bash
# 1. 环境检测
bash scripts/setup.sh

# 2. 配置凭证
cp config/credentials.env.example config/credentials.env
# 编辑 credentials.env 填入火山引擎 API Key + TOS AK/SK

# 3. 使用
bash scripts/transcribe.sh "https://www.bilibili.com/video/BVxxx"

# 带说话人分离 + 自定义标题
bash scripts/transcribe.sh "URL" \
  --speaker-diarization \
  --title "播客标题" \
  --output ./transcripts \
  --speaker-names '{"1":"主持人","2":"嘉宾"}'
```

## Supported Platforms

| Platform | URL Pattern | Method |
|----------|-------------|--------|
| Bilibili | bilibili.com/video/ | yt-dlp |
| YouTube | youtube.com/watch | yt-dlp |
| Xiaoyuzhou FM | xiaoyuzhoufm.com/episode/ | HTML scrape |
| Direct Audio | .mp3 .m4a .wav | curl |

## Engine Routing

| File Size | Diarization | Engine |
|-----------|-------------|--------|
| below 25MB | no | Groq Whisper |
| below 25MB | yes | Volcengine BigModel |
| over 25MB | any | Volcengine BigModel |

## Output

- Speaker-labeled Markdown (🎤/🎙️/👤)
- Default output directory: current directory (use `--output` to change)

## Pipeline

```
URL → download → engine select → (TOS upload → ASR submit → poll → format) → save
```

## Dependencies

- Python 3 + `tos` package (`pip3 install tos`)
- ffmpeg (audio conversion)
- yt-dlp (Bilibili/YouTube, auto-installed if missing)

## Credentials

See `config/credentials.env.example`. Requires:

| Key | Purpose | Console |
|-----|---------|---------|
| VOLC_ASR_KEY | Volcengine BigModel ASR | [console](https://console.volcengine.com/speech/) |
| VOLC_TOS_AK/SK | Object Storage upload | [console](https://console.volcengine.com/iam/keymanage/) |
| GROQ_API_KEY | Groq Whisper fallback | [console](https://console.groq.com/keys) |

## File Structure

- `scripts/transcribe.sh` — main entry point
- `scripts/download.sh` — platform download layer
- `scripts/upload_tos.py` — TOS upload + presigned URL
- `scripts/asr_submit.sh` — Volcengine BigModel submit + poll
- `scripts/format_output.py` — utterances → Markdown with speakers
- `scripts/save_output.sh` — output routing
- `scripts/setup.sh` — environment check + install guide
- `config/credentials.env.example` — credential template
- `references/volcengine-asr.md` — Volcengine ASR API reference
