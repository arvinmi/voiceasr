#!/bin/bash

set -e

if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg not found. Install with: brew install ffmpeg"
  exit 1
fi

uv venv
source .venv/bin/activate
uv pip install fastapi uvicorn torch python-multipart huggingface-hub
# install transformers v5 (not avail yet in pip)
uv pip install "git+https://github.com/huggingface/transformers.git@65dc261512cbdb1ee72b88ae5b222f2605aad8e5"
echo "Login to HuggingFace"
.venv/bin/python -c "from huggingface_hub import login; login()"
echo "Done"
