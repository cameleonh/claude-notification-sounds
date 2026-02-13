# Toggle sounds on/off
$ErrorActionPreference = "Stop"
$StatePath = "$env:USERPROFILE\.claude\hooks\notification-sounds\.state.json"

# Default state
$DefaultState = @{
    active_pack = "default"
    volume = 0.5
    paused = $false
    categories = @{
        session = $true
        prompt = $true
        stop = $true
        notification = $true
        tool = $true
    }
}

if (Test-Path $StatePath) {
    try {
        $State = Get-Content $StatePath -Raw | ConvertFrom-Json
    } catch {
        $State = $DefaultState
    }
} else {
    $State = $DefaultState
}

if ($State.paused -eq $true) {
    $State.paused = $false
    Write-Host "Sound notifications: ON"
} else {
    $State.paused = $true
    Write-Host "Sound notifications: OFF"
}

$State | ConvertTo-Json -Depth 3 | Set-Content $StatePath
