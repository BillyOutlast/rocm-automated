#!/bin/bash
set -e

# ComfyUI Virtual Environment Prebuild Script
# Creates optimized virtual environments for each GPU architecture variant

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_DIR="./comfyui-venvs"
COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI"
PYTHON_VERSION="python3"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ComfyUI Virtual Environment Builder  ${NC}"
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

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check for required tools
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists python3; then
    print_error "Python 3 is not installed"
    exit 1
fi

if ! command_exists git; then
    print_error "Git is not installed"
    exit 1
fi

print_success "Required tools found: python3, git"

# Create base directory
mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}"

# Clone ComfyUI if not exists
if [ ! -d "ComfyUI" ]; then
    print_step "Cloning ComfyUI repository..."
    git clone "${COMFYUI_REPO}"
    print_success "ComfyUI repository cloned"
else
    print_step "Updating ComfyUI repository..."
    cd ComfyUI
    git pull origin master || git pull origin main
    cd ..
    print_success "ComfyUI repository updated"
fi

# Define GPU architecture variants
declare -A GPU_VARIANTS=(
    ["rocm7.1"]="https://download.pytorch.org/whl/nightly/rocm7.1"
    ["rdna3-gfx110x"]="https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/"
    ["rdna3.5-gfx1151"]="https://rocm.nightlies.amd.com/v2/gfx1151/"
    ["rdna4-gfx120x"]="https://rocm.nightlies.amd.com/v2/gfx120X-all/"
)

declare -A GPU_DESCRIPTIONS=(
    ["rocm7.1"]="General ROCm 7.1 compatibility"
    ["rdna3-gfx110x"]="RDNA 3 (RX 7000 series)"
    ["rdna3.5-gfx1151"]="RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)"
    ["rdna4-gfx120x"]="RDNA 4 (RX 9000 series)"
)

# Function to create virtual environment for a variant
create_venv() {
    local variant=$1
    local pytorch_url=$2
    local description=$3
    local venv_dir="venv-${variant}"
    
    echo ""
    print_step "Creating virtual environment for ${variant}"
    echo -e "${CYAN}Description: ${description}${NC}"
    echo -e "${CYAN}PyTorch URL: ${pytorch_url}${NC}"
    
    # Remove existing venv if it exists
    if [ -d "ComfyUI/${venv_dir}" ]; then
        print_warning "Removing existing virtual environment..."
        rm -rf "ComfyUI/${venv_dir}"
    fi
    
    # Create virtual environment
    cd ComfyUI
    
    print_step "Creating Python virtual environment..."
    ${PYTHON_VERSION} -m venv "${venv_dir}"
    
    # Activate virtual environment and install dependencies
    source "${venv_dir}/bin/activate"
    
    print_step "Upgrading pip..."
    pip install --upgrade pip
    
    print_step "Installing PyTorch for ${variant}..."
    if echo "${pytorch_url}" | grep -q "rocm.nightlies.amd.com"; then
        pip install --pre torch torchvision torchaudio --extra-index-url "${pytorch_url}"
    else
        pip install --pre torch torchvision torchaudio --index-url "${pytorch_url}"
    fi
    
    print_step "Installing ComfyUI requirements..."
    pip install -r requirements.txt
    
    print_step "Installing additional dependencies..."
    pip install opencv-python gguf
    
    # Install ROCm-specific optimizations
    print_step "Installing ROCm optimizations..."
    pip install --pre torchvision torchaudio
    
    # Create environment activation script
    cat > "${venv_dir}/activate_comfyui.sh" << EOF
#!/bin/bash
# ComfyUI ${variant} Environment Activation Script

# Activate virtual environment
source \$(dirname \$0)/bin/activate

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
echo "Ready to run: python main.py --listen 0.0.0.0 --port 8188"
EOF
    
    chmod +x "${venv_dir}/activate_comfyui.sh"
    
    # Create requirements freeze
    pip freeze > "${venv_dir}/requirements-${variant}.txt"
    
    deactivate
    cd ..
    
    print_success "Virtual environment created for ${variant}"
    
    # Show size information
    local size=$(du -sh "ComfyUI/${venv_dir}" | cut -f1)
    echo -e "${CYAN}Environment size: ${size}${NC}"
}

# Build virtual environments for all variants
print_step "Building virtual environments for all GPU variants..."

for variant in "${!GPU_VARIANTS[@]}"; do
    create_venv "$variant" "${GPU_VARIANTS[$variant]}" "${GPU_DESCRIPTIONS[$variant]}"
done

# Create master launcher script
print_step "Creating master launcher script..."
cat > "launch-comfyui.sh" << 'EOF'
#!/bin/bash

# ComfyUI Multi-Variant Launcher
# Choose your GPU architecture and launch ComfyUI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMFYUI_DIR="${SCRIPT_DIR}/ComfyUI"

echo "========================================="
echo "      ComfyUI Multi-Variant Launcher     "
echo "========================================="
echo ""
echo "Available GPU variants:"
echo "  1) rocm7.1        - General ROCm 7.1 compatibility"
echo "  2) rdna3-gfx110x  - RDNA 3 (RX 7000 series)"
echo "  3) rdna3.5-gfx1151 - RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)"
echo "  4) rdna4-gfx120x  - RDNA 4 (RX 9000 series)"
echo ""

