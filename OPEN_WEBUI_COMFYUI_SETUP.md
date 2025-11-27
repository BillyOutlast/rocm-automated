# Open WebUI ComfyUI Integration Setup Guide

This guide will help you configure Open WebUI to work with ComfyUI for AI image generation.

## Prerequisites

- Open WebUI running and accessible
- ComfyUI running on your local network (typically at `http://172.28.0.5:8188`)
- Admin access to Open WebUI

## Configuration Steps

### 1. Navigate to Admin Settings

1. Open your Open WebUI interface in a web browser
2. Click on the **Admin** section in the navigation menu
3. Go to **Settings**
4. Select **Images** from the settings menu

### 2. Configure Image Generation Engine

In the Images settings page, configure the following:

#### Image Generation Engine
- Select: **ComfyUI**

#### ComfyUI Base URL
```
http://172.28.0.5:8188
```


### 3. ComfyUI Workflow Configuration

#### Workflow Setup
1. In ComfyUI, create your desired workflow
2. **Export the workflow as API format**:
   - In ComfyUI interface, go to the workflow menu
   - Choose "Export" 
   - Select "API Format"
   - Save as `workflow.json`

3. **Upload the workflow**:
   - In Open WebUI Images settings, click "Upload" under ComfyUI Workflow
   - Select your exported `workflow.json` file

#### Required Workflow Nodes

Configure the following node mappings in the ComfyUI Workflow Nodes section:

| Parameter | Node Type | Node ID | Description |
|-----------|-----------|---------|-------------|
| **prompt*** | text | 6 | Text prompt input (required) |
| **model** | unet_name | 37 | Model selection |
| **width** | width | 58 | Image width |
| **height** | height | 58 | Image height |
| **steps** | steps | 3 | Sampling steps |
| **seed** | seed | 3 | Random seed |

> **Note**: Prompt node ID(s) marked with * are required for image generation to work.

## Important Notes

1. **Network Configuration**: Ensure that Open WebUI can reach ComfyUI at the specified IP address (`172.28.0.5:8188`)

2. **API Format Export**: Always export your ComfyUI workflow in API format, not the regular format

3. **Node IDs**: The node IDs (like 6, 37, 58, 3) must match the actual node IDs in your ComfyUI workflow

4. **Required Nodes**: The prompt node is mandatory - image generation will fail without it

## Troubleshooting

### Common Issues

1. **Connection Failed**: 
   - Verify ComfyUI is running on `172.28.0.5:8188`
   - Check network connectivity between Open WebUI and ComfyUI

2. **Workflow Errors**:
   - Ensure workflow was exported in API format
   - Verify all required nodes are present in the workflow
   - Check that node IDs match your actual workflow

3. **Missing Images**:
   - Confirm the prompt node ID is correctly configured
   - Ensure ComfyUI has the required models installed

### Verification Steps

1. Test the ComfyUI connection by visiting `http://172.28.0.5:8188` in your browser
2. Generate a test image through Open WebUI to verify the integration
3. Check ComfyUI logs for any error messages if generation fails

## Additional Configuration

- **Edit Image**: Additional image editing capabilities can be configured through the same interface
- **Custom Workflows**: You can upload different workflows for various image generation tasks
- **Model Management**: Ensure required models are available in your ComfyUI installation

---

*For more advanced configuration options, refer to the Open WebUI and ComfyUI documentation.*