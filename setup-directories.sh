#!/bin/bash
# Setup script for docker directories
# This script creates all necessary directories for  Docker volumes

set -e

mkdir -p ./User-Directories

cd ./User-Directories

mkdir -p ./open-webui

mkdir -p ./ollama

echo "🚀 Setting up Stable Diffusion WebUI directory structure..."

mkdir -p ./sd.cpp-webui

# Define base directory
BASE_DIR="./sd.cpp-webui"

# Create output directories
echo "📁 Creating output directories..."
mkdir -p "${BASE_DIR}/outputs/any2video"
mkdir -p "${BASE_DIR}/outputs/img2img"
mkdir -p "${BASE_DIR}/outputs/imgedit"  
mkdir -p "${BASE_DIR}/outputs/txt2img"
mkdir -p "${BASE_DIR}/outputs/upscale"

# Create model directories
echo "🤖 Creating model directories..."
mkdir -p "${BASE_DIR}/models/checkpoints"
mkdir -p "${BASE_DIR}/models/clip"
mkdir -p "${BASE_DIR}/models/controlnet"
mkdir -p "${BASE_DIR}/models/embeddings"
mkdir -p "${BASE_DIR}/models/loras"
mkdir -p "${BASE_DIR}/models/photomaker"
mkdir -p "${BASE_DIR}/models/taesd"
mkdir -p "${BASE_DIR}/models/unet"
mkdir -p "${BASE_DIR}/models/upscale_models"
mkdir -p "${BASE_DIR}/models/vae"

# Set appropriate permissions
echo "🔒 Setting directory permissions..."
chmod -R 755 "${BASE_DIR}"

echo "✅ Directory structure created successfully!"
echo ""
echo "📂 Created directories:"
echo "   Outputs:"
echo "     - ${BASE_DIR}/outputs/any2video"
echo "     - ${BASE_DIR}/outputs/img2img"
echo "     - ${BASE_DIR}/outputs/imgedit"
echo "     - ${BASE_DIR}/outputs/txt2img"
echo "     - ${BASE_DIR}/outputs/upscale"
echo ""
echo "   Models:"
echo "     - ${BASE_DIR}/models/checkpoints"
echo "     - ${BASE_DIR}/models/clip"
echo "     - ${BASE_DIR}/models/controlnet"
echo "     - ${BASE_DIR}/models/embeddings"
echo "     - ${BASE_DIR}/models/loras"
echo "     - ${BASE_DIR}/models/photomaker"
echo "     - ${BASE_DIR}/models/taesd"
echo "     - ${BASE_DIR}/models/unet"
echo "     - ${BASE_DIR}/models/upscale_models"
echo "     - ${BASE_DIR}/models/vae"
echo ""
echo "💡 You can now run 'docker-compose up -d' to start the services."
echo "💡 Place your models in the appropriate subdirectories under ${BASE_DIR}/models/"
echo "💡 Generated images and outputs will be saved to ${BASE_DIR}/outputs/"


echo "🎨 Setting up ComfyUI directory structure..."

mkdir -p ./ComfyUI

# Define base directory
BASE_DIR="./ComfyUI"

# Create model directories
echo "🤖 Creating ComfyUI model directories..."
mkdir -p "${BASE_DIR}/models/audio_encoders"
mkdir -p "${BASE_DIR}/models/checkpoints"
mkdir -p "${BASE_DIR}/models/clip"
mkdir -p "${BASE_DIR}/models/clip_vision"
mkdir -p "${BASE_DIR}/models/controlnet"
mkdir -p "${BASE_DIR}/models/diffusers"
mkdir -p "${BASE_DIR}/models/diffusion_models"
mkdir -p "${BASE_DIR}/models/embeddings"
mkdir -p "${BASE_DIR}/models/gligen"
mkdir -p "${BASE_DIR}/models/hypernetworks"
mkdir -p "${BASE_DIR}/models/latent_upscale_models"
mkdir -p "${BASE_DIR}/models/loras"
mkdir -p "${BASE_DIR}/models/model_patches"
mkdir -p "${BASE_DIR}/models/photomaker"
mkdir -p "${BASE_DIR}/models/style_models"
mkdir -p "${BASE_DIR}/models/text_encoders"
mkdir -p "${BASE_DIR}/models/unet"
mkdir -p "${BASE_DIR}/models/upscale_models"
mkdir -p "${BASE_DIR}/models/vae"
mkdir -p "${BASE_DIR}/models/vae_approx"

# Create output and custom nodes directories
echo "📁 Creating ComfyUI output and custom directories..."
mkdir -p "${BASE_DIR}/output"
mkdir -p "${BASE_DIR}/custom_nodes"
mkdir -p "${BASE_DIR}/input"
mkdir -p "${BASE_DIR}/temp"

# Set appropriate permissions
echo "🔒 Setting ComfyUI directory permissions..."
chmod -R 755 "${BASE_DIR}"

echo "✅ ComfyUI directory structure created successfully!"
echo ""
echo "📂 Created ComfyUI directories:"
echo "   Models:"
echo "     - ${BASE_DIR}/models/audio_encoders"
echo "     - ${BASE_DIR}/models/checkpoints"
echo "     - ${BASE_DIR}/models/clip"
echo "     - ${BASE_DIR}/models/clip_vision"
echo "     - ${BASE_DIR}/models/controlnet"
echo "     - ${BASE_DIR}/models/diffusers"
echo "     - ${BASE_DIR}/models/diffusion_models"
echo "     - ${BASE_DIR}/models/embeddings"
echo "     - ${BASE_DIR}/models/gligen"
echo "     - ${BASE_DIR}/models/hypernetworks"
echo "     - ${BASE_DIR}/models/latent_upscale_models"
echo "     - ${BASE_DIR}/models/loras"
echo "     - ${BASE_DIR}/models/model_patches"
echo "     - ${BASE_DIR}/models/photomaker"
echo "     - ${BASE_DIR}/models/style_models"
echo "     - ${BASE_DIR}/models/text_encoders"
echo "     - ${BASE_DIR}/models/unet"
echo "     - ${BASE_DIR}/models/upscale_models"
echo "     - ${BASE_DIR}/models/vae"
echo "     - ${BASE_DIR}/models/vae_approx"
echo ""
echo "   Working directories:"
echo "     - ${BASE_DIR}/output"
echo "     - ${BASE_DIR}/custom_nodes"
echo "     - ${BASE_DIR}/input"
echo "     - ${BASE_DIR}/temp"
echo ""
echo "💡 You can now run ComfyUI containers with proper volume mounts."
echo "💡 Place your models in the appropriate subdirectories under ${BASE_DIR}/models/"
echo "💡 Generated images will be saved to ${BASE_DIR}/output/"
echo "💡 Custom nodes can be placed in ${BASE_DIR}/custom_nodes/"