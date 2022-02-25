$userfolder = get-childitem c:\users
$usine = read-host "which plant you want to update [SB;SF;DB;NP]"



if ($usine -eq "SB"){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionSB.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
            }
        }
    }
elseif ($usine -eq "SF"){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionSF.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
elseif ($usine -eq "DB"){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionDB.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
elseif ($usine -eq "NP"){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionNP.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
write-output "all folder in $userfolder has been updated"