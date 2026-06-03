# ============================================================
# hidefromGAL.ps1 - Mode automatique
# Cache les boites courriel de la GAL pour les comptes:
#   - desactives (Enabled -eq $false)
#   - OU dont le Surname est vide
# Decache les comptes actifs avec un Surname valide
# ============================================================

$users = Get-ADUser -Filter * -Properties Enabled, Surname, msExchHideFromAddressLists

foreach ($user in $users) {
    $shouldHide = (-not $user.Enabled) -or [string]::IsNullOrWhiteSpace($user.Surname)

    if ($shouldHide) {
        if ($user.msExchHideFromAddressLists -ne $true) {
            Set-ADUser -Identity $user -Add @{msExchHideFromAddressLists = $true}
            Write-Host "Cache de la GAL: $($user.SamAccountName)"
        }
    }
    else {
        if ($user.msExchHideFromAddressLists -eq $true) {
            Set-ADUser -Identity $user -Clear msExchHideFromAddressLists
            Write-Host "Decache de la GAL: $($user.SamAccountName)"
        }
    }
}
