param([string]$Path)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$img = [Drawing.Image]::FromFile($Path)
[Windows.Forms.Clipboard]::SetImage($img)
$img.Dispose()
