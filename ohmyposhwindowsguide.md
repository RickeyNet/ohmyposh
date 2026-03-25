# Oh My Posh Setup Guide for Windows (PowerShell)

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- A terminal that supports custom fonts (Windows Terminal recommended)

---

## 1. Install Oh My Posh

Open PowerShell and run:

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

> **Note:** Even when installed via PowerShell/winget, Oh My Posh may install as the Microsoft Store version. You can confirm by checking the install location:
> ```powershell
> Get-Command oh-my-posh | Select-Object -ExpandProperty Source
> ```
> If it returns a path under `WindowsApps`, you have the Store version — this is fine and works the same way.

---

## 2. Create Your PowerShell Profile

Your PowerShell profile is a script that runs automatically every time a new session starts. It may not exist yet, so create it first:

```powershell
New-Item -Path $PROFILE -ItemType File -Force
notepad $PROFILE
```

The `-Force` flag creates any missing parent directories automatically.

---

## 3. Install a Nerd Font

Oh My Posh themes use special icons that require a **Nerd Font**. Without one, you'll see boxes or question marks instead of icons.

1. Go to [nerdfonts.com](https://www.nerdfonts.com/font-downloads)
2. Download a font (popular choices: **CaskaydiaCove Nerd Font**, **MesloLGS NF**, **FiraCode Nerd Font**)
3. Extract the zip and install the `.ttf` files (right-click → Install)
4. Set the font in your terminal:
   - **Windows Terminal**: Settings → your profile → Appearance → Font face

---

## 4. Download a Theme

The Microsoft Store version of Oh My Posh does not bundle themes locally, so you need to download them manually.

**Create a themes folder:**

```powershell
New-Item -Path "$env:USERPROFILE\oh-my-posh\themes" -ItemType Directory -Force
```

**Download a theme (example: jandedobbeleer):**

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json" -OutFile "$env:USERPROFILE\oh-my-posh\themes\jandedobbeleer.omp.json"
```

You can browse all available themes at [ohmyposh.dev/docs/themes](https://ohmyposh.dev/docs/themes).

---

## 5. Configure Your Profile

Open your profile:

```powershell
notepad $PROFILE
```

Add the following line, making sure to include `| Invoke-Expression` at the end:

```powershell
oh-my-posh init pwsh --config "$env:USERPROFILE\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression
```

> ⚠️ **Common mistake:** Leaving off `| Invoke-Expression` causes PowerShell to print the init command instead of running it. Always include it.

Save the file, then reload your profile without restarting the terminal:

```powershell
. $PROFILE
```

---

## 6. Adding More Themes

### Download additional themes

Replace `<theme-name>` with the name of any theme from the [Oh My Posh theme gallery](https://ohmyposh.dev/docs/themes):

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/<theme-name>.omp.json" -OutFile "$env:USERPROFILE\oh-my-posh\themes\<theme-name>.omp.json"
```

**Example — download the `atomic` theme:**

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json" -OutFile "$env:USERPROFILE\oh-my-posh\themes\atomic.omp.json"
```

### Switch themes

Open your profile and update the `--config` path to point to the new theme:

```powershell
notepad $PROFILE
```

Change the filename at the end of the path:

```powershell
oh-my-posh init pwsh --config "$env:USERPROFILE\oh-my-posh\themes\atomic.omp.json" | Invoke-Expression
```

Then reload:

```powershell
. $PROFILE
```

### List your downloaded themes

```powershell
Get-ChildItem "$env:USERPROFILE\oh-my-posh\themes"
```

---

## 7. Setting a Terminal Color Scheme (Terminal Splash / Elemental)

Oh My Posh controls the **prompt segment colors**, but the terminal background, text, and cursor colors are controlled separately by Windows Terminal's color scheme settings. These are two independent layers that work together.

### Add a color scheme to Windows Terminal

**1. Open your Windows Terminal settings JSON:**

Press `Ctrl+Shift+,` or go to Settings → open the JSON file (bottom left corner).

**2. Find the `"schemes"` array and add your scheme to it** (do not replace existing ones — just append):

```json
"schemes": [
    {
        "name": "Campbell",
        ...existing scheme...
    },
    {
        "name": "Elemental",
        "black": "#3c3c30",
        "red": "#98290f",
        "green": "#479a43",
        "yellow": "#7f7111",
        "blue": "#497f7d",
        "purple": "#7f4e2f",
        "cyan": "#387f58",
        "white": "#807974",
        "brightBlack": "#555445",
        "brightRed": "#e0502a",
        "brightGreen": "#61e070",
        "brightYellow": "#d69927",
        "brightBlue": "#79d9d9",
        "brightPurple": "#cd7c54",
        "brightCyan": "#59d599",
        "brightWhite": "#fff1e9",
        "background": "#22211d",
        "foreground": "#807974",
        "cursorColor": "#facb80",
        "selectionBackground": "#413829"
    }
]
```

**3. Apply it to your PowerShell profile entry under `"profiles"` → `"list"`:**

```json
{
    "name": "PowerShell",
    "colorScheme": "Elemental"
}
```

**4. Save** — changes apply instantly, no restart needed.

You can also apply it through the GUI: **Settings → your PowerShell profile → Appearance → Color scheme → dropdown**.

### Matching Oh My Posh prompt colors to your terminal scheme

If you want your Oh My Posh prompt segments to use the same colors as your terminal scheme, define a `palette` block at the top of your `.omp.json` and reference colors with `p:colorname`:

```json
{
  "palette": {
    "blue":         "#497f7d",
    "cyan":         "#387f58",
    "brightWhite":  "#fff1e9",
    "brightYellow": "#d69927"
  },
  "blocks": [
    {
      "segments": [
        {
          "background": "p:blue",
          "foreground": "p:brightWhite"
        }
      ]
    }
  ]
}
```

This makes global color changes easy — update the palette once and it applies everywhere.

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `CONFIG NOT FOUND` in prompt | Theme file path is wrong or file doesn't exist | Verify the path with `Test-Path "your\path\here"` and re-download the theme |
| Init command prints instead of running | Missing `\| Invoke-Expression` in profile | Add `\| Invoke-Expression` to the end of the init line |
| Icons show as boxes or `?` | Nerd Font not installed or not set in terminal | Install a Nerd Font and set it in your terminal's font settings |
| Profile file not found | Profile doesn't exist yet | Run `New-Item -Path $PROFILE -ItemType File -Force` |
| Blank `$env:POSH_THEMES_PATH` | Store version doesn't set this variable | Use a full hardcoded path to your themes folder instead |

---

## Useful Commands

```powershell
# Check Oh My Posh version
oh-my-posh --version

# Open your profile for editing
notepad $PROFILE

# Reload your profile without restarting
. $PROFILE

# Show the full path of your profile file
echo $PROFILE

# List your downloaded themes
Get-ChildItem "$env:USERPROFILE\oh-my-posh\themes"

# Find where oh-my-posh is installed
Get-Command oh-my-posh | Select-Object -ExpandProperty Source
```

---

## Resources

- [Oh My Posh Documentation](https://ohmyposh.dev/docs)
- [Theme Gallery](https://ohmyposh.dev/docs/themes)
- [Nerd Fonts](https://www.nerdfonts.com)
- [Oh My Posh GitHub](https://github.com/JanDeDobbeleer/oh-my-posh)