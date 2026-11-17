param([Parameter(Mandatory)][string]$Name)
$wav = "C:\Windows\Media\$Name"
(New-Object Media.SoundPlayer $wav).PlaySync()
