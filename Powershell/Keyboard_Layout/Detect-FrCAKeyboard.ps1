# Detect-FrCAKeyboard.ps1 (USER CONTEXT) - PowerShell 5.1 compatible

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ---- Config ----
$LanguageTag = 'fr-CA'      # BCP-47
$LangHex     = '0C0C'       # LCID fr-CA pour le préfixe TIP
$Kb_FrCa     = '00001009'   # Canadian French (non-legacy)
$Kb_CMS      = '00011009'   # Canadian Multilingual Standard
$ExpectedTips = @("$LangHex:$Kb_FrCa", "$LangHex:$Kb_CMS")
$PreloadKey  = 'HKCU:\Keyboard Layout\Preload'

function Get-NumericRegValues {
    param([string]$Path)
    $vals = @{}
    if (-not (Test-Path $Path)) { return $vals }
    $props = (Get-ItemProperty -Path $Path).PSObject.Properties |
             Where-Object { $_.Name -match '^\d+$' }
    foreach ($p in $props) { $vals[$p.Name] = [string]$p.Value }
    return $vals
}

function Compare-Exact {
    param(
        [object[]]$A,
        [object[]]$B
    )
    if ($null -eq $A -and $null -eq $B) { return $true }
    if ($null -eq $A -or  $null -eq $B) { return $false }

    # S'assurer que ce sont des tableaux pour Count
    $arrA = @($A)
    $arrB = @($B)

    if ($arrA.Count -ne $arrB.Count) { return $false }

    for ($i = 0; $i -lt $arrA.Count; $i++) {
        $left  = [string]$arrA[$i]
        $right = [string]$arrB[$i]
        if ($left.ToUpper() -ne $right.ToUpper()) { return $false }
    }
    return $true
}

try {
    # 1) Liste de langues (par utilisateur courant)
    $list  = Get-WinUserLanguageList
    $langs = @()
    foreach ($l in $list) { $langs += $l.LanguageTag }

    if (-not ($langs.Count -eq 1 -and $langs[0].ToLower() -eq $LanguageTag.ToLower())) {
        exit 1
    }

    # 2) TIPs de la langue unique
    $tips = @()
    if ($list.Count -gt 0 -and $null -ne $list[0].InputMethodTips) {
        foreach ($t in $list[0].InputMethodTips) { $tips += ([string]$t) }
    }

    if (-not (Compare-Exact -A $tips -B $ExpectedTips)) { exit 1 }

    # 3) HKCU\Keyboard Layout\Preload (ordre et contenu exacts)
    $pre = Get-NumericRegValues -Path $PreloadKey
    $ok  = ($pre.Keys.Count -eq 2) -and
           ($pre.ContainsKey('1')) -and ($pre.ContainsKey('2')) -and
           ($pre['1'].ToUpper() -eq $Kb_FrCa.ToUpper()) -and
           ($pre['2'].ToUpper() -eq $Kb_CMS.ToUpper())

    if (-not $ok) { exit 1 }

    exit 0
}
catch {
    # Toute exception => non conforme
    exit 1
}