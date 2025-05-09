#!/bin/bash

set -eu

# Detect the shell from which the script was called
parent=$(ps -o comm $PPID |tail -1)
parent=${parent#-}  # remove the leading dash that login shells have
case "$parent" in
  # shells supported by `micromamba shell init`
  bash|fish|xonsh|zsh)
    shell=$parent
    ;;
  *)
    # use the login shell (basename of $SHELL) as a fallback
    shell=${SHELL##*/}
    ;;
esac

# Define default values to avoid user input
BIN_FOLDER="${BIN_FOLDER:-${HOME}/.local/bin}"
INIT_YES="${INIT_YES:-yes}"  # Automatically initialize shell
CONDA_FORGE_YES="${CONDA_FORGE_YES:-yes}"  # Automatically configure conda-forge
PREFIX_LOCATION="${PREFIX_LOCATION:-${HOME}/micromamba}"  # Default prefix location

# Computing artifact location
case "$(uname)" in
  Linux)
    PLATFORM="linux" ;;
  Darwin)
    PLATFORM="osx" ;;
  *NT*)
    PLATFORM="win" ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|ppc64le|arm64)
      ;;  # pass
  *)
    ARCH="64" ;;
esac

case "$PLATFORM-$ARCH" in
  linux-aarch64|linux-ppc64le|linux-64|osx-arm64|osx-64|win-64)
      ;;  # pass
  *)
    echo "Failed to detect your OS" >&2
    exit 1
    ;;
esac

if [ "${VERSION:-}" = "" ]; then
  RELEASE_URL="https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-${PLATFORM}-${ARCH}"
else
  RELEASE_URL="https://github.com/mamba-org/micromamba-releases/releases/download/${VERSION}/micromamba-${PLATFORM}-${ARCH}"
fi

# Downloading artifact
mkdir -p "${BIN_FOLDER}"
if hash curl >/dev/null 2>&1; then
  curl "${RELEASE_URL}" -o "${BIN_FOLDER}/micromamba" -fsSL --compressed ${CURL_OPTS:-}
elif hash wget >/dev/null 2>&1; then
  wget ${WGET_OPTS:-} -qO "${BIN_FOLDER}/micromamba" "${RELEASE_URL}"
else
  echo "Neither curl nor wget was found" >&2
  exit 1
fi
chmod +x "${BIN_FOLDER}/micromamba"

# Initializing shell
case "$INIT_YES" in
  y|Y|yes)
    case $("${BIN_FOLDER}/micromamba" --version) in
      1.*|0.*)
        shell_arg=-s
        prefix_arg=-p
        ;;
      *)
        shell_arg=--shell
        prefix_arg=--root-prefix
        ;;
    esac
    "${BIN_FOLDER}/micromamba" shell init $shell_arg "$shell" $prefix_arg "$PREFIX_LOCATION"

    echo "Please restart your shell to activate micromamba or run the following:\n"
    echo "  source ~/.bashrc (or ~/.zshrc, ~/.xonshrc, ~/.config/fish/config.fish, ...)"
    ;;
  *)
    echo "You can initialize your shell later by running:"
    echo "  micromamba shell init"
    ;;
esac

# Initializing conda-forge
case "$CONDA_FORGE_YES" in
  y|Y|yes)
    "${BIN_FOLDER}/micromamba" config append channels conda-forge
    "${BIN_FOLDER}/micromamba" config append channels nodefaults
    "${BIN_FOLDER}/micromamba" config set channel_priority strict
    ;;
esac

export MAMBA_ROOT_PREFIX=~/micromamba

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
pip install hydra-core omegaconf
pip install freetype-py shapely svgutils cairosvg
pip install opencv-python scikit-image matplotlib visdom wandb BeautifulSoup4
pip install triton numba
pip install numpy scipy scikit-fmm einops timm fairscale==0.4.13
pip install accelerate transformers safetensors datasets
pip install easydict scikit-learn pytorch_lightning==2.1.0 webdataset
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
