<#
.SYNOPSIS
  Enforces a single language (fr-CA) with two keyboard layouts:
   - Français (Canada)            -> Keyboard ID: 00000C0C
   - Canadian Multilingual Std    -> Keyboard ID: 00011009
  Includes detection logic for Intune (Win32 detection or Proactive Remediations).

.PARAMETER DetectOnly
  If specified, performs detection only:
    - Exit 0 if compliant
    - Exit 1 if not compliant

.PARAMETER VerboseLog
  If specified, prints extra diagnostic information.

.NOTES
  - Deploy via Intune and run in the **user** context.
  - 64-bit PowerShell recommended.
  - Idempotent: if already compliant, makes no changes and exits 0.
#>

[CmdletBinding()]
param(
    [switch]$DetectOnly,
    [switch]$VerboseLog
)

# -----------------------------
# Configurable constants
# -----------------------------
$LanguageTag          = 'fr-CA'       # Windows language tag
$LangHex              = '0C0C'        # Hex LCID for fr-CA
$Kb_FrCa              = '00001009'    # Français (Canada) keyboard
$Kb_CanMultilingual   = '00011009'    # Canadian Multilingual Standard keyboard
$DesiredTipsOrdered   = @(
    "${LangHex}:$Kb_CanMultilingual",
    "${LangHex}:$Kb_FrCa"
)

# Registry paths
$PreloadKey = 'HKCU:\Keyboard Layout\Preload'

