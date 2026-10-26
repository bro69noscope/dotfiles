# utils-script

AutoHotkey v2 utilities. Entry point is `main.ahk`, which only includes modules and defines the
direct hotkeys.

## streaming-ahk junction

`streaming-ahk/` is a junction to `$env:STREAMING_REPO_PATH\external\ahk`. It is gitignored and must
be created on each machine, otherwise includes fail with "Failed to open file":

```
pwsh -File scripts\create-junction.ps1          # create
pwsh -File scripts\create-junction.ps1 -Remove  # remove
```

Requires `DOTFILES_PATH` and `STREAMING_REPO_PATH` to be set.

Runtime files (`*.ini`, `logs/`, `keyboard_info.txt`) are written next to `main.ahk` and are
gitignored.
