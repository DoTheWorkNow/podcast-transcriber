#!/bin/bash
# podcast-transcriber 环境检测 + 依赖安装引导
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

check() { command -v "$1" &>/dev/null && echo "  ✅ $1" || echo "  ❌ $1 (需要安装)"; }

echo "podcast-transcriber 环境检测"
echo "═══════════════════════════════════════════"

echo "系统工具:"
check python3
check ffmpeg
check curl

echo ""
echo "Python 依赖:"
python3 -c "import tos" 2>/dev/null && echo "  ✅ tos" || echo "  ❌ tos → pip3 install tos"

echo ""
echo "可选:"
check yt-dlp || echo "  → pip3 install yt-dlp (B站/YouTube 下载需要)"

echo ""
echo "凭证:"
if [ -f "$SCRIPT_DIR/../config/credentials.env" ]; then
  source "$SCRIPT_DIR/../config/credentials.env" 2>/dev/null || true
  [ -n "$VOLC_ASR_KEY" ] && echo "  ✅ VOLC_ASR_KEY" || echo "  ⚠️ VOLC_ASR_KEY 未设置"
  [ -n "$VOLC_TOS_AK" ] && echo "  ✅ VOLC_TOS_AK" || echo "  ⚠️ VOLC_TOS_AK 未设置"
  [ -n "$GROQ_API_KEY" ] && echo "  ✅ GROQ_API_KEY" || echo "  ⚠️ GROQ_API_KEY 未设置 (短音频 fallback)"
else
  echo "  ❌ config/credentials.env 不存在"
  echo "  → cp config/credentials.env.example config/credentials.env 并填写凭证"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "快速修复:"
echo "  pip3 install tos yt-dlp"
echo "  brew install ffmpeg"
echo "  cp config/credentials.env.example config/credentials.env"
