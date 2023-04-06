# Function ConvertTo-Boolean {
#     param($Variable)
#     If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
#         $True
#     }
#     If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
#         $False
#     }
# }
while($username = read-host("Quel utilisateurs devons nous faire la modification?")) {

if ($username -eq "" -or $username -eq $null){break}



$code = read-host("Quel est le code usager Isovision")


 $code = $code.ToUpper()   


$username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute4 = $code}}
}
