<#
Reference: https://petri.com/how-to-get-ntfs-file-permissions-using-powershell

en utilisant la commande a la fin de l'article et en la transformant en function
#>

function Get-childpermissions {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $path,
        [Parameter(Mandatory=$false, Position=1)]
        [string] $outputmode
        )
    
    $FolderPath = Get-ChildItem -Directory -Path $path -Recurse -Force
    $Output = @()
    ForEach ($Folder in $FolderPath) {
        $Acl = Get-Acl -Path $Folder.FullName
        ForEach ($Access in $Acl.Access) {
            $Properties = [ordered]@{'Folder Name'=$Folder.FullName;'Group/User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
            $Output += New-Object -TypeName PSObject -Property $Properties            
            }
    }
if ($outputmode -match 'csv') { 
    $Output | export-csv -path (Read-Host -prompt 'where do we save the export')
    }
    else {
    $output | out-GridView
    }
}