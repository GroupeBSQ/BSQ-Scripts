##### Information got from https://docs.microsoft.com/en-us/azure/virtual-desktop/language-packs ###########
########################################################
## Add Languages to running Windows Image for Capture##
########################################################

##Disable Language Pack Cleanup##
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"

##Set Language Pack Content Stores##
[string]$LIPContent = "z:"

##French Canada##
Add-AppProvisionedPackage -Online -PackagePath $LIPContent\fr-ca\LanguageExperiencePack.fr-ca.Neutral.appx -LicensePath $LIPContent\fr-ca\License.xml
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Client-Language-Pack_x64_fr-ca.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Basic-fr-ca-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Handwriting-fr-ca-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-OCR-fr-ca-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Speech-fr-ca-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-TextToSpeech-fr-ca-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-MSPaint-FoD-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Notepad-FoD-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Printing-WFS-FoD-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~fr-ca~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-WordPad-FoD-Package~31bf3856ad364e35~amd64~fr-ca~.cab
$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("fr-ca")
Set-WinUserLanguageList $LanguageList -force



#########################################
## Update Inbox Apps for Multi Language##
#########################################
##Set Inbox App Package Content Stores##
[string] $AppsContent = "F:\"

##Update installed Inbox Store Apps##
foreach ($App in (Get-AppxProvisionedPackage -Online)) {
	$AppPath = $AppsContent + $App.DisplayName + '_' + $App.PublisherId
	Write-Host "Handling $AppPath"
	$licFile = Get-Item $AppPath*.xml
	if ($licFile.Count) {
		$lic = $true
		$licFilePath = $licFile.FullName
	} else {
		$lic = $false
	}
	$appxFile = Get-Item $AppPath*.appx*
	if ($appxFile.Count) {
		$appxFilePath = $appxFile.FullName
		if ($lic) {
			Add-AppxProvisionedPackage -Online -PackagePath $appxFilePath -LicensePath $licFilePath 
		} else {
			Add-AppxProvisionedPackage -Online -PackagePath $appxFilePath -skiplicense
		}
	}
}



########################################
############### Windows 11 #############
########################################
########################################################
## Add Languages to running Windows Image for Capture##
########################################################
##Disable Language Pack Cleanup##
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MUI\" -TaskName "LPRemove"
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller" -TaskName "Uninstallation"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d 1 /f

##Set Language Pack Content Stores##
$LIPContent = "z:"

##Set Path of CSV File##
$CSVFile = "Windows-10-1809-FOD-to-LP-Mapping-Table.csv"
$filePath = (Get-Location).Path + "\$CSVFile"

##Import Necesarry CSV File##
$FODList = Import-Csv -Path $filePath -Delimiter ";"

##Set Language (Target)##
$targetLanguage = "fr-ca"

$sourceLanguage = (($FODList | Where-Object {$_.'Target Lang' -eq $targetLanguage}) | Where-Object {$_.'Source Lang' -ne $targetLanguage} | Select-Object -Property 'Source Lang' -Unique).'Source Lang'
if(!($sourceLanguage)){
    $sourceLanguage = $targetLanguage
}

$langGroup = (($FODList | Where-Object {$_.'Target Lang' -eq $targetLanguage}) | Where-Object {$_.'Lang Group:' -ne ""} | Select-Object -Property 'Lang Group:' -Unique).'Lang Group:'

##List of additional features to be installed##
$additionalFODList = @(
    "$LIPContent\Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab", 
    "$LIPContent\Microsoft-Windows-MSPaint-FoD-Package~31bf3856ad364e35~amd64~$sourceLanguage~.cab",
    "$LIPContent\Microsoft-Windows-SnippingTool-FoD-Package~31bf3856ad364e35~amd64~$sourceLanguage~.cab"
    #"$LIPContent\Microsoft-Windows-Lip-Language_x64_$sourceLanguage.cab" ##only if applicable##
)

$additionalCapabilityList = @(
 "Language.Basic~~~$sourceLanguage~0.0.1.0",
 "Language.Handwriting~~~$sourceLanguage~0.0.1.0",
 "Language.OCR~~~$sourceLanguage~0.0.1.0",
 "Language.Speech~~~$sourceLanguage~0.0.1.0",
 "Language.TextToSpeech~~~$sourceLanguage~0.0.1.0"
 )

 ##Install all FODs or fonts from the CSV file###
 Dism /Online /Add-Package /PackagePath:$LIPContent\Microsoft-Windows-Client-Language-Pack_x64_$sourceLanguage.cab
 #Dism /Online /Add-Package /PackagePath:$LIPContent\Microsoft-Windows-Lip-Language-Pack_x64_$sourceLanguage.cab
 foreach($capability in $additionalCapabilityList){
    Dism /Online /Add-Capability /CapabilityName:$capability /Source:$LIPContent
 }

 foreach($feature in $additionalFODList){
 Dism /Online /Add-Package /PackagePath:$feature
 }

 if($langGroup){
 Dism /Online /Add-Capability /CapabilityName:Language.Fonts.$langGroup~~~und-$langGroup~0.0.1.0 
 }

 ##Add installed language to language list##
 $LanguageList = Get-WinUserLanguageList
 $LanguageList.Add("$targetlanguage")
 Set-WinUserLanguageList $LanguageList -force
##Cleanup to prepare sysprep##
Remove-AppxPackage -Package Microsoft.LanguageExperiencePackes-FR_22000.8.13.0_neutral__8wekyb3d8bbwe

Remove-AppxPackage -Package Microsoft.OneDriveSync_22000.8.13.0_neutral__8wekyb3d8bbwe