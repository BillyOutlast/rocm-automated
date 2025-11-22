#!/bin/bash

# Build script for stable-diffusion.cpp with different AMD GPU architecture support

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
BASE_IMAGE_NAME="stable-diffusion-cpp"

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Stable Diffusion.cpp Build Script   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Array of GFX architectures to build for
declare -A GFX_ARCHITECTURES
GFX_ARCHITECTURES["gfx1150"]="RDNA 3.5 (Ryzen AI 9 HX 370)"
GFX_ARCHITECTURES["gfx1151"]="RDNA 3.5 (Strix Point/Ryzen AI Max+ 365)"
GFX_ARCHITECTURES["gfx1200"]="RDNA 4 (RX 9070 XT)"
GFX_ARCHITECTURES["gfx1100"]="RDNA 3 (RX 7900 XTX/XT)"
GFX_ARCHITECTURES["gfx1101"]="RDNA 3 (RX 7800 XT/7700 XT)"
GFX_ARCHITECTURES["gfx1030"]="RDNA 2 (RX 6000 series)"
GFX_ARCHITECTURES["gfx1201"]="RDNA 4 (RX 9060 XT)"

# Check if podman is available
if ! command -v podman &> /dev/null; then
    print_error "podman is not installed or not in PATH"
    exit 1
fi

print_step "Building stable-diffusion.cpp podman images for different AMD GPU architectures..."
echo ""

# Build images for each architecture
for gfx_name in "${!GFX_ARCHITECTURES[@]}"; do
    architecture_desc="${GFX_ARCHITECTURES[$gfx_name]}"
    image_tag="${REGISTRY}/${BASE_IMAGE_NAME}:${gfx_name}"
    
    print_step "Building for ${gfx_name} - ${architecture_desc}..."
    echo -e "${YELLOW}Command: podman build -t ${image_tag} --build-arg GFX_NAME=${gfx_name} -f Dockerfile.stable-diffusion.cpp-rocm7.1 .${NC}"
    
    if podman build -t "${image_tag}" \
        --build-arg GFX_NAME="${gfx_name}" \
        -f Dockerfile.stable-diffusion.cpp-rocm7.1 .; then
        print_success "Built ${image_tag} successfully"
    else
        print_error "Failed to build ${image_tag}"
        exit 1
    fi
    echo ""
done

print_success "All stable-diffusion.cpp builds completed!"
echo ""

print_step "Pushing images to registry..."
echo ""

for gfx_name in "${!GFX_ARCHITECTURES[@]}"; do
    image_tag="${REGISTRY}/${BASE_IMAGE_NAME}:${gfx_name}"
    architecture_desc="${GFX_ARCHITECTURES[$gfx_name]}"
    
    print_step "Pushing ${image_tag} (${architecture_desc})..."
    if podman push "${image_tag}"; then
        print_success "Pushed ${image_tag} successfully"
    else
        print_error "Failed to push ${image_tag}"
    fi
    echo ""
done

print_success "All images pushed to registry!"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}              Summary                   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Built images:"
for gfx_name in "${!GFX_ARCHITECTURES[@]}"; do
    image_tag="${REGISTRY}/${BASE_IMAGE_NAME}:${gfx_name}"
    architecture_desc="${GFX_ARCHITECTURES[$gfx_name]}"
    echo -e "  ${GREEN}${image_tag}${NC} - ${architecture_desc}"
done
echo ""
echo -e "${CYAN}To run an image:${NC}"
echo -e "  ${YELLOW}podman run -it --device=/dev/kfd --device=/dev/dri --group-add video -p 7860:7860 ${REGISTRY}/${BASE_IMAGE_NAME}:<gfx_name>${NC}"
echo ""
echo -e "${CYAN}Example for RDNA 3:${NC}"
echo -e "  ${YELLOW}podman run -it --device=/dev/kfd --device=/dev/dri --group-add video -p 7860:7860 ${REGISTRY}/${BASE_IMAGE_NAME}:gfx1100${NC}"