#!/bin/bash

#############################################################################
# Daily Docker Image Build Script
# 
# This script builds all ROCm container images with daily tags
# Can be run locally or in CI/CD environments
#
# Usage:
#   ./daily-build.sh [options]
#
# Options:
#   --push              Push images to registry after building
#   --no-cache          Build without using cache
#   --base-only         Build only base images (skip GPU variants)
#   --variants-only     Build only GPU variants (skip base images)
#   --gfx-arch <arch>   Build specific GPU architecture variant
#   --registry <url>    Registry URL (default: docker.io)
#   --user <username>   Registry username (default: getterup)
#   --help              Show this help message
#
# Examples:
#   ./daily-build.sh --push
#   ./daily-build.sh --base-only --no-cache
#   ./daily-build.sh --gfx-arch gfx1100 --push
#############################################################################

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Default configuration
REGISTRY="${REGISTRY:-docker.io}"
REGISTRY_USER="${REGISTRY_USER:-getterup}"
PUSH_IMAGES=false
NO_CACHE=false
BUILD_BASE=true
BUILD_VARIANTS=true
SPECIFIC_GFX=""
BUILD_DATE=$(date +'%Y-%m-%d')
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji support (can be disabled on systems without emoji support)
USE_EMOJI=true

# GPU architectures to build
GPU_VARIANTS=(
    "gfx1150"  # RDNA 3.5 (Ryzen AI 9 HX 370)
    "gfx1151"  # RDNA 3.5 (Strix Point/Ryzen AI Max+ 365)
    "gfx1200"  # RDNA 4 (RX 9070 XT)
    "gfx1201"  # RDNA 4 (RX 9060 XT/ RX 9070/XT)
    "gfx1100"  # RDNA 3 (RX 7900 XTX/XT)
    "gfx1101"  # RDNA 3 (RX 7800 XT/7700 XT)
    "gfx1030"  # RDNA 2 (RX 6000 series)
)

# Base images configuration
declare -A BASE_IMAGES
BASE_IMAGES[comfyui-rocm7.1]="Dockerfile.comfyui-rocm7.1"
BASE_IMAGES[stable-diffusion.cpp-rocm7.1]="Dockerfile.stable-diffusion.cpp-rocm7.1"

#############################################################################
# Functions
#############################################################################

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_info() {
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${CYAN}ℹ️  $1${NC}"
    else
        echo -e "${CYAN}[INFO] $1${NC}"
    fi
}

print_success() {
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${GREEN}[SUCCESS] $1${NC}"
    fi
}

print_warning() {
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    else
        echo -e "${YELLOW}[WARNING] $1${NC}"
    fi
}

print_error() {
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${RED}❌ $1${NC}"
    else
        echo -e "${RED}[ERROR] $1${NC}"
    fi
}

print_progress() {
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${BLUE}🔄 $1${NC}"
    else
        echo -e "${BLUE}[PROGRESS] $1${NC}"
    fi
}

show_help() {
    cat << EOF
Daily Docker Image Build Script

Usage: $0 [options]

Options:
    --push              Push images to registry after building
    --no-cache          Build without using cache
    --base-only         Build only base images (skip GPU variants)
    --variants-only     Build only GPU variants (skip base images)
    --gfx-arch <arch>   Build specific GPU architecture variant
    --registry <url>    Registry URL (default: docker.io)
    --user <username>   Registry username (default: getterup)
    --no-emoji          Disable emoji in output
    --help              Show this help message

Supported GPU Architectures:
$(printf '    - %s\n' "${GPU_VARIANTS[@]}")

Examples:
    # Build all images and push to registry
    $0 --push

    # Build only base images without cache
    $0 --base-only --no-cache

    # Build specific GPU variant
    $0 --gfx-arch gfx1100 --push

    # Build for different registry
    $0 --registry ghcr.io --user myuser --push

Environment Variables:
    REGISTRY        Registry URL (overridden by --registry)
    REGISTRY_USER   Registry username (overridden by --user)
    DOCKER_PASSWORD Docker registry password (for pushing)

EOF
    exit 0
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker is installed: $(docker --version)"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    print_success "Docker daemon is running"
    
    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        print_warning "Docker Buildx is not available, installing..."
        install_buildx
    fi
    print_success "Docker Buildx is available: $(docker buildx version)"
    
    # Check if we're in the right directory
    if [ ! -d "Dockerfiles" ]; then
        print_error "Dockerfiles directory not found. Please run from the repository root."
        exit 1
    fi
    print_success "Repository structure verified"
    
    echo ""
}

install_buildx() {
    mkdir -p ~/.docker/cli-plugins
    BUILDX_VERSION="v0.12.1"
    
    print_info "Downloading Docker Buildx ${BUILDX_VERSION}..."
    curl -sL -o ~/.docker/cli-plugins/docker-buildx \
        "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64"
    
    chmod +x ~/.docker/cli-plugins/docker-buildx
    print_success "Docker Buildx installed"
}

