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
GPU_ARCH="gfx110X"
python3 -m venv gfx110X
. gfx110X/bin/activate
pip install --upgrade pip

# Try stable ROCm 7.1 first, fallback to nightly if needed
echo "Attempting to install PyTorch with ROCm 7.1 stable..."
if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm7.1; then
    echo "Successfully installed PyTorch with stable ROCm 7.1"
else
    echo "Failed with stable build, trying ROCm 6.2 as fallback..."
    if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.2; then
        echo "Successfully installed PyTorch with ROCm 6.2"
    else
        echo "Failed to install PyTorch for gfx110X. Skipping this environment."
        deactivate
        rm -rf gfx110X
        echo "Skipping gfx110X environment due to installation failure."
    fi
fi

# Install remaining dependencies if PyTorch was installed
if [ -d "gfx110X" ]; then
    if pip install -r ComfyUI/requirements.txt && pip install opencv-python gguf; then
        echo "Successfully installed ComfyUI dependencies for gfx110X"
    else
        echo "Failed to install ComfyUI dependencies for gfx110X"
        deactivate
        rm -rf gfx110X
        echo "Removed gfx110X environment due to dependency installation failure."
    fi
    deactivate
fi

# RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)
echo "Building ComfyUI for RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)..."
GPU_ARCH="gfx1151"
python3 -m venv gfx1151
. gfx1151/bin/activate
pip install --upgrade pip

# Try stable ROCm 7.1 first, fallback to nightly if needed
echo "Attempting to install PyTorch with ROCm 7.1 stable..."
if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm7.1; then
    echo "Successfully installed PyTorch with stable ROCm 7.1"
else
    echo "Failed with stable build, trying ROCm 6.2 as fallback..."
    if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.2; then
        echo "Successfully installed PyTorch with ROCm 6.2"
    else
        echo "Failed to install PyTorch for gfx1151. Skipping this environment."
        deactivate
        rm -rf gfx1151
        echo "Skipping gfx1151 environment due to installation failure."
    fi
fi

# Install remaining dependencies if PyTorch was installed
if [ -d "gfx1151" ]; then
    if pip install -r ComfyUI/requirements.txt && pip install opencv-python gguf; then
        echo "Successfully installed ComfyUI dependencies for gfx1151"
    else
        echo "Failed to install ComfyUI dependencies for gfx1151"
        deactivate
        rm -rf gfx1151
        echo "Removed gfx1151 environment due to dependency installation failure."
    fi
    deactivate
fi

# RDNA 4 (RX 9000 series)
echo "Building ComfyUI for RDNA 4 (RX 9000 series)..."
GPU_ARCH="gfx120X"
python3 -m venv gfx120X
. gfx120X/bin/activate
pip install --upgrade pip

# Try stable ROCm 7.1 first, fallback to nightly if needed
echo "Attempting to install PyTorch with ROCm 7.1 stable..."
if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm7.1; then
    echo "Successfully installed PyTorch with stable ROCm 7.1"
else
    echo "Failed with stable build, trying ROCm 6.2 as fallback..."
    if pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.2; then
        echo "Successfully installed PyTorch with ROCm 6.2"
    else
        echo "Failed to install PyTorch for gfx120X. Skipping this environment."
        deactivate
        rm -rf gfx120X
        echo "Skipping gfx120X environment due to installation failure."
    fi
fi

# Install remaining dependencies if PyTorch was installed
if [ -d "gfx120X" ]; then
    if pip install -r ComfyUI/requirements.txt && pip install opencv-python gguf; then
        echo "Successfully installed ComfyUI dependencies for gfx120X"
    else
        echo "Failed to install ComfyUI dependencies for gfx120X"
        deactivate
        rm -rf gfx120X
        echo "Removed gfx120X environment due to dependency installation failure."
    fi
    deactivate
fi

echo "Virtual environment creation completed!"
echo "Successfully created environments:"
if [ -d "rocm7.1" ]; then echo "  ✅ rocm7.1 (General ROCm 7.1)"; else echo "  ❌ rocm7.1 (Failed)"; fi
if [ -d "gfx110X" ]; then echo "  ✅ gfx110X (RDNA 3 - RX 7000 series)"; else echo "  ❌ gfx110X (Failed)"; fi
if [ -d "gfx1151" ]; then echo "  ✅ gfx1151 (RDNA 3.5 - Strix halo/Ryzen AI Max+ 365)"; else echo "  ❌ gfx1151 (Failed)"; fi
if [ -d "gfx120X" ]; then echo "  ✅ gfx120X (RDNA 4 - RX 9000 series)"; else echo "  ❌ gfx120X (Failed)"; fi

