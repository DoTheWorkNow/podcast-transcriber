#!/bin/bash
# 构建 podcast-transcriber.skill 分发包
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
STAGE="$DIST/podcast-transcriber"
OUTPUT="$DIST/podcast-transcriber.skill"

rm -rf "$STAGE" "$OUTPUT"
mkdir -p "$STAGE/config"

cp "$ROOT/SKILL.md" "$STAGE/"
cp -r "$ROOT/scripts" "$STAGE/"
cp -r "$ROOT/references" "$STAGE/"
cp "$ROOT/config/credentials.env.example" "$STAGE/config/"

cd "$DIST"
zip -qr "$OUTPUT" podcast-transcriber/
rm -rf "$STAGE"

SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
echo "✅ Built: $OUTPUT ($SIZE)"
echo ""
echo "安装到 Claude Code:"
echo "  cp $OUTPUT ~/.claude/skills/"
