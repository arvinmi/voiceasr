#!/bin/bash

set -e

INSTALL_DIR="$HOME/.voiceasr"
PLIST="$HOME/Library/LaunchAgents/com.voiceasr.server.plist"
VENV_DIR="$INSTALL_DIR/.venv"
PYTHON="$VENV_DIR/bin/python"
SERVER="$INSTALL_DIR/server.py"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: $1 is not installed. $2"
    exit 1
  fi
}

stop_voiceasr() {
  launchctl unload "$PLIST" 2>/dev/null || true
  pkill -f "$INSTALL_DIR/server.py" 2>/dev/null || true
}

login_hugging_face() {
  local token
  read -r -s -p "Hugging Face token for google/medasr (leave blank if already logged in): " token
  echo
  if [ -z "$token" ]; then
    return
  fi

  HF_TOKEN="$token" "$PYTHON" -c "import os; from huggingface_hub import login; login(token=os.environ['HF_TOKEN'], add_to_git_credential=False)"
  unset token
}

test_medasr_access() {
  "$PYTHON" -c "from huggingface_hub import hf_hub_download; hf_hub_download('google/medasr', 'config.json')"
}

require_command uv "Install it with: brew install uv"
require_command ffmpeg "Install it with: brew install ffmpeg"

if [ ! -f "server.py" ]; then
  echo "Error: server.py not found"
  exit 1
fi

stop_voiceasr
rm -f "$PLIST"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp server.py "$SERVER"

uv venv --python 3.12 "$VENV_DIR"
uv pip install --python "$PYTHON" fastapi uvicorn torch python-multipart huggingface-hub accelerate transformers

login_hugging_face
test_medasr_access

cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.voiceasr.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON</string>
        <string>$SERVER</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    <key>StandardOutPath</key><string>$INSTALL_DIR/server.log</string>
    <key>StandardErrorPath</key><string>$INSTALL_DIR/server.log</string>
</dict>
</plist>
EOF

launchctl load "$PLIST" 2>/dev/null || true
echo "Installed VoiceASR"
