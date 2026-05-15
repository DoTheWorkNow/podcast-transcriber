#!/bin/bash
# 火山引擎 BigModel ASR 提交 + 轮询 (独立版)
set -e

AUDIO_URL="${1:?用法: asr_submit.sh <audio_url> [speaker_diarization]}"
DIARIZATION="${2:-true}"

# 加载凭证
load_credentials() {
  for f in \
    "$SCRIPT_DIR/../config/credentials.env" \
    "$HOME/.podcast-transcriber/credentials.env" \
  ; do
    if [ -f "$f" ]; then source "$f" 2>/dev/null && return 0; fi
  done
  return 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
load_credentials || true

ASR_ENDPOINT="${VOLC_ASR_ENDPOINT:-https://openspeech.bytedance.com/api/v3/auc/bigmodel/submit}"
ASR_QUERY="${VOLC_ASR_QUERY:-https://openspeech.bytedance.com/api/v3/auc/bigmodel/query}"

if [ -z "$VOLC_ASR_KEY" ]; then
  echo "ERROR: 缺少 VOLC_ASR_KEY" >&2
  echo "请在 config/credentials.env 中配置" >&2
  exit 1
fi

TASK_ID=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
echo "[asr] Task: $TASK_ID"

# 提交
echo "[asr] 提交识别任务..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$ASR_ENDPOINT" \
  -H 'Content-Type: application/json' \
  -H "X-Api-Key: $VOLC_ASR_KEY" \
  -H "X-Api-Resource-Id: ${VOLC_ASR_RESOURCE_ID:-volc.seedasr.auc}" \
  -H "X-Api-Request-Id: $TASK_ID" \
  -H 'X-Api-Sequence: -1' \
  -d "{
 \"user\": {\"uid\": \"podcast-transcriber\"},
 \"audio\": {\"url\": \"$AUDIO_URL\", \"format\": \"mp3\"},
 \"request\": {
   \"model_name\": \"bigmodel\",
   \"enable_itn\": true,
   \"enable_punc\": true,
   \"enable_ddc\": true,
   \"enable_speaker_info\": $DIARIZATION,
   \"show_utterances\": true,
   \"vad_segment\": true
 }
}")

if [ "$STATUS" != "200" ]; then
  echo "[asr] ❌ 提交失败 HTTP $STATUS" >&2; exit 1
fi
echo "[asr] ✅ 已提交"

# 轮询
for i in $(seq 1 40); do
  sleep 20
  RESULT=$(curl -s -X POST "$ASR_QUERY" \
    -H 'Content-Type: application/json' \
    -H "X-Api-Key: $VOLC_ASR_KEY" \
    -H "X-Api-Resource-Id: ${VOLC_ASR_RESOURCE_ID:-volc.seedasr.auc}" \
    -H "X-Api-Request-Id: $TASK_ID" \
    -d '{}')
  
  TEXT_LEN=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('result',{}).get('text','')))" 2>/dev/null || echo "0")
  
  if [ "$TEXT_LEN" -gt 0 ]; then
    echo "$RESULT" > /tmp/asr_result.json
    echo "[asr] ✅ 完成 (${i}轮, ${TEXT_LEN}字)"
    exit 0
  fi
  echo "[asr] 等待... ($i/40)"
done

echo "[asr] ❌ 超时" >&2; exit 1
