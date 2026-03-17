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

# SIG # Begin signature block
# MIIKIAYJKoZIhvcNAQcCoIIKETCCCg0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiJcMar3iJ4SmS
# d+Ph9Pcb9ICI+sLT91TSN6tnMqPiIaCCBjAwggYsMIIEFKADAgECAhRQQGmZSiWu
# R1hlnUKfCD4py4JQhzANBgkqhkiG9w0BAQsFADB7MS0wKwYDVQQKEyRVc2luZSBE
# ZSBDb25nZWxhdGlvbiBEZSBTdC1icnVubyBJbmMxLTArBgNVBAsTJDY4YTU2NzBm
# LWRjNzQtNDc0Ni05MWQ3LTNjMWY3MDhkZTBkNzEbMBkGA1UEAxMSU0NFUG1hbi1S
# b290LUNBLVYxMB4XDTI2MDMxNjE1MTMwOVoXDTI4MDMxNjE1MTMwOVowLDEqMCgG
# A1UEAwwhV2lsZC1ibHVlYmVycmllc19jb2RlLWNlcnRpZmljYXRlMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxQ8im9mCZGg4dlDgVnVZP4pAdDwPp5aO
# I3ZQyqSQfZJUiKqquh2ZB8B0iQrM1JkHnn3fchhZyQRBcmKAaM6B1MTmj9whlWZi
# Yl2QDkQ+/faOWT0Qyztkvx0M4oWCFDTXQhN6bRA7fAl3E4iys7BRErZ5gL3yaz9N
# bENGqvIpEcJAdiweRNLvNnZ5o0k49L0RFCzDsWyvKLhFg3ZAA7332Al2nTO4CGfm
# tU5K1fzxfYZzLh5T78THQd/M1YRrrw2EXIa2t51k2VFrKTGlXlWO1tgrV6dlx7ah
# +p0qlvJoRqANInUL8WFNRmMV9uwsDkfI30QFmknd2/tm7JhIsYRsLDyX3XLUjEOq
# rVtKOXlWQDjnuUaT+E6gnb3ma611xYFzuIFItxlUPlPYRdXfVqzj2X5rVp0bGqXP
# 6vPTrMvQTmnQzjRhOJgrzCnHVsGI8MTV5qpa06y2fOzmjZ626TUbNDJLICvfExV5
# qiUmtnVdz5tFM6VjVGEH4CYY49SYu44wvgmvp8h3/W7Qybg6QW59fgUbdloTDflo
# +oG0dwN4ZT4mfi8e0WWMfShUJtIAZH7+IOo7rNW17EthUX2ZV71naV42GNWWcYyd
# CByotUVVivr+HY2ulj2eZmrPO+iP1K10HfJ8Ci2Ha+6QkogWYe2bNESTncBtr/h8
# zZs9ujpuORUCAwEAAaOB9jCB8zAfBgNVHSMEGDAWgBQKRBuNvc62o2FXR2t36nBh
# 9GCFNzAdBgNVHQ4EFgQU18cJv19t8AMhtUxwRy1WZsxVPHEwDAYDVR0TAQH/BAIw
# ADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwMwWwYIKwYB
# BQUHAQEETzBNMCQGCCsGAQUFBzAChhhodHRwczovL3NjZXAuYnNxLmxpbmsvY2Ew
# JQYIKwYBBQUHMAGGGWh0dHA6Ly9zY2VwLmJzcS5saW5rL29jc3AwHgYIKoZIhvcU
# BQ4EEgQQD2elaHTcRkeR1zwfcI3g1zANBgkqhkiG9w0BAQsFAAOCAgEAWHcKOA2/
# jakJOWp80OfbH2mLZF7wH2C6xsQ3Pbv6VGWDdy1uBR8GpwsZh/WQfqpL7CVgfd4c
# 37HSt3daECUUcmiR6OardQCtoJ9r/xKM7tZerXnV5jAPFyxBh4up9JBw/VK854fR
# TUxlrxvqFYiQaxnaxVUExanWW5yW842jqM3GNWQFMNGWmkxbDn+vaz8Y3KQdCuOC
# ExbpaEM87iM0m2IyMhXSBPniapk+W4fMIHXYo0pMXtOgzqgCIHSGo60RiT2WVniQ
# AOlDDJJzUzhIWj0scNsMuMaXERmJy56faorE5Pvif92l/+4QbO/iaboer45zBRo1
# CfvyNaPO9mHYkYSm0fY1HWYxeHOaoiL7Z1Ys0wZSyauoR+EGtdDTOJyKU8thaqrg
# Mu//XU1hwZSB8IFCWFk/RRSe2qO5Fxez19u+WBTweHXQ10hSFUdxQAr2Pk+FDM/p
# Gx86pfuoBUgGMJ3b1XE0KN/MExS60uUyXy1JJT07lHNf0E/BaKS3uPzwTtTqat8C
# OT0HN+jvlf+/CVRuzFaPpjWccTLHFK+xtENcEdnmnRBGW+v+xM0vmgQ03VnHKquc
# ebrtkIIBfAunpKmJJDJ6FJHCuz6SwC2yxJlVJrSNM9v+rfjBHUIAqLZCjzS0gQVH
# 0T6ygKVyp615C7NMdVn7NCS66hnzPY+jDBQxggNGMIIDQgIBATCBkzB7MS0wKwYD
# VQQKEyRVc2luZSBEZSBDb25nZWxhdGlvbiBEZSBTdC1icnVubyBJbmMxLTArBgNV
# BAsTJDY4YTU2NzBmLWRjNzQtNDc0Ni05MWQ3LTNjMWY3MDhkZTBkNzEbMBkGA1UE
# AxMSU0NFUG1hbi1Sb290LUNBLVYxAhRQQGmZSiWuR1hlnUKfCD4py4JQhzANBglg
# hkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCDDy8zof027VZTDPVUmgRzH+L7YoFx4/YntwBUMjwrG
# dzANBgkqhkiG9w0BAQEFAASCAgAicvFJiqbdYn+MhU1w9kfw7opS81Ccth1kF8T9
# KA5hGy6SkAMvTFOS5WAfiNo9md9F56vaTkaMzImrsCynM2M4RYUxr8ubPHT9qkmc
# HY2OayNEOsYpsafmtts13Hoz0VV6mYZMLX6UeHJi89Nh3eFscalzG+yjaXrR6+LA
# PPYZ5D1gRd2iS5DlFclOZtGufQSyRKIBgyiD+0qaln47ltHOP7ON6PeQXGC3kas2
# NzJQ0xrG/Ea4mhY+yLNCMeYTsDoo9SNFguu/EWvqt8LQmgTlgqwzKnSPK2y4TxU5
# DGSfZfPcJkJmCG6AVgExtjW+FfANE3UJvlylfnVVQr2F9ZmVBs7mklD2sF2/7Eoe
# ucKXyiqErSS4DddogvoET9RWsE1o3QyECTt8CytFYoMYQ99nDAHL5bEg2plmRIek
# 5cNi1fTCQXB3WgC5QM4EJoeTtZcENt7zXoZdnMY7FCjJVBFljunDWnWFS/TrlbYP
# hgtJ81pMWDtKi9fpjKsWCx33VULTqLTtbySts1GFbpTZIx+2gOVJyLBVyrpWjQ+9
# gkR2CPqhdYfrnYhSWIEvDoimnI74V85t1aQmr9axFwRZttjJRjEtRSJ23ofcHKkA
# 8Hb3aTqJ2F2sDAC6iH0ydLqCGz1sQ9DEYkLVhTn+15iftp3HHEYC2/H1LrC0NXql
# MvustQ==
# SIG # End signature block
