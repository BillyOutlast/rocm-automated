#!/bin/bash
set -e

# Ollama Development Environment Setup Script
# This script clones the Ollama source and sets up a development container

# Configuration
OLLAMA_REPO="https://github.com/rjmalagon/ollama-linux-amd-apu.git"
BASE_IMAGE="docker.io/getterup/fedora-rocm7.1:latest"
CONTAINER_NAME="ollama-dev"
SOURCE_DIR="./ollama-src"
MOUNT_PATH="/ollama-src"

echo "=== Ollama Development Environment Setup ==="

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

# Get the absolute path for mounting
ABSOLUTE_SOURCE_PATH=$(realpath "${SOURCE_DIR}")
echo "Source path: ${ABSOLUTE_SOURCE_PATH}"

# Pull the base image
echo "Pulling base image: ${BASE_IMAGE}"
podman pull "${BASE_IMAGE}"

# Create and start the development container
echo "Creating development container..."
podman run -d \
    --name "${CONTAINER_NAME}" \
    --hostname ollama-dev \
    -v "${ABSOLUTE_SOURCE_PATH}:${MOUNT_PATH}:Z" \
    --device /dev/kfd:/dev/kfd \
    --device /dev/dri:/dev/dri \
    --group-add video \
    --security-opt label=disable \
    --cap-add SYS_PTRACE \
    --ipc host \
    -e ROCM_PATH=/opt/rocm \
    -e HIP_PATH=/opt/rocm \
    -e HSA_PATH=/opt/rocm/hsa \
    -e PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:/usr/local/go/bin:$PATH \
    -e LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:$LD_LIBRARY_PATH \
    --workdir "${MOUNT_PATH}" \
    "${BASE_IMAGE}" \
    sleep infinity

echo "✓ Container '${CONTAINER_NAME}' created and started"

# Install additional dependencies in the container
echo "Installing additional build dependencies..."
podman exec "${CONTAINER_NAME}" dnf install -y \
    git cmake gcc-c++ golang \
    rocm-dev rocm-runtime hip-devel \
    rocblas-devel hipblas-devel \
    wget curl

# Verify the setup
echo "Verifying setup..."
echo "Container status:"
podman ps --filter name="${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Mounted source in container:"
podman exec "${CONTAINER_NAME}" ls -la "${MOUNT_PATH}"

echo ""
echo "ROCm installation check:"
podman exec "${CONTAINER_NAME}" rocminfo | head -10 || echo "ROCm info not available"

echo ""
echo "=== Setup Complete ==="
echo "Container Name: ${CONTAINER_NAME}"
echo "Source Mount: ${MOUNT_PATH}"
echo "Local Source: ${ABSOLUTE_SOURCE_PATH}"
echo ""
echo "To enter the development environment:"
echo "  podman exec -it ${CONTAINER_NAME} bash"
echo ""
echo "To build Ollama in the container:"
echo "  podman exec -it ${CONTAINER_NAME} bash -c 'cd ${MOUNT_PATH} && make'"
echo ""
echo "To stop the container:"
echo "  podman stop ${CONTAINER_NAME}"
echo ""
echo "To remove the container:"
echo "  podman rm ${CONTAINER_NAME}"