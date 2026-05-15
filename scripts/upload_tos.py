#!/usr/bin/env python3
"""TOS 上传 + 预签名 URL 生成 (独立版)"""
import sys, os, argparse
from tos import TosClientV2, HttpMethodType

def load_config():
    """从环境变量或 credentials.env 读取"""
    cfg = {}
    # 1. 环境变量
    for k in ['VOLC_TOS_AK','VOLC_TOS_SK','VOLC_TOS_BUCKET','VOLC_TOS_ENDPOINT','VOLC_TOS_REGION']:
        cfg[k] = os.environ.get(k, '')
    # 2. credentials.env 文件
    if not all([cfg['VOLC_TOS_AK'], cfg['VOLC_TOS_SK']]):
        for search in [
            os.path.join(os.path.dirname(__file__), '..', 'config', 'credentials.env'),
            os.path.expanduser('~/.podcast-transcriber/credentials.env'),
        ]:
            if os.path.exists(search):
                with open(search) as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            k, v = line.split('=', 1)
                            if k in cfg and not cfg[k]:
                                cfg[k] = v
                break
    return cfg

parser = argparse.ArgumentParser()
parser.add_argument('file')
parser.add_argument('--key', help='对象 key')
parser.add_argument('--expires', type=int, default=86400)
args = parser.parse_args()

cfg = load_config()
ak, sk = cfg['VOLC_TOS_AK'], cfg['VOLC_TOS_SK']
bucket = cfg['VOLC_TOS_BUCKET']
endpoint = cfg['VOLC_TOS_ENDPOINT'] or 'tos-cn-beijing.volces.com'
region = cfg['VOLC_TOS_REGION'] or 'cn-beijing'

if not all([ak, sk, bucket]):
    print("ERROR: 缺少 TOS 凭证。请复制 config/credentials.env.example 为 config/credentials.env 并填写", file=sys.stderr)
    sys.exit(1)

key = args.key or os.path.basename(args.file)
size_mb = os.path.getsize(args.file) / 1024 / 1024
print(f"Uploading {key} ({size_mb:.1f}MB) → {bucket}...", file=sys.stderr)
client = TosClientV2(ak, sk, endpoint=endpoint, region=region)

try:
    client.upload_file(bucket=bucket, key=key, file_path=args.file)
    print("✅ Upload OK", file=sys.stderr)
except Exception as e:
    print(f"Upload failed: {e}", file=sys.stderr)
    sys.exit(1)

url = client.pre_signed_url(HttpMethodType.Http_Method_Get, bucket=bucket, key=key, expires=args.expires)
print(url.signed_url)
