ARG UBUNTU_VERSION=24.04
ARG CUDA_VERSION=12.8.1

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS build

ARG TURBOQUANT_REPO=https://github.com/TheTom/llama-cpp-turboquant.git
ARG TURBOQUANT_BRANCH=feature/turboquant-kv-cache
ARG CUDA_DOCKER_ARCH=default

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        g++-14 \
        gcc-14 \
        git \
        libgomp1 \
        libssl-dev \
        python3 \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

ENV CC=gcc-14 \
    CXX=g++-14 \
    CUDAHOSTCXX=g++-14

WORKDIR /src

RUN git clone --depth 1 --branch "${TURBOQUANT_BRANCH}" "${TURBOQUANT_REPO}" llama-cpp-turboquant

WORKDIR /src/llama-cpp-turboquant

RUN if [ "${CUDA_DOCKER_ARCH}" != "default" ]; then \
        export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=${CUDA_DOCKER_ARCH}"; \
    fi && \
    cmake -B build \
        -DGGML_CUDA=ON \
        -DGGML_NATIVE=OFF \
        -DLLAMA_BUILD_TESTS=OFF \
        ${CMAKE_ARGS} \
        . && \
    cmake --build build --config Release -j"$(nproc)"

RUN mkdir -p /out/bin /out/lib && \
    cp build/bin/llama-server /out/bin/ && \
    find build -name "*.so*" -exec cp -P {} /out/lib \;

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

ENV HF_HOME=/workspace/.cache/huggingface \
    LLAMA_CACHE=/workspace/.cache/llama.cpp \
    LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080 \
    LLAMA_ARG_CTX_SIZE=8192 \
    LLAMA_SERVER_BIN=/app/llama-server \
    LD_LIBRARY_PATH=/app/lib:${LD_LIBRARY_PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /out/bin/llama-server /app/llama-server
COPY --from=build /out/lib /app/lib
COPY docker/entrypoint.sh /usr/local/bin/runpod-llama-server

RUN chmod +x /usr/local/bin/runpod-llama-server && \
    mkdir -p "${HF_HOME}" "${LLAMA_CACHE}"

VOLUME ["/workspace"]

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/runpod-llama-server"]
