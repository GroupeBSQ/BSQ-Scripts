Add-Type -AssemblyName System.Windows.Forms

$ServiceName = "ViridemConnectService"

function Show-Message {
    param(
        [string]$Text,
        [string]$Title = "Information",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )

    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

try {
    $service = Get-Service -Name $ServiceName -ErrorAction Stop
}
catch {
    Show-Message "Le service '$ServiceName' est introuvable." "Erreur" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

switch ($service.Status) {
    'Running' {
        $action = "arrêter"
        $targetStatus = 'Stopped'
        $confirmMessage = "Le service '$($service.DisplayName)' est actuellement démarré.`n`nVoulez-vous l'arrêter ?"
    }

    'Stopped' {
        $action = "démarrer"
        $targetStatus = 'Running'
        $confirmMessage = "Le service '$($service.DisplayName)' est actuellement arrêté.`n`nVoulez-vous le démarrer ?"
    }

    default {
        Show-Message "Le service '$($service.DisplayName)' est dans un état non géré : $($service.Status)." "Etat non géré" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        exit 2
    }
}

$result = [System.Windows.Forms.MessageBox]::Show(
    $confirmMessage,
    "Confirmation",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
    Show-Message "Opération annulée par l'utilisateur." "Annulation" ([System.Windows.Forms.MessageBoxIcon]::Information)
    exit 0
}

try {
    if ($service.Status -eq 'Running') {
        Stop-Service -Name $ServiceName -ErrorAction Stop
    }
    elseif ($service.Status -eq 'Stopped') {
        Start-Service -Name $ServiceName -ErrorAction Stop
    }

    $timeout = [datetime]::Now.AddSeconds(30)
    do {
        Start-Sleep -Seconds 1
        $service.Refresh()
    } while ($service.Status -ne $targetStatus -and [datetime]::Now -lt $timeout)

    if ($service.Status -eq $targetStatus) {
        if ($targetStatus -eq 'Running') {
            Show-Message "Le service '$($service.DisplayName)' a démarré avec succès." "Succès" ([System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            Show-Message "Le service '$($service.DisplayName)' a été arrêté avec succès." "Succès" ([System.Windows.Forms.MessageBoxIcon]::Information)
        }
        exit 0
    }
    else {
        Show-Message "L'opération a été lancée, mais le service n'a pas atteint l'état attendu dans le délai imparti." "Erreur" ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 3
    }
}
catch {
    Show-Message "Echec lors de la tentative de $action du service '$($service.DisplayName)'.`n`nDétail : $($_.Exception.Message)" "Erreur" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit 4
}
