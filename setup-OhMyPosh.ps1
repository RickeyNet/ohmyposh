#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive Oh My Posh setup script for Windows PowerShell.

.DESCRIPTION
    Installs Oh My Posh, deploys a custom theme, configures the PowerShell
    profile, optionally installs a Nerd Font, and patches Windows Terminal
    settings (font face + Elemental color scheme).

.NOTES
    Place your custom .omp.json theme file in the same directory as this script.
    Run from an elevated (admin) PowerShell prompt for font installation.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step  { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "   [OK] $Msg" -ForegroundColor Green }
function Write-Skip  { param([string]$Msg) Write-Host "   [SKIP] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "   [ERROR] $Msg" -ForegroundColor Red }

function Prompt-Choice {
    param(
        [string]$Question,
        [string[]]$Options        # first option is the default
    )
    Write-Host ""
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $default = $(if ($i -eq 0) { " (default)" } else { "" })
        Write-Host "   [$($i + 1)] $($Options[$i])$default"
    }
    $selection = Read-Host "   Enter choice [1-$($Options.Count)]"
    if ([string]::IsNullOrWhiteSpace($selection)) { return $Options[0] }
    $idx = [int]$selection - 1
    if ($idx -ge 0 -and $idx -lt $Options.Count) { return $Options[$idx] }
    return $Options[0]
}

# ── 1. Install Oh My Posh ────────────────────────────────────────────────────

Write-Step "Installing Oh My Posh"

$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    Write-Ok "Oh My Posh is already installed at: $($omp.Source)"
    $reinstall = Prompt-Choice "Reinstall / upgrade?" @("No","Yes")
    if ($reinstall -eq "Yes") {
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
    }
} else {
    Write-Host "   Trying winget..."
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements 2>$null

    # Refresh PATH and check if winget succeeded
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host "   winget failed, falling back to official install script..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        # Temporarily relax strict mode - the official install script uses
        # $IsMacOS/$IsLinux which are undefined in Windows PowerShell 5.1
        Set-StrictMode -Off
        # Suppress the "Script Execution Risk" warning from Invoke-WebRequest
        $PSDefaultParameterValues['Invoke-WebRequest:UseBasicParsing'] = $true
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
        $PSDefaultParameterValues.Remove('Invoke-WebRequest:UseBasicParsing')
        Set-StrictMode -Version Latest
    }
}

# Refresh PATH so oh-my-posh is available in this session
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Err "Oh My Posh installation failed. Check your internet connection and try again."
    exit 1
}
Write-Ok "Oh My Posh installed"

# ── 2. Deploy custom theme ───────────────────────────────────────────────────

Write-Step "Deploying custom theme"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$themeFiles  = @(Get-ChildItem -Path $scriptDir -Filter "*.omp.json" -ErrorAction SilentlyContinue)

if (-not $themeFiles -or $themeFiles.Count -eq 0) {
    Write-Err "No .omp.json files found in script directory: $scriptDir"
    Write-Host "   Place your custom theme file next to this script and re-run."
    exit 1
}

if ($themeFiles.Count -eq 1) {
    $selectedTheme = $themeFiles[0]
    Write-Host "   Found theme: $($selectedTheme.Name)"
} else {
    Write-Host "   Found multiple themes:"
    for ($i = 0; $i -lt $themeFiles.Count; $i++) {
        Write-Host "   [$($i + 1)] $($themeFiles[$i].Name)"
    }
    $pick = Read-Host "   Select a theme [1-$($themeFiles.Count)]"
    $idx  = [int]$pick - 1
    if ($idx -lt 0 -or $idx -ge $themeFiles.Count) { $idx = 0 }
    $selectedTheme = $themeFiles[$idx]
}

$themesDir  = Join-Path $env:USERPROFILE "oh-my-posh\themes"
$themeDest  = Join-Path $themesDir $selectedTheme.Name

if (-not (Test-Path $themesDir)) {
    New-Item -Path $themesDir -ItemType Directory -Force | Out-Null
}
Copy-Item -Path $selectedTheme.FullName -Destination $themeDest -Force
Write-Ok "Theme copied to: $themeDest"

