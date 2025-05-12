#!/bin/bash
set -e

eval "$(micromamba shell hook --shell=bash)"

micromamba create --name svgrender python=3.10 --yes
micromamba activate svgrender
echo "The conda environment was successfully created"

# Install PyTorch and related libraries
micromamba install pytorch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 cudatoolkit=11.3 -c pytorch --yes
echo "Pytorch installation is complete. version: 1.12.1"

# Install xformers
micromamba install xformers -c xformers --yes
echo "xformers installation is complete."

# Install common Python dependencies
micromamba install hydra-core omegaconf --yes
micromamba install freetype-py shapely svgutils cairosvg --yes
micromamba install opencv-python scikit-image matplotlib visdom wandb BeautifulSoup4 --yes
micromamba install triton numba --yes
micromamba install numpy scipy scikit-fmm einops timm fairscale==0.4.13 --yes
micromamba install accelerate transformers safetensors datasets --yes
micromamba install easydict scikit-learn pytorch_lightning==2.1.0 webdataset --yes
micromamba install matplotlib_inline --yes
micromamba install matplotlib --yes
micromamba install hydra-core --yes
echo "The basic dependency library is installed."

# Additional utility libraries
pip install ftfy regex tqdm
pip install git+https://github.com/openai/CLIP.git
echo "CLIP installation is complete."

# Install diffusers
pip install diffusers==0.20.2
echo "Diffusers installation is complete. version: 0.20.2"

# Clone and set up DiffVG, handling dependencies on Ubuntu
git clone https://github.com/BachiLi/diffvg.git
cd diffvg
git submodule update --init --recursive

# Install system dependencies for Ubuntu (to avoid potential issues)
echo "Installing system dependencies for DiffVG..."
sudo apt update
sudo apt install -y cmake ffmpeg build-essential libjpeg-dev libpng-dev libtiff-dev

micromamba install -y -c anaconda cmake
micromamba install -y -c conda-forge ffmpeg
pip install svgwrite svgpathtools cssutils torch-tools

# Install DiffVG
python setup.py install
echo "DiffVG installation is complete."

# Final confirmation
echo "The running environment has been successfully installed!!!"
