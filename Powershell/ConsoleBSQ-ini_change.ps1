##############################################################
## this is a functions that need to be included for the change of the ini configguration,
## available at https://www.powershellgallery.com/packages/PsIni/3.1.2
##############################################################
Set-StrictMode -Version Latest
Function Set-IniContent {
    <#
    .Synopsis
        Updates existing values or adds new key-value pairs to an INI file

    .Description
        Updates specified keys to new values in all sections or certain sections.
        Used to add new or change existing values. To comment, uncomment or remove keys use the related functions instead.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.

    .Notes
        Author : Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
        Source : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version : 1.0.0 - 2016/08/18 - SS - Initial release

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Parameter FilePath
        Specifies the path to the input file.

    .Parameter InputObject
        Specifies the Hashtable to be modified. Enter a variable that contains the objects or type a command or expression that gets the objects.

    .Parameter NameValuePairs
        String of one or more key names and values to modify, with the name/value separated by a delimiter and the pairs separated by another delimiter . Required.

    .Parameter NameValueDelimiter
        Specify what character should be used to split the names and values specified in -NameValuePairs.
        Default: "="

    .Parameter NameValuePairDelimiter
        Specify what character should be used to split the specified name-value pairs.
        Default: ","

    .Parameter Sections
        String of one or more sections to limit the changes to, separated by a delimiter. Default is a comma, but this can be changed with -SectionDelimiter.
        Surrounding section names with square brackets is not necessary but is supported.
        Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.

    .Parameter SectionDelimiter
        Specify what character should be used to split the -Sections parameter value.
        Default: ","

    .Example
        $ini = Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Printers' -NameValuePairs 'Name With Space=Value1,AnotherName=Value2'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, adds or updates the 'Name With Space' and 'AnotherName' keys in the [Printers] section to the values specified,
        and saves the modified ini to $ini.

    .Example
        Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Terminals,Monitors' -NameValuePairs 'Updated=FY17Q2' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and adds or updates the 'Updated' key in the [Terminals] and [Monitors] sections to the value specified.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs 'Headers=True,Update=False' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Set-IniContent to add or update the 'Headers' and 'Update' keys in all sections
        to the specified values. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs 'Updated=FY17Q2' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Set-IniContent to add or update the 'Updated' key that
        is orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.

    .Link
        Get-IniContent
        Out-IniFile
    #>

    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType(
        [System.Collections.IDictionary]
    )]
    Param
    (
        [Parameter(ParameterSetName="File",Mandatory=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$FilePath,

        [Parameter(ParameterSetName="Object",Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]$InputObject,

        [Parameter(ParameterSetName="File",Mandatory=$True)]
        [Parameter(ParameterSetName="Object",Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$NameValuePairs,

        [char]$NameValueDelimiter = '=',
        [char]$NameValuePairDelimiter = ',',
        [char]$SectionDelimiter = ',',

        [Parameter(ParameterSetName="File")]
        [Parameter(ParameterSetName="Object")]
        [ValidateNotNullOrEmpty()]
        [String]$Sections
    )

    Begin
    {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        # Update or add the name/value pairs to the section.
        Function Update-IniEntry
        {
            param ($content, $section)

            foreach ($pair in $NameValuePairs.Split($NameValuePairDelimiter))
            {
                Write-Debug ("Processing '{0}' pair." -f $pair)

                $splitPair = $pair.Split($NameValueDelimiter)

                if ($splitPair.Length -ne 2)
                {
                    Write-Warning("$($MyInvocation.MyCommand.Name):: Unable to split '{0}' into a distinct key/value pair." -f $pair)
                    continue
                }

                $key = $splitPair[0].Trim()
                $value = $splitPair[1].Trim()
                Write-Debug ("Split key is {0}, split value is {1}" -f $key, $value)

                if (!($content[$section]))
                {
                    Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist, creating it." -f $section)
                    $content[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }

                Write-Verbose ("$($MyInvocation.MyCommand.Name):: Setting '{0}' key in section {1} to '{2}'." -f $key, $section, $value)
                $content[$section][$key] = $value
            }
        }
    }
    # Update the specified keys in the list, either in the specified section or in all sections.
    Process
    {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        # Specific section(s) were requested.
        if ($Sections)
        {
            foreach ($section in $Sections.Split($SectionDelimiter))
            {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]',''

                Write-Debug ("Processing '{0}' section." -f $section)

                Update-IniEntry $content $section
            }
        }
        else # No section supplied, go through the entire ini since changes apply to all sections.
        {
            foreach ($item in $content.GetEnumerator())
            {
                $section = $item.key

                Write-Debug ("Processing '{0}' section." -f $section)

                Update-IniEntry $content $section
            }
        }
        return $content
    }
    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias sic Set-IniContent

################################
Function Out-IniFile {
       <#
       .Synopsis
           Write hash content to INI file
    
       .Description
           Write hash content to INI file
    
       .Notes
           Author : Oliver Lipkau <oliver@lipkau.net>
           Blog : http://oliver.lipkau.net/blog/
           Source : https://github.com/lipkau/PsIni
                         http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
    
           #Requires -Version 2.0
    
       .Inputs
           System.String
           System.Collections.IDictionary
    
       .Outputs
           System.IO.FileSystemInfo
    
       .Example
           Out-IniFile $IniVar "C:\myinifile.ini"
           -----------
           Description
           Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini
    
       .Example
           $IniVar | Out-IniFile "C:\myinifile.ini" -Force
           -----------
           Description
           Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present
    
       .Example
           $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru
           -----------
           Description
           Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file
    
       .Example
           $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}
           $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}
           $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}
           Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
           -----------
           Description
           Creating a custom Hashtable and saving it to C:\MyNewFile.ini
       .Link
           Get-IniContent
       #>
   
       [CmdletBinding()]
       [OutputType(
           [System.IO.FileSystemInfo]
       )]
       Param(
           # Adds the output to the end of an existing file, instead of replacing the file contents.
           [switch]
           $Append,
   
           # Specifies the file encoding. The default is UTF8.
           #
           # Valid values are:
           # -- ASCII: Uses the encoding for the ASCII (7-bit) character set.
           # -- BigEndianUnicode: Encodes in UTF-16 format using the big-endian byte order.
           # -- Byte: Encodes a set of characters into a sequence of bytes.
           # -- String: Uses the encoding type for a string.
           # -- Unicode: Encodes in UTF-16 format using the little-endian byte order.
           # -- UTF7: Encodes in UTF-7 format.
           # -- UTF8: Encodes in UTF-8 format.
           [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
           [Parameter()]
           [String]
           $Encoding = "UTF8",
   
           # Specifies the path to the output file.
           [ValidateNotNullOrEmpty()]
           [ValidateScript( {Test-Path $_ -IsValid} )]
           [Parameter( Position = 0, Mandatory = $true )]
           [String]
           $FilePath,
   
           # Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.
           [Switch]
           $Force,
   
           # Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.
           [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
           [System.Collections.IDictionary]
           $InputObject,
   
           # Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.
           [Switch]
           $Passthru,
   
           # Adds spaces around the equal sign when writing the key = value
           [Switch]
           $Loose,
   
           # Writes the file as "pretty" as possible
           #
           # Adds an extra linebreak between Sections
           [Switch]
           $Pretty
       )
   
       Begin {
           Write-Debug "PsBoundParameters:"
           $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
           if ($PSBoundParameters['Debug']) {
               $DebugPreference = 'Continue'
           }
           Write-Debug "DebugPreference: $DebugPreference"
   
           Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
   
           function Out-Keys {
               param(
                   [ValidateNotNullOrEmpty()]
                   [Parameter( Mandatory, ValueFromPipeline )]
                   [System.Collections.IDictionary]
                   $InputObject,
   
                   [ValidateSet("Unicode", "UTF7", "UTF8", "ASCII", "BigEndianUnicode", "Byte", "String")]
                   [Parameter( Mandatory )]
                   [string]
                   $Encoding = "UTF8",
   
                   [ValidateNotNullOrEmpty()]
                   [ValidateScript( {Test-Path $_ -IsValid})]
                   [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
                   [Alias("Path")]
                   [string]
                   $FilePath,
   
                   [Parameter( Mandatory )]
                   $Delimiter,
   
                   [Parameter( Mandatory )]
                   $MyInvocation
               )
   
               Process {
                   if (!($InputObject.get_keys())) {
                       Write-Warning ("No data found in '{0}'." -f $FilePath)
                   }
                   Foreach ($key in $InputObject.get_keys()) {
                       if ($key -match "^Comment\d+") {
                           Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                           "$($InputObject[$key])" | Out-File -Encoding $Encoding -FilePath $FilePath -Append
                       }
                       else {
                           Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                           $InputObject[$key] |
                               ForEach-Object { "$key$delimiter$_" } |
                               Out-File -Encoding $Encoding -FilePath $FilePath -Append
                       }
                   }
               }
           }
   
           $delimiter = '='
           if ($Loose) {
               $delimiter = ' = '
           }
   
           # Splatting Parameters
           $parameters = @{
               Encoding = $Encoding;
               FilePath = $FilePath
           }
   
       }
   
       Process {
           $extraLF = ""
   
           if ($Append) {
               Write-Debug ("Appending to '{0}'." -f $FilePath)
               $outfile = Get-Item $FilePath
           }
           else {
               Write-Debug ("Creating new file '{0}'." -f $FilePath)
               $outFile = New-Item -ItemType file -Path $Filepath -Force:$Force
           }
   
           if (!(Test-Path $outFile.FullName)) {Throw "Could not create File"}
   
           Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"
           foreach ($i in $InputObject.get_keys()) {
               if (!($InputObject[$i].GetType().GetInterface('IDictionary'))) {
                   #Key value pair
                   Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                   "$i$delimiter$($InputObject[$i])" | Out-File -Append @parameters
   
               }
               elseif ($i -eq $script:NoSection) {
                   #Key value pair of NoSection
                   Out-Keys $InputObject[$i] `
                       @parameters `
                       -Delimiter $delimiter `
                       -MyInvocation $MyInvocation
               }
               else {
                   #Sections
                   Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"
   
                   # Only write section, if it is not a dummy ($script:NoSection)
                   if ($i -ne $script:NoSection) { "$extraLF[$i]"  | Out-File -Append @parameters }
                   if ($Pretty) {
                       $extraLF = "`r`n"
                   }
   
                   if ( $InputObject[$i].Count) {
                       Out-Keys $InputObject[$i] `
                           @parameters `
                           -Delimiter $delimiter `
                           -MyInvocation $MyInvocation
                   }
   
               }
           }
           Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $FilePath"
       }
   
       End {
           if ($PassThru) {
               Write-Debug ("Returning file due to PassThru argument.")
               Write-Output (Get-Item $outFile)
           }
           Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
       }
   }
   
   Set-Alias oif Out-IniFile
####################################################

###  here the script start

$sfolder = "c:\Logiciels_BSQ\Console_BSQ"
$notsfolder = "c:\Logiciel_BSQ\Console_BSQ"

$installedfolder  

if (Test-Path -path $sfolder) {
       $installedfolder = $sfolder
        }
 elseif (Test-Path -path $notsfolder) {
       $installedfolder = $notsfolder
        }
 else {
       write-output "the folder was not found on this computer"
        }

set-inicontent -filepath "$installedfolder\Connexion.ini" -Sections "Serveur" -NameValuePairs "IP=172.30.2.6,Service=172.30.2.6" | out-inifile "$insatlledfolder\Connexion.ini"
