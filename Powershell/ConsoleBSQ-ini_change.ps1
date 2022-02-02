$sfolder = "c:\Logiciels_BSQ\Console_BSQ"
$notsfolder = "c:\Logiciel_BSQ\Console_BSQ"

if (Test-Path -path $sfolder) {
       copy-item -path ".\Connexion.ini" -Destination $sfolder -Force
       Write-Output "the file has been changed in $notsfolder"
        }
 elseif (Test-Path -path $notsfolder) {
       copy-item -path ".\Connexion.ini" -Destination $notsfolder -Force  
       Write-Output "the file has been changed in $notsfolder"
        }
 else {
       write-output "the folder was not found on this computer"
        }