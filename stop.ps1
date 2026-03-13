# Stop Hook - Claude finished working - Meme Sound
$ErrorActionPreference = "SilentlyContinue"

. "$PSScriptRoot\common.ps1"

Play-NotificationSound -Category "stop" -FallbackFile "fbi.mp3" -DurationMs 1500
