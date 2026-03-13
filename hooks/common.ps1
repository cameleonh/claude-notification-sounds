function Get-NotificationSoundDefaultConfig {
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
            stop = "fbi.mp3"
            notification = "bruh.mp3"
            session = $null
            prompt = $null
        }
    }
}

function Test-NotificationSoundProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne $InputObject -and ($InputObject.PSObject.Properties.Name -contains $Name)
}

function Merge-NotificationSoundConfig {
    param(
        [Parameter()]
        [object]$Config
    )

    $merged = Get-NotificationSoundDefaultConfig
    if ($null -eq $Config) {
        return $merged
    }

    if (Test-NotificationSoundProperty -InputObject $Config -Name "version") {
        $merged.version = [int]$Config.version
    }

    if (Test-NotificationSoundProperty -InputObject $Config -Name "volume") {
        try {
            $merged.volume = [double]$Config.volume
        } catch {
            $merged.volume = 0.5
        }
    }

    if (Test-NotificationSoundProperty -InputObject $Config -Name "paused") {
        $merged.paused = [bool]$Config.paused
    }

    foreach ($category in @("stop", "notification", "session", "prompt")) {
        if ((Test-NotificationSoundProperty -InputObject $Config -Name "categories") -and
            (Test-NotificationSoundProperty -InputObject $Config.categories -Name $category)) {
            $merged.categories.$category = [bool]$Config.categories.$category
        }

        if ((Test-NotificationSoundProperty -InputObject $Config -Name "sounds") -and
            (Test-NotificationSoundProperty -InputObject $Config.sounds -Name $category)) {
            $sound = [string]$Config.sounds.$category
            if ([string]::IsNullOrWhiteSpace($sound)) {
                $merged.sounds.$category = $null
            } elseif ($sound -match "\.mp3$") {
                $merged.sounds.$category = $sound
            } else {
                $merged.sounds.$category = "$sound.mp3"
            }
        }
    }

    return $merged
}

function Get-NotificationSoundStatePath {
    return Join-Path $PSScriptRoot ".state.json"
}

function Save-NotificationSoundConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter()]
        [string]$StatePath = (Get-NotificationSoundStatePath)
    )

    $parentDir = Split-Path -Parent $StatePath
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    $Config | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 $StatePath
}

function Get-NotificationSoundConfig {
    param(
        [Parameter()]
        [string]$StatePath = (Get-NotificationSoundStatePath)
    )

    $config = Get-NotificationSoundDefaultConfig

    if (Test-Path $StatePath) {
        try {
            $rawConfig = Get-Content $StatePath -Raw | ConvertFrom-Json
            $config = Merge-NotificationSoundConfig -Config $rawConfig
        } catch {
            $config = Get-NotificationSoundDefaultConfig
        }
    }

    return $config
}

function Test-NotificationSoundEnabled {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    if ($Config.paused -eq $true) {
        return $false
    }

    if ((Test-NotificationSoundProperty -InputObject $Config -Name "categories") -and
        (Test-NotificationSoundProperty -InputObject $Config.categories -Name $Category)) {
        return [bool]$Config.categories.$Category
    }

    return $true
}

function Get-NotificationSoundVolume {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    try {
        $volume = [double]$Config.volume
    } catch {
        $volume = 0.5
    }

    if ($volume -lt 0) {
        return 0
    }

    if ($volume -gt 1) {
        return 1
    }

    return $volume
}

function Get-NotificationSoundPath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter()]
        [string]$FallbackFile
    )

    $soundFile = $FallbackFile
    if ((Test-NotificationSoundProperty -InputObject $Config -Name "sounds") -and
        (Test-NotificationSoundProperty -InputObject $Config.sounds -Name $Category) -and
        -not [string]::IsNullOrWhiteSpace([string]$Config.sounds.$Category)) {
        $soundFile = [string]$Config.sounds.$Category
    }

    if ([string]::IsNullOrWhiteSpace($soundFile)) {
        return $null
    }

    return Join-Path (Join-Path $PSScriptRoot "sounds") $soundFile
}

function Play-NotificationSound {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter()]
        [string]$FallbackFile,

        [Parameter()]
        [int]$DurationMs = 1000
    )

    $config = Get-NotificationSoundConfig
    if (-not (Test-NotificationSoundEnabled -Config $config -Category $Category)) {
        return
    }

    $soundPath = Get-NotificationSoundPath -Config $config -Category $Category -FallbackFile $FallbackFile
    if ([string]::IsNullOrWhiteSpace($soundPath) -or -not (Test-Path $soundPath)) {
        return
    }

    Add-Type -AssemblyName presentationCore
    $player = New-Object System.Windows.Media.MediaPlayer

    try {
        $player.Open((New-Object System.Uri($soundPath)))
        $player.Volume = Get-NotificationSoundVolume -Config $config
        $player.Play()
        Start-Sleep -Milliseconds $DurationMs
    } finally {
        $player.Close()
    }
}
