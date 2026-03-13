# Claude Code Notification Sounds Installer for Windows
# Run: irm https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main/install.ps1 | iex

param(
    [switch]$Update
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main"
$InstallDir = "$env:USERPROFILE\.claude\hooks\notification-sounds"
$SkillDir = "$env:USERPROFILE\.claude\skills\notification-toggle"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"

function Invoke-Download {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $requestParams = @{
        Uri = $Uri
        OutFile = $Destination
    }

    if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
        $requestParams.UseBasicParsing = $true
    }

    Invoke-WebRequest @requestParams
}

function Read-SoundChoice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [int]$DefaultChoice
    )

    while ($true) {
        $choice = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($choice)) {
            return $DefaultChoice
        }

        if ($choice -match "^\d+$") {
            $number = [int]$choice
            if ($number -ge 1 -and $number -le 10) {
                return $number
            }
        }

        Write-Host "Please enter a number between 1 and 10." -ForegroundColor Yellow
    }
}

function Get-SettingsObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{}
    }

    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse $Path. Fix the JSON and run the installer again."
    }
}

function Get-OrCreate-HooksObject {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Settings
    )

    if (-not ($Settings.PSObject.Properties.Name -contains "hooks")) {
        $Settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{})
    }

    return $Settings.hooks
}

