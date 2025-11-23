#!/bin/bash

# ComfyUI Virtual Environment Creation Script for AMD GPUs
# This script clones ComfyUI and creates 4 different virtual environments
# optimized for different AMD GPU architectures

set -e

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

cd ..


echo "Building ComfyUI with ROCm 7.1 (General)..."
PYTORCH_INDEX_URL="https://download.pytorch.org/whl/nightly/rocm7.1"
GPU_ARCH="rocm7.1"
python3 -m venv rocm7.1
. rocm7.1/bin/activate
pip install --upgrade pip
if echo "${PYTORCH_INDEX_URL}" | grep -q "rocm.nightlies.amd.com"; then
    pip install --pre torch torchvision torchaudio --extra-index-url ${PYTORCH_INDEX_URL}
else
    pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
fi
pip install -r ComfyUI/requirements.txt
pip install opencv-python gguf
deactivate

# RDNA 3 (RX 7000 series)
echo "Building ComfyUI for RDNA 3 (RX 7000 series)..."
PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/"
GPU_ARCH="gfx110X"
python3 -m venv gfx110X
. gfx110X/bin/activate
pip install --upgrade pip
if echo "${PYTORCH_INDEX_URL}" | grep -q "rocm.nightlies.amd.com"; then
    pip install --pre torch torchvision torchaudio --extra-index-url ${PYTORCH_INDEX_URL}
else
    pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
fi
pip install -r ComfyUI/requirements.txt
pip install opencv-python gguf
deactivate

# RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)
echo "Building ComfyUI for RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)..."
PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx1151/"
GPU_ARCH="gfx1151"
python3 -m venv gfx1151
. gfx1151/bin/activate
pip install --upgrade pip
if echo "${PYTORCH_INDEX_URL}" | grep -q "rocm.nightlies.amd.com"; then
    pip install --pre torch torchvision torchaudio --extra-index-url ${PYTORCH_INDEX_URL}
else
    pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
fi
pip install -r ComfyUI/requirements.txt
pip install opencv-python gguf
deactivate

# RDNA 4 (RX 9000 series)
echo "Building ComfyUI for RDNA 4 (RX 9000 series)..."
PYTORCH_INDEX_URL="https://rocm.nightlies.amd.com/v2/gfx120X-all/"
GPU_ARCH="gfx120X"
python3 -m venv gfx120X
. gfx120X/bin/activate
pip install --upgrade pip
if echo "${PYTORCH_INDEX_URL}" | grep -q "rocm.nightlies.amd.com"; then
    pip install --pre torch torchvision torchaudio --extra-index-url ${PYTORCH_INDEX_URL}
else
    pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
fi
pip install -r ComfyUI/requirements.txt
pip install opencv-python gguf
deactivate

echo "All virtual environments created successfully!"
echo "Available environments:"
echo "  - rocm7.1 (General ROCm 7.1)"
echo "  - gfx110X (RDNA 3 - RX 7000 series)"
echo "  - gfx1151 (RDNA 3.5 - Strix halo/Ryzen AI Max+ 365)"
echo "  - gfx120X (RDNA 4 - RX 9000 series)"

