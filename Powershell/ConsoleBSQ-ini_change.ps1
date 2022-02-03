If (-not(Get-InstalledModule psini -ErrorAction silentlycontinue)) {
    Write-Host "Module does not exist"
    install-module -name psini -SkipPublisherCheck -Force -AcceptLicense -Verbose
  }
  Else {
    Write-Host "Module exists"
    import-module psini 
  }


###  here the script start

$config = convertfrom-stringdata -stringdata @'
IP=172.30.2.6
Service=172.30.2.6
'@
$ip = "IP=172.30.2.6"
$service = "Service=172.30.2.6"
$string = $ip +","+ $service

$console_install = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | foreach-object { Get-ItemProperty $_.PsPath } | Select-object DisplayName,InstallLocation | Sort-Object Displayname -Descending | where-object displayname -match console_bsq

$installedfolder = $console_install.InstallLocation

foreach ($folder in $installedfolder) {
    $ini = get-inicontent -filepath $folder"Connexion.ini" 
    write-output $ini["Serveur"]["IP","Service"]
    $iniset = set-inicontent $ini -Debug -Sections "Serveur" -NameValuePairs $string 
    #$ini | set-inicontent -Sections "Serveur" -NameValuePairs "Service=172.30.2.6"  
    write-output $ini["Serveur"]["IP","Service"]
    Out-IniFile -InputObject $iniset -FilePath $folder"Connexion.ini" -Force
}