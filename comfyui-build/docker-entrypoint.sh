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

set -e

echo "Updating ComfyUI repository..."
if command -v git &> /dev/null; then
    echo "Git found!"
else
    echo "Git not found, attempting to install..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y git python3-venv python3-full
    else
        echo "Warning: Git not available and cannot install. Skipping repository update."
        exit 1
    fi
fi

echo "=== ComfyUI Multi-Architecture Build Script ==="
echo "Creating optimized builds for different AMD GPU architectures..."

# Configure git to handle ownership issues in Docker containers
git config --global --add safe.directory /app/ComfyUI
git config --global init.defaultBranch master

# Clone ComfyUI if it doesn't exist or if it's not a valid git repository
if [ ! -d "ComfyUI" ]; then
    echo "ComfyUI directory doesn't exist, cloning repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
elif [ ! -d "ComfyUI/.git" ]; then
    echo "ComfyUI directory exists but is not a valid git repository..."
    echo "Attempting to initialize git repository in existing directory..."
    cd ComfyUI
    # Initialize as git repository and add remote
    git init
    git remote add origin https://github.com/comfyanonymous/ComfyUI.git
    echo "Fetching latest ComfyUI code..."
    git fetch origin
    git checkout -f master || git checkout -f main
    git reset --hard origin/master || git reset --hard origin/main
    cd ..
else
    echo "ComfyUI directory already exists and is a valid git repository..."
    cd ComfyUI
    # Fix git ownership issues for existing repository
    git config --add safe.directory /app/ComfyUI
    echo "Pulling latest updates..."
    git pull || echo "Git pull failed, continuing with existing code..."
    cd ..
fi

# Set PyTorch index URL based on GPU_ARCH if specified
echo "Configuring PyTorch index URL based on GPU_ARCH: $GPU_ARCH..."
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

cd ComfyUI
echo "Creating Python virtual environment..."
python3 -m venv venv
echo "Activating virtual environment..."
. venv/bin/activate
echo "Upgrading pip..."
pip install --upgrade pip
echo "Installing PyTorch with ROCm support..."
# Check if PYTORCH_INDEX_URL is set, if not, use default
if [ -z "${PYTORCH_INDEX_URL}" ]; then
    echo "Warning: No specific GPU architecture detected, using default ROCm 7.1..."
    PYTORCH_INDEX_URL="https://download.pytorch.org/whl/nightly/rocm7.1"
fi


echo "Using PyTorch index URL: ${PYTORCH_INDEX_URL}"
pip install --pre torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}
# TO debug flash_attn issues, temporarily disabling its installation
#pip install --upgrade flash_attn --no-build-isolation
echo "Installing ComfyUI requirements..."
pip install -r requirements.txt
#pip install ultralytics
#pip install onnxruntime-rocm

# Set up ROCm library path
#echo "Setting up ROCm library path..."
#export PYTHONPATH=/opt/rocm/lib:$PYTHONPATH

cd custom_nodes

echo "Installing ComfyUI Manager..."
if [ ! -d "comfyui-manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
    cd comfyui-manager && pip install -r requirements.txt && cd ..
else
    echo "ComfyUI Manager already exists, skipping..."
fi

echo "Installing ComfyUI Multi-GPU Support..."
if [ ! -d "comfyui-multigpu" ]; then
    git clone https://github.com/pollockjj/ComfyUI-MultiGPU.git comfyui-multigpu
else
    echo "ComfyUI Multi-GPU already exists, skipping..."
fi

echo "Custom nodes installation complete."

echo "Moving back to ComfyUI root"
cd /app/ComfyUI

echo "Installing additional Python packages..."
pip install accelerate deepdiff gguf git

echo "Starting ComfyUI..."
if [ -f "start.sh" ]; then
    echo "Found start.sh, executing it..."
    chmod +x start.sh
    ./start.sh
else
    echo "No start.sh found, creating default startup script..."
    echo "python main.py --listen 0.0.0.0 --port 8188 --normalvram --reserve-vram 2 --use-quad-cross-attention" > start.sh
    chmod +x start.sh
    ./start.sh
fi
