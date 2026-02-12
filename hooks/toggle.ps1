# Toggle sounds on/off
$StatePath = "$env:USERPROFILE\.claude\hooks\notification-sounds\.state.json"

if (Test-Path $StatePath) {
    $State = Get-Content $StatePath | ConvertFrom-Json
} else {
    $State = @{}
}

if ($State.paused -eq $true) {
    $State.paused = $false
    Write-Host "Sound notifications: ON"
} else {
    $State.paused = $true
    Write-Host "Sound notifications: OFF"
}

$State | ConvertTo-Json | Set-Content $StatePath
