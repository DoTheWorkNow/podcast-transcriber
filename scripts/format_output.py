#!/usr/bin/env python3
"""格式化火山 BigModel ASR 结果 → 说话人分离 Markdown"""
import json, sys, os
from datetime import datetime

def format_transcript(result_path, title="播客转录", source_url="", speakers_map=None):
    """speakers_map: {'1': '主持人', '2': '嘉宾'}"""
    with open(result_path) as f:
        d = json.load(f)
    
    utts = d['result'].get('utterances', [])
    if not utts:
        print("ERROR: 无识别结果", file=sys.stderr)
        sys.exit(1)

    duration_sec = d.get('audio_info', {}).get('duration', 0) / 1000
    total_chars = len(d['result'].get('text', ''))
    total_utts = len(utts)

    # 自动映射 speaker
    if speakers_map is None:
        speakers_map = {'1': '主持人', '2': '嘉宾', '3': '其他'}
    
    # 统计说话人分布
    speaker_count = {}
    for u in utts:
        sid = str(u.get('additions', {}).get('speaker', '?'))
        speaker_count[sid] = speaker_count.get(sid, 0) + 1
    
    # 生成 Markdown
    lines = []
    lines.append("---")
    lines.append(f"title: {title} · 完整逐字稿（说话人分离）")
    lines.append(f"source: {source_url}")
    lines.append(f"transcribed_at: {datetime.now().isoformat()}")
    lines.append(f"duration_min: {duration_sec/60:.0f}")
    lines.append(f"total_chars: {total_chars}")
    lines.append(f"total_utterances: {total_utts}")
    lines.append(f"asr_engine: 火山引擎豆包语音 BigModel（Seed ASR）")
    sp_labels = ", ".join(f"Speaker{k}={speakers_map.get(k, k)}" for k in sorted(speaker_count.keys()))
    lines.append(f"speakers: {sp_labels}")
    lines.append("---")
    lines.append("")
    lines.append(f"# {title} · 完整逐字稿")
    lines.append("")
    lines.append(f"> **说话人分离版** · 火山引擎豆包语音 BigModel 转录")
    lines.append(f"> 时长 {duration_sec/60:.0f} 分钟 · {total_chars:,} 字 · {total_utts} 分句")
    lines.append(f"> 来源：{source_url}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # 分组输出
    emoji_map = {'1': '🎤', '2': '🎙️', '3': '👤'}
    current_speaker = None
    buffer = ""

    for u in utts:
        sid = str(u.get('additions', {}).get('speaker', '?'))
        text = u['text'].strip()
        if not text:
            continue
        
        label = speakers_map.get(sid, f"Speaker{sid}")
        emoji = emoji_map.get(sid, '👤')
        heading = f"### {emoji} {label}"
        
        if sid != current_speaker:
            if buffer:
                lines.append(buffer)
                lines.append("")
            current_speaker = sid
            start_ms = u.get('start_time', 0)
            ts = f"{start_ms//60000:02d}:{(start_ms//1000)%60:02d}"
            buffer = f"\n{heading}  `{ts}`\n\n{text}"
        else:
            buffer += text

    if buffer:
        lines.append(buffer)

    # 统计
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## 📊 转录统计")
    lines.append("")
    lines.append(f"| 说话人 | 分句数 |")
    lines.append(f"|--------|--------|")
    for sid, count in sorted(speaker_count.items(), key=lambda x: -x[1]):
        label = speakers_map.get(sid, f"Speaker{sid}")
        emoji = emoji_map.get(sid, '👤')
        lines.append(f"| {emoji} {label} | {count} |")
    lines.append("")
    lines.append(f"- 总字符数：{total_chars:,}")
    lines.append(f"- 音频时长：{duration_sec/60:.0f} 分钟")
    lines.append(f"- 转录引擎：火山引擎豆包语音 BigModel（Seed ASR）")
    lines.append(f"- 转录时间：{datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append("")

    return '\n'.join(lines)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('result_json', help='ASR 结果 JSON 路径')
    parser.add_argument('--title', default='播客转录')
    parser.add_argument('--source-url', default='')
    parser.add_argument('--speaker-names', help='说话人名称映射 JSON，如 \'{"1":"罗永浩","2":"李想"}\'')
    args = parser.parse_args()

    speakers = None
    if args.speaker_names:
        speakers = json.loads(args.speaker_names)
    
    md = format_transcript(args.result_json, args.title, args.source_url, speakers)
    print(md)
