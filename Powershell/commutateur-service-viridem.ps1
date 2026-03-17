Add-Type -AssemblyName System.Windows.Forms

$ServiceName = "Spooler"

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

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PwshPath {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $defaultPath = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $defaultPath) {
        return $defaultPath
    }

    throw "Impossible de localiser pwsh.exe"
}

if (-not (Test-IsAdministrator)) {
    try {
        $pwshPath   = Get-PwshPath
        $scriptPath = $PSCommandPath

        if (-not $scriptPath) {
            throw "Impossible de déterminer le chemin du script en cours."
        }

        $arguments = @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-WindowStyle", "Hidden"
            "-File", "`"$scriptPath`""
        ) -join ' '

        Start-Process -FilePath $pwshPath -ArgumentList $arguments -Verb RunAs
        exit 0
    }
    catch {
        Show-Message "L'élévation a été refusée ou a échoué.`n`nDétail : $($_.Exception.Message)" "Élévation requise" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        exit 10
    }
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
# MIIKIAYJKoZIhvcNAQcCoIIKETCCCg0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9WDDQcP3T2woS
# HsYlQE6YFm+tCwLOgO0sxl3bGDFVGaCCBjAwggYsMIIEFKADAgECAhRQQGmZSiWu
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
# MC8GCSqGSIb3DQEJBDEiBCC5nLZykl/OYjtM8klaq5LzAVnYasQJTBl7WU03AkTz
# kzANBgkqhkiG9w0BAQEFAASCAgBE06dFSlb0QiKnajCPh3Wb1HeCIAhEnK972IUC
# Yoeewzts8Ro66aiAEEK451E6WkRqwRSi/ESZh2juymdwtyMtjEacJAIjnJXicjpd
# ZEfYU40nqjnt8bs0RPN3/7QkIFiPzEW1OKRB6Zi1OUUT1UUKiWQAvTqVLns4CXJQ
# 5WyH+ubfuShEwOhZHF5/zwgyxOari8GLKTK3aSPnImECwRZAGaEtuGxmGeZXMDTT
# RzyHy8jOfyU6LDFZrf/oolH+nFp4mNDnh18Rwcc+xmx+vUa7WmOLK7jgDOQFWquh
# OT/Fmfdq1UhjYcKyBBkzKmvYGUncjq0jf+GTUmbVmRkVQW4Kb8BJt0TtLfekUl8u
# 1ovqK8yx/ZClfuwXJE0rW4Ak9QcD2xyeik9B3qFeBub14Goyxxqcn9rpum//PmH3
# QaKdYcCUCTxjzrrmLRLTW5uLvd3pxzEujb2LH+XegQ3NZB5lKXVtFFOpYC7r5MuI
# 1/rLRKnAog1SRYhmoFJHbsVswYfpOMVb/0vXkED31qTctOIj5eKnz7KkGFc4Vp2w
# 0gwirPzuoMM0mR55QUB7iZANBLKM2mPI2K6/cHaTjtY8BXIU88VmPo66rU8kUZhH
# zWaR6E+X+2OHnV3YUwnWTNlV26jy2ghqYyCgUrjd7lC9uZbeiZGf4kbnN+QevCOa
# DGEVVA==
# SIG # End signature block
