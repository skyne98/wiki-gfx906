# How to install ComfyUI on Linux
The following instructions are aimed at Ubuntu 24.04 LTS using ROCm 7.2 
If you are using a different distro I recommend [uv](https://docs.astral.sh/uv/) and setting a Python 3.12 virtual environment i.e. `uv venv venv --python 3.12`

## Install
1. Clone the repository:
```
git clone https://github.com/comfyanonymous/ComfyUI.git
```
2. Change to the ComfyUI directory and create a python virtual environment:
```
cd ComfyUI
python3 -m venv venv
```
3. Activate the virtual environment:
```
source venv/bin/activate
```
4. Update pip:
```
pip install --upgrade pip wheel setuptools
```
5. Install PyTorch wheels, you can experiment with different versions for more stability or newer features:
```
pip install torch torchvision torchaudio triton --index-url https://download.pytorch.org/whl/rocm7.1
```
6. Install requirements for ComfyUI:
```
pip install -r requirements.txt
```

### Verify it
1. Run 'python3 main.py` to check it installed properly, you can exit after as we still have a few more steps.

## Creating a script to make it easier to run

1. Use your favourite text editor to create the script with a name you like in a location you want e.g.
```
cd ~
nano run-comfyui.sh
```
2. Insert the following, adjust the ROCm environment accordingly:
```
#!/bin/bash
export PATH=$PATH:/opt/rocm-7.2.0/bin
export LD_LIBRARY_PATH=/opt/rocm-7.2.0/lib

cd ComfyUI
source venv/bin/activate
python3 main.py --use-split-cross-attention --disable-smart-memory --front-end-version Comfy-Org/ComfyUI_frontend@latest
```
3. Make the script executable:
```
chmod +x run-comfyui.sh
```

#### Note: 
These are the parameters that seem to work the best for Z-Image Turbo, but more testing is needed - also with other models. You may come across many other environment variables, but I haven't seen any perceivable differences on gfx906.
Feel free to remove `--front-end-version` if you experience problems with the latest version.

#### Fixing missing ROCm environment paths:
If for any reason you get a missing tensor files error in ComfyUI, please check the "installing_ROCm_7.x" guide to obtain them.
If you still encounter the error, it means the environment is not set properly. You can also manually add the files to ComyUI:
```
sudo cp ~/rocblas7.1/rocblas/*gfx906* ~/ComfyUI/venv/lib/python3.12/site-packages/torch/lib/rocblas/library/
```

## (Optional but recommended) Install ComfyUI Manager
```
cd ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
```

# That's it, now you can run ComfyUI by running the script `./run-comfyui.sh`