# Function to launch ComfyUI with specified variant
launch_variant() {
    local variant=$1
    local venv_dir="venv-${variant}"
    
    if [ ! -d "${COMFYUI_DIR}/${venv_dir}" ]; then
        echo "Error: Virtual environment for ${variant} not found"
        echo "Please run comfyui-build-venv.sh first"
        exit 1
    fi
    
    echo "Launching ComfyUI with ${variant} variant..."
    cd "${COMFYUI_DIR}"
    
    # Activate the environment
    source "${venv_dir}/activate_comfyui.sh"
    
    # Launch ComfyUI
    python main.py --listen 0.0.0.0 --port 8188 --force-fp16 "$@"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <variant> [additional_args...]"
    echo "Example: $0 rocm7.1"
    echo "Example: $0 rdna3-gfx110x --cpu"
    exit 1
fi

VARIANT=$1
shift  # Remove first argument, keep the rest for ComfyUI

case $VARIANT in
    1|rocm7.1)
        launch_variant "rocm7.1" "$@"
        ;;
    2|rdna3-gfx110x|rdna3)
        launch_variant "rdna3-gfx110x" "$@"
        ;;
    3|rdna3.5-gfx1151|rdna3.5)
        launch_variant "rdna3.5-gfx1151" "$@"
        ;;
    4|rdna4-gfx120x|rdna4)
        launch_variant "rdna4-gfx120x" "$@"
        ;;
    *)
        echo "Error: Unknown variant '$VARIANT'"
        echo "Use: rocm7.1, rdna3-gfx110x, rdna3.5-gfx1151, or rdna4-gfx120x"
        exit 1
        ;;
esac
EOF

chmod +x "launch-comfyui.sh"

# Create summary information
print_step "Creating environment summary..."
cat > "VENV_INFO.md" << EOF
# ComfyUI Virtual Environments

This directory contains pre-built virtual environments for different AMD GPU architectures.

## Available Environments

$(for variant in "${!GPU_VARIANTS[@]}"; do
    echo "### ${variant}"
    echo "- **Description**: ${GPU_DESCRIPTIONS[$variant]}"
    echo "- **PyTorch Index**: ${GPU_VARIANTS[$variant]}"
    echo "- **Directory**: ComfyUI/venv-${variant}"
    echo "- **Activation**: cd ComfyUI && source venv-${variant}/activate_comfyui.sh"
    echo ""
done)

## Usage

### Quick Launch
\`\`\`bash
./launch-comfyui.sh <variant>
\`\`\`

Examples:
\`\`\`bash
./launch-comfyui.sh rocm7.1
./launch-comfyui.sh rdna3-gfx110x
./launch-comfyui.sh rdna3.5-gfx1151
./launch-comfyui.sh rdna4-gfx120x
\`\`\`

### Manual Activation
\`\`\`bash
cd ComfyUI
source venv-<variant>/activate_comfyui.sh
python main.py --listen 0.0.0.0 --port 8188
\`\`\`

## Environment Sizes
$(for variant in "${!GPU_VARIANTS[@]}"; do
    if [ -d "ComfyUI/venv-${variant}" ]; then
        size=$(du -sh "ComfyUI/venv-${variant}" | cut -f1)
        echo "- ${variant}: ${size}"
    fi
done)

## Built on: $(date)
EOF

echo ""
echo -e "${GREEN}🎉 All virtual environments built successfully! 🎉${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
for variant in "${!GPU_VARIANTS[@]}"; do
    if [ -d "ComfyUI/venv-${variant}" ]; then
        size=$(du -sh "ComfyUI/venv-${variant}" | cut -f1)
        echo "  ✅ ${variant}: ${size} (${GPU_DESCRIPTIONS[$variant]})"
    fi
done

echo ""
echo -e "${CYAN}Usage:${NC}"
echo "  Launch ComfyUI: ./launch-comfyui.sh <variant>"
echo "  Examples:"
echo "    ./launch-comfyui.sh rocm7.1"
echo "    ./launch-comfyui.sh rdna3-gfx110x"
echo ""
echo -e "${CYAN}Directory structure:${NC}"
echo "  ${BASE_DIR}/"
echo "  ├── ComfyUI/                    # ComfyUI source code"
echo "  ├── ComfyUI/venv-rocm7.1/      # ROCm 7.1 environment"
echo "  ├── ComfyUI/venv-rdna3-gfx110x/ # RDNA 3 environment"
echo "  ├── ComfyUI/venv-rdna3.5-gfx1151/ # RDNA 3.5 environment"
echo "  ├── ComfyUI/venv-rdna4-gfx120x/ # RDNA 4 environment"
echo "  ├── launch-comfyui.sh          # Multi-variant launcher"
echo "  └── VENV_INFO.md               # Documentation"
echo ""
echo -e "${YELLOW}Ready to run ComfyUI with optimized environments for each GPU architecture!${NC}"