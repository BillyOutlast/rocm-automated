#!/bin/bash

# ROCm 7.1 podman Build and Push Script
# Builds and pushes fedora-rocm7.1, ollama-rocm7.1, stable-diffusion.cpp-rocm7.1, and comfyui-rocm7.1 images

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="docker.io/getterup"
FEDORA_IMAGE="fedora-rocm7.1"
OLLAMA_IMAGE="ollama-rocm7.1"
COMFYUI_IMAGE="comfyui-rocm7.1"
Dockerfiles_DIR="./Dockerfiles"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    ROCm 7.1 podman Build Script      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${CYAN}➤ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if podman is available
if ! command -v podman &> /dev/null; then
    print_error "podman is not installed or not in PATH"
    exit 1
fi

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

cd ollama-build

print_step "Checking/cloning Ollama ROCm repository..."
if [ ! -d "ollama-linux-amd-apu" ]; then
    echo -e "${YELLOW}Command: git clone https://github.com/phueper/ollama-linux-amd-apu.git ollama-linux-amd-apu${NC}"
    if git clone https://github.com/phueper/ollama-linux-amd-apu.git ollama-linux-amd-apu; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
else
    print_success "Repository already exists, skipping clone"
fi

print_step "Building Ollama ROCm 7.1 image..."
echo -e "${YELLOW}Command: podman build -t ${OLLAMA_IMAGE}:latest --build-arg FLAVOR=rocm .${NC}"
cd ollama-linux-amd-apu
if podman build -t "${OLLAMA_IMAGE}:latest" --build-arg FLAVOR=rocm .; then
    print_success "Ollama ROCm 7.1 image built successfully"
    cd ..
else
    print_error "Failed to build Ollama ROCm 7.1 image"
    exit 1
fi

print_step "Tagging Ollama ROCm 7.1 image for registry..."
if podman tag "${OLLAMA_IMAGE}:latest" "${REGISTRY}/${OLLAMA_IMAGE}:latest"; then
    print_success "Tagged: ${REGISTRY}/${OLLAMA_IMAGE}:latest"
else
    print_error "Failed to tag Ollama ROCm 7.1 image"
    exit 1
fi

print_step "Pushing Ollama ROCm 7.1 image to registry..."
if podman push "${REGISTRY}/${OLLAMA_IMAGE}:latest"; then
    print_success "Pushed: ${REGISTRY}/${OLLAMA_IMAGE}:latest"
else
    print_error "Failed to push Ollama ROCm 7.1 image"
    exit 1
fi

cd ..

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

print_step "Building ComfyUI ROCm 7.1 image..."
echo -e "${YELLOW}Command: podman build -t ${COMFYUI_IMAGE}:latest -f Dockerfiles/Dockerfile.comfyui-rocm7.1 .${NC}"
if podman build -t "${COMFYUI_IMAGE}:latest" -f Dockerfiles/Dockerfile.comfyui-rocm7.1 .; then
    print_success "ComfyUI ROCm 7.1 image built successfully"
else
    print_error "Failed to build ComfyUI ROCm 7.1 image"
    exit 1
fi

print_step "Tagging ComfyUI ROCm 7.1 image for registry..."
if podman tag "${COMFYUI_IMAGE}:latest" "${REGISTRY}/${COMFYUI_IMAGE}:latest"; then
    print_success "Tagged: ${REGISTRY}/${COMFYUI_IMAGE}:latest"
else
    print_error "Failed to tag ComfyUI ROCm 7.1 image"
    exit 1
fi

print_step "Pushing ComfyUI ROCm 7.1 image to registry..."
if podman push "${REGISTRY}/${COMFYUI_IMAGE}:latest"; then
    print_success "Pushed: ${REGISTRY}/${COMFYUI_IMAGE}:latest"
else
    print_error "Failed to push ComfyUI ROCm 7.1 image"
    exit 1
fi

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

print_step "Building Stable-Diffusion variants for different GPU architectures..."
echo -e "${YELLOW}Command: bash ./build-scripts/build-stable-diffusion-variants.sh${NC}"
if bash ./build-scripts/build-stable-diffusion-variants.sh; then
    print_success "Stable-Diffusion variants built successfully"
else
    print_error "Failed to build Stable-Diffusion variants"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All images built and pushed successfully! 🎉${NC}"
echo ""
echo -e "${CYAN}Images available at:${NC}"
echo -e "  • https://hub.docker.com/r/getterup/${FEDORA_IMAGE}"
echo -e "  • https://hub.docker.com/r/getterup/${OLLAMA_IMAGE}"
echo ""