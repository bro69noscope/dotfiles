# Vault setup

Scripts that share Obsidian config between vaults. The shared config is in `../config/`, with the
same layout as `<vault>/.obsidian/`: `hotkeys.json` and `plugins/<plugin-id>/`. Vaults do not
track these files.

Each vault has a `setup-vault/` folder that commits:

- `dotfiles-init.ps1`: a copy of the script here. Gets `fetch-vault.ps1` and `push-vault.ps1`
  from this folder if they are missing. The vault gitignores them.
- `plugins.json`: the plugins that the vault gets from dotfiles. The scripts do not use
  `.obsidian/community-plugins.json`, because Obsidian removes a plugin from that file when the
  plugin is missing at startup.

## Scripts

| Script | Direction | What it does |
| --- | --- | --- |
| `dotfiles-init.ps1` | dotfiles (GitHub) to vault | Sparse-clones `obsidian/setup-vault/`, copies the missing scripts, deletes the clone. |
| `fetch-vault.ps1` | dotfiles (GitHub) to vault | Sparse-clones the shared files and the listed plugins, copies the missing files, deletes the clone. `-Force` overwrites existing files too. |
| `push-vault.ps1` | vault to dotfiles (local repo) | Mirrors the shared files and the listed plugins into `~/myfiles/dotfiles/obsidian/config/`. Does not commit. |

```pwsh
# New vault: copy dotfiles-init.ps1 and write plugins.json in <vault>/setup-vault/

# New machine, or get the changes from another machine
pwsh -File setup-vault/dotfiles-init.ps1
pwsh -File setup-vault/fetch-vault.ps1
pwsh -File setup-vault/fetch-vault.ps1 -Force

# After a change in Obsidian (hotkeys, plugin settings, plugin update, new plugin)
pwsh -File setup-vault/push-vault.ps1
git -C ~/myfiles/dotfiles diff -- obsidian/config
```

Then commit and push in dotfiles. `dotfiles-init.ps1` and `fetch-vault.ps1` read from GitHub, not
from the local dotfiles folder.

Edit the scripts here, not in a vault. To update a vault copy, delete it and run
`dotfiles-init.ps1`.

## Shared files and vault-specific files

`$Files` in `fetch-vault.ps1` and `push-vault.ps1` lists the shared files. Keep the two lists the
same.

Some plugin files hold data for one vault only. `push-vault.ps1` does not copy them: see
`$VaultOnly` in the script. Add a file there when a plugin starts to keep vault data.

## Warnings

`fetch-vault.ps1` warns when a listed plugin:

- is not in dotfiles. Install it from Obsidian, add its id to `plugins.json`, then run
  `push-vault.ps1`.
- is not enabled in Obsidian. Enable it in Settings > Community plugins.
