# Stop Hook - Claude finished working - Meme Sound
$ErrorActionPreference = "SilentlyContinue"

$StatePath = "$env:USERPROFILE\.claude\hooks\notification-sounds\.state.json"
$SoundPath = "C:\Users\honey\.claude\hooks\notification-sounds\sounds\fbi.mp3"

# Check if paused or category disabled
if (Test-Path $StatePath) {
    try {
        $State = Get-Content $StatePath -Raw | ConvertFrom-Json
        if ($State.paused -eq $true) { exit 0 }
        if ($State.categories.stop -eq $false) { exit 0 }
        $Volume = if ($State.volume) { [double]$State.volume } else { 0.5 }
    } catch {
        $Volume = 0.5
    }
} else {
    $Volume = 0.5
}

if (Test-Path $SoundPath) {
    Add-Type -AssemblyName presentationCore
    $player = New-Object System.Windows.Media.MediaPlayer
    $player.Open($SoundPath)
    $player.Volume = $Volume
    $player.Play()
    Start-Sleep -Milliseconds 1500
    $player.Close()
}
