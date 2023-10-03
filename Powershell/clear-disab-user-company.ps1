# Get a list of disabled users
$disabledUsers = Get-ADUser -Filter {Enabled -eq $false} -Properties Company

foreach ($user in $disabledUsers) {
    # Check if the Company attribute is not already empty
    if ($user.Company -ne $null) {
        # Clear the Company attribute for the user
        Set-ADUser -Identity $user -Clear Company
        Write-Host "Cleared company for $($user.SamAccountName)"
    } else {
        Write-Host "Company for $($user.SamAccountName) is already empty"
    }
}
