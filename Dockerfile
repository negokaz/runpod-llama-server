FROM ghcr.io/ggml-org/llama.cpp:server-cuda

ENV HF_HOME=/workspace/.cache/huggingface \
    LLAMA_CACHE=/workspace/.cache/llama.cpp \
    LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080 \
    LLAMA_ARG_CTX_SIZE=8192 \
    LLAMA_ARG_N_GPU_LAYERS=999

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /usr/local/bin/runpod-llama-server

RUN chmod +x /usr/local/bin/runpod-llama-server && \
    mkdir -p "${HF_HOME}" "${LLAMA_CACHE}"

VOLUME ["/workspace"]

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/runpod-llama-server"]