# ── 3. Configure PowerShell profile ──────────────────────────────────────────

Write-Step "Configuring PowerShell profile"

$initLine = "oh-my-posh init pwsh --config `"$themeDest`" | Invoke-Expression"

if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Ok "Created profile: $PROFILE"
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -and $profileContent -match 'oh-my-posh init') {
    Write-Host "   Existing Oh My Posh init line detected in profile."
    $overwrite = Prompt-Choice "Replace it with the new theme config?" @("Yes","No")
    if ($overwrite -eq "Yes") {
        $updated = $profileContent -replace '(?m)^.*oh-my-posh init.*$', $initLine
        Set-Content -Path $PROFILE -Value $updated -Encoding UTF8
        Write-Ok "Profile updated"
    } else {
        Write-Skip "Profile left unchanged"
    }
} else {
    Add-Content -Path $PROFILE -Value "`n$initLine" -Encoding UTF8
    Write-Ok "Init line added to profile"
}

# ── 4. Nerd Font ─────────────────────────────────────────────────────────────

Write-Step "Nerd Font setup"

$fontOptions = @(
    "CaskaydiaCove Nerd Font"
    "MesloLGS Nerd Font"
    "FiraCode Nerd Font"
    "Skip - I already have one installed"
)
$fontChoice = Prompt-Choice "Which Nerd Font would you like to install?" $fontOptions

$fontMap = @{
    "CaskaydiaCove Nerd Font" = "CascadiaCode"
    "MesloLGS Nerd Font"      = "Meslo"
    "FiraCode Nerd Font"       = "FiraCode"
}

# The font face string Windows Terminal expects
$fontFaceMap = @{
    "CaskaydiaCove Nerd Font" = "CaskaydiaCove Nerd Font"
    "MesloLGS Nerd Font"      = "MesloLGS Nerd Font"
    "FiraCode Nerd Font"       = "FiraCode Nerd Font"
}

if ($fontChoice -ne "Skip - I already have one installed") {
    $fontSlug  = $fontMap[$fontChoice]
    $fontZip   = Join-Path $env:TEMP "$fontSlug.zip"
    $fontDir   = Join-Path $env:TEMP "$fontSlug"
    $nerdUrl   = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$fontSlug.zip"

    Write-Host "   Downloading $fontChoice ..."
    Invoke-WebRequest -Uri $nerdUrl -OutFile $fontZip -UseBasicParsing

    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force

    Write-Host "   Installing fonts ..."
    $localFonts = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (-not (Test-Path $localFonts)) {
        New-Item -Path $localFonts -ItemType Directory -Force | Out-Null
    }

    Get-ChildItem -Path $fontDir -Include "*.ttf","*.otf" -Recurse | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $localFonts -Force
        # Register the font for the current user
        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        New-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -Value $_.FullName -PropertyType String -Force | Out-Null
    }

    Write-Ok "$fontChoice installed"
    $terminalFontFace = $fontFaceMap[$fontChoice]

    # Cleanup
    Remove-Item $fontZip -Force -ErrorAction SilentlyContinue
    Remove-Item $fontDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Skip "Font installation skipped"
    $terminalFontFace = Read-Host "   Enter the exact font face name you want in Windows Terminal (e.g. CaskaydiaCove Nerd Font)"
    if ([string]::IsNullOrWhiteSpace($terminalFontFace)) {
        $terminalFontFace = "CaskaydiaCove Nerd Font"
        Write-Host "   Defaulting to: $terminalFontFace"
    }
}

# ── 5. Patch Windows Terminal settings.json ──────────────────────────────────

Write-Step "Patching Windows Terminal settings"

# Locate settings.json (stable and preview locations)
$wtPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

