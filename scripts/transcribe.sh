#!/bin/bash
# podcast-transcriber 主入口 (独立版)
# 用法: transcribe.sh <URL> [--speaker-diarization] [--title 标题] [--output 目录] [--speaker-names '{"1":"甲","2":"乙"}']
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载凭证
for f in "$SCRIPT_DIR/../config/credentials.env" "$HOME/.podcast-transcriber/credentials.env"; do
  if [ -f "$f" ]; then source "$f" 2>/dev/null; fi
done

URL=""; DIARIZATION="true"; TITLE=""; OUTPUT="."; SPEAKER_NAMES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --speaker-diarization) DIARIZATION="true" ;;
    --no-diarization) DIARIZATION="false" ;;
    --title) TITLE="$2"; shift ;;
    --output) OUTPUT="$2"; shift ;;
    --speaker-names) SPEAKER_NAMES="$2"; shift ;;
    --help|-h)
      echo "用法: $0 <URL> [选项]"
      echo "  --speaker-diarization    开启说话人分离 (默认开启)"
      echo "  --no-diarization         关闭说话人分离"
      echo "  --title 标题             输出文件标题"
      echo "  --output 目录            输出目录 (默认当前目录)"
      echo "  --speaker-names JSON     说话人名称映射 '{\"1\":\"主持人\",\"2\":\"嘉宾\"}'"
      exit 0 ;;
    *) URL="$1" ;;
  esac
  shift
done

[ -z "$URL" ] && { echo "用法: $0 <URL>" >&2; exit 1; }

echo "═══════════════════════════════════════════"
echo "🎙️  podcast-transcriber"
echo "═══════════════════════════════════════════"

AUDIO_FILE=/tmp/podcast_audio.mp3
AUDIO_KEY=$(basename "$AUDIO_FILE")

# Step 1: 下载
echo "── 1. 下载 ──"
bash "$SCRIPT_DIR/download.sh" "$URL" "$AUDIO_FILE"

# Step 2: 引擎选择
SIZE_MB=$(ls -l "$AUDIO_FILE" | awk '{print int($5/1024/1024)}')
echo "── 2. 引擎选择 (${SIZE_MB}MB, diarization=$DIARIZATION) ──"

if [ "$SIZE_MB" -lt 25 ] && [ "$DIARIZATION" = "false" ] && [ -n "$GROQ_API_KEY" ]; then
  echo "引擎: Groq Whisper (短音频，免费)"
  curl -s https://api.groq.com/openai/v1/audio/transcriptions \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -F "file=@$AUDIO_FILE" \
    -F "model=whisper-large-v3-turbo" \
    -F "response_format=text" \
    -F "language=zh" \
    -o /tmp/groq_transcript.txt
  python3 -c "
import datetime
text = open('/tmp/groq_transcript.txt').read()
print(f'---\ntitle: $TITLE\nsource: $URL\ntranscribed_at: {datetime.datetime.now().isoformat()}\nasr: Groq Whisper\n---\n\n# $TITLE\n\n{text}')
" > /tmp/transcript_output.md
else
  if [ "$DIARIZATION" = "true" ]; then
    echo "引擎: 火山 BigModel (说话人分离)"
  else
    echo "引擎: 火山 BigModel"
  fi

  # Step 3: TOS 上传
  echo "── 3. TOS 上传 ──"
  PRESIGNED_URL=$(python3 "$SCRIPT_DIR/upload_tos.py" "$AUDIO_FILE" --key "$AUDIO_KEY")

  # Step 4: ASR
  echo "── 4. ASR 识别 ──"
  bash "$SCRIPT_DIR/asr_submit.sh" "$PRESIGNED_URL" "$DIARIZATION"

  # Step 5: 清理 TOS
  echo "── 5. 清理 TOS ──"
  TOS_KEY="$AUDIO_KEY" python3 -c "
import os, sys
from tos import TosClientV2
ak = os.environ.get('VOLC_TOS_AK', '')
sk = os.environ.get('VOLC_TOS_SK', '')
bucket = os.environ.get('VOLC_TOS_BUCKET', '')
key = os.environ.get('TOS_KEY', '')
if not (ak and sk and bucket and key):
    sys.exit(0)
c = TosClientV2(ak, sk,
    endpoint=os.environ.get('VOLC_TOS_ENDPOINT', 'tos-cn-beijing.volces.com'),
    region=os.environ.get('VOLC_TOS_REGION', 'cn-beijing'))
c.delete_object(bucket=bucket, key=key)
print(f'TOS 已清理: {key}')
"
  
  # Step 6: 格式化
  echo "── 6. 格式化 ──"
  FORMAT_ARGS="--source-url \"$URL\""
  [ -n "$TITLE" ] && FORMAT_ARGS="$FORMAT_ARGS --title \"$TITLE\""
  [ -n "$SPEAKER_NAMES" ] && FORMAT_ARGS="$FORMAT_ARGS --speaker-names '$SPEAKER_NAMES'"
  eval "python3 $SCRIPT_DIR/format_output.py /tmp/asr_result.json $FORMAT_ARGS" > /tmp/transcript_output.md
fi

# Step 7: 存储
echo "── 7. 存储 ──"
[ -z "$TITLE" ] && TITLE="播客转录"
bash "$SCRIPT_DIR/save_output.sh" /tmp/transcript_output.md "$TITLE" "$OUTPUT"

# 清理
rm -f "$AUDIO_FILE" /tmp/groq_transcript.txt /tmp/asr_result.json /tmp/transcript_output.md

echo "✅ 完成: $OUTPUT/${TITLE//\//-}.md"
