###### outlook config
#rem Mount the default user registry hive
reg load HKU\TempDefault C:\Users\Default\NTUSER.DAT
#rem Must be executed with default registry hive mounted.
reg add HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common /v InsiderSlabBehavior /t REG_DWORD /d 2 /f
#rem Set Outlook's Cached Exchange Mode behavior
#rem Must be executed with default registry hive mounted.
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v enable /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v syncwindowsetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSettingMonths  /t REG_DWORD /d 1 /f
#rem Unmount the default user registry hive
reg unload HKU\TempDefault

#rem Set the Office Update UI behavior.
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f

####OneDrive config
### From https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image ###
"[staged location]\OneDriveSetup.exe" /uninstall
REG ADD "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64
Run "[staged location]\OneDriveSetup.exe" /allusers
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "SilentAccountConfig" /t REG_DWORD /d 1 /f
## added by the GPO
#REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "KFMSilentOptIn" /t REG_SZ /d $Env:ARM_TENANT_ID /f

## added after the fact
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "FilesOnDemandEnabled" /t REG_DWORD /d 1 /f
### Not shure it's really needed as the others before are functionning
###REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RailRunonce" /v "OneDrive" /t REG_SZ /d "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background"
###REG ADD "HKCU\Software\Microsoft\OneDrive" /v "EnableADAL" /t REG_DWORD /d 2 /f

### END with the sysprep command

C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown

icacls W: /grant GR_Usines:(M)
icacls W: /grant "Creator Owner":(OI)(CI)(IO)(M)
icacls W: /remove "Authenticated Users"
icacls W: /remove "Builtin\Users"