function Get-HookCommandString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    return "powershell -ExecutionPolicy Bypass -File `"$InstallDir\$ScriptName`""
}

function Add-OrUpdate-HookCommand {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$EventName,

        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $hooksObject = Get-OrCreate-HooksObject -Settings $Settings
    $command = Get-HookCommandString -ScriptName $ScriptName
    $eventEntries = @()

    if ($hooksObject.PSObject.Properties.Name -contains $EventName) {
        $eventEntries = @($hooksObject.$EventName)
    }

    $matcherEntry = $eventEntries | Where-Object { $_.matcher -eq "" } | Select-Object -First 1
    if ($null -eq $matcherEntry) {
        $matcherEntry = [pscustomobject]@{
            matcher = ""
            hooks = @()
        }
        $eventEntries += $matcherEntry
    }

    $hookList = @()
    if ($matcherEntry.PSObject.Properties.Name -contains "hooks") {
        $hookList = @($matcherEntry.hooks)
    }

    $hookList = @($hookList | Where-Object { $_.command -ne $command })
    $hookList += [pscustomobject]@{
        type = "command"
        command = $command
        timeout = 5
    }

    $matcherEntry.hooks = $hookList

    if ($hooksObject.PSObject.Properties.Name -contains $EventName) {
        $hooksObject.PSObject.Properties.Remove($EventName)
    }

    $hooksObject | Add-Member -NotePropertyName $EventName -NotePropertyValue $eventEntries -Force
}

function Save-SettingsObject {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Settings | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $Path
}

function New-InitialState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StopSound,

        [Parameter(Mandatory = $true)]
        [string]$NotificationSound
    )

    return [pscustomobject]@{
        version = 1
        volume = 0.5
        paused = $false
        categories = [pscustomobject]@{
            stop = $true
            notification = $true
            session = $false
            prompt = $false
        }
        sounds = [pscustomobject]@{
            stop = "$StopSound.mp3"
            notification = "$NotificationSound.mp3"
            session = $null
            prompt = $null
        }
    }
}

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Notification Sounds" -ForegroundColor Cyan
Write-Host "  Windows Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "$env:USERPROFILE\.claude")) {
    Write-Host "Error: ~/.claude/ not found. Is Claude Code installed?" -ForegroundColor Red
    exit 1
}

# Create directories
Write-Host "Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$InstallDir\sounds" | Out-Null
New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null

# Download hook scripts
Write-Host "Downloading hook scripts..." -ForegroundColor Yellow
$Scripts = @("common.ps1", "stop.ps1", "notification.ps1", "session-start.ps1", "prompt-submit.ps1", "toggle.ps1")
foreach ($Script in $Scripts) {
    $Url = "$RepoUrl/hooks/$Script"
    $Dest = "$InstallDir\$Script"
    Invoke-Download -Uri $Url -Destination $Dest
    Write-Host "  - $Script" -ForegroundColor Green
}

# Download sounds
Write-Host "Downloading meme sounds..." -ForegroundColor Yellow
$Sounds = @("fbi.mp3", "bruh.mp3", "vine-boom.mp3", "wow.mp3", "nice.mp3", "oof.mp3", "yeet.mp3", "damn.mp3", "hell-nah.mp3", "airhorn.mp3", "sad-violin.mp3")
foreach ($Sound in $Sounds) {
    $Url = "$RepoUrl/sounds/$Sound"
    $Dest = "$InstallDir\sounds\$Sound"
    try {
        Invoke-Download -Uri $Url -Destination $Dest
        Write-Host "  - $Sound" -ForegroundColor Green
    } catch {
        Write-Host "  - $Sound (skipped)" -ForegroundColor DarkGray
    }
}

# Download skill
Write-Host "Downloading toggle skill..." -ForegroundColor Yellow
Invoke-Download -Uri "$RepoUrl/skills/notification-toggle/SKILL.md" -Destination "$SkillDir\SKILL.md"
Write-Host "  - SKILL.md" -ForegroundColor Green

# Ask user for sound preferences
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sound Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Available sounds:" -ForegroundColor White
Write-Host "  1. fbi        - FBI Open Up! (default)" -ForegroundColor White
Write-Host "  2. vine-boom  - Boom!" -ForegroundColor White
Write-Host "  3. nice       - Nice!" -ForegroundColor White
Write-Host "  4. wow        - Wow!" -ForegroundColor White
Write-Host "  5. bruh       - Bruh" -ForegroundColor White
Write-Host "  6. oof        - Oof" -ForegroundColor White
Write-Host "  7. damn       - Damn!" -ForegroundColor White
Write-Host "  8. yeet       - Yeet!" -ForegroundColor White
Write-Host "  9. hell-nah   - Hell Nah!" -ForegroundColor White
Write-Host " 10. airhorn    - Air Horn" -ForegroundColor White
Write-Host ""

$SoundNames = @("fbi", "vine-boom", "nice", "wow", "bruh", "oof", "damn", "yeet", "hell-nah", "airhorn")

$StopChoice = Read-SoundChoice -Prompt "Work complete sound (1-10, default=1)" -DefaultChoice 1
$NotificationChoice = Read-SoundChoice -Prompt "Permission request sound (1-10, default=5)" -DefaultChoice 5
$StopSound = $SoundNames[$StopChoice - 1]
$NotificationSound = $SoundNames[$NotificationChoice - 1]

Write-Host ""
Write-Host "Saving sound settings..." -ForegroundColor Yellow
$InitialState = New-InitialState -StopSound $StopSound -NotificationSound $NotificationSound
$InitialState | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $InstallDir ".state.json")
Write-Host "  - Work complete: $StopSound" -ForegroundColor Green
Write-Host "  - Permission request: $NotificationSound" -ForegroundColor Green

# Update settings.json without clobbering unrelated hooks
Write-Host ""
Write-Host "Updating Claude Code settings..." -ForegroundColor Yellow
$Settings = Get-SettingsObject -Path $SettingsPath
Add-OrUpdate-HookCommand -Settings $Settings -EventName "Stop" -ScriptName "stop.ps1"
Add-OrUpdate-HookCommand -Settings $Settings -EventName "Notification" -ScriptName "notification.ps1"
Save-SettingsObject -Settings $Settings -Path $SettingsPath
Write-Host "  - Hooks registered without overwriting existing settings" -ForegroundColor Green

# Test sound
Write-Host ""
Write-Host "Testing sound..." -ForegroundColor Yellow
. "$InstallDir\common.ps1"
Play-NotificationSound -Category "stop" -FallbackFile "fbi.mp3" -DurationMs 1500
Write-Host "  - Sound playback attempted" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sounds:" -ForegroundColor White
Write-Host "  - Work complete: $StopSound" -ForegroundColor Cyan
Write-Host "  - Permission request: $NotificationSound" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor White
Write-Host "  /notification-toggle  - Toggle sounds ON/OFF" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Code to apply!" -ForegroundColor Yellow
Write-Host ""
