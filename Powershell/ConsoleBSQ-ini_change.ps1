
if (Test-Path -path "c:\Logiciels_BSQ\Console_BSQ") {
       copy-item -path ".\Connexion.ini" -Destination "c:\Logiciels_BSQ\Console_BSQ" -Force
        }