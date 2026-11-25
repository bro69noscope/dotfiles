# Vault setup

Scripts that share Obsidian config between vaults. The shared config is in `../config/`, with the
same layout as `<vault>/.obsidian/`: `hotkeys.json` and `plugins/<plugin-id>/`. Vaults do not
track these files.

Each vault has a `setup-vault/` folder that commits `dotfiles-init.ps1`, a copy of the script
here. It gets `fetch-vault.ps1`, `push-vault.ps1` and `paths.ps1` (the paths that both scripts
dot-source) from this folder if they are missing.

## Scripts

| Script | Direction | What it does |
| --- | --- | --- |
| `dotfiles-init.ps1` | dotfiles (GitHub) to vault | Sparse-clones `obsidian/setup-vault/`, copies the missing scripts, deletes the clone. |
| &nbsp; | | |
| `fetch-vault.ps1` | dotfiles (GitHub) to vault | Sparse-clones the shared files and all the plugins, copies the missing files, deletes the clone. `-Force` overwrites existing files too. |
| &nbsp; | | |
| `push-vault.ps1` | vault to dotfiles (local repo) | Mirrors the shared files and the installed plugins (except the local ones) into `~/myfiles/dotfiles/obsidian/config/`. Does not commit. |

```pwsh
# New vault: copy dotfiles-init.ps1 in <vault>/setup-vault/

# New machine, or get the changes from another machine
pwsh -File setup-vault/dotfiles-init.ps1
pwsh -File setup-vault/fetch-vault.ps1
pwsh -File setup-vault/fetch-vault.ps1 -Force

# After a change in Obsidian (hotkeys, plugin settings, plugin update, new plugin)
pwsh -File setup-vault/push-vault.ps1
```

## Plugins

The plugin folders in `../config/plugins/` are the shared plugins: there is no list.

- `fetch-vault.ps1` gets all of them.
- `push-vault.ps1` sends every plugin installed in the vault, so a new plugin becomes shared.
  It skips the ids in the vault's optional `setup-vault/local-plugins.json` (a JSON array): these
  plugins stay in that vault.

A plugin removed from a vault stays here. Delete its folder here to stop sharing it.

## shared.json

`shared.json` here sets, with paths relative to `.obsidian/`:

- `files`: shared files outside `plugins/`, such as `hotkeys.json`.
- `vaultOnly`: plugin files that hold data for one vault only. `push-vault.ps1` does not copy
  them. Add a file there when a plugin starts to keep vault data.

Vaults do not keep a copy. `push-vault.ps1` reads it from the local dotfiles repo, and
`fetch-vault.ps1` reads it from its clone.
