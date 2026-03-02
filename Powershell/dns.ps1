# C:\Zabbix\scripts\dns_discovery.ps1
# Sortie: JSON array [{ "{#IFACE}": "...", "{#DNS}": "ip,ip" }, ...]
# Compatible Windows Server 2012R2+ (PowerShell 4+), IPv4/IPv6
$ErrorActionPreference = "Stop"

try {
    $adapters = Get-DnsClientServerAddress -AddressFamily IPv4,IPv6 |
        Where-Object { $_.InterfaceAlias } |
        Sort-Object InterfaceAlias

    $result = foreach ($a in $adapters) {
        $dns = $a.ServerAddresses -join ','
        [pscustomobject]@{
            '{#IFACE}' = $a.InterfaceAlias
            '{#DNS}'   = $dns
        }
    }

    # En cas d’absence complète, renvoyer un tableau vide (valide LLD)
    if (-not $result) { $result = @() }

    $result | ConvertTo-Json -Compress
}
catch {
    # En cas d’erreur, renvoyer tableau vide pour ne pas casser la LLD
    '[]'
}