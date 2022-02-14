$Domains = "bsq.link","qwb.email","bsq-qwb.com","senco.cloud","senco.farm","fruitsbleues.com","fruitsbleues.ca","bleuet.cloud"
Get-ADuser -Filter * -properties mail | foreach-object {
    $Proxies = @("SMTP:$($_.mail)")
    $Proxies += foreach ($Domain in $Domains)
    {
        "smtp:$($_.samaccountname)@$Domain"
    }
    $Proxies += "sip:$($_.mail)"
    
    $_ | Set-ADuser -Replace @{ProxyAddresses = $Proxies}
}