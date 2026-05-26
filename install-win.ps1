$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $HOME ".voiceasr"
$TaskName = "VoiceASR"
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$VenvDir = Join-Path $InstallDir ".venv"
$HuggingFaceHome = Join-Path $InstallDir "huggingface"
$Python = Join-Path $VenvDir "Scripts\python.exe"
$Server = Join-Path $InstallDir "server.py"
$ServerSource = Join-Path $ScriptDir "server.py"
$Launcher = Join-Path $InstallDir "run-hidden.vbs"
$LogFile = Join-Path $InstallDir "server.log"
$Packages = @(
  "fastapi",
  "uvicorn",
  "torch",
  "python-multipart",
  "huggingface-hub",
  "accelerate",
  "transformers"
)

function Stop-VoiceASR {
  Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  Get-CimInstance Win32_Process |
    Where-Object {
      ($_.Name -in @("python.exe", "pythonw.exe", "cmd.exe")) -and
      ($_.CommandLine -like "*$InstallDir*") -and
      ($_.CommandLine -like "*server.py*")
    } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Assert-Command($Name, $InstallHint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is not installed. $InstallHint"
  }
}

function Get-FFmpegBinDir {
  $Command = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
  if ($Command) {
    return Split-Path -Parent $Command.Source
  }

  $WingetPackageDir = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
  $FFmpeg = Get-ChildItem -Path $WingetPackageDir -Recurse -Filter "ffmpeg.exe" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*Gyan.FFmpeg*" } |
    Select-Object -First 1

  if ($FFmpeg) {
    return $FFmpeg.DirectoryName
  }

  throw "ffmpeg is not installed. Install it with: winget install Gyan.FFmpeg"
}

function Read-HuggingFaceToken {
  $SecureToken = Read-Host "Hugging Face token for google/medasr (leave blank if already logged in)" -AsSecureString
  $Credential = [System.Net.NetworkCredential]::new("", $SecureToken)
  return $Credential.Password
}

function Login-HuggingFace($Token) {
  if ([string]::IsNullOrWhiteSpace($Token)) {
    return
  }

  $env:HF_TOKEN = $Token
  $env:HF_HOME = $HuggingFaceHome
  try {
    & $Python -c "import os; from huggingface_hub import login; login(token=os.environ['HF_TOKEN'], add_to_git_credential=False)"
  } finally {
    Remove-Item Env:HF_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:HF_HOME -ErrorAction SilentlyContinue
  }
}

function Test-MedASRAccess {
  $env:HF_HOME = $HuggingFaceHome
  try {
    & $Python -c "from huggingface_hub import hf_hub_download; hf_hub_download('google/medasr', 'config.json')"
  } finally {
    Remove-Item Env:HF_HOME -ErrorAction SilentlyContinue
  }
}

function Warmup-MedASR {
  echo "Downloading and loading MedASR. This can take several minutes..."
  $OriginalPath = $env:PATH
  $env:HF_HOME = $HuggingFaceHome
  $env:PATH = "$FFmpegBinDir;$env:PATH"
  try {
    & $Python -c "import sys; sys.path.insert(0, r'$InstallDir'); from server import load_model; load_model()"
  } finally {
    Remove-Item Env:HF_HOME -ErrorAction SilentlyContinue
    $env:PATH = $OriginalPath
  }
}

Assert-Command "uv" "Install it with: winget install astral-sh.uv"
$FFmpegBinDir = Get-FFmpegBinDir
if (-not (Test-Path $ServerSource)) {
  throw "server.py not found next to install-win.ps1"
}

Stop-VoiceASR
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $HuggingFaceHome | Out-Null
Copy-Item -Path $ServerSource -Destination $Server -Force

uv venv --python 3.12 $VenvDir
uv pip install --python $Python @Packages

$Token = Read-HuggingFaceToken
Login-HuggingFace $Token
$Token = $null
Test-MedASRAccess
Warmup-MedASR

$LauncherContent = @"
Set Shell = CreateObject("WScript.Shell")
Set Environment = Shell.Environment("PROCESS")
Environment("PATH") = "$FFmpegBinDir;" & Environment("PATH")
Environment("HF_HOME") = "$HuggingFaceHome"
Shell.CurrentDirectory = "$InstallDir"
Shell.Run "cmd.exe /c " & Chr(34) & Chr(34) & "$Python" & Chr(34) & " -u " & Chr(34) & "$Server" & Chr(34) & " >> " & Chr(34) & "$LogFile" & Chr(34) & " 2>&1" & Chr(34), 0, False
"@
Set-Content -Path $Launcher -Value $LauncherContent -Encoding ASCII

$Action = New-ScheduledTaskAction `
  -Execute "wscript.exe" `
  -Argument "`"$Launcher`"" `
  -WorkingDirectory $InstallDir
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $User
$Settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -RestartCount 999 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -ExecutionTimeLimit (New-TimeSpan -Seconds 0) `
  -MultipleInstances IgnoreNew `
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
