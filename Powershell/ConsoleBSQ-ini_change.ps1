install-module -name psini -SkipPublisherCheck -Force -AcceptLicense

###  here the script start

$console_install = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | foreach-object { Get-ItemProperty $_.PsPath } | Select-object DisplayName,InstallLocation | Sort-Object Displayname -Descending | where-object displayname -match console_bsq

$installedfolder = $console_install.InstallLocation

foreach ($folder in $installedfolder) {
    set-inicontent -filepath "$folder\Connexion.ini" -Sections "Serveur" -NameValuePairs "IP=172.30.2.6,Service=172.30.2.6" | out-inifile "$folder\Connexion.ini"
}