# Notification Hook - Permission request, user input needed
$ErrorActionPreference = "SilentlyContinue"

. "$PSScriptRoot\common.ps1"

Play-NotificationSound -Category "notification" -FallbackFile "bruh.mp3" -DurationMs 1000
