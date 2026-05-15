# podcast-transcriber

> 一键把 **B 站 / YouTube / 小宇宙 / 直链音频** 转成带说话人分离的 Markdown 逐字稿。
> A Claude Code Skill for one-command podcast/video transcription with speaker diarization.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://docs.claude.com/claude-code)

## 这是什么

一个独立可运行的 Bash + Python 流水线，也可以打包成 Claude Code Skill。
丢一个 URL 进去，吐一个排版漂亮的 `.md` 出来，自带说话人分离、时间戳和统计。

```
URL  →  download  →  engine select  →  TOS upload  →  ASR submit  →  poll  →  format  →  .md
                          │
                          └─ < 25MB & no diar.  →  Groq Whisper
                          └─ otherwise          →  火山 BigModel
```

## 支持平台

| Platform | URL Pattern | Method |
|----------|-------------|--------|
| Bilibili | `bilibili.com/video/` | `yt-dlp` |
| YouTube | `youtube.com/watch` | `yt-dlp` |
| 小宇宙 | `xiaoyuzhoufm.com/episode/` | HTML scrape |
| Direct | `.mp3 .m4a .wav .ogg .aac .flac` | `curl` |

## 引擎选路

| 文件大小 | 说话人分离 | 引擎 |
|---------|----------|------|
| < 25MB  | 否       | Groq Whisper |
| < 25MB  | 是       | 火山 BigModel |
| ≥ 25MB  | 任意     | 火山 BigModel |

具体费用以各家控制台计费规则为准，本仓库不做预估。

## 快速开始

### 1. 安装依赖

```bash
pip3 install tos yt-dlp
brew install ffmpeg            # macOS
# apt install ffmpeg           # Linux
```

### 2. 配置凭证

```bash
cp config/credentials.env.example config/credentials.env
# 编辑 credentials.env，填入:
#   VOLC_ASR_KEY        — 火山豆包语音 API Key
#   VOLC_TOS_AK / SK    — 火山 TOS 对象存储
#   VOLC_TOS_BUCKET     — 你自己创建的桶名
#   GROQ_API_KEY        — (可选) 短音频免费 fallback
```

详细申请流程见 [`references/setup-guide.md`](references/setup-guide.md)。

### 3. 运行

```bash
# 最简单的用法
bash scripts/transcribe.sh "https://www.bilibili.com/video/BVxxx"

# 完整选项
bash scripts/transcribe.sh "URL" \
  --title "播客标题" \
  --output ./transcripts \
  --speaker-names '{"1":"主持人","2":"嘉宾"}'

# 关闭说话人分离（小音频走 Groq 免费）
bash scripts/transcribe.sh "URL" --no-diarization
```

## 作为 Claude Code Skill 使用

```bash
# 构建 .skill 分发包
bash build.sh

# 安装到 Claude Code
cp dist/podcast-transcriber.skill ~/.claude/skills/
```

之后在 Claude Code 里直接对话即可触发：

> 把这个播客转成文字：https://www.xiaoyuzhoufm.com/episode/xxx

触发词：`转文字`、`逐字稿`、`文字稿`、`转录`、`提取字幕`、`做逐字稿`。

## 输出示例

```markdown
---
title: XX 播客 · 完整逐字稿（说话人分离）
duration_min: 142
total_chars: 38291
asr_engine: 火山引擎豆包语音 BigModel
speakers: Speaker1=主持人, Speaker2=嘉宾
---

### 🎤 主持人  `00:12`

欢迎来到本期节目，今天我们聊聊……

### 🎙️ 嘉宾  `00:28`

谢谢邀请，我先简单介绍一下……
```

## 项目结构

```
podcast-transcriber/
├── SKILL.md                          Claude Code Skill 入口
├── build.sh                          打包成 .skill 的构建脚本
├── config/credentials.env.example    凭证模板
├── references/                       接入文档与 API 参考
└── scripts/
    ├── transcribe.sh                 主入口（编排器）
    ├── download.sh                   多平台下载
    ├── upload_tos.py                 TOS 上传 + 预签名
    ├── asr_submit.sh                 火山 ASR 提交 + 轮询
    ├── format_output.py              JSON → Markdown
    ├── save_output.sh                输出路由
    └── setup.sh                      环境检测
```

## 设计取舍

- **为什么要 TOS 中转**：火山 BigModel ASR 只接受 URL，不支持 multipart 上传。所以 ≥25MB 的音频必须先传 TOS → 拿预签名 URL → 提交 → 用完删除。
- **为什么 Groq 作 fallback**：免费 + 速度快，但单次上传 ≤ 25MB 且不支持说话人分离。两个引擎互补。
- **为什么用轮询而不是 webhook**：火山 BigModel 不提供回调，最长 13 分钟轮询（40 × 20s）覆盖了绝大多数节目长度。

## 凭证申请

| Key | 申请地址 |
|-----|----------|
| `VOLC_ASR_KEY` | https://console.volcengine.com/speech/new/setting/apikeys |
| `VOLC_TOS_AK/SK` | https://console.volcengine.com/iam/keymanage/ |
| `VOLC_TOS_BUCKET` | https://console.volcengine.com/tos/ |
| `GROQ_API_KEY` | https://console.groq.com/keys |

## License

[MIT](LICENSE)
