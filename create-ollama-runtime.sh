#!/bin/bash
set -e

# Create Ollama Runtime Container Script
# Uses the binary built by build-ollama-binary.sh

# Configuration
RUNTIME_IMAGE="registry.fedoraproject.org/fedora:43"
CONTAINER_NAME="ollama-runtime"
BUILD_OUTPUT_DIR="./ollama-build-output"
RUNTIME_DATA_DIR="./ollama-data"

echo "=== Creating Ollama Runtime Container ==="

# Check if build output exists
if [ ! -f "${BUILD_OUTPUT_DIR}/bin/ollama" ]; then
    echo "Error: Ollama binary not found at ${BUILD_OUTPUT_DIR}/bin/ollama"
    echo "Please run ./build-ollama-binary.sh first"
    exit 1
fi

if [ ! -d "${BUILD_OUTPUT_DIR}/lib/ollama" ]; then
    echo "Error: Ollama libraries not found at ${BUILD_OUTPUT_DIR}/lib/ollama"
    echo "Please run ./build-ollama-binary.sh first"
    exit 1
fi

# Create runtime data directory
mkdir -p "${RUNTIME_DATA_DIR}"

# Get absolute paths
ABSOLUTE_BUILD_PATH=$(realpath "${BUILD_OUTPUT_DIR}")
ABSOLUTE_DATA_PATH=$(realpath "${RUNTIME_DATA_DIR}")

# Clean up existing container if it exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    podman stop ${CONTAINER_NAME} 2>/dev/null || true
    podman rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Pull runtime image
echo "Pulling runtime image: ${RUNTIME_IMAGE}"
podman pull ${RUNTIME_IMAGE}

echo "Creating runtime container..."
podman run -d \
    --name "${CONTAINER_NAME}" \
    --hostname ollama-runtime \
    -p 11434:11434 \
    -v "${ABSOLUTE_BUILD_PATH}/bin:/usr/local/bin:Z" \
    -v "${ABSOLUTE_BUILD_PATH}/lib/ollama:/usr/lib/ollama:Z" \
    -v "${ABSOLUTE_DATA_PATH}:/root/.ollama:Z" \
    --device /dev/kfd:/dev/kfd \
    --device /dev/dri:/dev/dri \
    --group-add video \
    --security-opt label=disable \
    --cap-add SYS_PTRACE \
    --ipc host \
    -e ROCM_PATH=/opt/rocm \
    -e HIP_PATH=/opt/rocm \
    -e HSA_PATH=/opt/rocm/hsa \
    -e PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:/usr/local/bin:$PATH \
    -e LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:/usr/lib/ollama:/usr/lib/ollama/rocm:$LD_LIBRARY_PATH \
    -e OLLAMA_DEBUG=1 \
    --entrypoint /bin/bash \
    "${RUNTIME_IMAGE}" \
    -c "
    # Install ROCm runtime
    tee /etc/yum.repos.d/rocm.repo <<REPO
[ROCm-7.1]
name=ROCm7.1
baseurl=https://repo.radeon.com/rocm/el9/7.1/main
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
REPO

    dnf -y --nodocs --setopt=install_weak_deps=False install \
        rocm-runtime rocm-device-libs hip-runtime-amd \
        rocblas hipblas rocminfo rocm-smi hsa-rocr \
        ca-certificates

    # Start Ollama
    exec /usr/local/bin/ollama serve
    "

echo "✓ Runtime container '${CONTAINER_NAME}' created and started"
echo ""
echo "Container is now running on port 11434"
echo "Test with: curl http://localhost:11434/api/tags"
echo ""
echo "To enter the container:"
echo "  podman exec -it ${CONTAINER_NAME} bash"
echo ""
echo "To view logs:"
echo "  podman logs -f ${CONTAINER_NAME}"
echo ""
echo "To stop the container:"
echo "  podman stop ${CONTAINER_NAME}"