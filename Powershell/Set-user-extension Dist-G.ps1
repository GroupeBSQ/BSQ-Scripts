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


$postecont = read-host("Est-ce que le titre du poste est Contrmaitre? (O/N)")
$postedir = read-host("Est-ce que le titre du poste est Directeur? (O/N)")
$postece = read-host("est-ce que le titre du poste est Chef d'equipe? (O/N)")
$poste = $NULL

$postecontbool = ConvertTo-Boolean -Variable $postecont
$postedirbool = ConvertTo-Boolean -Variable $postedir
$postecebool = ConvertTo-Boolean -Variable $postece
if ($postecontbool) {$poste = "Contremaitres"}
    elseif ($postecebool) {$poste = "Chef-equipe"}
        elseif ($postedirbool) {$poste = "Directeur"}
    


$username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute3 = $poste}}
    
