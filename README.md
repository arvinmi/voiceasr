# VoiceASR

Google MedASR local endpoint for VoiceInk, Handy, and other OpenAI-compatible API clients.

## Setup

> Note: You must accept the model license [here](https://huggingface.co/google/medasr) and create a "Read" access token [here](https://huggingface.co/settings/tokens) to login via the cli.

macOS:

```bash
./install-mac.sh
```

> Note: This script will setup and install the VoiceASR server as a launchd service, which will start automatically on login.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-win.ps1
```

> Note: This script will setup and install the VoiceASR server as a scheduled task, which will start automatically on login.

## VoiceInk

Add custom model in Settings > Transcription:

- Endpoint: `http://localhost:8000/v1/audio/transcriptions`
- API Key: `local`
- Model: `medasr`
- Multilingual: unchecked

## Troubleshooting

macOS:

```
curl http://localhost:8000/           # server health
tail -f ~/.voiceasr/server.log        # server log
launchctl stop com.voiceasr.server    # stop
launchctl start com.voiceasr.server   # start
./uninstall-mac.sh                    # uninstall
```

Windows:

```
curl http://localhost:8000/           # server health
Get-Content ~/.voiceasr/server.log -Wait # server log
Stop-ScheduledTask VoiceASR           # stop
Start-ScheduledTask VoiceASR          # start
powershell -ExecutionPolicy Bypass -File .\uninstall-win.ps1  # uninstall
```
