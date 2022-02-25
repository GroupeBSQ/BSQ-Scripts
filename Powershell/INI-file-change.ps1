$userfolder = get-childitem c:\users
$usine = 


if ($env:usine == SB){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionSB.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
            }
        }
    }
elseif ($env:usine == SF){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionSF.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
elseif ($env:usine == DB){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionDB.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
elseif ($env:usine == NP){
    foreach ($userappdata in $userfolder) {
        write-output "working on $userappdata"
        if (Test-Path -path "c:\users\$userappdata\appdata\roaming\Logi-Trace") {
            copy-item -path ".\ConnexionNP.ini" -Destination "c:\users\$userappdata\appdata\Roaming\Logi-Trace\Connexion.ini" -Force
            write-output "the $userappdata folder has been updated"
        }
    }
}
write-output "all folder in $userfolder has been updated"