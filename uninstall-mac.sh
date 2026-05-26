#!/bin/bash

INSTALL_DIR="$HOME/.voiceasr"
PLIST="$HOME/Library/LaunchAgents/com.voiceasr.server.plist"
HUGGINGFACE_CACHE="$HOME/.cache/huggingface/hub"

launchctl unload "$PLIST" 2>/dev/null
pkill -f "$INSTALL_DIR/server.py" 2>/dev/null
rm -f "$PLIST"
rm -rf "$INSTALL_DIR"
rm -rf "$HUGGINGFACE_CACHE/models--google--medasr"
rm -rf "$HUGGINGFACE_CACHE/.locks/models--google--medasr"
if command -v brew >/dev/null 2>&1 && brew list --formula ffmpeg >/dev/null 2>&1; then
  brew uninstall ffmpeg
fi
echo "Uninstalled VoiceASR"
