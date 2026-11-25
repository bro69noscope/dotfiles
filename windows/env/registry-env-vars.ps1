# Env vars stored in the registry.
# Apply them with: Set-RegistryEnvVars
# List the current ones with: Get-ItemProperty -Path "HKCU:\Environment"
@{
  NVIM_CONFIG_PATH   = "$env:DOTFILES_PATH\nvim-config3.0"
  BRO_NLLS_REPO_PATH = "$env:MYFILES_PATH\git-repos\next-level-live-streaming"
}
