Get-Printer | ForEach-Object {
    $printer = $_
    $port = Get-PrinterPort -Name $printer.PortName -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Nom          = $printer.Name
        Driver       = $printer.DriverName
        Port         = $printer.PortName
        AdresseIP    = $port.PrinterHostAddress
        Partagee     = $printer.Shared
        NomPartage   = $printer.ShareName
        Statut       = $printer.PrinterStatus
        Defaut       = $printer.Default
    }
} | Format-Table -AutoSize