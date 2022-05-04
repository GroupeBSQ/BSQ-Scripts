$software = "Covalence endpoint agent";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null

If(-Not $installed) {
	Write-Host "'$software' is NOT installed.";
} else {
	Write-Host "'$software' is installed."
}