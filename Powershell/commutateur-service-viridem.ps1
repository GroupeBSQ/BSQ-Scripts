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
        Show-Message "Le service '$($service.DisplayName)' est dans un état non géré : $($service.Status)." "État non géré" ([System.Windows.Forms.MessageBoxIcon]::Warning)
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
    Show-Message "Échec lors de la tentative de $action du service '$($service.DisplayName)'.`n`nDétail : $($_.Exception.Message)" "Erreur" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit 4
}

# SIG # Begin signature block
# MIIghAYJKoZIhvcNAQcCoIIgdTCCIHECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAy9Cj3h0K9yXV7
# OMwKYgRLzvsGZQHLu6NsxbLh4Sh3/qCCGWowggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggYsMIIEFKADAgECAhRQQGmZSiWuR1hlnUKfCD4py4JQhzAN
# BgkqhkiG9w0BAQsFADB7MS0wKwYDVQQKEyRVc2luZSBEZSBDb25nZWxhdGlvbiBE
# ZSBTdC1icnVubyBJbmMxLTArBgNVBAsTJDY4YTU2NzBmLWRjNzQtNDc0Ni05MWQ3
# LTNjMWY3MDhkZTBkNzEbMBkGA1UEAxMSU0NFUG1hbi1Sb290LUNBLVYxMB4XDTI2
# MDMxNjE1MTMwOVoXDTI4MDMxNjE1MTMwOVowLDEqMCgGA1UEAwwhV2lsZC1ibHVl
# YmVycmllc19jb2RlLWNlcnRpZmljYXRlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAxQ8im9mCZGg4dlDgVnVZP4pAdDwPp5aOI3ZQyqSQfZJUiKqquh2Z
# B8B0iQrM1JkHnn3fchhZyQRBcmKAaM6B1MTmj9whlWZiYl2QDkQ+/faOWT0Qyztk
# vx0M4oWCFDTXQhN6bRA7fAl3E4iys7BRErZ5gL3yaz9NbENGqvIpEcJAdiweRNLv
# NnZ5o0k49L0RFCzDsWyvKLhFg3ZAA7332Al2nTO4CGfmtU5K1fzxfYZzLh5T78TH
# Qd/M1YRrrw2EXIa2t51k2VFrKTGlXlWO1tgrV6dlx7ah+p0qlvJoRqANInUL8WFN
# RmMV9uwsDkfI30QFmknd2/tm7JhIsYRsLDyX3XLUjEOqrVtKOXlWQDjnuUaT+E6g
# nb3ma611xYFzuIFItxlUPlPYRdXfVqzj2X5rVp0bGqXP6vPTrMvQTmnQzjRhOJgr
# zCnHVsGI8MTV5qpa06y2fOzmjZ626TUbNDJLICvfExV5qiUmtnVdz5tFM6VjVGEH
# 4CYY49SYu44wvgmvp8h3/W7Qybg6QW59fgUbdloTDflo+oG0dwN4ZT4mfi8e0WWM
# fShUJtIAZH7+IOo7rNW17EthUX2ZV71naV42GNWWcYydCByotUVVivr+HY2ulj2e
# ZmrPO+iP1K10HfJ8Ci2Ha+6QkogWYe2bNESTncBtr/h8zZs9ujpuORUCAwEAAaOB
# 9jCB8zAfBgNVHSMEGDAWgBQKRBuNvc62o2FXR2t36nBh9GCFNzAdBgNVHQ4EFgQU
# 18cJv19t8AMhtUxwRy1WZsxVPHEwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMC
# B4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwMwWwYIKwYBBQUHAQEETzBNMCQGCCsG
# AQUFBzAChhhodHRwczovL3NjZXAuYnNxLmxpbmsvY2EwJQYIKwYBBQUHMAGGGWh0
# dHA6Ly9zY2VwLmJzcS5saW5rL29jc3AwHgYIKoZIhvcUBQ4EEgQQD2elaHTcRkeR
# 1zwfcI3g1zANBgkqhkiG9w0BAQsFAAOCAgEAWHcKOA2/jakJOWp80OfbH2mLZF7w
# H2C6xsQ3Pbv6VGWDdy1uBR8GpwsZh/WQfqpL7CVgfd4c37HSt3daECUUcmiR6Oar
# dQCtoJ9r/xKM7tZerXnV5jAPFyxBh4up9JBw/VK854fRTUxlrxvqFYiQaxnaxVUE
# xanWW5yW842jqM3GNWQFMNGWmkxbDn+vaz8Y3KQdCuOCExbpaEM87iM0m2IyMhXS
# BPniapk+W4fMIHXYo0pMXtOgzqgCIHSGo60RiT2WVniQAOlDDJJzUzhIWj0scNsM
# uMaXERmJy56faorE5Pvif92l/+4QbO/iaboer45zBRo1CfvyNaPO9mHYkYSm0fY1
# HWYxeHOaoiL7Z1Ys0wZSyauoR+EGtdDTOJyKU8thaqrgMu//XU1hwZSB8IFCWFk/
# RRSe2qO5Fxez19u+WBTweHXQ10hSFUdxQAr2Pk+FDM/pGx86pfuoBUgGMJ3b1XE0
# KN/MExS60uUyXy1JJT07lHNf0E/BaKS3uPzwTtTqat8COT0HN+jvlf+/CVRuzFaP
# pjWccTLHFK+xtENcEdnmnRBGW+v+xM0vmgQ03VnHKqucebrtkIIBfAunpKmJJDJ6
# FJHCuz6SwC2yxJlVJrSNM9v+rfjBHUIAqLZCjzS0gQVH0T6ygKVyp615C7NMdVn7
# NCS66hnzPY+jDBQwgga0MIIEnKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yNTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYg
# MjAyNSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphB
# cr48RsAcrHXbo0ZodLRRF51NrY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6p
# vF4uGjwjqNjfEvUi6wuim5bap+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHe
# HYNnQxqXmRinvuNgxVBdJkf77S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEd
# gkFiDNYiOTx4OtiFcMSkqTtF2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjU
# jsZvkgFkriK9tUKJm/s80FiocSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bR
# VFLeGkuAhHiGPMvSGmhgaTzVyhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeS
# LsJygoLPp66bkDX1ZlAeSpQl92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIV
# NSaz7BX8VtYGqLt9MmeOreGPRdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL
# 6s36czwzsucuoKs7Yk/ehb//Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2Zd
# SoQbU2rMkpLiQ6bGRinZbI4OLu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFU
# eEY0qVjPKOWug/G6X5uAiynM7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/
# BAgwBgEB/wIBADAdBgNVHQ4EFgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0j
# BBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8E
# PDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEw
# DQYJKoZIhvcNAQELBQADggIBABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/
# T8ObXAZz8OjuhUxjaaFdleMM0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQ
# E7jU/kXjjytJgnn0hvrV6hqWGd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9r
# EVKChHyfpzee5kH0F8HABBgr0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y
# 1IsA0QF8dTXqvcnTmpfeQh35k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gx
# dEkMx1NKU4uHQcKfZxAvBAKqMVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3t
# y9qIijanrUR3anzEwlvzZiiyfTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcy
# tL5TTLL4ZaoBdqbhOhZ3ZRDUphPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEB
# YTptMSbhdhGQDpOXgpIUsWTjd6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud
# /v4+7RWsWCiKi9EOLLHfMR2ZyJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiS
# uEtQvLsNz3Qbp7wGWqbIiOWCnb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZP
# ubdcMIIG7TCCBNWgAwIBAgIQCoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsF
# ADBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNV
# BAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hB
# MjU2IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzEL
# MAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJE
# aWdpQ2VydCBTSEEyNTYgUlNBNDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUg
# MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMr
# V7pvUf+GcAoB38o3zBlCMGMyqJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8
# dE2/pPvOx/Vj8TchTySA2R4QKpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7M
# rxVyfQO9sMx6ZAWjFDYOzDi8SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZ
# ZREr4h/GI6Dxb2UoyrN0ijtUDVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFO
# nHoRh6+86Ltc5zjPKHW5KqCvpSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+n
# igNJFmt6LAHvH3KSuNLoZLc1Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeIt
# K/DhKbPxTTuGoX7wJNdoRORVbPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1
# zBp+xUIZkpSFA8vWdoUoHLWnqWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk
# 8iyyizNDIXj//cOgrY7rlRyTlaCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsW
# eupWs7NpChUk555K096V1hE0yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAk
# prxMiXAJQ1XCmnCfgPf8+3mnAgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0G
# A1UdDgQWBBTkO/zyMe39/dfzkXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQG
# fHrK4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEy
# NTYyMDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hB
# MjU2MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWL
# pQq1b4URGnwWBdEZD9gBq9fNaNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgj
# g8K8elC4+oWCqnU/ML9lFfim8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3Q
# YIUP2S3HQvHG1FDu+WUqW4daIqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5
# bdrPbF6MRYs03h4obEMnxYOX8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUG
# tMTaiLR9wjxUxu2hECZpqyU1d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNE
# suEB7O7/cuvTQasnM9AWcIQfVjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6U
# Arb+BOVAkg2oOvol/DJgddJ35XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG
# 0LIhp6GvReQGgMgYxQbV1S3CrWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWV
# FjF7mcr4C34Mj3ocCVccAvlKV9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5
# t2nGj/ULLi49xTcBZU8atufk+EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjs
# arfNZzGCBnAwggZsAgEBMIGTMHsxLTArBgNVBAoTJFVzaW5lIERlIENvbmdlbGF0
# aW9uIERlIFN0LWJydW5vIEluYzEtMCsGA1UECxMkNjhhNTY3MGYtZGM3NC00NzQ2
# LTkxZDctM2MxZjcwOGRlMGQ3MRswGQYDVQQDExJTQ0VQbWFuLVJvb3QtQ0EtVjEC
# FFBAaZlKJa5HWGWdQp8IPinLglCHMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIb9gphS
# eNutiyG1tKbyJMpdTgxRm+JAPtKJiTAk/wzOMA0GCSqGSIb3DQEBAQUABIICACB8
# UIVtG7oJJhozB0WLLCZKsTuLRm8y6HIuNsuHEGg7OT5W1IXXD6ddpoQWQm4QxFdd
# Apf9yjCX/MBb/Goz0s+Hnh2i1dS+dEHp+GhwBMpfpAW8XC0mIDVJcLqjbVO9tTc5
# v+XUAWCOku+lkxu3RpI/czIWce2bVZCReXoWnc5lm13JtCoepjjm+WuiMvcW5VXd
# KgoBtXV2uiRsH9TTv9Br1cpEe2mA70jCVZUCdyWjggR73xEXXdEjVnf9F0vCPboV
# 7ybcj7Z4eN7IF0AjniHBoWqZfHeF5vF2dWo+bAOShv1UiDIIisyg5skoHzxeo2aI
# xzHfJCa/vNQGJvzS5/YVNaCicLZkfnmODrdyvgXVCm3R6w0eY+ytaXGcHvrd3JrE
# UsPL6SGOJmjnURIGJRbs/f7PIVlhZ0XSGvDOgW+/KiBD/p4CGcz4/vnJ2csK3WBe
# ARY0OKXlFl4TsKm2zlbUW5tYYpgTsXkNSuzvP1Nn4xGFTo/LX2AdP2/kShVmY1Eu
# 6U3Ao3r7p8G0lBfpLwUI/Nofmx6rEAJMbr8IM9TpPMQFl9sRmZVdd2ah+y5PfkSM
# 4UaiCjbGuNKd6/If3hIlX9UpE7Iyrm4/r4G/o6p4JSXtph5M02uXfjoI7q6Xg7fg
# wjfBeHNeB6cFTIBj6JojzPuk+ITs8EuX4iGc/Rr8oYIDJjCCAyIGCSqGSIb3DQEJ
# BjGCAxMwggMPAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGlu
# ZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC0cR2p5V0aDANBglg
# hkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcN
# AQkFMQ8XDTI2MDMxNzE5MjEwMVowLwYJKoZIhvcNAQkEMSIEIDpf32k1zf+yghuY
# dhZ1D9dJebTKAmbMrP99hD7iMoDQMA0GCSqGSIb3DQEBAQUABIICAB7qcjPqOQZb
# YkqFrTj2hCVYvDHkSOSFE5qwDkT1wUJbDJxelgHJpDXBE57rKL4ypcmZ5KF8149g
# RtrfXyUP0NjlBQHjl6CYPZxBC2UUt2vTgXbnKTqM04BRK9E19Vwfpd5SIqFOXdf8
# nFgDK8lc4kwxKGBi2ZJHraiDQm2Qr4H32Nditf7DYT7O3PLK4v996FWyeiIy8poj
# JC6QHu0ISuTuBDBW3u3FzqD3ENZhP8nxqvPxexdowcKfxhNmedo4/81Rkk//PLnO
# UyC0DY9d4zNlmm9fiIsTcZoqHGVUHPZsZ6wPG4TI1DOMyrXl7xhnD08AXbplItk+
# 6ho2891bmVQpsFU+u4qw9zUJckldFV0zcYGCGTzNbcpUaJOZs+xFvbZpSlRJ6kIm
# D7PA0Wmhwxt/M6vEBJkOKADZjJQzAsirOC1u/TW/+FX+JZjjLEwR5mGLVM16qpl/
# S9FYtznDG33ADLGQ67QEpL6mVM4aN/m3h/PSA8DdpVwJU75Og/YRgwqv6YtjXbUW
# NIlFCoUgXNno0JmL8uvXaOQbaMeuQJ/ak9qlWBKR4HynVSsmvpgiNayvjm9bf9YO
# YxniD5cwY2dNKSB/fYS5KVnQ8dK+tild1ns0wln+6jNapIeRPSEyJq2DEvP7IQJf
# bmWahKqoBvMS4tkL4OCFNeShJpdVpSDP
# SIG # End signature block
