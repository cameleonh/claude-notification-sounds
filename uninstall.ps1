# Claude Code Notification Sounds Uninstaller
# Run: irm https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"
$InstallDir = "$env:USERPROFILE\.claude\hooks\notification-sounds"
$SkillDir = "$env:USERPROFILE\.claude\skills\notification-toggle"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  Claude Code Notification Sounds" -ForegroundColor Red
Write-Host "  Uninstaller" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Confirm
$Confirm = Read-Host "Are you sure you want to uninstall? (y/N)"
if ($Confirm -ne "y" -and $Confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Remove hooks directory
if (Test-Path $InstallDir) {
    Write-Host "Removing hooks directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  - Done" -ForegroundColor Green
}

# Remove skill directory
if (Test-Path $SkillDir) {
    Write-Host "Removing skill directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $SkillDir
    Write-Host "  - Done" -ForegroundColor Green
}

# Remove hooks from settings.json
if (Test-Path $SettingsPath) {
    Write-Host "Cleaning settings.json..." -ForegroundColor Yellow
    $Settings = Get-Content $SettingsPath | ConvertFrom-Json

    if ($Settings.hooks) {
        $Settings.hooks.PSObject.Properties.Remove("Stop")
        $Settings.hooks.PSObject.Properties.Remove("Notification")
        $Settings.hooks.PSObject.Properties.Remove("SessionStart")
        $Settings.hooks.PSObject.Properties.Remove("UserPromptSubmit")

        # Remove empty hooks object
        if ($Settings.hooks.PSObject.Properties.Count -eq 0) {
            $Settings.PSObject.Properties.Remove("hooks")
        }

        $Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath
        Write-Host "  - Done" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
