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


$server = read-host("Est-ce que l'utilisateur doit avoir acces a ACOMBA (O/N)")

$serverbool = ConvertTo-Boolean -Variable $server
if ($serverbool) {$server = "Acomba"}
    else {$server = "Production"}

    
$session = read-host("Est-ce que l'utilisateur doit obtenir un bureau a distance (O/N)")

$sessionbool = ConvertTo-Boolean -Variable $session
if ($sessionbool) {$session = "Desktop"}
    else {$session = "App"}

$username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute1 = $session; extensionAttribute2 = $server }}
    
