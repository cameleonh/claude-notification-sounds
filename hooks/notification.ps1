# Notification Hook - Permission request, user input needed
$ErrorActionPreference = "SilentlyContinue"
$SoundPath = "$env:USERPROFILE\.claude\hooks\notification-sounds\sounds\bruh.mp3"

if (Test-Path $SoundPath) {
    Add-Type -AssemblyName presentationCore
    $player = New-Object System.Windows.Media.MediaPlayer
    $player.Open($SoundPath)
    $player.Volume = 0.5
    $player.Play()
    Start-Sleep -Milliseconds 1000
    $player.Close()
}
