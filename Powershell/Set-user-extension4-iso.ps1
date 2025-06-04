# Function ConvertTo-Boolean {
#     param($Variable)
#     If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
#         $True
#     }
#     If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
#         $False
#     }
# }
# while($username = read-host("Quel utilisateurs devons nous faire la modification?")) {

# if ($username -eq "" -or $username -eq $null){break}



# $code = read-host("Quel est le code usager Isovision")


#  $code = $code.ToUpper()   


# $username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute4 = $code}}
# }


# ...existing code...
$sites = @("SB", "SF", "DB", "NP")


while($username = read-host("Quel utilisateurs devons nous faire la modification?")) {

    if ($username -eq "" -or $username -eq $null){break}

    # Ask if it's for administration
    $isAdmin = Read-Host "Est-ce un poste administratif? (Y/N)"
    $isAdmin = $isAdmin.Trim().ToUpper()
    $adminFlag = $false
    if ($isAdmin -eq "Y" -or $isAdmin -eq "O" -or $isAdmin -eq "YES" -or $isAdmin -eq "OUI") {
        $adminFlag = $true
    }

    if (-not $adminFlag) {
        # Ask for site selection only if not administration
        Write-Host "Sélectionnez le site de l'employé:"
        for ($i = 0; $i -lt $sites.Count; $i++) {
            Write-Host "$($i+1): $($sites[$i])"
        }
        $siteIndex = Read-Host "Entrez le numéro du site"
        if ($siteIndex -match '^\d+$' -and $siteIndex -ge 1 -and $siteIndex -le $sites.Count) {
            $selectedSite = $sites[$siteIndex - 1]
        } else {
            Write-Host "Sélection invalide. Script arrêté."
            break
        }
    }

    $code = read-host("Quel est le numéro d'employé de l'usager")
    #$code = $code.ToUpper()

    if ($adminFlag) {
        # If it's for administration, prefix with "AD-"
        $code = "AD-$code"
    } else {
        # If it's not for administration, prefix with the selected site
        $code = "$selectedSite-$code"
    }

    $username | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute4 = $code}}    }

# ...existing code...