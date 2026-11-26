# Obsidian config

Shared Obsidian config, with the same layout as `<vault>/.obsidian/`:

- `hotkeys.json`
- `plugins/<plugin-id>/`: code (`main.js`, `manifest.json`, `styles.css`) and settings
  (`data.json`).

Scripts in `../setup-vault/`:

- `fetch-vault.ps1`: gets this config into the vault.
- `push-vault.ps1`: mirrors the vault config back into this folder.

Vault-specific plugin files (for example `yazi-explorer/local.json`) are not copied here.