$wtSettings = $wtPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $wtSettings) {
    Write-Err "Could not locate Windows Terminal settings.json"
    Write-Host "   Searched:"
    $wtPaths | ForEach-Object { Write-Host "     $_" }
    Write-Host "   You can manually set the font and color scheme in Windows Terminal settings."
} else {
    Write-Host "   Found: $wtSettings"

    # Back up
    $backup = "$wtSettings.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $wtSettings -Destination $backup -Force
    Write-Ok "Backup created: $backup"

    # Read JSON (strip BOM and comments for clean parsing)
    $rawJson   = Get-Content $wtSettings -Raw -Encoding UTF8
    # Remove single-line comments (// ...) that Windows Terminal allows but .NET JSON parser doesn't
    $cleanJson = $rawJson -replace '(?m)^\s*//[^"]*$', '' -replace '(?<=,)\s*//[^"]*$', ''
    $settings  = $cleanJson | ConvertFrom-Json

    # ── 5a. Add Elemental color scheme if missing ─────────────────────────────

    $elementalScheme = @{
        name             = "Elemental"
        black            = "#3c3c30"
        red              = "#98290f"
        green            = "#479a43"
        yellow           = "#7f7111"
        blue             = "#497f7d"
        purple           = "#7f4e2f"
        cyan             = "#387f58"
        white            = "#807974"
        brightBlack      = "#555445"
        brightRed        = "#e0502a"
        brightGreen      = "#61e070"
        brightYellow     = "#d69927"
        brightBlue       = "#79d9d9"
        brightPurple     = "#cd7c54"
        brightCyan       = "#59d599"
        brightWhite      = "#fff1e9"
        background       = "#22211d"
        foreground       = "#807974"
        cursorColor      = "#facb80"
        selectionBackground = "#413829"
    }

    if (-not $settings.PSObject.Properties['schemes']) {
        $settings | Add-Member -NotePropertyName "schemes" -NotePropertyValue @()
    }

    $hasElemental = $settings.schemes | Where-Object { $_.name -eq "Elemental" }
    if ($hasElemental) {
        Write-Ok "Elemental color scheme already exists - skipping"
    } else {
        $settings.schemes += [PSCustomObject]$elementalScheme
        Write-Ok "Elemental color scheme added"
    }

    # ── 5b. Update PowerShell profile in Windows Terminal ─────────────────────

    $pwshProfile = $settings.profiles.list | Where-Object {
        $_.name -match 'PowerShell' -or
        $_.commandline -match 'pwsh' -or
        $_.source -match 'PowerShell'
    } | Select-Object -First 1

    if ($pwshProfile) {
        # Set color scheme
        if ($pwshProfile.PSObject.Properties['colorScheme']) {
            $pwshProfile.colorScheme = "Elemental"
        } else {
            $pwshProfile | Add-Member -NotePropertyName "colorScheme" -NotePropertyValue "Elemental"
        }

        # Set font face
        if (-not $pwshProfile.PSObject.Properties['font']) {
            $pwshProfile | Add-Member -NotePropertyName "font" -NotePropertyValue ([PSCustomObject]@{ face = $terminalFontFace })
        } else {
            if ($pwshProfile.font.PSObject.Properties['face']) {
                $pwshProfile.font.face = $terminalFontFace
            } else {
                $pwshProfile.font | Add-Member -NotePropertyName "face" -NotePropertyValue $terminalFontFace
            }
        }

        Write-Ok "PowerShell profile updated - scheme: Elemental, font: $terminalFontFace"
    } else {
        Write-Err "No PowerShell profile found in Windows Terminal settings"
        Write-Host "   You may need to set the font and color scheme manually."
    }

    # Write back
    $settings | ConvertTo-Json -Depth 20 | Set-Content -Path $wtSettings -Encoding UTF8
    Write-Ok "Windows Terminal settings saved"
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host "`n" -NoNewline
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Theme:    $($selectedTheme.Name)"
Write-Host "  Font:     $terminalFontFace"
Write-Host "  Scheme:   Elemental"
Write-Host "  Profile:  $PROFILE"
Write-Host ""
Write-Host "  If icons look broken, restart Windows Terminal" -ForegroundColor Yellow
Write-Host "  so the new font takes effect." -ForegroundColor Yellow
Write-Host ""

# Activate Oh My Posh in the current session
. $PROFILE