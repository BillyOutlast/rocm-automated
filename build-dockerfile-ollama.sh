#!/bin/bash
set -e

# Container-based Ollama Build Script using Dockerfile
# Builds Ollama binary using the Dockerfile and extracts output to host

# Configuration matching the Dockerfile
OLLAMA_REPO="https://github.com/rjmalagon/ollama-linux-amd-apu.git"
DOCKERFILE_PATH="./Dockerfiles/Dockerfile.ollama-rocm-7.1"
CONTAINER_NAME="ollama-dockerfile-build"
BUILD_IMAGE_NAME="ollama-rocm7.1-build-temp"
SOURCE_DIR="./ollama-src"
BUILD_OUTPUT_DIR="./ollama-build-output"
PARALLEL=${PARALLEL:-8}
CMAKEVERSION=${CMAKEVERSION:-3.31.2}

echo "=== Container-based Dockerfile Ollama Build ==="

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

# Clean up any existing build container or image
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing build container: ${CONTAINER_NAME}"
    podman stop ${CONTAINER_NAME} 2>/dev/null || true
    podman rm ${CONTAINER_NAME} 2>/dev/null || true
fi

if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${BUILD_IMAGE_NAME}:latest$"; then
    echo "Removing existing build image: ${BUILD_IMAGE_NAME}"
    podman rmi ${BUILD_IMAGE_NAME}:latest
fi

# Build the Docker image
echo "Building Ollama Docker image..."
echo "Command: podman build --build-arg PARALLEL=${PARALLEL} --build-arg CMAKEVERSION=${CMAKEVERSION} -t ${BUILD_IMAGE_NAME} -f ${DOCKERFILE_PATH}"

if podman build \
    --build-arg PARALLEL=${PARALLEL} \
    --build-arg CMAKEVERSION=${CMAKEVERSION} \
    -t "${BUILD_IMAGE_NAME}" \
    -f "${DOCKERFILE_PATH}" \
    .; then
    echo "✓ Docker image '${BUILD_IMAGE_NAME}' built successfully"
else
    echo "✗ Failed to build Docker image"
    exit 1
fi

# Create a temporary container to extract the built artifacts
echo "Creating temporary container to extract build artifacts..."
podman create --name ${CONTAINER_NAME} ${BUILD_IMAGE_NAME}

# Extract the built binary and libraries
echo "Extracting built artifacts..."
if podman cp ${CONTAINER_NAME}:/ollama-output/bin/ollama ${BUILD_OUTPUT_DIR}/bin/ 2>/dev/null; then
    echo "✓ Extracted binary from /ollama-output/bin/"
elif podman cp ${CONTAINER_NAME}:/usr/bin/ollama ${BUILD_OUTPUT_DIR}/bin/ 2>/dev/null; then
    echo "✓ Extracted binary from /usr/bin/"
else
    echo "✗ Failed to extract binary"
    podman rm ${CONTAINER_NAME}
    exit 1
fi

if podman cp ${CONTAINER_NAME}:/ollama-output/lib/ollama ${BUILD_OUTPUT_DIR}/lib/ 2>/dev/null; then
    echo "✓ Extracted libraries from /ollama-output/lib/"
elif podman cp ${CONTAINER_NAME}:/usr/lib/ollama ${BUILD_OUTPUT_DIR}/lib/ 2>/dev/null; then
    echo "✓ Extracted libraries from /usr/lib/"
else
    echo "⚠ Warning: Could not extract libraries, they may be in a different location"
fi

# Clean up the temporary container
podman rm ${CONTAINER_NAME}

# Verify the build output
echo "Verifying build output..."
if [ -f "${BUILD_OUTPUT_DIR}/bin/ollama" ]; then
    echo "✓ Ollama binary extracted successfully!"
    ls -la "${BUILD_OUTPUT_DIR}/bin/ollama"
    file "${BUILD_OUTPUT_DIR}/bin/ollama"
else
    echo "✗ Build failed - binary not found"
    exit 1
fi

if [ -d "${BUILD_OUTPUT_DIR}/lib/ollama" ]; then
    echo "✓ Ollama libraries extracted successfully!"
    ls -la "${BUILD_OUTPUT_DIR}/lib/ollama/"
else
    echo "⚠ Libraries not found - binary may be statically linked"
fi

echo ""
echo "=== Build Complete ==="
echo "Build Image: ${BUILD_IMAGE_NAME}"
echo "Ollama binary: ${BUILD_OUTPUT_DIR}/bin/ollama"
echo "Ollama libraries: ${BUILD_OUTPUT_DIR}/lib/ollama/"
echo ""
echo "To run the built image directly:"
echo "  podman run --rm -p 11434:11434 --device /dev/kfd:/dev/kfd --device /dev/dri:/dev/dri --group-add video ${BUILD_IMAGE_NAME}"
echo ""
echo "To test the extracted binary:"
echo "  ${BUILD_OUTPUT_DIR}/bin/ollama --help"
echo ""
echo "To create a runtime container:"
echo "  ./create-ollama-runtime.sh"