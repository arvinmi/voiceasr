# VoiceASR

Google MedASR local endpoint for VoiceInk, Handy, and other OpenAI-compatible API clients.

## Setup

Run setup and install:

```bash
./setup.sh
```

> Note: You must accept the model license at https://huggingface.co/google/medasr

macOS:

```bash
./install-mac.sh
```

> Note: This script will install the VoiceASR server as a launchd service, which will start automatically on login.

Windows:

```powershell
.\install-win.ps1
```

> Note: This script will install the VoiceASR server as a scheduled task, which will start automatically on login.

## VoiceInk

Add custom model in Settings > Transcription:

- Endpoint: `http://localhost:8000/v1/audio/transcriptions`
- API Key: `local`
- Model: `medasr`
- Multilingual: unchecked

## Troubleshooting

macOS:

```bash
curl http://localhost:8000/           # server health
launchctl stop com.voiceasr.server    # stop
launchctl start com.voiceasr.server   # start
./uninstall-mac.sh                    # uninstall
```

Windows:

```powershell
curl http://localhost:8000/           # server health
Stop-ScheduledTask VoiceASR           # stop
Start-ScheduledTask VoiceASR          # start
.\uninstall-win.ps1                   # uninstall
```
