#!/bin/bash
# 结果存储路由
set -e
MD_FILE="${1:?用法: save_output.sh <markdown_file> [title] [output_dir]}"
TITLE="${2:-播客转录}"
OUTPUT_DIR="${3:-.}"

FILENAME="${TITLE//\//-}.md"

mkdir -p "$OUTPUT_DIR"
# ditto 在 macOS 上能穿透 iCloud Drive 等受限路径的写权限；非 macOS / ditto 失败时回落到 cp
ditto "$MD_FILE" "$OUTPUT_DIR/$FILENAME" 2>/dev/null || cp "$MD_FILE" "$OUTPUT_DIR/$FILENAME"
echo "[save] ✅ $OUTPUT_DIR/$FILENAME"
