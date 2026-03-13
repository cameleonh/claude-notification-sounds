# Toggle sounds on/off
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\common.ps1"

$state = Get-NotificationSoundConfig
$state.paused = -not [bool]$state.paused
Save-NotificationSoundConfig -Config $state

if ($state.paused) {
    Write-Host "Sound notifications: OFF"
} else {
    Write-Host "Sound notifications: ON"
}
