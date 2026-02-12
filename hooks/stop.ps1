# Stop Hook - Claude finished working - Meme Sound
$ErrorActionPreference = "SilentlyContinue"
$SoundPath = "$env:USERPROFILE\.claude\hooks\notification-sounds\sounds\fbi.mp3"

if (Test-Path $SoundPath) {
    Add-Type -AssemblyName presentationCore
    $player = New-Object System.Windows.Media.MediaPlayer
    $player.Open($SoundPath)
    $player.Volume = 0.5
    $player.Play()
    Start-Sleep -Milliseconds 1500
    $player.Close()
}