setup_buildx() {
    print_header "Setting up Docker Buildx"
    
    # Create builder if it doesn't exist
    if ! docker buildx inspect daily-builder &> /dev/null; then
        print_info "Creating new buildx builder instance..."
        docker buildx create --name daily-builder --use --bootstrap
        print_success "Builder 'daily-builder' created"
    else
        print_info "Using existing builder 'daily-builder'"
        docker buildx use daily-builder
    fi
    
    # Show builder info
    docker buildx inspect --bootstrap
    echo ""
}

login_registry() {
    if [ "$PUSH_IMAGES" = true ]; then
        print_header "Logging into Registry"
        
        if [ -z "${DOCKER_PASSWORD}" ]; then
            print_warning "DOCKER_PASSWORD not set, prompting for password..."
            docker login "$REGISTRY" -u "$REGISTRY_USER"
        else
            print_info "Logging in to ${REGISTRY}..."
            echo "${DOCKER_PASSWORD}" | docker login "$REGISTRY" -u "$REGISTRY_USER" --password-stdin
        fi
        
        print_success "Logged in to ${REGISTRY}"
        echo ""
    fi
}

build_base_image() {
    local image_name=$1
    local dockerfile=$2
    
    print_header "Building Base Image: ${image_name}"
    
    local full_image_name="${REGISTRY}/${REGISTRY_USER}/${image_name}"
    local tags=(
        "${full_image_name}:latest"
        "${full_image_name}:${BUILD_DATE}"
        "${full_image_name}:${GIT_SHA}"
    )
    
    print_info "Image: ${image_name}"
    print_info "Dockerfile: Dockerfiles/${dockerfile}"
    print_info "Date: ${BUILD_DATE}"
    print_info "Git SHA: ${GIT_SHA}"
    echo ""
    
    # Build tag arguments
    local tag_args=""
    for tag in "${tags[@]}"; do
        tag_args="$tag_args --tag $tag"
        print_info "Tag: $tag"
    done
    echo ""
    
    # Build arguments
    local build_args=""
    build_args="$build_args --build-arg BUILD_DATE=${BUILD_DATE}"
    build_args="$build_args --build-arg VCS_REF=${GIT_SHA}"
    
    # Cache settings
    local cache_args=""
    if [ "$NO_CACHE" = true ]; then
        cache_args="--no-cache"
        print_info "Cache: Disabled"
    else
        print_info "Cache: Enabled"
    fi
    
    # Push or load
    local output_arg=""
    if [ "$PUSH_IMAGES" = true ]; then
        output_arg="--push"
        print_info "Output: Push to registry"
    else
        output_arg="--load"
        print_info "Output: Load locally"
    fi
    echo ""
    
    # Build the image
    print_progress "Building ${image_name}..."
    
    if docker buildx build \
        --file "Dockerfiles/${dockerfile}" \
        --platform linux/amd64 \
        $build_args \
        $tag_args \
        $cache_args \
        $output_arg \
        . ; then
        print_success "Successfully built ${image_name}"
    else
        print_error "Failed to build ${image_name}"
        return 1
    fi
    
    echo ""
    return 0
}

build_gpu_variant() {
    local gfx_arch=$1
    
    print_header "Building GPU Variant: ${gfx_arch}"
    
    local image_name="stable-diffusion-cpp-${gfx_arch}"
    local full_image_name="${REGISTRY}/${REGISTRY_USER}/${image_name}"
    local tags=(
        "${full_image_name}:latest"
        "${full_image_name}:${BUILD_DATE}"
        "${full_image_name}:${GIT_SHA}"
    )
    
    print_info "GPU Architecture: ${gfx_arch}"
    print_info "Image: ${image_name}"
    print_info "Date: ${BUILD_DATE}"
    print_info "Git SHA: ${GIT_SHA}"
    echo ""
    
    # Build tag arguments
    local tag_args=""
    for tag in "${tags[@]}"; do
        tag_args="$tag_args --tag $tag"
        print_info "Tag: $tag"
    done
    echo ""
    
    # Build arguments
    local build_args=""
    build_args="$build_args --build-arg GFX_ARCH=${gfx_arch}"
    build_args="$build_args --build-arg BUILD_DATE=${BUILD_DATE}"
    build_args="$build_args --build-arg VCS_REF=${GIT_SHA}"
    
    # Cache settings
    local cache_args=""
    if [ "$NO_CACHE" = true ]; then
        cache_args="--no-cache"
    fi
    
    # Push or load
    local output_arg=""
    if [ "$PUSH_IMAGES" = true ]; then
        output_arg="--push"
        print_info "Output: Push to registry"
    else
        output_arg="--load"
        print_info "Output: Load locally"
    fi
    echo ""
    
    # Build the image
    print_progress "Building ${gfx_arch} variant..."
    
    if docker buildx build \
        --file "Dockerfiles/Dockerfile.stable-diffusion.cpp-rocm7.1" \
        --platform linux/amd64 \
        $build_args \
        $tag_args \
        $cache_args \
        $output_arg \
        . ; then
        print_success "Successfully built ${gfx_arch} variant"
    else
        print_error "Failed to build ${gfx_arch} variant"
        return 1
    fi
    
    echo ""
    return 0
}

