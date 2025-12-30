#!/bin/bash

launchctl unload "$HOME/Library/LaunchAgents/com.voiceasr.server.plist" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/com.voiceasr.server.plist"
rm -rf "$HOME/.voiceasr"
echo "Uninstalled VoiceASR"
