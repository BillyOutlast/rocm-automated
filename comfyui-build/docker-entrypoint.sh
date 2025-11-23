#!/bin/bash

# ComfyUI Virtual Environment Creation Script for AMD GPUs
# This script clones ComfyUI and creates 4 different virtual environments
# optimized for different AMD GPU architectures


# Read GPU_ARCH environment variable if set
if [ -n "$GPU_ARCH" ]; then
    echo "GPU_ARCH environment variable detected: $GPU_ARCH"
    echo "Will prioritize build for architecture: $GPU_ARCH"
else
    echo "No GPU_ARCH environment variable set, building all architectures..."
fi

cd /app

echo "=== ComfyUI Multi-Architecture Build Script ==="
echo "Creating optimized builds for different AMD GPU architectures..."

# Clone ComfyUI if it doesn't exist
if [ ! -d "ComfyUI" ]; then
    echo "Cloning ComfyUI repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
else
    echo "ComfyUI directory already exists, skipping clone..."
fi
cd ComfyUI

# Update ComfyUI repository
echo "Updating ComfyUI repository..."
git pull


# Set PyTorch index URL based on GPU_ARCH if specified
if [ "$GPU_ARCH" = "rocm7.1" ]; then
    echo "Building ComfyUI with ROCm 7.1 (General)..."
    PYTORCH_INDEX_URL="https://download.pytorch.org/whl/nightly/rocm7.1"
fi

if [ "$GPU_ARCH" = "gfx110X" ]; then
    echo "Building ComfyUI with ROCm 7.1 RDNA 3 (RX 7000 series)..."
    PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/"
fi

if [ "$GPU_ARCH" = "gfx1151" ]; then
    echo "Building ComfyUI with ROCm 7.1 RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)..."
    PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx1151/"
fi

if [ "$GPU_ARCH" = "gfx120X" ]; then
    echo "Building ComfyUI with ROCm 7.1 RDNA 4 (RX 9000 series)..."
    PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx120X-all/"
fi

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip
if echo "${PYTORCH_INDEX_URL}" | grep -q "rocm.nightlies.amd.com"; then
    pip install --pre torch torchvision torchaudio --extra-index-url ${PYTORCH_INDEX_URL}
else
    pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
fi
pip install -r ComfyUI/requirements.txt

python main.py --listen 0.0.0.0 --port 8188 --force-fp16
