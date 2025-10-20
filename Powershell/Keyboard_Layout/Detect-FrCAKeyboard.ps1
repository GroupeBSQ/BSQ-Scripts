# Detect-FrCAKeyboard.ps1 (User Context) - Console output only, PS 5.1 compatible

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ---- Config ----
$LanguageTag = 'fr-CA'
$LangHex     = '0C0C'
$Kb_FrCa     = '00001009'   # Canadian French (non-legacy)
$Kb_CMS      = '00011009'   # Canadian Multilingual Standard
$ExpectedTips = @("$($LangHex):$Kb_FrCa", "$($LangHex):$Kb_CMS")
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
    param([object[]]$A,[object[]]$B)
    if ($null -eq $A -and $null -eq $B) { return $true }
    if ($null -eq $A -or  $null -eq $B) { return $false }
    $arrA=@($A); $arrB=@($B)       # force arrays
    if ($arrA.Count -ne $arrB.Count) { return $false }
    for ($i=0;$i -lt $arrA.Count;$i++){
        if ( ([string]$arrA[$i]).ToUpper() -ne ([string]$arrB[$i]).ToUpper() ) { return $false }
    }
    return $true
}

try {
    Write-Host "=== Detection Started ==="
    Write-Host "Expected Language: $LanguageTag"
    Write-Host "Expected TIPs: $($ExpectedTips -join ', ')"
    Write-Host "Expected Preload: 1=$Kb_FrCa, 2=$Kb_CMS"
    Write-Host "---------------------------"

    # 1) Language list
    $list  = Get-WinUserLanguageList
    $langs = @($list | ForEach-Object { $_.LanguageTag })  # force array
    Write-Host "Detected Languages: $($langs -join ', ')"

    # Use a safe first element as string
    $firstLang = if ($langs.Count -ge 1) { [string]$langs[0] } else { '' }

    if (-not ($langs.Count -eq 1 -and $firstLang.ToLower() -eq $LanguageTag.ToLower())) {
        Write-Host "❌ Non-compliant: Language mismatch (expected '$LanguageTag', got '$($langs -join ', ')')"
        exit 1
    }

    # 2) TIPs
    $tips = @()
    if ($list.Count -gt 0 -and $null -ne $list[0].InputMethodTips) {
        $tips = @($list[0].InputMethodTips | ForEach-Object { [string]$_ })  # force array of strings
    }
    Write-Host "Detected TIPs: $($tips -join ', ')"

    if (-not (Compare-Exact -A $tips -B $ExpectedTips)) {
        Write-Host "❌ Non-compliant: TIPs mismatch (expected '$($ExpectedTips -join ', ')')"
        exit 1
    }

    # 3) Preload
    $pre = Get-NumericRegValues -Path $PreloadKey
    $pairs = ($pre.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '; '
    Write-Host "Detected Preload: $pairs"

    $ok = ($pre.Keys.Count -eq 2) -and
          ($pre.ContainsKey('1')) -and ($pre.ContainsKey('2')) -and
          ($pre['1'].ToUpper() -eq $Kb_FrCa.ToUpper()) -and
          ($pre['2'].ToUpper() -eq $Kb_CMS.ToUpper())

    if (-not $ok) {
        Write-Host "❌ Non-compliant: Preload mismatch (must be 1=$Kb_FrCa; 2=$Kb_CMS, only those two)"
        exit 1
    }

    Write-Host "✅ Detection Compliant"
    exit 0
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)"
    exit 1
}
``