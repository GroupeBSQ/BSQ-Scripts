Function ConvertTo-Boolean {
    param($Variable)
    If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
        $True
    }
    If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
        $False
    }
}
$username = read-host("Quel utilisateurs devons nous faire la modification? séparer par virgule pour plusieurs")
$username = $username.split(',')


$poste = read-host("Est-ce que le titre du poste est contrmaitre? (O/N)")

$postebool = ConvertTo-Boolean -Variable $poste
if ($postebool) {$poste = "Contremaitres"}
    #else {$poste = "Production"}

    


$username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute3 = $poste}}
    
