# VoiceASR

Google MedASR local endpoint for VoiceInk that runs on your Mac.

## Setup

Run setup and install:

```bash
./setup.sh
```

> Note: You must accept the model license at https://huggingface.co/google/medasr

```bash
./install.sh
```

> Note: This script will install the VoiceASR server as a launchd service, which will start automatically on login.

## VoiceInk

Add custom model in Settings > Transcription:

- Endpoint: `http://localhost:8000/v1/audio/transcriptions`
- API Key: `local`
- Model: `medasr`
- Multilingual: unchecked

## Troubleshooting

```bash
curl http://localhost:8000/           # status
tail -f ~/.voiceasr/server.log        # logs
launchctl stop com.voiceasr.server    # stop
launchctl start com.voiceasr.server   # start
./uninstall.sh                        # uninstall
```
