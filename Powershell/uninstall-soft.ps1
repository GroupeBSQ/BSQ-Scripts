##### the first method should work but sometime programs don't show up in WMI object


Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -match "RMM"}
write-host $MyApp

$MyApp.uninstall()

###### the second method shoudl show more apps  and then uninstall the app 

Get-Package -Provider Programs -IncludeWindowsInstaller -Name "Datto RMM" | Uninstall-Package