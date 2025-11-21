#!/bin/bash

# ROCm 7.1 Docker Build and Push Script
# Builds and pushes fedora-rocm7.1 and ollama-rocm7.1 images

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    ROCm 7.1 Docker Build Script      ${NC}"
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
    print_error "Podman is not installed or not in PATH"
    exit 1
fi

print_step "Building Fedora ROCm 7.1 base image..."
echo -e "${YELLOW}Command: podman build -t ${FEDORA_IMAGE}:latest -f Dockerfile.rocm-7.1${NC}"
if podman build -t "${FEDORA_IMAGE}:latest" -f Dockerfile.rocm-7.1; then
    print_success "Fedora ROCm 7.1 image built successfully"
else
    print_error "Failed to build Fedora ROCm 7.1 image"
    exit 1
fi

print_step "Tagging Fedora ROCm 7.1 image for registry..."
if podman tag "${FEDORA_IMAGE}:latest" "${REGISTRY}/${FEDORA_IMAGE}:latest"; then
    print_success "Tagged: ${REGISTRY}/${FEDORA_IMAGE}:latest"
else
    print_error "Failed to tag Fedora ROCm 7.1 image"
    exit 1
fi

print_step "Pushing Fedora ROCm 7.1 image to registry..."
if podman push "${REGISTRY}/${FEDORA_IMAGE}:latest"; then
    print_success "Pushed: ${REGISTRY}/${FEDORA_IMAGE}:latest"
else
    print_error "Failed to push Fedora ROCm 7.1 image"
    exit 1
fi

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

print_step "Building Ollama ROCm 7.1 image..."
echo -e "${YELLOW}Command: podman build -t ${OLLAMA_IMAGE}:latest -f Dockerfile.ollama-rocm-7.1${NC}"
if podman build -t "${OLLAMA_IMAGE}:latest" -f Dockerfile.ollama-rocm-7.1; then
    print_success "Ollama ROCm 7.1 image built successfully"
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

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

print_step "Building Stable Diffusion ROCm 7.1 image..."
echo -e "${YELLOW}Command: podman build -t stable-diffusion.cpp-rocm7.1:gfx1151 -f Dockerfile.stable-diffusion.cpp-rocm7.1-gfx1151${NC}"
if podman build -t stable-diffusion.cpp-rocm7.1:gfx1151 -f Dockerfile.stable-diffusion.cpp-rocm7.1-gfx1151; then
    print_success "Stable Diffusion ROCm 7.1 image built successfully"
else
    print_error "Failed to build Stable Diffusion ROCm 7.1 image"
    exit 1
fi

print_step "Tagging Stable Diffusion image for registry..."
if podman tag stable-diffusion.cpp-rocm7.1:gfx1151 ${REGISTRY}/stable-diffusion.cpp-rocm7.1:gfx1151; then
    print_success "Tagged: ${REGISTRY}/stable-diffusion.cpp-rocm7.1:gfx1151"
else
    print_error "Failed to tag Stable Diffusion image"
    exit 1
fi

print_step "Pushing Stable Diffusion image to registry..."
if podman push ${REGISTRY}/stable-diffusion.cpp-rocm7.1:gfx1151; then
    print_success "Pushed: ${REGISTRY}/stable-diffusion.cpp-rocm7.1:gfx1151"
else
    print_error "Failed to push Stable Diffusion image"
    exit 1
fi



echo ""
echo -e "${GREEN}🎉 All images built and pushed successfully! 🎉${NC}"
echo ""
echo -e "${CYAN}Images available at:${NC}"
echo -e "  • https://hub.docker.com/r/getterup/${FEDORA_IMAGE}"
echo -e "  • https://hub.docker.com/r/getterup/${OLLAMA_IMAGE}"
echo -e "  • https://hub.docker.com/r/getterup/stable-diffusion.cpp-rocm7.1:gfx1151"
echo ""