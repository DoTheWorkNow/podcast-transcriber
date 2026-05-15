# 火山引擎豆包语音 BigModel API 参考

## 提交接口

- **URL**: `https://openspeech.bytedance.com/api/v3/auc/bigmodel/submit`
- **Method**: POST
- **Headers**: `X-Api-Key`, `X-Api-Resource-Id` (volc.seedasr.auc), `X-Api-Request-Id` (UUID), `X-Api-Sequence` (-1)
- **Body**: JSON，包含 `user.uid`, `audio.url`, `request.model_name` (bigmodel)
- **Response**: 200 + 空 body，Header 含 `X-Api-Status-Code: 20000000`

## 查询接口

- **URL**: `https://openspeech.bytedance.com/api/v3/auc/bigmodel/query`
- **Request ID**: 必须与提交时一致
- **Response**: `result.text`, `result.utterances[].{text,start_time,end_time,additions.speaker,words}`

## 关键参数

| 参数 | 类型 | 说明 |
|------|------|------|
| enable_speaker_info | bool | 说话人分离（需开启） |
| enable_itn | bool | 文本规范化 |
| enable_punc | bool | 标点 |
| enable_ddc | bool | 语义顺滑（去口癖） |
| show_utterances | bool | 分句信息 |
| vad_segment | bool | VAD 分句 |
| language | string | zh-CN/en-US 等 |

## 限制

- 音频最大 512MB
- 单次提交音频 ≤ 6 小时
- 每半小时最多提交 500 小时
