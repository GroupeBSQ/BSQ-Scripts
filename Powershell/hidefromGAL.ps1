#fonction pour convertir les inputs en boolean
Function ConvertTo-Boolean {
    param($Variable)
    If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
        $True
    }
    If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
        $False
    }
}
# question pour savoir quel utilisateur nous devons verifier

while($user_name= read-host -Prompt "entré le nom d'usager") {

    if ($user_name -eq "" -or $user_name -eq $null){break}

#parametre pour sortir un peut d'information du get-aduser
$params = @{
    "identity" = $user_name
    
    "Properties" = "samAccountName",
    "CN",
    "LastLogonDate",
    "msExchHideFromAddressLists",
    "msExchWhenMailboxCreated",
    "whenChanged",
    "whenCreated"
    
    }



get-aduser @params

# question  pour savoir si nous effectuons le changmenet du paramtre "msExchHideFromAddressLists"

$add =  read-host -Prompt "est-ce que nous cachons l'adresse de la liste global? (Y/N)"

$add = ConvertTo-Boolean -Variable $add

if (-not $add) {
$remove =  read-host -prompt "est-ce que nous voulons décaché cette utilisateur de la liste global exchange? (Y/N)"
$remove= ConvertTo-Boolean -Variable $remove
}






#converti l'input en boolean
#$change = ConvertTo-Boolean -Variable $change

#si nous avons dit oui fait le changmeent du paramtre dans le profil utilisateur
if ($add) {
    set-aduser -Identity $user_name -add @{msExchHideFromAddressLists = $true}
    get-aduser @params
} elseif ($remove) {
    set-aduser -Identity $user_name -clear "msExchHideFromAddressLists"
    get-aduser @params
}
    ## "SearchBase"="ou=bleuet,dc=contoso,dc=com"
    ##"SearchScope" = "Subtree"
    ##"filter" = {enabled -eq $true}
}