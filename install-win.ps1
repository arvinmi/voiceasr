$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $HOME ".voiceasr"
$TaskName = "VoiceASR"
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

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

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Path "server.py" -Destination $InstallDir -Force
Copy-Item -Path ".venv" -Destination $InstallDir -Recurse -Force

$Python = Join-Path $InstallDir ".venv\Scripts\pythonw.exe"
$Server = Join-Path $InstallDir "server.py"

$Action = New-ScheduledTaskAction `
  -Execute $Python `
  -Argument $Server `
  -WorkingDirectory $InstallDir
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $User
$Settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -RestartCount 999 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $Action `
  -Trigger $Trigger `
  -Settings $Settings `
  -Description "Run VoiceASR at login." `
  -Force | Out-Null

Start-ScheduledTask -TaskName $TaskName
echo "Installed VoiceASR"
