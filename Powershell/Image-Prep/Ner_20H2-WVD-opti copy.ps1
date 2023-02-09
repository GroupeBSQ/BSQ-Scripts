#description: Installs Microsoft Virtual Desktop Optimizations for Windows 10 20H2 (clone and edit to customize)
#execution mode: IndividualWithRestart
#tags: Nerdio
<#
Notes:
This script uses the Virtual Desktop Optimization tool, found here: 
https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
to remove default apps, disable tasks and services, and alter registry values in order to optimizze
windows for VDI. This script is written in a way to allow alteration to deviate from the default settings
specified in the original optimization tool.

To use this script:
Customize the values below as desired.
- Ensure this script is run for version 2009 / 20H2 
#>

# ================ Customize the Appx To remove here. If an Appx is desired, delete the line to keep it installed.
$AppxPackages = @"
Microsoft.BingWeather,"https://www.microsoft.com/en-us/p/msn-weather/9wzdncrfj3q2"
Microsoft.Getstarted,"https://www.microsoft.com/en-us/p/microsoft-tips/9wzdncrdtbjj"
Microsoft.Messaging,"https://www.microsoft.com/en-us/p/microsoft-messaging/9wzdncrfjbq6"
Microsoft.MicrosoftOfficeHub,"https://www.microsoft.com/en-us/p/office/9wzdncrd29v9"
Microsoft.MicrosoftSolitaireCollection,"https://www.microsoft.com/en-us/p/microsoft-solitaire-collection/9wzdncrfhwd2"
Microsoft.MicrosoftStickyNotes,"https://www.microsoft.com/en-us/p/microsoft-sticky-notes/9nblggh4qghw"
Microsoft.MixedReality.Portal,"https://www.microsoft.com/en-us/p/mixed-reality-portal/9ng1h8b3zc7m"
Microsoft.Office.OneNote,"https://www.microsoft.com/en-us/p/onenote/9wzdncrfhvjl"
Microsoft.People,"https://www.microsoft.com/en-us/p/microsoft-people/9nblggh10pg8"
Microsoft.Print3D,"https://www.microsoft.com/en-us/p/print-3d/9pbpch085s3s"
Microsoft.SkypeApp,"https://www.microsoft.com/en-us/p/skype/9wzdncrfj364"
Microsoft.Wallet,"https://www.microsoft.com/en-us/payments"
Microsoft.Microsoft3DViewer,"https://www.microsoft.com/en-us/p/3d-viewer/9nblggh42ths"
Microsoft.WindowsCamera,"https://www.microsoft.com/en-us/p/windows-camera/9wzdncrfjbbg"
microsoft.windowscommunicationsapps,"https://www.microsoft.com/en-us/p/mail-and-calendar/9wzdncrfhvqm"
Microsoft.WindowsFeedbackHub,"https://www.microsoft.com/en-us/p/feedback-hub/9nblggh4r32n"
Microsoft.WindowsMaps,"https://www.microsoft.com/en-us/p/windows-maps/9wzdncrdtbvb"
Microsoft.WindowsSoundRecorder,"https://www.microsoft.com/en-us/p/windows-voice-recorder/9wzdncrfhwkn"
Microsoft.Xbox.TCUI,"https://docs.microsoft.com/en-us/gaming/xbox-live/features/general/tcui/live-tcui-overview"
Microsoft.XboxApp,"https://www.microsoft.com/store/apps/9wzdncrfjbd8"
Microsoft.XboxGameOverlay,"https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p"
Microsoft.XboxGamingOverlay,"https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p"
Microsoft.XboxIdentityProvider,"https://www.microsoft.com/en-us/p/xbox-identity-provider/9wzdncrd1hkw"
Microsoft.XboxSpeechToTextOverlay,"https://support.xbox.com/help/account-profile/accessibility/use-game-chat-transcription"
Microsoft.YourPhone,"https://www.microsoft.com/en-us/p/Your-phone/9nmpj99vjbwv"
Microsoft.ZuneMusic, "https://www.microsoft.com/en-us/p/groove-music/9wzdncrfj3pt"
Microsoft.ZuneVideo,"https://www.microsoft.com/en-us/p/movies-tv/9wzdncrfj3p2"
"@




# =========================== Logic Code to use previously specified values.
# Enable Logging
$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$VMTime = Get-Date
$LogTime = $VMTime.ToUniversalTime()
mkdir "C:\Windows\temp\NMWLogs\ScriptedActions\win10optimize2009" -Force
Start-Transcript -Path "C:\Windows\temp\NMWLogs\ScriptedActions\win10optimize2009\ps_log.txt" -Append
Write-Host "################# New Script Run #################"
Write-host "Current time (UTC-0): $LogTime"

# variables
$WinVersion = '2009'

# Download repo for WVD optimizations
mkdir C:\wvdtemp\Optimize_sa\optimize -Force

Invoke-WebRequest `
-Uri "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip" `
-OutFile "C:\wvdtemp\Optimize_sa\optimize.zip"

Expand-Archive -Path "C:\wvdtemp\Optimize_sa\optimize.zip" -DestinationPath "C:\wvdtemp\Optimize_sa\optimize\"

# Remove default json files 
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\AppxPackages.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Autologgers.Json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\DefaultUserSettings.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\ScheduledTasks.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Services.json" -Force

# Build JSON and txt Configuration Files - These are built here according to the hash table variables specified above.

# AppXPackages Json
$AppxPackages = ($AppxPackages -split "`n").trim()
$AppxPackages = $AppxPackages | ConvertFrom-Csv -Delimiter ',' -Header "PackageName", "HelpURL"
$AppxPackagesJson = $AppxPackages | ForEach-Object { [PSCustomObject]@{'AppxPackage' = $_.PackageName; 'VDIState' = 'Disabled'; 'Description' = $_.PackageName; 'URL' = $_.HelpURL } } | ConvertTo-Json
$AppxPackagesJson | Out-File C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\AppxPackages.json


# run the Optimize Script with newly created JSON files 
C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion $WinVersion -AcceptEULA

# Clean up Temp Folder
Remove-Item C:\WVDTemp\Optimize_sa\ -Recurse -Force

# End Logging
Stop-Transcript
$VerbosePreference=$SaveVerbosePreference
