#!/bin/bash
set -e

# ComfyUI Build Manager
# Choose between different venv build approaches

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       ComfyUI Build Manager          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${CYAN}Choose your build approach:${NC}"
echo ""
echo "1. 🐍 Native venv build (comfyui-build-venv.sh)"
echo "   - Builds virtual environments directly on host"
echo "   - Requires Python, pip, and ROCm installed on host"
echo "   - Fastest runtime performance"
echo "   - Best for development"
echo ""
echo "2. 🐳 Container-based extraction (build-venv-from-containers.sh)"
echo "   - Builds venvs in containers, then extracts them"
echo "   - Only requires docker/Docker"
echo "   - Isolated build environment"
echo "   - Best for deployment"
echo ""
echo "3. 🐳 Full container build (build-comfyui-variants.sh)"
echo "   - Builds complete container images"
echo "   - Ready-to-run containers"
echo "   - Best for production deployment"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo -e "${GREEN}Starting native venv build...${NC}"
        echo ""
        exec ./comfyui-build-venv.sh
        ;;
    2)
        echo -e "${GREEN}Starting container-based venv extraction...${NC}"
        echo ""
        exec ./build-venv-from-containers.sh
        ;;
    3)
        echo -e "${GREEN}Starting full container build...${NC}"
        echo ""
        exec ./build-comfyui-variants.sh
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac