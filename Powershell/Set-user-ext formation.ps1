# Function ConvertTo-Boolean {
#     param($Variable)
#     If ($Variable -eq "Y" -or $Variable -eq "o"-or $Variable -eq "yes"-or $Variable -eq "oui") {
#         $True
#     }
#     If ($Variable -eq "N" -or $Variable -eq "no" -or $Variable -eq "non") {
#         $False
#     }
# }
# $username = read-host("Quel utilisateurs devons nous faire la modification? séparer par virgule pour plusieurs")
# $username = $username.split(',')


# $server = read-host("Est-ce que l'utilisateur doit avoir acces a ACOMBA (O/N)")

# $serverbool = ConvertTo-Boolean -Variable $server
# if ($serverbool) {$server = "Acomba"}
#     else {$server = "Production"}

    
# $session = read-host("Est-ce que l'utilisateur doit obtenir un bureau a distance (O/N)")

# $sessionbool = ConvertTo-Boolean -Variable $session
# if ($sessionbool) {$session = "Desktop"}
#     else {$session = "App"}

# $users = Get-ADUser -filter * | Where-Object {$_.surname -ne $null -AND $_.surname -ne '' -AND $_.Enabled -eq 'true'}

# $users | ForEach-Object {Get-AdUser -Identity $_ | Set-ADuser -Replace @{extensionAttribute5 = "true" }}

$users = Get-ADUser -Filter * -Properties Enabled, Surname, extensionAttribute5

foreach ($user in $users) {
    $shouldHaveAttribute = $user.Enabled -and -not [string]::IsNullOrWhiteSpace($user.Surname)

    if ($shouldHaveAttribute) {
        if ($user.extensionAttribute5 -ne "true") {
            Set-ADUser -Identity $user -Replace @{extensionAttribute5 = "true"}
            Write-Host "Set extensionAttribute5 for $($user.SamAccountName)"
        }
    }
    else {
        if (-not [string]::IsNullOrEmpty($user.extensionAttribute5)) {
            Set-ADUser -Identity $user -Clear extensionAttribute5
            Write-Host "Cleared extensionAttribute5 for $($user.SamAccountName)"
        }
    }
}