build_all_base_images() {
    print_header "Building All Base Images"
    
    local success_count=0
    local fail_count=0
    
    for image_name in "${!BASE_IMAGES[@]}"; do
        if build_base_image "$image_name" "${BASE_IMAGES[$image_name]}"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    print_header "Base Images Build Summary"
    print_success "Successfully built: ${success_count}"
    if [ $fail_count -gt 0 ]; then
        print_error "Failed: ${fail_count}"
    fi
    echo ""
    
    return $fail_count
}

build_all_gpu_variants() {
    print_header "Building All GPU Variants"
    
    local variants_to_build=()
    
    if [ -n "$SPECIFIC_GFX" ]; then
        variants_to_build=("$SPECIFIC_GFX")
        print_info "Building specific variant: ${SPECIFIC_GFX}"
    else
        variants_to_build=("${GPU_VARIANTS[@]}")
        print_info "Building all GPU variants (${#GPU_VARIANTS[@]} total)"
    fi
    echo ""
    
    local success_count=0
    local fail_count=0
    
    for gfx_arch in "${variants_to_build[@]}"; do
        if build_gpu_variant "$gfx_arch"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    print_header "GPU Variants Build Summary"
    print_success "Successfully built: ${success_count}"
    if [ $fail_count -gt 0 ]; then
        print_error "Failed: ${fail_count}"
    fi
    echo ""
    
    return $fail_count
}

cleanup() {
    print_header "Cleanup"
    
    print_info "Cleaning up build cache..."
    docker buildx prune -f || true
    
    print_success "Cleanup completed"
    echo ""
}

show_summary() {
    local total_time=$1
    
    print_header "Build Summary"
    
    echo "Build Date:      ${BUILD_DATE}"
    echo "Git SHA:         ${GIT_SHA}"
    echo "Registry:        ${REGISTRY}"
    echo "User:            ${REGISTRY_USER}"
    echo "Base Images:     $([ "$BUILD_BASE" = true ] && echo "Yes" || echo "No")"
    echo "GPU Variants:    $([ "$BUILD_VARIANTS" = true ] && echo "Yes" || echo "No")"
    echo "Pushed:          $([ "$PUSH_IMAGES" = true ] && echo "Yes" || echo "No")"
    echo "Total Time:      ${total_time}s"
    echo ""
    
    if [ "$PUSH_IMAGES" = true ]; then
        print_success "Images are now available at:"
        for image_name in "${!BASE_IMAGES[@]}"; do
            echo "  - ${REGISTRY}/${REGISTRY_USER}/${image_name}:${BUILD_DATE}"
        done
        if [ "$BUILD_VARIANTS" = true ]; then
            for gfx_arch in "${GPU_VARIANTS[@]}"; do
                echo "  - ${REGISTRY}/${REGISTRY_USER}/stable-diffusion-cpp-${gfx_arch}:${BUILD_DATE}"
            done
        fi
    else
        print_info "Images are loaded locally (not pushed to registry)"
    fi
    
    echo ""
}

#############################################################################
# Main Script
#############################################################################

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --base-only)
            BUILD_VARIANTS=false
            shift
            ;;
        --variants-only)
            BUILD_BASE=false
            shift
            ;;
        --gfx-arch)
            SPECIFIC_GFX="$2"
            BUILD_BASE=false
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --user)
            REGISTRY_USER="$2"
            shift 2
            ;;
        --no-emoji)
            USE_EMOJI=false
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Start timer
START_TIME=$(date +%s)

# Show configuration
print_header "Daily Docker Image Build"
echo "Date:            ${BUILD_DATE}"
echo "Git SHA:         ${GIT_SHA}"
echo "Registry:        ${REGISTRY}"
echo "User:            ${REGISTRY_USER}"
echo "Push Images:     $([ "$PUSH_IMAGES" = true ] && echo "Yes" || echo "No")"
echo "No Cache:        $([ "$NO_CACHE" = true ] && echo "Yes" || echo "No")"
echo "Build Base:      $([ "$BUILD_BASE" = true ] && echo "Yes" || echo "No")"
echo "Build Variants:  $([ "$BUILD_VARIANTS" = true ] && echo "Yes" || echo "No")"
if [ -n "$SPECIFIC_GFX" ]; then
    echo "Specific GFX:    ${SPECIFIC_GFX}"
fi
echo ""

# Run build process
check_prerequisites
setup_buildx
login_registry

# Track overall success
OVERALL_SUCCESS=true

# Build base images
if [ "$BUILD_BASE" = true ]; then
    if ! build_all_base_images; then
        OVERALL_SUCCESS=false
    fi
fi

# Build GPU variants
if [ "$BUILD_VARIANTS" = true ] || [ -n "$SPECIFIC_GFX" ]; then
    if ! build_all_gpu_variants; then
        OVERALL_SUCCESS=false
    fi
fi

# Cleanup
cleanup

# Calculate total time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

# Show summary
show_summary "$TOTAL_TIME"

# Exit with appropriate code
if [ "$OVERALL_SUCCESS" = true ]; then
    print_success "All builds completed successfully!"
    exit 0
else
    print_error "Some builds failed. Please check the logs above."
    exit 1
fi
