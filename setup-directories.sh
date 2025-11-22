#!/bin/bash
# Setup script for docker directories
# This script creates all necessary directories for  Docker volumes

set -e

mkdir -p ./open-webui

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