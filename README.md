# runpod-llama-server

Runpod の Custom Pod Template で `llama.cpp` の `llama-server` を起動するための最小構成です。

## 仕様

- コンテナの `command` 第1引数をモデル指定として解釈します
- Hugging Face リポジトリ指定時は `llama-server --hf-repo ...` で自動ダウンロードします
- 追加引数はそのまま `llama-server` に渡します
- GitHub Actions で GitHub Container Registry へ `linux/amd64` イメージを push します
- モデルとキャッシュの保存先は `/workspace` 配下です

## モデル指定

第1引数は次のいずれかです。

- `ggml-org/gemma-3-1b-it-GGUF:Q4_K_M` のような Hugging Face リポジトリ
- `/workspace/models/model.gguf` のようなローカル GGUF パス
- `https://.../model.gguf` のような直接 URL

Hugging Face リポジトリ内でファイルを明示したい場合は、追加引数で `--hf-file` を使います。

## Runpod テンプレート設定例

Image:

```text
ghcr.io/<owner>/<repo>:latest
```

Container Disk:

```text
20
```

Expose HTTP Ports:

```text
8080
```

Command:

```text
unsloth/Qwen3-8B-GGUF:Q4_K_M --hf-file Qwen3-8B-Q4_K_M.gguf --jinja --ctx-size 8192
```

OpenAI 互換 API は `http://<pod-ip>:8080/v1/chat/completions` で利用できます。

## 環境変数

- `HF_TOKEN`: gated model 用の Hugging Face トークン
- `HF_HOME`: Hugging Face キャッシュ先。既定値は `/workspace/.cache/huggingface`
- `LLAMA_ARG_PORT`: 既定値 `8080`
- `LLAMA_ARG_HOST`: 既定値 `0.0.0.0`
- `LLAMA_CACHE`: llama.cpp のキャッシュ先。既定値は `/workspace/.cache/llama.cpp`

GPU レイヤー数は既定では固定せず、`llama.cpp` 側の判定に任せます。必要な場合だけ `--n-gpu-layers` または `LLAMA_ARG_N_GPU_LAYERS` で明示指定してください。

## GitHub Actions

`.github/workflows/publish.yml` は GitHub Container Registry に以下のタグを push します。

- `sha-<short commit sha>`
- `<branch-name>` (`branch push` のみ)
- `latest` (`default branch` のみ)
- `<tag-name>` (`tag push` のみ)

`GITHUB_TOKEN` を使って `ghcr.io/<owner>/<repo>` へ push します。
