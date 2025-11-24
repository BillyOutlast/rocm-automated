cd User-Directories/ComfyUI/custom_nodes

# Manager
git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
cd comfyui-manager && pip install -r requirements.txt && cd ..

# Crystools (AMD branch)
git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git
cd ComfyUI-Crystools && pip install -r requirements.txt && cd ..

# MIGraphX DISABLED DUE TO CRASHES
#git clone https://github.com/pnikolic-amd/ComfyUI_MIGraphX.git
#cd ComfyUI_MIGraphX && pip install -r requirements.txt && cd ..

# Unsafe Torch
git clone https://github.com/ltdrdata/comfyui-unsafe-torch

# Impact Pack
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack comfyui-impact-pack
cd comfyui-impact-pack && pip install -r requirements.txt && cd ..

# Impact Subpack
git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack
cd ComfyUI-Impact-Subpack && pip install -r requirements.txt && cd ..

# WaveSpeed
git clone https://github.com/chengzeyi/Comfy-WaveSpeed.git