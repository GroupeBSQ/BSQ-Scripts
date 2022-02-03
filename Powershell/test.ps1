
$console_install = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | % { Get-ItemProperty $_.PsPath } | Select DisplayName,InstallLocation | Sort-Object Displayname -Descending | where displayname -match console_bsq

$installedfolder = $console_install.InstallLocation

write-output $installedfolder

