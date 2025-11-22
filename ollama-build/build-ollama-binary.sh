#!/bin/bash
set -e

# Ollama Build Script - Builds Ollama binary inside container and saves to mounted folder

# Configuration
OLLAMA_REPO="https://github.com/rjmalagon/ollama-linux-amd-apu.git"
BASE_IMAGE="docker.io/getterup/fedora-rocm7.1:latest"
CONTAINER_NAME="ollama-build"
SOURCE_DIR="./ollama-build/ollama-src"
BUILD_OUTPUT_DIR="./ollama-build/ollama-build-output"
MOUNT_SOURCE_PATH="/ollama-src"
MOUNT_OUTPUT_PATH="/ollama-output"
PARALLEL=${PARALLEL:-8}
CMAKEVERSION=${CMAKEVERSION:-3.31.2}

echo "=== Ollama Build Script ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
if ! command_exists podman; then
    echo "Error: podman is not installed or not in PATH"
    echo "Please install podman first"
    exit 1
fi

if ! command_exists git; then
    echo "Error: git is not installed or not in PATH"
    echo "Please install git first"
    exit 1
fi

echo "✓ Required tools found: podman, git"

# Create directories
mkdir -p "${BUILD_OUTPUT_DIR}"
mkdir -p "${BUILD_OUTPUT_DIR}/bin"
mkdir -p "${BUILD_OUTPUT_DIR}/lib"

# Clean up existing container if it exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    podman stop ${CONTAINER_NAME} 2>/dev/null || true
    podman rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Clone or update the repository
if [ -d "${SOURCE_DIR}" ]; then
    echo "Source directory exists, updating repository..."
    cd "${SOURCE_DIR}"
    git pull origin main || git pull origin master
    cd ..
else
    echo "Cloning Ollama repository..."
    git clone "${OLLAMA_REPO}" "${SOURCE_DIR}"
fi

echo "✓ Repository ready at: ${SOURCE_DIR}"

# Get absolute paths for mounting
ABSOLUTE_SOURCE_PATH=$(realpath "${SOURCE_DIR}")
ABSOLUTE_OUTPUT_PATH=$(realpath "${BUILD_OUTPUT_DIR}")
echo "Source path: ${ABSOLUTE_SOURCE_PATH}"
echo "Output path: ${ABSOLUTE_OUTPUT_PATH}"

# Pull the base image
echo "Pulling base image: ${BASE_IMAGE}"
podman pull "${BASE_IMAGE}"

# Create and start the build container
echo "Creating build container..."
podman run -d \
    --name "${CONTAINER_NAME}" \
    --hostname ollama-build \
    -v "${ABSOLUTE_SOURCE_PATH}:${MOUNT_SOURCE_PATH}:Z" \
    -v "${ABSOLUTE_OUTPUT_PATH}:${MOUNT_OUTPUT_PATH}:Z" \
    --device /dev/kfd:/dev/kfd \
    --device /dev/dri:/dev/dri \
    --group-add video \
    --security-opt label=disable \
    --cap-add SYS_PTRACE \
    --ipc host \
    -e ROCM_PATH=/opt/rocm \
    -e HIP_PATH=/opt/rocm \
    -e HSA_PATH=/opt/rocm/hsa \
    -e PATH=/opt/rocm/hcc/bin:/opt/rocm/hip/bin:/opt/rocm/bin:/opt/rocm/hcc/bin:/usr/local/go/bin:$PATH \
    -e LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:$LD_LIBRARY_PATH \
    -e PARALLEL=${PARALLEL} \
    -e CMAKEVERSION=${CMAKEVERSION} \
    -e LDFLAGS=-s \
    -e CGO_ENABLED=1 \
    --workdir "${MOUNT_SOURCE_PATH}" \
    "${BASE_IMAGE}" \
    sleep infinity

echo "✓ Container '${CONTAINER_NAME}' created and started"

echo "Installing CMake ${CMAKEVERSION}..."
podman exec ${CONTAINER_NAME} bash -c "
curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKEVERSION}/cmake-${CMAKEVERSION}-linux-\$(uname -m).tar.gz | tar xz -C /usr/local --strip-components 1
"

echo "✓ CMake installed"

# Set up build environment and run the build
echo "Starting Ollama build process..."
podman exec ${CONTAINER_NAME} bash -c "
set -e
echo '=== Setting up build environment ==='
export PATH=/opt/rocm/hcc/bin:/opt/rocm/hip/bin:/opt/rocm/bin:/opt/rocm/hcc/bin:\$PATH
export LDFLAGS=-s
export PARALLEL=${PARALLEL}

echo '=== Running CMake build ==='
cmake --preset 'ROCm 7' -DOLLAMA_RUNNER_DIR=\"rocm_v7\"
cmake --build --parallel \${PARALLEL} --preset 'ROCm 7'
cmake --install build --component HIP --strip --parallel \${PARALLEL}

echo '=== Cleaning up ROCM libraries ==='
rm -f dist/lib/ollama/rocm/rocblas/library/*gfx90[06]*

echo '=== Installing Go ==='
curl -fsSL https://golang.org/dl/go\$(awk '/^go/ { print \$2 }' go.mod).linux-\$(case \$(uname -m) in x86_64) echo amd64 ;; aarch64) echo arm64 ;; esac).tar.gz | tar xz -C /usr/local
export PATH=/usr/local/go/bin:\$PATH

echo '=== Downloading Go dependencies ==='
go mod download

echo '=== Building Ollama binary ==='
export GOFLAGS=\"-ldflags=-w -s\"
export CGO_ENABLED=1
go build -trimpath -buildmode=pie -o ${MOUNT_OUTPUT_PATH}/bin/ollama .

echo '=== Copying built libraries ==='
cp -r dist/lib/ollama ${MOUNT_OUTPUT_PATH}/lib/

echo '=== Build completed successfully ==='
echo \"Ollama binary saved to: ${MOUNT_OUTPUT_PATH}/bin/ollama\"
echo \"Libraries saved to: ${MOUNT_OUTPUT_PATH}/lib/ollama\"
"

# Verify the build output
echo "Verifying build output..."
if [ -f "${BUILD_OUTPUT_DIR}/bin/ollama" ]; then
    echo "✓ Ollama binary built successfully!"
    ls -la "${BUILD_OUTPUT_DIR}/bin/ollama"
    file "${BUILD_OUTPUT_DIR}/bin/ollama"
else
    echo "✗ Build failed - binary not found"
    exit 1
fi

if [ -d "${BUILD_OUTPUT_DIR}/lib/ollama" ]; then
    echo "✓ Ollama libraries built successfully!"
    ls -la "${BUILD_OUTPUT_DIR}/lib/ollama/"
else
    echo "✗ Build failed - libraries not found"
    exit 1
fi

# Clean up container
echo "Cleaning up build container..."
podman stop ${CONTAINER_NAME}
podman rm ${CONTAINER_NAME}

echo ""
echo "=== Build Complete ==="
echo "Ollama binary: ${BUILD_OUTPUT_DIR}/bin/ollama"
echo "Ollama libraries: ${BUILD_OUTPUT_DIR}/lib/ollama/"
echo ""
echo "To test the binary:"
echo "  ${BUILD_OUTPUT_DIR}/bin/ollama --help"
echo ""
echo "To create a runtime container:"
echo "  ./create-ollama-runtime.sh"