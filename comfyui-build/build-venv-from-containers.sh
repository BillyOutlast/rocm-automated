#!/bin/bash
set -e

# ComfyUI Container-based Virtual Environment Builder
# Uses containers to build and extract optimized venvs for each variant

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REGISTRY="docker.io/getterup"
DOCKERFILE_DIR="../Dockerfiles"
OUTPUT_DIR="./venv-containers"
EXTRACT_DIR="./extracted-venvs"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} ComfyUI Container venv Extractor     ${NC}"
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

# Check for podman
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed"
    exit 1
fi

print_success "Podman found"

# Create output directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${EXTRACT_DIR}"

# Define variants (matching build-comfyui-variants.sh)
declare -A VARIANTS=(
    ["rocm7.1"]="https://download.pytorch.org/whl/nightly/rocm7.1"
    ["rdna3-gfx110x"]="https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/"
    ["rdna3.5-gfx1151"]="https://rocm.nightlies.amd.com/v2/gfx1151/"
    ["rdna4-gfx120x"]="https://rocm.nightlies.amd.com/v2/gfx120X-all/"
)

declare -A DESCRIPTIONS=(
    ["rocm7.1"]="General ROCm 7.1 compatibility"
    ["rdna3-gfx110x"]="RDNA 3 (RX 7000 series)"
    ["rdna3.5-gfx1151"]="RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)"
    ["rdna4-gfx120x"]="RDNA 4 (RX 9000 series)"
)

# Function to extract venv from container
extract_venv() {
    local variant=$1
    local pytorch_url=$2
    local description=$3
    local image_name="comfyui-venv-${variant}"
    local container_name="comfyui-extract-${variant}"
    
    echo ""
    print_step "Building and extracting venv for ${variant}"
    echo -e "${CYAN}Description: ${description}${NC}"
    
    # Build container with venv
    print_step "Building container image for ${variant}..."
    if podman build \
        --build-arg PYTORCH_INDEX_URL="${pytorch_url}" \
        --build-arg GPU_ARCH="${variant}" \
        -t "${image_name}" \
        -f "${DOCKERFILE_DIR}/Dockerfile.comfyui-rocm7.1" \
        .; then
        print_success "Container built successfully"
    else
        print_error "Failed to build container for ${variant}"
        return 1
    fi
    
    # Create container to extract venv
    print_step "Creating temporary container..."
    podman create --name "${container_name}" "${image_name}"
    
    # Extract the virtual environment
    print_step "Extracting virtual environment..."
    local extract_path="${EXTRACT_DIR}/${variant}"
    mkdir -p "${extract_path}"
    
    # Extract the venv and ComfyUI
    if podman cp "${container_name}:/app/ComfyUI/venv" "${extract_path}/" && \
       podman cp "${container_name}:/app/ComfyUI" "${extract_path}/ComfyUI"; then
        print_success "Virtual environment extracted"
    else
        print_error "Failed to extract venv for ${variant}"
        podman rm "${container_name}" 2>/dev/null || true
        return 1
    fi
    
    # Create activation script
    cat > "${extract_path}/activate_${variant}.sh" << EOF
#!/bin/bash
# ComfyUI ${variant} Environment Activation Script

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "\${SCRIPT_DIR}/venv/bin/activate"

# Set ROCm environment variables
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HIP_CLANG_PATH=/opt/rocm/llvm/bin
export HIP_DEVICE_LIB_PATH=/opt/rocm/amdgcn/bitcode
export PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:\$PATH
export LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:\$LD_LIBRARY_PATH

# Set GPU-specific variables
export HIP_VISIBLE_DEVICES=0
export AMD_SERIALIZE_KERNEL=3
export PYTORCH_ROCM_ARCH="${variant}"
export HSA_OVERRIDE_GFX_VERSION="${variant}"
export TORCH_USE_HIP_DSA=1

echo "ComfyUI environment activated for ${variant} (${description})"
echo "Working directory: \${SCRIPT_DIR}/ComfyUI"
echo "Ready to run: cd \${SCRIPT_DIR}/ComfyUI && python main.py --listen 0.0.0.0 --port 8188"
EOF
    
    chmod +x "${extract_path}/activate_${variant}.sh"
    
    # Create launcher script
    cat > "${extract_path}/launch_comfyui_${variant}.sh" << EOF
#!/bin/bash
# ComfyUI ${variant} Launcher

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

# Activate environment
source "\${SCRIPT_DIR}/activate_${variant}.sh"

# Change to ComfyUI directory and launch
cd "\${SCRIPT_DIR}/ComfyUI"
python main.py --listen 0.0.0.0 --port 8188 --force-fp16 "\$@"
EOF
    
    chmod +x "${extract_path}/launch_comfyui_${variant}.sh"
    
    # Clean up container
    podman rm "${container_name}"
    
    # Optionally remove the image to save space
    read -p "Remove container image for ${variant} to save space? (y/N): " remove_image
    if [[ $remove_image =~ ^[Yy]$ ]]; then
        podman rmi "${image_name}"
        print_success "Container image removed"
    fi
    
    # Show size information
    local size=$(du -sh "${extract_path}" | cut -f1)
    print_success "Virtual environment for ${variant} complete (${size})"
}

