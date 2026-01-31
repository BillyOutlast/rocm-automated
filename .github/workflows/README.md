# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for automated building, testing, and releasing of the ROCm 7.1 container environment.

## 🔧 Workflows

### 1. Daily Build (`daily-build.yml`)
- **Schedule**: Runs daily at 02:00 UTC
- **Purpose**: Automated builds of all container images
- **Triggers**: 
  - Daily schedule
  - Manual dispatch with options
- **What it builds**:
  - Base images (ComfyUI, Stable Diffusion.cpp)
  - GPU-specific variants for different AMD architectures
  - Tests Docker Compose configuration

### 2. Release Build (`release.yml`)
- **Triggers**: 
  - Git tags matching `v*.*.*`
  - Manual dispatch with version input
- **Purpose**: Production releases with proper versioning
- **Features**:
  - Semantic versioning
  - GitHub releases with changelogs
  - Multi-architecture GPU support
  - Docker Hub image publishing

### 3. Security Scan (`security-scan.yml`)
- **Schedule**: Weekly on Sundays at 03:00 UTC
- **Purpose**: Security and vulnerability scanning
- **Includes**:
  - Dockerfile linting with Hadolint
  - Vulnerability scanning with Trivy
  - Base image update checking
  - Security advisory monitoring

## 🔑 Required Secrets

Add these secrets in your GitHub repository settings:

| Secret | Description | Required For |
|--------|-------------|--------------|
| `DOCKER_PASSWORD` | Docker Hub password/token | All workflows that push images |

## 🚀 Setup Instructions

1. **Configure Docker Hub Access**:
   ```bash
   # Create a Docker Hub access token
   # Go to: https://hub.docker.com/settings/security
   # Add it as DOCKER_PASSWORD secret in GitHub
   ```

2. **Update Registry Settings**:
   - Edit the `REGISTRY_USER` environment variable in workflow files
   - Change from `getterup` to your Docker Hub username

3. **Enable Workflows**:
   - Workflows are automatically enabled when you push them to your repository
   - Manual workflows can be triggered from the Actions tab

## 📊 Build Matrix

### Base Images
- `comfyui-rocm7.1` - ComfyUI with ROCm 7.1 support
- `stable-diffusion.cpp-rocm7.1` - Stable Diffusion with ROCm 7.1

### GPU Architecture Variants
| GFX Architecture | GPU Series | Build Target |
|-----------------|-------------|--------------|
| `gfx1150` | RDNA 3.5 (Ryzen AI 9 HX 370) | `stable-diffusion-cpp-gfx1150` |
| `gfx1151` | RDNA 3.5 (Strix Point) | `stable-diffusion-cpp-gfx1151` |
| `gfx1200` | RDNA 4 (RX 9070 XT) | `stable-diffusion-cpp-gfx1200` |
| `gfx1100` | RDNA 3 (RX 7900 XTX/XT) | `stable-diffusion-cpp-gfx1100` |
| `gfx1101` | RDNA 3 (RX 7800/7700 XT) | `stable-diffusion-cpp-gfx1101` |
| `gfx1030` | RDNA 2 (RX 6000 series) | `stable-diffusion-cpp-gfx1030` |
| `gfx1201` | RDNA 4 (RX 9060/9070 XT) | `stable-diffusion-cpp-gfx1201` |

## 🏷️ Image Tags

### Daily Builds
- `latest` - Latest daily build
- `YYYY-MM-DD` - Date-specific builds
- `<commit-sha>` - Commit-specific builds

### Releases
- `latest` - Latest stable release
- `v1.2.3` - Specific version
- `v1.2` - Minor version
- `v1` - Major version (for stable releases only)

## 🛠️ Manual Triggers

### Daily Build Manual Run
```bash
# Via GitHub CLI
gh workflow run daily-build.yml \
  -f push_images=true \
  -f build_all=true

# Via GitHub UI
# Go to Actions > Daily ROCm Container Build > Run workflow
```

### Release Manual Run
```bash
# Create a release
gh workflow run release.yml \
  -f version=v1.0.0 \
  -f create_release=true
```

### Security Scan Manual Run
```bash
# Run security scan
gh workflow run security-scan.yml
```

## 📈 Monitoring

### Build Status
- Check the Actions tab for workflow status
- Failed builds will show detailed logs
- Security scan results appear in the Security tab

### Docker Hub
- Images are automatically pushed to Docker Hub
- Check pull counts and popularity metrics
- Monitor for automated security scans

## 🔍 Troubleshooting

### Common Issues

1. **Docker Hub Authentication Failed**
   - Verify `DOCKER_PASSWORD` secret is set
   - Check that the token has push permissions
   - Ensure `REGISTRY_USER` matches your Docker Hub username

2. **Build Failures**
   - Check Dockerfile syntax
   - Verify base image availability
   - Review build logs for specific errors

3. **Security Scan Failures**
   - Review Trivy scan results
   - Update base images if vulnerabilities found
   - Fix Hadolint warnings in Dockerfiles

### Debug Commands
```bash
# Test workflows locally with act
act schedule -j build-base-images

# Validate Docker Compose
docker-compose config

# Test Dockerfile syntax
hadolint Dockerfiles/Dockerfile.comfyui-rocm7.1
```

## 📋 Maintenance

### Regular Tasks
- Monitor workflow success rates
- Update base images when security patches are available
- Review and update GPU architecture matrix as new GPUs are released
- Update dependencies in Dockerfiles

### Quarterly Reviews
- Assess build times and optimize if needed
- Review security scan results and trends
- Update workflow actions to latest versions
- Check for new GitHub Actions features that could improve the pipeline