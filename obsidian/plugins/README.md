# Obsidian plugins

Shared Obsidian plugins: code (`main.js`, `manifest.json`, `styles.css`) and settings
(`data.json`). Each folder is `<plugin-id>/`, the same as in `<vault>/.obsidian/plugins/`.

Each vault has two scripts in its `scripts/` folder:

- `fetch-plugins.ps1`: gets plugins from this folder into the vault
- `push-plugins.ps1`: mirrors the listed vault plugin folders back into this folder.

Vault-specific plugin files (for example `yazi-explorer/local.json`) are not copied here.