# Build and extract venvs for all variants
print_step "Building and extracting virtual environments for all variants..."

for variant in "${!VARIANTS[@]}"; do
    extract_venv "$variant" "${VARIANTS[$variant]}" "${DESCRIPTIONS[$variant]}"
done

# Create master launcher
print_step "Creating master launcher script..."
cat > "${EXTRACT_DIR}/launch-any-variant.sh" << 'EOF'
#!/bin/bash
# ComfyUI Multi-Variant Launcher (from extracted containers)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "   ComfyUI Container-Extracted Launcher  "
echo "========================================="
echo ""
echo "Available variants:"

# List available variants
for dir in "${SCRIPT_DIR}"/*; do
    if [ -d "$dir" ] && [ -f "$dir/activate_"*.sh ]; then
        variant=$(basename "$dir")
        echo "  - ${variant}"
    fi
done

echo ""

if [ $# -eq 0 ]; then
    echo "Usage: $0 <variant> [comfyui_args...]"
    echo "Example: $0 rocm7.1"
    exit 1
fi

VARIANT=$1
shift

VARIANT_DIR="${SCRIPT_DIR}/${VARIANT}"

if [ ! -d "${VARIANT_DIR}" ]; then
    echo "Error: Variant '${VARIANT}' not found"
    exit 1
fi

if [ ! -f "${VARIANT_DIR}/launch_comfyui_${VARIANT}.sh" ]; then
    echo "Error: Launcher not found for variant '${VARIANT}'"
    exit 1
fi

echo "Launching ComfyUI with variant: ${VARIANT}"
exec "${VARIANT_DIR}/launch_comfyui_${VARIANT}.sh" "$@"
EOF

chmod +x "${EXTRACT_DIR}/launch-any-variant.sh"

# Create documentation
cat > "${EXTRACT_DIR}/README.md" << EOF
# Extracted ComfyUI Virtual Environments

This directory contains virtual environments extracted from ComfyUI containers, optimized for different AMD GPU architectures.

## Available Variants

$(for variant in "${!VARIANTS[@]}"; do
    if [ -d "${EXTRACT_DIR}/${variant}" ]; then
        size=$(du -sh "${EXTRACT_DIR}/${variant}" 2>/dev/null | cut -f1 || echo "unknown")
        echo "### ${variant} (${size})"
        echo "- **Description**: ${DESCRIPTIONS[$variant]}"
        echo "- **PyTorch Index**: ${VARIANTS[$variant]}"
        echo "- **Directory**: ${variant}/"
        echo "- **Launcher**: ${variant}/launch_comfyui_${variant}.sh"
        echo ""
    fi
done)

## Usage

### Quick Launch
\`\`\`bash
./launch-any-variant.sh <variant>
\`\`\`

### Direct Launch
\`\`\`bash
./<variant>/launch_comfyui_<variant>.sh
\`\`\`

### Manual Activation
\`\`\`bash
cd <variant>
source activate_<variant>.sh
cd ComfyUI
python main.py --listen 0.0.0.0 --port 8188
\`\`\`

## Built on: $(date)
EOF

echo ""
echo -e "${GREEN}🎉 All virtual environments extracted successfully! 🎉${NC}"
echo ""
echo -e "${CYAN}Extracted variants:${NC}"
for variant in "${!VARIANTS[@]}"; do
    if [ -d "${EXTRACT_DIR}/${variant}" ]; then
        size=$(du -sh "${EXTRACT_DIR}/${variant}" | cut -f1)
        echo "  ✅ ${variant}: ${size} (${DESCRIPTIONS[$variant]})"
    fi
done

echo ""
echo -e "${CYAN}Usage:${NC}"
echo "  cd ${EXTRACT_DIR}"
echo "  ./launch-any-variant.sh <variant>"
echo ""
echo -e "${CYAN}Individual launchers:${NC}"
for variant in "${!VARIANTS[@]}"; do
    if [ -d "${EXTRACT_DIR}/${variant}" ]; then
        echo "  ./${variant}/launch_comfyui_${variant}.sh"
    fi
done

echo ""
echo -e "${YELLOW}Ready to run ComfyUI with pre-built, optimized environments!${NC}"