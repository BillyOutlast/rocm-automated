#!/bin/bash

# Build script for ComfyUI with different AMD GPU architecture support

REGISTRY="docker.io/getterup"
Dockerfiles_DIR="./Dockerfiles"


echo "Building ComfyUI docker images for different AMD GPU architectures..."

# ROCm 7.1 (General compatibility)
echo "Building ComfyUI with ROCm 7.1 (General)..."
docker build -t ${REGISTRY}/comfyui:rocm7.1 \
  --build-arg PYTORCH_INDEX_URL="https://download.pytorch.org/whl/nightly/rocm7.1" \
  --build-arg GPU_ARCH="rocm7.1" \
  -f ${Dockerfiles_DIR}/Dockerfile.comfyui-rocm7.1 .

# RDNA 3 (RX 7000 series)
echo "Building ComfyUI for RDNA 3 (RX 7000 series)..."
docker build -t ${REGISTRY}/comfyui:rdna3-gfx110x \
  --build-arg PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/" \
  --build-arg GPU_ARCH="gfx110X" \
  -f ${Dockerfiles_DIR}/Dockerfile.comfyui-rocm7.1 .

# RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)
echo "Building ComfyUI for RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)..."
docker build -t ${REGISTRY}/comfyui:rdna3.5-gfx1151 \
  --build-arg PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx1151/" \
  --build-arg GPU_ARCH="gfx1151" \
  -f ${Dockerfiles_DIR}/Dockerfile.comfyui-rocm7.1 .

# RDNA 4 (RX 9000 series)
echo "Building ComfyUI for RDNA 4 (RX 9000 series)..."
docker build -t ${REGISTRY}/comfyui:rdna4-gfx120x \
  --build-arg PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx120X-all/" \
  --build-arg GPU_ARCH="gfx120X" \
  -f ${Dockerfiles_DIR}/Dockerfile.comfyui-rocm7.1 .

echo "All ComfyUI builds completed!"
echo ""
echo "Pushing images to registry..."

# Push all images to registry
echo "Pushing ${REGISTRY}/comfyui:rocm7.1..."
docker push ${REGISTRY}/comfyui:rocm7.1

echo "Pushing ${REGISTRY}/comfyui:rdna3-gfx110x..."
docker push ${REGISTRY}/comfyui:rdna3-gfx110x

echo "Pushing ${REGISTRY}/comfyui:rdna3.5-gfx1151..."
docker push ${REGISTRY}/comfyui:rdna3.5-gfx1151

echo "Pushing ${REGISTRY}/comfyui:rdna4-gfx120x..."
docker push ${REGISTRY}/comfyui:rdna4-gfx120x

echo ""
echo "All images pushed to registry!"
echo ""
echo "Available images at ${REGISTRY}:"
echo "  - ${REGISTRY}/comfyui:rocm7.1       (General ROCm 7.1)"
echo "  - ${REGISTRY}/comfyui:rdna3-gfx110x (RDNA 3 - RX 7000 series)"
echo "  - ${REGISTRY}/comfyui:rdna3.5-gfx1151 (RDNA 3.5 - Strix halo/Ryzen AI Max+ 365)"
echo "  - ${REGISTRY}/comfyui:rdna4-gfx120x (RDNA 4 - RX 9000 series)"
echo ""
echo "Run with: docker run --rm --device=/dev/kfd --device=/dev/dri -p 8188:8188 ${REGISTRY}/comfyui:<tag>"

