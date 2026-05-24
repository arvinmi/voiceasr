$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $HOME ".voiceasr"
$TaskName = "VoiceASR"

Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process |
  Where-Object {
    ($_.Name -eq "python.exe") -and
    ($_.CommandLine -like "*$InstallDir*") -and
    ($_.CommandLine -like "*server.py*")
  } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
echo "Uninstalled VoiceASR"
