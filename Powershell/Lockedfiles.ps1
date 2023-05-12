$lockedFile="C:\IT\GIT\BSQ-Scripts\Powershell\Lockedfiles.ps1"

Get-Process | foreach{$processVar = $_;$_.Modules | foreach{if($_.FileName -eq $lockedFile){$processVar.Name + " PID:" + $processVar.id}}}