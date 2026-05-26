$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $HOME ".voiceasr"
$TaskName = "VoiceASR"

Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process |
  Where-Object {
    ($_.Name -in @("python.exe", "pythonw.exe", "cmd.exe")) -and
    ($_.CommandLine -like "*$InstallDir*") -and
    ($_.CommandLine -like "*server.py*")
  } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-Process wscript -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
winget list --id Gyan.FFmpeg --exact | Out-Null
if ($LASTEXITCODE -eq 0) {
  winget uninstall --id Gyan.FFmpeg --exact --accept-source-agreements | Out-Null
}
echo "Uninstalled VoiceASR"
