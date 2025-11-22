#!/bin/bash
# Quick Ollama Development Commands

CONTAINER_NAME="ollama-dev"
MOUNT_PATH="/ollama"

case "$1" in
    "setup"|"init")
        echo "Setting up Ollama development environment..."
        chmod +x build-ollama.sh
        ./build-ollama.sh
        ;;
    "enter"|"shell"|"bash")
        echo "Entering Ollama development container..."
        podman exec -it ${CONTAINER_NAME} bash
        ;;
    "build")
        echo "Building Ollama in container..."
        podman exec -it ${CONTAINER_NAME} bash -c "cd ${MOUNT_PATH} && make"
        ;;
    "status"|"ps")
        echo "Container status:"
        podman ps --filter name=${CONTAINER_NAME}
        ;;
    "logs")
        echo "Container logs:"
        podman logs ${CONTAINER_NAME}
        ;;
    "stop")
        echo "Stopping container..."
        podman stop ${CONTAINER_NAME}
        ;;
    "start")
        echo "Starting container..."
        podman start ${CONTAINER_NAME}
        ;;
    "remove"|"rm")
        echo "Removing container..."
        podman stop ${CONTAINER_NAME} 2>/dev/null || true
        podman rm ${CONTAINER_NAME}
        ;;
    "clean")
        echo "Cleaning up everything..."
        podman stop ${CONTAINER_NAME} 2>/dev/null || true
        podman rm ${CONTAINER_NAME} 2>/dev/null || true
        rm -rf ollama-src
        ;;
    "help"|"")
        echo "Ollama Development Helper Commands:"
        echo ""
        echo "  setup    - Clone repository and setup development container"
        echo "  enter    - Enter the development container shell"
        echo "  build    - Build Ollama in the container"
        echo "  status   - Show container status"
        echo "  logs     - Show container logs"
        echo "  stop     - Stop the container"
        echo "  start    - Start the container"
        echo "  remove   - Remove the container"
        echo "  clean    - Remove everything (container and source)"
        echo "  help     - Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use './ollama-dev.sh help' for available commands"
        exit 1
        ;;
esac