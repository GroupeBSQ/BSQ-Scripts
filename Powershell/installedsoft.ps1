<#
.SYNOPSIS
	Get-InstalledSoftware retrieves a list of installed software
.DESCRIPTION
	Get-InstalledSoftware opens up the specified (remote) registry and scours it for installed software. When found it returns a list of the software and it's version.
.PARAMETER ComputerName
	The computer from which you want to get a list of installed software. Defaults to the local host.
.EXAMPLE
	Get-InstalledSoftware DC1
	
	This will return a list of software from DC1. Like:
	Name			Version		Computer  UninstallCommand
	----			-------     --------  ----------------
	7-Zip 			9.20.00.0	DC1       MsiExec.exe /I{23170F69-40C1-2702-0920-000001000000}
	Google Chrome	65.119.95	DC1       MsiExec.exe /X{6B50D4E7-A873-3102-A1F9-CD5B17976208}
	Opera			12.16		DC1		  "C:\Program Files (x86)\Opera\Opera.exe" /uninstall
.EXAMPLE
	Import-Module ActiveDirectory
	Get-ADComputer -filter 'name -like "DC*"' | Get-InstalledSoftware
	
	This will get a list of installed software on every AD computer that matches the AD filter (So all computers with names starting with DC)
.INPUTS
	[string[]]Computername
.OUTPUTS
	PSObject with properties: Name,Version,Computer,UninstallCommand
.NOTES
	Author: Anthony Howell
	
	To add directories, add to the LMkeys (LocalMachine)
.LINK
	[Microsoft.Win32.RegistryHive]
	[Microsoft.Win32.RegistryKey]
#>
Function Get-InstalledSoftware {
    Param(
        [Alias('Computer','ComputerName','HostName')]
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true,
            Position=1
        )]
        [string]$Name = $env:COMPUTERNAME
    )
    Begin{
        $lmKeys = '\Software\Microsoft\Windows\CurrentVersion\Uninstall','\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        $lmReg = 'Registry::HKEY_LOCAL_MACHINE'
        $cuKeys = '\Software\Microsoft\Windows\CurrentVersion\Uninstall'
        $cuReg = 'Registry::HKEY_CURRENT_USER'
    }
    Process{
        if (!(Test-Connection -ComputerName $Name -count 1 -quiet)) {
            Write-Error -Message "Unable to contact $Name. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Computer
            Break
        }
        enter-pssession -ComputerName $Name
        $masterKeys = @()
        $remoteCURegKey = "$cuReg$cuKeys"
        $remoteLMRegKey = "$lmReg$lmKeys"
        foreach ($key in {get-item -Path $remoteLMRegKey}) {
            $regKey = "$remoteLMRegKey\$key"
            foreach ($subName in {get-item -Path $regKey}) {
                foreach($sub in {get-itemproperty -Path "$regKey\$subName"}) {
                    $masterKeys += (New-Object PSObject -Property @{
                        "ComputerName" = $Name
                        "Name" = {Get-ItemPropertyValue -path $sub -filter "displayname"}
                        "SystemComponent" = {Get-ItemPropertyValue -path $sub -filter "systemcomponent"}
                        "ParentKeyName" = {Get-ItemPropertyValue -path $sub -filter "parentkeyname"}
                        "Version" = {Get-ItemPropertyValue -path $sub -filter "DisplayVersion"}
                        "UninstallCommand" = {Get-ItemPropertyValue -path $sub -filter "UninstallString"}
                        "InstallDate" = {Get-ItemPropertyValue -path $sub -filter "InstallDate"}
                        "RegPath" = $sub.ToString()
                    })
                }
            }
        }
        foreach ($key in {get-item -path $remoteCURegKey}) {
            $regKey = "$remoteCURegKey\$key"
            if ($regKey -ne $null) {
                foreach ($subName in {get-item -Path $regKey}) {
                    foreach ($sub in {get-item -path "$regKey\$subName"}) {
                        $masterKeys += (New-Object PSObject -Property @{
                            "ComputerName" = $Name
                            "Name" = {Get-ItemPropertyValue -path $sub -filter "displayname"}
                            "SystemComponent" = {Get-ItemPropertyValue -path $sub -filter "systemcomponent"}
                            "ParentKeyName" = {Get-ItemPropertyValue -path $sub -filter "parentkeyname"}
                            "Version" = {Get-ItemPropertyValue -path $sub -filter "DisplayVersion"}
                            "UninstallCommand" = {Get-ItemPropertyValue -path $sub -filter "UninstallString"}
                            "InstallDate" = {Get-ItemPropertyValue -path $sub -filter "InstallDate"}
                            "RegPath" = $sub.ToString()
                        })
                    }
                }
            }
        }
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
        $props = 'Name','Version','ComputerName','Installdate','UninstallCommand','RegPath'
        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object $props | Sort-Object Name)
        $masterKeys >> c:\it\installedsoft.txt
    }
    End{}
}