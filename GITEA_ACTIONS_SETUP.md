# Gitea Actions Configuration Guide

This guide explains how to set up and use the Gitea Actions workflows for the ROCm 7.1 container environment.

## 🔧 Gitea Actions Setup

### 1. Enable Gitea Actions
First, ensure Gitea Actions is enabled on your Gitea instance:

```ini
# In app.ini
[actions]
ENABLED = true
DEFAULT_ACTIONS_URL = https://gitea.com
```

### 2. Configure Runners
You need to set up Gitea Actions runners. You can use:

#### Option A: Docker Runner (Recommended)
```bash
# Pull the official runner image
docker pull gitea/act_runner:latest

# Register the runner
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD/runner-config:/data \
  gitea/act_runner:latest \
  register --instance https://your-gitea.com --token YOUR_REGISTRATION_TOKEN

# Run the runner
docker run -d \
  --name gitea-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD/runner-config:/data \
  gitea/act_runner:latest
```

#### Option B: Binary Runner
```bash
# Download the runner
wget -O act_runner https://gitea.com/gitea/act_runner/releases/download/v0.2.6/act_runner-0.2.6-linux-amd64
chmod +x act_runner

# Register and run
./act_runner register --instance https://your-gitea.com --token YOUR_REGISTRATION_TOKEN
./act_runner daemon
```

## 📁 Workflow Files

The Gitea-compatible workflow files are:

| File | Purpose | Schedule |
|------|---------|----------|
| `daily-build-gitea.yml` | Daily container builds | 02:00 UTC daily |
| `security-scan-gitea.yml` | Security scanning | 03:00 UTC weekly |
| `release-gitea.yml` | Release builds | On git tags |

## 🔑 Required Secrets

Configure these secrets in your Gitea repository settings (`Settings > Secrets`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_PASSWORD` | Docker Hub password or token | `dckr_pat_...` |

## 🚀 Getting Started

### 1. Copy the Workflow Files
Move the Gitea-specific workflow files to your repository:

```bash
# Rename the Gitea workflows to be the primary ones
mv .github/workflows/daily-build-gitea.yml .github/workflows/daily-build.yml
mv .github/workflows/security-scan-gitea.yml .github/workflows/security-scan.yml
mv .github/workflows/release-gitea.yml .github/workflows/release.yml

# Optional: Remove GitHub-specific workflows if not needed
rm .github/workflows/daily-build.yml.bak  # if you backed them up
```

### 2. Update Configuration
Edit the workflow files to match your setup:

```yaml
env:
  REGISTRY: docker.io
  REGISTRY_USER: your-dockerhub-username  # Change this
```

### 3. Test the Workflows

#### Manual Test Run
```bash
# Trigger a manual build (via Gitea UI)
# Go to: Repository > Actions > Daily ROCm Container Build > Run workflow
```

#### Test with act (Local Testing)
```bash
# Install act for local testing
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

# Test the workflow locally
act workflow_dispatch -j prepare
```

## 🔄 Key Differences from GitHub Actions

### 1. Action References
- **GitHub**: `uses: actions/checkout@v4`
- **Gitea**: `uses: https://gitea.com/actions/checkout@v4`

### 2. Docker Actions
Gitea Actions uses simpler Docker setups:
```yaml
# Instead of complex Docker actions, we use direct docker commands
- name: Build and push Docker image
  run: |
    docker buildx build \
      --tag image:tag \
      --push \
      .
```

### 3. Available Actions
Gitea Actions has fewer pre-built actions available, so we:
- Use direct shell commands where possible
- Install tools manually when needed
- Use official Gitea actions when available

## 📊 Workflow Features

### Daily Build (`daily-build-gitea.yml`)
- ✅ Builds base images (ComfyUI, Stable Diffusion)
- ✅ Builds GPU-specific variants (7 architectures)
- ✅ Docker Compose validation
- ✅ Manual trigger support
- ✅ Build notifications

### Security Scan (`security-scan-gitea.yml`)
- ✅ Dockerfile linting with Hadolint
- ✅ Vulnerability scanning with Trivy
- ✅ Base image update checks
- ✅ Weekly automated scans

### Release Build (`release-gitea.yml`)
- ✅ Semantic versioning
- ✅ Multi-architecture builds
- ✅ Release notes generation
- ✅ Pre-release support

## 🛠️ Customization

### Adding New GPU Architectures
Edit the matrix in the workflows:

```yaml
strategy:
  matrix:
    gfx_arch:
      - gfx1150  # RDNA 3.5 (Ryzen AI 9 HX 370)
      - gfx1151  # RDNA 3.5 (Strix Point)
      - gfx1200  # RDNA 4 (RX 9070 XT)
      - gfx1100  # RDNA 3 (RX 7900 XTX/XT)
      - gfx1101  # RDNA 3 (RX 7800 XT/7700 XT)
      - gfx1030  # RDNA 2 (RX 6000 series)
      - gfx1201  # RDNA 4 (RX 9060 XT/ RX 9070/XT)
      - gfx1102  # Add new architecture here
```

### Changing Build Schedule
Modify the cron expressions:

```yaml
on:
  schedule:
    # Daily at 02:00 UTC
    - cron: '0 2 * * *'
    # Change to twice daily:
    # - cron: '0 2,14 * * *'
```

### Custom Notifications
Add notification steps:

```yaml
- name: Send notification
  run: |
    # Send to webhook, email, etc.
    curl -X POST https://your-webhook.com/notify \
      -d "Build completed: ${{ github.run_number }}"
```

## 🐛 Troubleshooting

### Common Issues

1. **Runner Not Found**
   ```
   Error: No runners available
   ```
   **Solution**: Ensure you have registered and started a Gitea Actions runner.

2. **Docker Permission Denied**
   ```
   Error: permission denied while trying to connect to Docker
   ```
   **Solution**: Ensure the runner has access to Docker socket:
   ```bash
   sudo usermod -aG docker $USER
   ```

3. **Action Not Found**
   ```
   Error: Could not find action
   ```
   **Solution**: Use full URLs for actions:
   ```yaml
   uses: https://gitea.com/actions/checkout@v4
   ```

### Debug Commands

```bash
# Check runner status
docker logs gitea-runner

# Test Docker access
docker info

# Validate workflow syntax
# (You can use GitHub's workflow validator or yamllint)
yamllint .github/workflows/daily-build-gitea.yml
```

## 📈 Monitoring

### View Build Results
- Go to your repository in Gitea
- Click on "Actions" tab
- View workflow runs and logs

### Build Artifacts
Currently, the workflows push directly to Docker Hub. To save build artifacts in Gitea:

```yaml
- name: Save build logs
  run: |
    # Save build output to file
    docker build . > build.log 2>&1 || true
    
- name: Upload artifacts
  # Use Gitea's artifact upload when available
  run: |
    echo "Build artifacts saved locally"
```

## 🔧 Advanced Configuration

### Private Registry
To use a private Docker registry:

```yaml
env:
  REGISTRY: your-private-registry.com
  REGISTRY_USER: your-username

# In the login step:
- name: Log in to Private Registry
  run: |
    echo "${{ secrets.REGISTRY_PASSWORD }}" | docker login ${{ env.REGISTRY }} -u ${{ env.REGISTRY_USER }} --password-stdin
```

### Multi-Platform Builds
For ARM64 support:

```yaml
- name: Set up QEMU
  run: |
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

- name: Build multi-platform
  run: |
    docker buildx create --use --name multiarch
    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      --push \
      .
```

This configuration should get your ROCm container builds working smoothly on Gitea Actions!