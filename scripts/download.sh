#!/bin/bash
# 播客/视频音频下载层 (独立版，不依赖 agent-reach)
set -e
URL="${1:?用法: download.sh <URL>}"
OUTPUT="${2:-/tmp/podcast_audio.mp3}"

detect_platform() {
  case "$1" in
    *bilibili.com/video/*|*b23.tv/*)    echo "bilibili" ;;
    *youtube.com/watch*|*youtu.be/*)     echo "youtube" ;;
    *xiaoyuzhoufm.com/episode/*)         echo "xiaoyuzhou" ;;
    *.mp3|*.m4a|*.wav|*.ogg|*.aac|*.flac) echo "direct" ;;
    *)                                   echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform "$URL")
echo "[download] 平台: $PLATFORM"

case "$PLATFORM" in
  bilibili|youtube)
    if ! command -v yt-dlp &>/dev/null; then
      echo "[download] yt-dlp 未安装，正在安装..."
      pip3 install yt-dlp -q
    fi
    yt-dlp -f "worstaudio[ext=m4a]/worstaudio" \
      --extract-audio --audio-format mp3 --audio-quality 64K \
      -o "$OUTPUT" "$URL" --no-progress 2>&1 | tail -3
    ;;
  xiaoyuzhou)
    EP_HTML=$(curl -sL "$URL" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
    AUDIO_URL=$(echo "$EP_HTML" | grep -oP 'https://[^"]+\.(mp3|m4a|aac)[^"]*' | head -1)
    [ -z "$AUDIO_URL" ] && AUDIO_URL=$(echo "$EP_HTML" | grep -oP 'property="og:audio"[^>]+content="([^"]+)"' | grep -oP 'https://[^"]+\.(mp3|m4a|aac)[^"]*' | head -1)
    if [ -z "$AUDIO_URL" ]; then
      echo "[download] 小宇宙音频提取失败" >&2; exit 1
    fi
    curl -sL -o "$OUTPUT" "$AUDIO_URL" -H "User-Agent: Mozilla/5.0"
    ;;
  direct)
    curl -sL -o "$OUTPUT" "$URL" -H "User-Agent: Mozilla/5.0"
    ;;
  *)
    if command -v yt-dlp &>/dev/null; then
      yt-dlp -f "worstaudio[ext=m4a]/worstaudio" --extract-audio --audio-format mp3 --audio-quality 64K -o "$OUTPUT" "$URL" --no-progress 2>&1 | tail -3
    else
      echo "[download] 无法识别平台且 yt-dlp 未安装" >&2; exit 1
    fi
    ;;
esac

if [ -f "$OUTPUT" ]; then
  SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
  DURATION=$(ffprobe -i "$OUTPUT" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null | cut -d. -f1)
  echo "[download] ✅ $OUTPUT ($SIZE, ${DURATION}s)"
else
  echo "[download] ❌ 下载失败" >&2; exit 1
fi
