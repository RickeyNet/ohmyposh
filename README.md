# Oh My Posh Setup Script for Windows

An interactive PowerShell script that automates the full Oh My Posh setup on Windows: installs Oh My Posh, deploys a custom Gruvbox/Elemental theme, configures your PowerShell profile, installs a Nerd Font, and patches Windows Terminal settings.

## What's Included

| File | Purpose |
|---|---|
| `setup-OhMyPosh.ps1` | Automated setup script |
| `gruvbox_elemental.omp.json` | Custom Oh My Posh theme with Gruvbox/Elemental colors |
| `ohmyposhwindowsguide.md` | Manual step-by-step guide (for reference) |

## Prerequisites

- Windows 10 or 11
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- [Windows Terminal](https://aka.ms/terminal) installed
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) available (comes with modern Windows)
 
- Open Windows Terminal as Administrator (right-click → Run as administrator), then run:

      winget source reset --force

- That one command fixes winget. After that, close the admin window, open a regular terminal, and run:

      winget install pwsh

- Close and re open a regular terminal window and run:

      pwsh --version

- You should be on version 7+

## Quick Start

1. Clone or download this repository
2. Open an **elevated (admin) PowerShell** prompt — admin is required for font installation
3. Navigate to the script directory:

   ```powershell
   cd path\to\ohmyposh
   ```

4. If needed, allow script execution:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

5. Run the script:

   ```powershell
   .\setup-OhMyPosh.ps1
   ```

6. After the script completes, reload your profile:

   ```powershell
   . $PROFILE
   ```

7. If icons appear as boxes or question marks, **close and reopen Windows Terminal** so the new font takes effect.

## What the Script Does

### Step 1 — Install Oh My Posh

Checks if Oh My Posh is already installed. If not, installs it via `winget`. If it is, offers to reinstall/upgrade. Refreshes your PATH so `oh-my-posh` is available immediately without restarting the terminal.

### Step 2 — Deploy Custom Theme

Finds all `.omp.json` theme files in the script's directory. If there's one theme, it auto-selects it. If there are multiple, it asks you to pick. The selected theme is copied to:

```
%USERPROFILE%\oh-my-posh\themes\
```

The directory is created automatically if it doesn't exist.

### Step 3 — Configure PowerShell Profile

Adds the Oh My Posh init line to your PowerShell profile (`$PROFILE`):

```powershell
oh-my-posh init pwsh --config "C:\Users\<you>\oh-my-posh\themes\gruvbox_elemental.omp.json" | Invoke-Expression
```

- If the profile file doesn't exist, it creates it.
- If an existing Oh My Posh init line is found, it asks whether to replace it.
- Otherwise, it appends the line to the end of the file.

### Step 4 — Install a Nerd Font

Oh My Posh themes use special icons that require a Nerd Font. The script presents a menu:

```
[1] CaskaydiaCove Nerd Font (default)
[2] MesloLGS Nerd Font
[3] FiraCode Nerd Font
[4] Skip — I already have one installed
```

If you choose a font, the script downloads it from GitHub, extracts it, and installs the font files into your system Fonts folder. If you skip, it asks for the name of your existing Nerd Font so it can configure Windows Terminal.

### Step 5 — Patch Windows Terminal Settings

The script automatically finds your Windows Terminal `settings.json` (supports Store, Preview, and standalone installs) and:

1. **Creates a timestamped backup** of your current settings
2. **Adds the Elemental color scheme** to the `schemes` array (if not already present) — the colors match the `gruvbox_elemental.omp.json` theme palette
3. **Updates your PowerShell profile** in Windows Terminal to use the Elemental color scheme and the selected Nerd Font

### Summary

When finished, the script prints a summary of everything it configured:

```
=============================================
  Setup complete!
=============================================

  Theme:    gruvbox_elemental.omp.json
  Font:     CaskaydiaCove Nerd Font
  Scheme:   Elemental
  Profile:  C:\Users\<you>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

## Using Your Own Theme

Place any `.omp.json` theme file in the same directory as the script. If multiple themes are present, the script will ask you to choose one. You can download themes from the [Oh My Posh theme gallery](https://ohmyposh.dev/docs/themes).

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Execution policy error | Scripts are blocked by default | Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `CONFIG NOT FOUND` in prompt | Theme file path is wrong or missing | Verify with `Test-Path "$env:USERPROFILE\oh-my-posh\themes\gruvbox_elemental.omp.json"` |
| Init command prints instead of running | Missing `\| Invoke-Expression` in profile | Re-run the script or manually add it to `$PROFILE` |
| Icons show as boxes or `?` | Nerd Font not installed or not set in terminal | Re-run the script and install a font, then restart Windows Terminal |
| Font install fails | Not running as admin | Right-click PowerShell and select "Run as administrator" |
| Windows Terminal settings not found | Terminal installed in a non-standard location | Manually set the font and color scheme in Windows Terminal settings |

## Useful Commands

```powershell
# Reload your profile without restarting
. $PROFILE

# Check Oh My Posh version
oh-my-posh --version

# Open your profile for editing
notepad $PROFILE

# List your downloaded themes
Get-ChildItem "$env:USERPROFILE\oh-my-posh\themes"

# Find where oh-my-posh is installed
Get-Command oh-my-posh | Select-Object -ExpandProperty Source
```

## Resources

- [Oh My Posh Documentation](https://ohmyposh.dev/docs)
- [Theme Gallery](https://ohmyposh.dev/docs/themes)
- [Nerd Fonts](https://www.nerdfonts.com)
- [Oh My Posh GitHub](https://github.com/JanDeDobbeleer/oh-my-posh)
