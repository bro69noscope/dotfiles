function Initialize-Zoxide {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
  Invoke-Expression (& {
      (zoxide init --cmd cd --hook pwd powershell) -join "`n"
    })
}
