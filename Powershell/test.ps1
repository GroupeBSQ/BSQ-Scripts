
$console_install = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | foreach-object { Get-ItemProperty $_.PsPath } | Select-object DisplayName,InstallLocation | Sort-Object Displayname -Descending | where-object displayname -match console_bsq

$installedfolder = $console_install.InstallLocation

write-output $installedfolder

