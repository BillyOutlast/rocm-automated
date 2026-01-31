# ROCm 7.1 Automated Docker Environment

[![ROCm](https://img.shields.io/badge/ROCm-7.1-red.svg)](https://github.com/RadeonOpenCompute/ROCm)
[![Docker](https://img.shields.io/badge/Docker-supported-blue.svg)](https://www.docker.com/)
[![AMD GPU](https://img.shields.io/badge/AMD-GPU-green.svg)](https://www.amd.com/en/graphics)

[![Daily Build](https://github.com/yourusername/rocm-automated/actions/workflows/daily-build.yml/badge.svg)](https://github.com/yourusername/rocm-automated/actions/workflows/daily-build.yml)
[![Security Scan](https://github.com/yourusername/rocm-automated/actions/workflows/security-scan.yml/badge.svg)](https://github.com/yourusername/rocm-automated/actions/workflows/security-scan.yml)
[![Release](https://github.com/yourusername/rocm-automated/actions/workflows/release.yml/badge.svg)](https://github.com/yourusername/rocm-automated/actions/workflows/release.yml)

A comprehensive Docker-based environment for running AI workloads on AMD GPUs with ROCm 7.1 support. This project provides optimized containers for Ollama LLM inference and Stable Diffusion image generation.

Sponsored by https://shad-base.com

## 🚀 Features

- **ROCm 7.1 Support**: Latest AMD GPU compute platform
- **Ollama Integration**: Optimized LLM inference with ROCm backend
- **Stable Diffusion**: AI image generation with AMD GPU acceleration
- **Multi-GPU Support**: Automatic detection and utilization of multiple AMD GPUs
- **Performance Optimized**: Tuned for maximum throughput and minimal latency
- **Easy Deployment**: One-command setup with Docker Compose

## 📋 Prerequisites

### Hardware Requirements
- **AMD GPU**: RDNA 2/3 architecture (RX 6000/7000 series or newer)
- **Memory**: 16GB+ system RAM recommended
- **VRAM**: 8GB+ GPU memory for large models

### Software Requirements
- **Linux Distribution**: Ubuntu 22.04+, Fedora 38+, or compatible
- **Docker**: 24.0+ with BuildKit support
- **Docker Compose**: 2.20+
- **Podman** (alternative): 4.0+

### Supported GPUs
- Radeon RX 7900 XTX/XT
- Radeon RX 7800/7700 XT
- Radeon RX 6950/6900/6800/6700 XT
- AMD APUs with RDNA graphics (limited performance)

## 🛠️ Installation

### 1. Clone Repository
```bash
git clone https://github.com/BillyOutlast/rocm-automated.git
cd rocm-automated
```

### 2. Set GPU Override (if needed)
For newer or unsupported GPU architectures:
```bash
# Check your GPU architecture
rocminfo | grep "Name:"

# Set override for newer GPUs (example for RX 7000 series)
export HSA_OVERRIDE_GFX_VERSION=11.0.0
```

### 3. Download and Start Services
```bash
# Pull the latest prebuilt images and start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Alternative: Build Images Locally
If you prefer to build the images locally instead of using prebuilt ones:
```bash
# Make build script executable
chmod +x build.sh

# Build all Docker images
./build.sh

# Then start services
docker-compose up -d
```

## 🐳 Docker Images

### Available Prebuilt Images
- **`getterup/ollama-rocm7.1:latest`**: Ollama with ROCm 7.1 backend for LLM inference
- **`getterup/stable-diffusion.cpp-rocm7.1:gfx1151`**: Stable Diffusion with ROCm 7.1 acceleration
- **`getterup/comfyui:rocm7.1`**: ComfyUI with ROCm 7.1 support
- **`ghcr.io/open-webui/open-webui:main`**: Web interface for Ollama

### What's Included
These prebuilt images come with:
- ROCm 7.1 runtime libraries
- GPU-specific optimizations
- Performance tuning for inference workloads
- Ready-to-run configurations

### Build Process (Optional)
The automated build script can create custom images with:
- ROCm 7.1 runtime libraries
- GPU-specific optimizations
- Performance tuning for inference workloads

## 📊 Services

### Ollama LLM Service
**Port**: `11434`  
**Container**: `ollama`

Features:
- Multi-model support (Llama, Mistral, CodeLlama, etc.)
- ROCm-optimized inference engine
- Flash Attention support
- Quantized model support (Q4, Q8)

#### Usage Examples
```bash
# Pull a model
docker exec ollama ollama pull llama3.2

# Run inference
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2", "prompt": "Hello, world!"}'

# Chat interface
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2", "messages": [{"role": "user", "content": "Hi there!"}]}'
```

### Stable Diffusion Service
**Port**: `7860`  
**Container**: `stable-diffusion.cpp`

Features:
- Text-to-image generation
- ROCm acceleration
- Multiple model formats
- Customizable parameters

## ⚙️ Configuration

### Environment Variables

#### Ollama Service
```yaml
environment:
  - OLLAMA_DEBUG=1                    # Debug level (0-2)
  - OLLAMA_FLASH_ATTENTION=true       # Enable flash attention
  - OLLAMA_KV_CACHE_TYPE="q8_0"      # KV cache quantization
  - ROCR_VISIBLE_DEVICES=0            # GPU selection
  - OLLAMA_KEEP_ALIVE=-1              # Keep models loaded
  - OLLAMA_MAX_LOADED_MODELS=1        # Max concurrent models
```

#### GPU Configuration
```yaml
environment:
  - HSA_OVERRIDE_GFX_VERSION="11.5.1" # GPU architecture override
  - HSA_ENABLE_SDMA=0                 # Disable SDMA for stability
```

### Volume Mounts
```yaml
volumes:
  - ./ollama:/root/.ollama:Z          # Model storage
  - ./stable-diffusion.cpp:/app:Z     # SD model storage
```

### Device Access
```yaml
devices:
  - /dev/kfd:/dev/kfd                 # ROCm compute device
  - /dev/dri:/dev/dri                 # GPU render nodes
group_add:
  - video                             # Video group access
```

## 🔧 Performance Tuning

### GPU Selection
For multi-GPU systems, specify the preferred device:
```bash
# List available GPUs
rocminfo

# Set specific GPU
export ROCR_VISIBLE_DEVICES=0
```

### Memory Optimization
```bash
# For large models, increase system memory limits
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Model Optimization
- Use quantized models (Q4_K_M, Q8_0) for better performance
- Enable flash attention for transformer models
- Adjust context length based on available VRAM

## 🚨 Troubleshooting

### Common Issues

#### GPU Not Detected
```bash
# Check ROCm installation
rocminfo

# Verify device permissions
ls -la /dev/kfd /dev/dri/

# Check container access
docker exec ollama rocminfo
```

#### Memory Issues
```bash
# Check VRAM usage
rocm-smi

# Monitor system memory
free -h

# Reduce model size or use quantization
```

#### Performance Issues
```bash
# Enable performance mode
sudo sh -c 'echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

# Check GPU clocks
rocm-smi -d 0 --showclocks
```

### Debug Commands
```bash
# View Ollama logs
docker-compose logs -f ollama

# Check GPU utilization
watch -n 1 rocm-smi

# Test GPU compute
docker exec ollama rocminfo | grep "Compute Unit"
```

## 📁 Project Structure

```
rocm-automated/
├── build.sh                              # Automated build script
├── docker-compose.yaml                   # Service orchestration
├── Dockerfile.rocm-7.1                   # Base ROCm image
├── Dockerfile.ollama-rocm-7.1            # Ollama with ROCm
├── Dockerfile.stable-diffusion.cpp-rocm7.1-gfx1151  # Stable Diffusion
├── ollama/                               # Ollama data directory
└── stable-diffusion.cpp/                # SD model storage
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ROCm Platform](https://github.com/RadeonOpenCompute/ROCm) - AMD's open-source GPU compute platform
- [Ollama](https://github.com/ollama/ollama) - Local LLM inference engine
- [Stable Diffusion CPP](https://github.com/leejet/stable-diffusion.cpp) - Efficient SD implementation
- [rjmalagon/ollama-linux-amd-apu](https://github.com/rjmalagon/ollama-linux-amd-apu) - AMD APU optimizations
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI/) - Advanced node-based interface for Stable Diffusion workflows
- [phueper/ollama-linux-amd-apu](https://github.com/phueper/ollama-linux-amd-apu/tree/ollama_main_rocm7) - Enhanced Ollama build with ROCm 7 optimizations

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/BillyOutlast/rocm-automated/issues)
- **Discussions**: [GitHub Discussions](https://github.com/BillyOutlast/rocm-automated/discussions)
- **ROCm Documentation**: [AMD ROCm Docs](https://docs.amd.com/)

## 🏷️ Version History

- **v1.0.0**: Initial release with ROCm 7.1 support
- **v1.1.0**: Added Ollama integration and multi-GPU support
- **v1.2.0**: Performance optimizations and Stable Diffusion support

---

## ⚠️ Known Hardware Limitations

### External GPU Enclosures
- **AOOSTAR AG02 EGPU**: ASM246X chipset is known to have compatiblity issues with linux and may downgrade to 8 GT/s PCIe x1 (tested on Fedora 42). This may impact performance with large models requiring significant VRAM transfers.

### Mini PCs
- **Minisforum MS-A1**: Tested by Level1Techs, shown to have resizable BAR issues with eGPUs over USB4 connections. May result in reduced performance or compatibility problems with ROCm workloads.


<div align="center">

**⭐ Star this repository if it helped you! ⭐**

Made with ❤️ for the AMD GPU community

</div>
