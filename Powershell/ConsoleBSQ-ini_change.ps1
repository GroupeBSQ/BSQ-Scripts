
if (Test-Path -path "$userappdata\appdata\roaming\Logi-Trace") {
       copy-item -path "\\wild-blueberries.com\SYSVOL\wild-blueberries.com\scripts\Azure-ini\Connexion.ini" -Destination "$userappdata\appdata\Roaming\Logi-Trace" -Force
        }