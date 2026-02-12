# Claude Code Notification Sounds Installer for Windows
# Run: irm https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main/install.ps1 | iex

param(
    [switch]$Update
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main"
$InstallDir = "$env:USERPROFILE\.claude\hooks\notification-sounds"
$SkillDir = "$env:USERPROFILE\.claude\skills\notification-toggle"

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Notification Sounds" -ForegroundColor Cyan
Write-Host "  Windows Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
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
$Scripts = @("stop.ps1", "notification.ps1", "session-start.ps1", "prompt-submit.ps1", "toggle.ps1")
foreach ($Script in $Scripts) {
    $Url = "$RepoUrl/hooks/$Script"
    $Dest = "$InstallDir\$Script"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
    Write-Host "  - $Script" -ForegroundColor Green
}

# Download sounds
Write-Host "Downloading meme sounds..." -ForegroundColor Yellow
$Sounds = @("fbi.mp3", "bruh.mp3", "vine-boom.mp3", "wow.mp3", "nice.mp3", "oof.mp3", "yeet.mp3", "damn.mp3", "hell-nah.mp3", "airhorn.mp3", "sad-violin.mp3")
foreach ($Sound in $Sounds) {
    $Url = "$RepoUrl/sounds/$Sound"
    $Dest = "$InstallDir\sounds\$Sound"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
        Write-Host "  - $Sound" -ForegroundColor Green
    } catch {
        Write-Host "  - $Sound (skipped)" -ForegroundColor DarkGray
    }
}

# Download skill
Write-Host "Downloading toggle skill..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "$RepoUrl/skills/notification-toggle/SKILL.md" -OutFile "$SkillDir\SKILL.md" -UseBasicParsing
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

# Work complete sound
$StopChoice = Read-Host "Work complete sound (1-10, default=1)"
if ([string]::IsNullOrWhiteSpace($StopChoice)) { $StopChoice = "1" }
$StopSounds = @("fbi", "vine-boom", "nice", "wow", "bruh", "oof", "damn", "yeet", "hell-nah", "airhorn")
$StopSound = $StopSounds[[int]$StopChoice - 1]

# Notification sound
$NotifChoice = Read-Host "Permission request sound (1-10, default=5)"
if ([string]::IsNullOrWhiteSpace($NotifChoice)) { $NotifChoice = "5" }
$NotifSound = $StopSounds[[int]$NotifChoice - 1]

# Update scripts with chosen sounds
Write-Host ""
Write-Host "Configuring sounds..." -ForegroundColor Yellow
(Get-Content "$InstallDir\stop.ps1") -replace 'sounds\\.*\.mp3', "sounds\$StopSound.mp3" | Set-Content "$InstallDir\stop.ps1"
(Get-Content "$InstallDir\notification.ps1") -replace 'sounds\\.*\.mp3', "sounds\$NotifSound.mp3" | Set-Content "$InstallDir\notification.ps1"
Write-Host "  - Work complete: $StopSound" -ForegroundColor Green
Write-Host "  - Permission request: $NotifSound" -ForegroundColor Green

# Update settings.json
Write-Host ""
Write-Host "Updating Claude Code settings..." -ForegroundColor Yellow
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
$Username = $env:USERNAME

if (Test-Path $SettingsPath) {
    $Settings = Get-Content $SettingsPath | ConvertFrom-Json
} else {
    $Settings = @{}
}

# Add hooks
$Hooks = @{
    Stop = @(
        @{
            matcher = ""
            hooks = @(
                @{
                    type = "command"
                    command = "powershell -ExecutionPolicy Bypass -File `"C:\Users\$Username\.claude\hooks\notification-sounds\stop.ps1`""
                    timeout = 5
                }
            )
        }
    )
    Notification = @(
        @{
            matcher = ""
            hooks = @(
                @{
                    type = "command"
                    command = "powershell -ExecutionPolicy Bypass -File `"C:\Users\$Username\.claude\hooks\notification-sounds\notification.ps1`""
                    timeout = 5
                }
            )
        }
    )
}

$Settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $Hooks -Force
$Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath
Write-Host "  - Hooks registered" -ForegroundColor Green

# Test sound
Write-Host ""
Write-Host "Testing sound..." -ForegroundColor Yellow
Add-Type -AssemblyName presentationCore
$TestPlayer = New-Object System.Windows.Media.MediaPlayer
$TestPlayer.Open("$InstallDir\sounds\$StopSound.mp3")
$TestPlayer.Volume = 0.5
$TestPlayer.Play()
Start-Sleep -Milliseconds 2000
$TestPlayer.Close()
Write-Host "  - Sound works!" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sounds:" -ForegroundColor White
Write-Host "  - Work complete: $StopSound" -ForegroundColor Cyan
Write-Host "  - Permission request: $NotifSound" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor White
Write-Host "  /notification-toggle  - Toggle sounds ON/OFF" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Code to apply!" -ForegroundColor Yellow
Write-Host ""
