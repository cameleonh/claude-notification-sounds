# Claude Code Notification Sounds Uninstaller
# Run: irm https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"
$InstallDir = "$env:USERPROFILE\.claude\hooks\notification-sounds"
$SkillDir = "$env:USERPROFILE\.claude\skills\notification-toggle"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"

function Get-SettingsObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse $Path. Fix the JSON and run the uninstaller again."
    }
}

function Get-HookCommandString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    return "powershell -ExecutionPolicy Bypass -File `"$InstallDir\$ScriptName`""
}

function Remove-HookCommand {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Settings,

        [Parameter(Mandatory = $true)]
        [string]$EventName,

        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    if (-not ($Settings.PSObject.Properties.Name -contains "hooks")) {
        return
    }

    $hooksObject = $Settings.hooks
    if (-not ($hooksObject.PSObject.Properties.Name -contains $EventName)) {
        return
    }

    $command = Get-HookCommandString -ScriptName $ScriptName
    $updatedEntries = @()

    foreach ($entry in @($hooksObject.$EventName)) {
        $hookList = @()
        if ($entry.PSObject.Properties.Name -contains "hooks") {
            $hookList = @($entry.hooks | Where-Object { $_.command -ne $command })
        }

        if ($hookList.Count -gt 0) {
            $entry.hooks = $hookList
            $updatedEntries += $entry
        }
    }

    $hooksObject.PSObject.Properties.Remove($EventName)
    if ($updatedEntries.Count -gt 0) {
        $hooksObject | Add-Member -NotePropertyName $EventName -NotePropertyValue $updatedEntries -Force
    }

    if ($hooksObject.PSObject.Properties.Count -eq 0) {
        $Settings.PSObject.Properties.Remove("hooks")
    }
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

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  Claude Code Notification Sounds" -ForegroundColor Red
Write-Host "  Uninstaller" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

$Confirm = Read-Host "Are you sure you want to uninstall? (y/N)"
if ($Confirm -ne "y" -and $Confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

if (Test-Path $InstallDir) {
    Write-Host "Removing hooks directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  - Done" -ForegroundColor Green
}

if (Test-Path $SkillDir) {
    Write-Host "Removing skill directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $SkillDir
    Write-Host "  - Done" -ForegroundColor Green
}

if (Test-Path $SettingsPath) {
    Write-Host "Cleaning settings.json..." -ForegroundColor Yellow
    $Settings = Get-SettingsObject -Path $SettingsPath

    if ($null -ne $Settings) {
        Remove-HookCommand -Settings $Settings -EventName "Stop" -ScriptName "stop.ps1"
        Remove-HookCommand -Settings $Settings -EventName "Notification" -ScriptName "notification.ps1"
        Save-SettingsObject -Settings $Settings -Path $SettingsPath
        Write-Host "  - Removed only notification-sounds hooks" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Restart Claude Code to apply changes." -ForegroundColor Yellow
Write-Host ""
