#!/bin/bash

set -e

INSTALL_DIR="$HOME/.voiceasr"
PLIST="$HOME/Library/LaunchAgents/com.voiceasr.server.plist"

# find python lib path
PYLIB=$(dirname "$(find /opt/homebrew/Cellar -name 'libpython3*.dylib' -path '*/Frameworks/*' 2>/dev/null | head -1)")

mkdir -p "$INSTALL_DIR"
cp server.py "$INSTALL_DIR/"
cp -r .venv "$INSTALL_DIR/"

cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.voiceasr.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/.venv/bin/python</string>
        <string>$INSTALL_DIR/server.py</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>DYLD_LIBRARY_PATH</key>
        <string>$PYLIB</string>
    </dict>
    <key>StandardOutPath</key><string>$INSTALL_DIR/server.log</string>
    <key>StandardErrorPath</key><string>$INSTALL_DIR/server.log</string>
</dict>
</plist>
EOF

launchctl load "$PLIST" 2>/dev/null || true
echo "Installed VoiceASR"
