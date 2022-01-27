#"bsq.link","qwb.email","bsq-qwb.com","senco.cloud","senco.farm","fruitsbleues.com","fruitsbleues.ca","bleuet.cloud"
$Domains = "congelation.ca","usinecongelation.ca","usinecongelation.com"
Get-ADuser -Filter * -properties mail | foreach-object {
    $Proxies += foreach ($Domain in $Domains)
    {
        "smtp:$($_.samaccountname)@$Domain"
    }
    
    
    $_ | Set-ADuser -add @{ProxyAddresses = $Proxies}
}