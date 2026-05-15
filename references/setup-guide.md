# podcast-transcriber 接入指南

## 5 分钟接入

### 1. 安装依赖

```bash
pip3 install tos yt-dlp
brew install ffmpeg        # macOS
# apt install ffmpeg        # Linux
```

### 2. 火山引擎 ASR API Key

1. 打开 https://console.volcengine.com/speech/new/setting/apikeys
2. 创建 API Key
3. 填入 `config/credentials.env` 的 `VOLC_ASR_KEY`

### 3. 火山引擎 TOS 对象存储

1. 打开 https://console.volcengine.com/tos/
2. 创建存储桶（桶策略私有即可）
3. 记住桶名和外网域名（如 `tos-cn-beijing.volces.com`）
4. 打开 https://console.volcengine.com/iam/keymanage/
5. 创建 Access Key，复制 AK 和 SK
6. 填入 `config/credentials.env` 的 `VOLC_TOS_AK/SK/BUCKET/ENDPOINT`

### 4. (可选) Groq Whisper API Key

1. 打开 https://console.groq.com/keys
2. 创建 API Key
3. 填入 `config/credentials.env` 的 `GROQ_API_KEY`
4. 不配也不影响，所有音频都走火山引擎

## 费用预估

| 场景 | 2.5h 播客 |
|------|----------|
| ASR 识别 | ¥5-10 |
| TOS 存储+流量 | ¥0.04 |
| 短音频 Groq | 免费 |
