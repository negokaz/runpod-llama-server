# runpod-llama-server

Runpod の Custom Pod Template で `llama-server` を起動するための最小構成です。ベースは upstream 配布イメージではなく、`TheTom/llama-cpp-turboquant` の `feature/turboquant-kv-cache` ブランチを Docker build 時に CUDA ビルドした独自イメージです。

## 仕様

- コンテナの `command` 第1引数をモデル指定として解釈します
- Hugging Face リポジトリ指定時は `llama-server --hf-repo ...` で自動ダウンロードします
- 追加引数はそのまま `llama-server` に渡します
- GitHub Actions で GitHub Container Registry へ `linux/amd64` イメージを push します
- モデルとキャッシュの保存先は `/workspace` 配下です
- `llama-server` は [TheTom/llama-cpp-turboquant](https://github.com/TheTom/llama-cpp-turboquant) の `--cache-type-k` / `--cache-type-v` を利用できます

## モデル指定

第1引数は次のいずれかです。既存の指定方法はそのまま使えます。

- `ggml-org/gemma-3-1b-it-GGUF:Q4_K_M` のような Hugging Face リポジトリ
- `/workspace/models/model.gguf` のようなローカル GGUF パス
- `https://.../model.gguf` のような直接 URL

Hugging Face リポジトリ内でファイルを明示したい場合は、追加引数で `--hf-file` を使います。

## TurboQuant の使い方

TurboQuant は KV キャッシュ圧縮を追加する fork の機能です。まずは K 側を強く圧縮しない設定から始めるのが無難です。

- 推奨初期値: `--cache-type-k q8_0 --cache-type-v turbo3`
- より安全な開始例: `--cache-type-k f16 --cache-type-v turbo4`
- `--cache-type-k turbo*` は初手では非推奨です。品質確認後に個別検証してください

例:

```text
unsloth/Qwen3-8B-GGUF --hf-file Qwen3-8B-Q4_K_M.gguf --jinja --ctx-size 8192 --cache-type-k q8_0 --cache-type-v turbo3
```

```text
/workspace/models/model.gguf --ctx-size 32768 --cache-type-k f16 --cache-type-v turbo4
```

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
unsloth/Qwen3-8B-GGUF --hf-file Qwen3-8B-Q4_K_M.gguf --jinja --ctx-size 8192 --cache-type-k q8_0 --cache-type-v turbo3
```

OpenAI 互換 API は `http://<pod-ip>:8080/v1/chat/completions` で利用できます。

## 環境変数

- `HF_TOKEN`: gated model 用の Hugging Face トークン
- `HF_HOME`: Hugging Face キャッシュ先。既定値は `/workspace/.cache/huggingface`
- `LLAMA_ARG_PORT`: 既定値 `8080`
- `LLAMA_ARG_HOST`: 既定値 `0.0.0.0`
- `LLAMA_ARG_CTX_SIZE`: 既定値 `8192`
- `LLAMA_CACHE`: llama.cpp のキャッシュ先。既定値は `/workspace/.cache/llama.cpp`

GPU レイヤー数は既定では固定せず、`llama.cpp` 側の判定に任せます。必要な場合だけ `--n-gpu-layers` または `LLAMA_ARG_N_GPU_LAYERS` で明示指定してください。

## GitHub Actions

`.github/workflows/publish.yml` は GitHub Container Registry に以下のタグを push します。

- `sha-<short commit sha>`
- `<branch-name>` (`branch push` のみ)
- `latest` (`default branch` のみ)
- `<tag-name>` (`tag push` のみ)

`GITHUB_TOKEN` を使って `ghcr.io/<owner>/<repo>` へ push します。
