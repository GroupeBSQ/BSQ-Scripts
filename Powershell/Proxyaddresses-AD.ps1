$Domains = "bsq.link","qwb.email","bsq-qwb.com","senco.cloud","senco.farm","fruitsbleues.com","fruitsbleues.ca","bleuet.cloud","congelation.ca","usinecongelation.ca","usinecongelation.com","aadds.wild-blueberries.com"
#$Domains += read-host("is there new domain you want to add to this list:$Domains")
$username = read-host("which user are we adding the proxies address? * for all")
if ($username -eq "*"){
    Get-ADuser -Filter * -properties mail | foreach-object {
        $Proxies = @("SMTP:$($_.mail)")
        $Proxies += foreach ($Domain in $Domains)
        {
            "smtp:$($_.samaccountname)@$Domain"
        }
        $Proxies += "sip:$($_.mail)"
    
        $_ | Set-ADuser -Replace @{ProxyAddresses = $Proxies}
    }
}
else {
    Get-ADuser -identity $username -properties mail | foreach-object {
        $Proxies = @("SMTP:$($_.mail)")
        $Proxies += foreach ($Domain in $Domains)
        {
            "smtp:$($_.samaccountname)@$Domain"
        }
        $Proxies += "sip:$($_.mail)"
        
        $_ | Set-ADuser -Replace @{ProxyAddresses = $Proxies}
    }
}