# ============================================================
# hidefromGAL.ps1 - Mode automatique
# Cache les boites courriel de la GAL pour les comptes:
#   - desactives (Enabled -eq $false)
#   - OU dont le Surname est vide
# Decache les comptes actifs avec un Surname valide
# Exception: les comptes dans $exclusions ne sont jamais caches
# ============================================================

$exclusions = @(
    "laboratoire",
    "contremaitressf",
    "contremaitrenp",
    "refrigerationnp",
    "administrationnp",
    "contremaitresdb",
    "mecaniciennp",
    "laboratoirenp",
    "laboratoiresf",
    "maintenanceetmmf",
    "support"
)

$users = Get-ADUser -Filter * -Properties Enabled, Surname, msExchHideFromAddressLists

foreach ($user in $users) {
    $isHidden = $user.msExchHideFromAddressLists -eq $true

    if ($exclusions -contains $user.SamAccountName) {
        if ($isHidden) {
            Set-ADUser -Identity $user -Clear msExchHideFromAddressLists
            Write-Host "Decache de la GAL (exclusion): $($user.SamAccountName)"
        }
        continue
    }

    $shouldHide = (-not $user.Enabled) -or [string]::IsNullOrWhiteSpace($user.Surname)

    if ($shouldHide) {
        if (-not $isHidden) {
            Set-ADUser -Identity $user -Add @{msExchHideFromAddressLists = $true}
            Write-Host "Cache de la GAL: $($user.SamAccountName)"
        }
    }
    else {
        if ($isHidden) {
            Set-ADUser -Identity $user -Clear msExchHideFromAddressLists
            Write-Host "Decache de la GAL: $($user.SamAccountName)"
        }
    }
}
