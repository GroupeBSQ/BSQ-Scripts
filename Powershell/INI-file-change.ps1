$userfolder = get-childitem c:\users

foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\Connexion.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\" -Force
            write-output "the $userappdata folder has been updated"
        }
    }

write-output "all folder in $userfolder has been updated"