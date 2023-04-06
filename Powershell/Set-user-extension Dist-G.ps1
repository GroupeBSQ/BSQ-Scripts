# Function ConvertTo-Boolean {
#     param($Variable)
#     If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
#         $True
#     }
#     If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
#         $False
#     }
# }
$username = read-host("Quel utilisateurs devons nous faire la modification? séparer par virgule pour plusieurs")
$username = $username.split(',')


$poste = read-host("Est-ce que le titre du poste est Contrmaitre(C) Directeur(D) ou Chef d'equipe(CE)")
#$postedir = read-host("Est-ce que le titre du poste est Directeur? (O/N)")
#$postece = read-host("est-ce que le titre du poste est Chef d'equipe? (O/N)")
#$poste = $NULL

$poste = $poste.ToUpper()

if ($poste -eq "C") {$poste = "Contremaitres"}
    elseif ($poste -eq "CE") {$poste = "Chef-equipe"}
        elseif ($poste -eq "D") {$poste = "Directeurs"}
    


$username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute3 = $poste}}
    