# -----------------------------
# Helpers
# -----------------------------
function Write-Log {
    param([string]$Message,[string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Output "[$timestamp][$Level] $Message"
}

function Compare-ArraysExact {
    param(
        [Parameter(Mandatory=$true)][object[]]$A,
        [Parameter(Mandatory=$true)][object[]]$B,
        [switch]$CaseInsensitive
    )
    if ($null -eq $A -and $null -eq $B) { return $true }
    if ($null -eq $A -or  $null -eq $B) { return $false }
    if ($A.Count -ne $B.Count) { return $false }
    for ($i=0; $i -lt $A.Count; $i++) {
        $left  = "$($A[$i])"
        $right = "$($B[$i])"
        if ($CaseInsensitive) {
            if ($left.ToUpperInvariant() -ne $right.ToUpperInvariant()) { return $false }
        } else {
            if ($left -ne $right) { return $false }
        }
    }
    return $true
}

function Get-NumericRegistryValues {
    param([string]$Path)
    $vals = @{}
    if (-not (Test-Path $Path)) { return $vals }
    $props = Get-ItemProperty -Path $Path
    foreach ($p in ($props.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' })) {
        $vals[$p.Name] = [string]$p.Value
    }
    return $vals
}

function Test-FrCaKeyboardCompliance {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        IsCompliant             = $false
        LanguageListOk          = $false
        TipsOk                  = $false
        PreloadOk               = $false
        DetectedLanguages       = @()
        DetectedTips            = @()
        PreloadValues           = @{}
        ExpectedLanguageTag     = $LanguageTag
        ExpectedTipsOrdered     = $DesiredTipsOrdered
        ExpectedPreloadOrder    = @{'1'=$Kb_CanMultilingual; '2'=$Kb_FrCa}
    }

    try {
        # 1) Language & TIPs
        $effective = Get-WinUserLanguageList
        $langs = $effective | ForEach-Object { $_.LanguageTag }
        $result.DetectedLanguages = $langs

        # Expect exactly 1 language, fr-CA
        if (($langs.Count -eq 1) -and ($langs[0].ToLowerInvariant() -eq $LanguageTag.ToLowerInvariant())) {
            $result.LanguageListOk = $true
        }

        # Collect TIPs for the single language (if present)
        $tips = @()
        if ($effective.Count -gt 0 -and $null -ne $effective[0].InputMethodTips) {
            $tips = @($effective[0].InputMethodTips | ForEach-Object { "$_"} )
        }
        $result.DetectedTips = $tips

        if (Compare-ArraysExact -A $tips -B $DesiredTipsOrdered -CaseInsensitive) {
            $result.TipsOk = $true
        }

        # 2) HKCU\Keyboard Layout\Preload (order and only two entries)
        $preload = Get-NumericRegistryValues -Path $PreloadKey
        $result.PreloadValues = $preload

        $hasOnlyTwo = ($preload.Keys.Count -eq 2) -and ($preload.ContainsKey('1')) -and ($preload.ContainsKey('2'))
        $orderOk    = $hasOnlyTwo -and
                      ($preload['1'].ToUpperInvariant() -eq $Kb_CanMultilingual.ToUpperInvariant()) -and
                      ($preload['2'].ToUpperInvariant() -eq $Kb_FrCa.ToUpperInvariant())

        if ($hasOnlyTwo -and $orderOk) { $result.PreloadOk = $true }

        # 3) Final compliance
        $result.IsCompliant = $result.LanguageListOk -and $result.TipsOk -and $result.PreloadOk
    }
    catch {
        Write-Log "Detection error: $($_.Exception.Message)" "ERROR"
        $result.IsCompliant = $false
    }

    return $result
}

function Ensure-FrCaKeyboard {
    [CmdletBinding()]
    param()

    Write-Log "Applying fr-CA language & keyboard remediation..."

    # Build desired language list
    $desired = New-WinUserLanguageList -Language $LanguageTag
    $desired[0].InputMethodTips.Clear()
    foreach ($tip in $DesiredTipsOrdered) {
        $desired[0].InputMethodTips.Add($tip) | Out-Null
    }

    # Apply language + tips (replaces user's list)
    Set-WinUserLanguageList -LanguageList $desired -Force
    Write-Log "Set-WinUserLanguageList applied. Tips: $($DesiredTipsOrdered -join ', ')"

    # Preload order in HKCU (idempotent)
    if (-not (Test-Path $PreloadKey)) {
        New-Item -Path $PreloadKey -Force | Out-Null
    }
    New-ItemProperty -Path $PreloadKey -Name '1' -Value $Kb_FrCa -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $PreloadKey -Name '2' -Value $Kb_CanMultilingual -PropertyType String -Force | Out-Null
    # Remove any extra numeric entries beyond 1 and 2
    $preloadVals = Get-NumericRegistryValues -Path $PreloadKey
    foreach ($name in $preloadVals.Keys) {
        if ($name -notin @('1','2')) {
            Remove-ItemProperty -Path $PreloadKey -Name $name -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "HKCU Preload set to 1=$Kb_FrCa (default), 2=$Kb_CanMultilingual; extras pruned."

    # Optional: language bar/CTF tidying (non-blocking)
    try {
        $ctfKey = 'HKCU:\Software\Microsoft\Input\Settings'
        if (-not (Test-Path $ctfKey)) { New-Item -Path $ctfKey -Force | Out-Null }
        New-ItemProperty -Path $ctfKey -Name 'LanguageBarEnabled' -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $ctfKey -Name 'HotkeyState' -Value 0 -PropertyType DWord -Force | Out-Null
    } catch { Write-Log "CTF tweak skipped: $($_.Exception.Message)" "WARN" }
}

# -----------------------------
# Main
# -----------------------------
try {
    if ($VerboseLog) {
        Write-Log "Starting detection... Desired Tips: $($DesiredTipsOrdered -join ', '); Language: $LanguageTag"
    }

    $check = Test-FrCaKeyboardCompliance

    if ($VerboseLog) {
        Write-Log "Detected languages: $($check.DetectedLanguages -join ', ')"
        Write-Log "Detected TIPs: $($check.DetectedTips -join ', ')"
        Write-Log ("Detected Preload: " + ($check.PreloadValues.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" } -join '; '))
        Write-Log "Compliance breakdown -> Language:$($check.LanguageListOk) Tips:$($check.TipsOk) Preload:$($check.PreloadOk)"
    }

    if ($DetectOnly) {
        if ($check.IsCompliant) {
            Write-Log "COMPLIANT"
            exit 0
        } else {
            Write-Log "NON-COMPLIANT"
            exit 1
        }
    }

    # Remediate if needed
    if ($check.IsCompliant) {
        Write-Log "Already compliant. No changes required."
        exit 0
    }

    Ensure-FrCaKeyboard

    # Re-check
    $recheck = Test-FrCaKeyboardCompliance
    if ($VerboseLog) {
        Write-Log "Post-remediation compliance: $($recheck.IsCompliant)"
    }

    if ($recheck.IsCompliant) {
        Write-Log "Remediation successful."
        exit 0
    } else {
        Write-Log "Remediation attempted but compliance not confirmed." "WARN"
        exit 1
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}