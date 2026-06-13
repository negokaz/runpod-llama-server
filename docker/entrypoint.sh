#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  runpod-llama-server <hf-repo[:quant]> [llama-server options...]
  runpod-llama-server <model.gguf|/path/to/model.gguf> [llama-server options...]
  runpod-llama-server <https://.../model.gguf> [llama-server options...]

examples:
  runpod-llama-server ggml-org/gemma-3-1b-it-GGUF:Q4_K_M --jinja
  runpod-llama-server unsloth/Qwen3-8B-GGUF --hf-file Qwen3-8B-Q4_K_M.gguf
EOF
}

mkdir -p "${HF_HOME:-/workspace/.cache/huggingface}" "${LLAMA_CACHE:-/workspace/.cache/llama.cpp}"

LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-/app/llama-server}"

if [[ $# -eq 0 ]]; then
  usage
  exit 64
fi

if [[ "${1}" == "-"* ]]; then
  exec "${LLAMA_SERVER_BIN}" "$@"
fi

model_ref="$1"
shift

case "${model_ref}" in
  http://*|https://*)
    exec "${LLAMA_SERVER_BIN}" --model-url "${model_ref}" "$@"
    ;;
  *.gguf|/*|./*|../*)
    exec "${LLAMA_SERVER_BIN}" --model "${model_ref}" "$@"
    ;;
  *)
    exec "${LLAMA_SERVER_BIN}" --hf-repo "${model_ref}" "$@"
    ;;
esac
