# iPhone Auto Library Sorter

A small Windows tool that sorts a downloaded iCloud Photos export into clean folders: **Live Photos**, **Photos**, **Videos** and **Other**.

iCloud exports are limited to a maximum of 1,000 media files each, so a larger library arrives as many separate folders with everything mixed together. This tool copies everything from all of those folders into one organized structure and checks at the end that no file went missing.

## What it does

- Reads every `iCloud Photos*` folder inside `Raw Files`
- Detects **Live Photos** (a `.heic`/`.jpg` paired with a `.mov` of the same name) and puts them in their own folder
- Lets you choose whether to include the Live Photo `.mov` files or keep only the still images
- Sorts everything else into `Photos`, `Videos` or `Other`
- Handles duplicate file names safely (`IMG_0001.HEIC` -> `IMG_0001_1.HEIC`), so nothing is overwritten
- Prints a final report with counts per file type and a total check (`Missing` should be `0`)

**Your original files are never moved, changed or deleted.** The tool only copies.

## Folder structure

Put the tool next to a folder named `Raw Files`, and place your downloaded iCloud export folders inside it:

```
iPhone Auto Library Sorter/
├── iPhone - iCloud Sorter.exe      (or the .ps1 script)
└── Raw Files/
    ├── iCloud Photos/
    ├── iCloud Photos (1)/
    ├── iCloud Photos (2)/
    └── ...
```

> Folders inside `Raw Files` must have names that start with **`iCloud Photos`**. Any folder with a different name is ignored. Since each export holds at most 1,000 files, put all of them in `Raw Files` and the tool merges them in one run.

After running, you get:

```
Organized/
├── LivePhotos/
├── Photos/
├── Videos/
└── Other/
```

## How to use

### Option A: the .exe
1. Download `iPhone-Auto-Library-Sorter.zip` from the [Releases](../../releases) page and extract it anywhere.
2. Put your iCloud export folders inside the `Raw Files` folder (see the note in that folder).
3. Double-click `iPhone - iCloud Sorter.exe` and follow the prompt.

The exe is unsigned, so Windows SmartScreen or your antivirus may show a warning the first time. You can click **More info -> Run anyway**, or build it yourself (below) or use Option B.

### Option B: the PowerShell script
1. Open PowerShell in the folder that contains `Raw Files`.
2. Run:
   ```powershell
   .\iCloud - Sorting Script.ps1
   ```
   If Windows blocks it, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once and try again.

If `Raw Files` has no iCloud export folders, the tool tells you to add them first and exits.

## Build the exe yourself

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe ".\iCloud - Sorting Script.ps1" ".\iPhone - iCloud Sorter.exe" -title "iPhone Auto Library Sorter"
```

## Requirements

- Windows with PowerShell 5.1 or newer (included with Windows 10/11)
- Enough free disk space for a second copy of your library, since files are copied, not moved

## License

MIT. See [LICENSE](LICENSE).
