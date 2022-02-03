##############################################################
## this is a functions that need to be included for the change of the ini configguration,
## available at https://www.powershellgallery.com/packages/PsIni/3.1.2
##############################################################
Function Remove-IniEntry {
    <#
    .Synopsis
        Removes specified content from an INI file
 
    .Description
        Removes specified keys in all sections or certain sections.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.
 
    .Notes
        Author : Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
        Source : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version : 1.0.0 - 2016/08/18 - SS - Initial release
                    : 1.0.1 - 2016/12/29 - SS - Removed need for delimiters by making Sections and Keys string arrays.
 
        #Requires -Version 2.0
 
    .Inputs
        System.String
        System.Collections.IDictionary
 
    .Outputs
        System.Collections.Specialized.OrderedDictionary
 
    .Example
        $ini = Remove-IniEntry -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers','Version'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, removes any keys named 'Headers' or 'Version' in the [Printers] section, and saves the modified ini to $ini.
 
    .Example
        Remove-IniEntry -FilePath "C:\myinifile.ini" -Sections 'Terminals','Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and removes any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Sections 'Terminals' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove the 'Terminals' section.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove any 'Updated' keys that
        are orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.
 
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
        # Specifies the path to the input file.
        [Parameter( Position = 0, Mandatory = $true, ParameterSetName = "File")]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        # Specifies the Hashtable to be modified.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Object" )]
        [System.Collections.IDictionary]
        $InputObject,

        # String array of one or more keys to limit the changes to, separated by a comma. Optional.
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Keys,

        [ValidateNotNullOrEmpty()]
        [String[]]
        $Sections
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }
    # Remove the specified keys in the list, either in the specified section or in all sections.
    Process {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        if (!$Keys -and !$Sections) {
            Write-Verbose ("No sections or keys provided, exiting.")
            Write-Output $content
        }

        # Specific section(s) were requested.
        if ($Sections) {
            foreach ($section in $Sections) {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]', ''

                Write-Debug ("Processing '{0}' section." -f $section)

                # If the user wants to remove an entire section, there will be a section specified but no keys.
                if (!$Keys) {
                    Write-Verbose ("Deleting entire section '{0}'." -f $section)
                    $content.Remove($section)
                }
                else {
                    foreach ($key in $Keys) {
                        Write-Debug ("Processing '{0}' key." -f $key)

                        $key = $key.Trim()

                        if ($content[$section]) {
                            $currentValue = $content[$section][$key]
                        }
                        else {
                            Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                            # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                            break
                        }

                        if ($currentValue) {
                            Write-Verbose ("Removing {0} key from {1} section." -f $key, $section)
                            $content[$section].Remove($key)
                        }
                        else {
                            Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist." -f $key)
                        }
                    }
                }
            }
        }
        else {
            # No section supplied, go through the entire ini since changes apply to all sections.
            foreach ($item in $content.GetEnumerator()) {
                $section = $item.key
                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    $key = $key.Trim()
                    Write-Debug ("Processing '{0}' key." -f $key)

                    if ($content[$section][$key]) {
                        Write-Verbose ("Removing {0} key from {1} section." -f $key, $section)
                        $content[$section].Remove($key)
                    }
                    else {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist in {1} section." -f $key, $section)
                    }
                }
            }
        }

        Write-Output $content
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias rie Remove-IniEntry
##############################################################
Function Remove-IniComment {
    <#
    .Synopsis
        Uncomments out specified content of an INI file
 
    .Description
        Uncomments out specified keys in all sections or certain sections.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.
 
    .Notes
        Author : Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
        Source : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version : 1.0.0 - 2016/08/18 - SS - Initial release
                    : 1.0.1 - 2016/12/29 - SS - Removed need for delimiters by making Sections and Keys string arrays.
 
        #Requires -Version 2.0
 
    .Inputs
        System.String
        System.Collections.IDictionary
 
    .Outputs
        System.Collections.Specialized.OrderedDictionary
 
    .Example
        $ini = Remove-IniComment -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, uncomments out any keys named 'Headers' in the [Printers] section, and saves the modified ini to $ini.
 
    .Example
        Remove-IniComment -FilePath "C:\myinifile.ini" -Sections 'Terminals','Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and uncomments out any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniComment -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniComment to uncomment any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniComment -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniComment to uncomment any 'Updated' keys that
        are orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.
 
    .Link
        Get-IniContent
        Out-IniFile
    #>

    [CmdletBinding( DefaultParameterSetName = "File" )]
    [OutputType(
        [System.Collections.IDictionary]
    )]
    Param
    (
        # Specifies the path to the input file.
        [Parameter( Position = 0,  Mandatory = $true, ParameterSetName = "File" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        # Specifies the Hashtable to be modified. Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Object" )]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]
        $InputObject,

        # String array of one or more keys to limit the changes to, separated by a comma. Optional.
        [Parameter( Mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Keys,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # String array of one or more sections to limit the changes to, separated by a comma.
        # Surrounding section names with square brackets is not necessary but is supported.
        # Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Sections
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }
    # Uncomment out the specified keys in the list, either in the specified section or in all sections.
    Process {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        # Specific section(s) were requested.
        if ($Sections) {
            foreach ($section in $Sections) {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]', ''

                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    Write-Debug ("Processing '{0}' key." -f $key)

                    $key = $key.Trim()

                    if (!($content[$section])) {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                        # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                        break
                    }
                    # Since this is a comment, we need to search through all the CommentX keys in this section.
                    # That's handled in the Convert-IniCommentToEntry function, so don't bother checking key existence here.
                    Convert-IniCommentToEntry $content $key $section $CommentChar
                }
            }
        }
        else {
            # No section supplied, go through the entire ini since changes apply to all sections.
            foreach ($item in $content.GetEnumerator()) {
                $section = $item.key
                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    $key = $key.Trim()
                    Write-Debug ("Processing '{0}' key." -f $key)
                    Convert-IniCommentToEntry $content $key $section $CommentChar
                }
            }
        }

        Write-Output $content
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias ric Remove-IniComment
##############################################################
Function Convert-IniEntryToComment {
    <#
    .SYNOPSIS
        Internal module function to remove the old key then insert a new one at the old location in the comment style used by Get-IniContent.
    #>
    param ($content, $key, $section, $commentChar)

    # Comments in Get-IniContent start with 1, not zero.
    $commentCount = 1

    foreach ($entry in $content[$section].GetEnumerator()) {
        if ($entry.key.StartsWith('Comment')) {
            $commentCount++
        }
    }

    Write-Debug ("commentCount is {0}." -f $commentCount)

    $desiredValue = $content[$section][$key]

    # Don't attempt to comment out non-existent keys.
    if ($desiredValue) {
        Write-Debug ("desiredValue is {0}." -f $desiredValue)

        $commentKey = 'Comment' + $commentCount
        Write-Debug ("commentKey is {0}." -f $commentKey)

        $commentValue = $commentChar[0] + $key + '=' + $desiredValue
        Write-Debug ("commentValue is {0}." -f $commentValue)

        # Thanks to http://stackoverflow.com/a/35731603/844937. However, that solution is case sensitive.
        # Tried $index = $($content[$section].keys).IndexOf($key, [StringComparison]"CurrentCultureIgnoreCase")
        # but it said there were no IndexOf overloads with two arguments. So if we get a -1 (not found),
        # use a variation on http://stackoverflow.com/a/34930231/844937 to search for a case-insensitive match.
        $sectionKeys = $($content[$section].keys)
        $index = $sectionKeys.IndexOf($key)
        Write-Debug ("Index of {0} is {1}." -f $key, $index)

        if ($index -eq -1) {
            $i = 0
            foreach ($sectionKey in $sectionKeys) {
                if ($sectionKey -match $key) {
                    $index = $i
                    Write-Debug ("Index updated to {0}." -f $index)
                    break
                }
                else {
                    $i++
                }
            }
        }

        if ($index -ge 0) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Commenting out {0} key in {1} section." -f $key, $section)
            $content[$section].Remove($key)
            $content[$section].Insert($index, $commentKey, $commentValue)
        }
        else {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Could not find '{0}' key in {1} section to comment out." -f $key, $section)
        }
    }
}
##############################################################
Function Convert-IniCommentToEntry {
    <#
    .SYNOPSIS
        Internal module function to remove the old comment then insert a new key/value pair at the old location with the previous comment's value.
    #>
    param ($content, $key, $section, $commentChar)

    $index = 0
    $commentFound = $false

    $commentRegex = "^([$($commentChar -join '')]$key.*)$"
    Write-Debug ("commentRegex is {0}." -f $commentRegex)

    foreach ($entry in $content[$section].GetEnumerator()) {
        Write-Debug ("Uncomment looking at key '{0}' with value '{1}'." -f $entry.key, $entry.value)

        if ($entry.key.StartsWith('Comment') -and $entry.value -match $commentRegex) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Uncommenting '{0}' in {1} section." -f $entry.value, $section)
            $oldKey = $entry.key
            $split = $entry.value.Split("=")

            if ($split.Length -ge 2) {
                $newValue = $split[1].Trim()
            }
            else {
                # If the split did not result in 2+ items, it was not in the key=value form.
                # So just uncomment the key, as there is no value. It will result in a "key=" formatted output.
                $newValue = ''
            }

            # Break out once a match is found. If there are multiple commented out keys
            # with the same name, we can't add them anyway since it's a hash.
            $commentFound = $true
            break
        }
        $index++
    }

    if ($commentFound) {
        if ($content[$section][$key]) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Unable to uncomment '{0}' key in {1} section as there is already a key with that name." -f $key, $section)
        }
        else {
            Write-Debug ("Removing '{0}'." -f $oldKey)
            $content[$section].Remove($oldKey)
            Write-Debug ("Inserting [{0}][{1}] = {2} at index {3}." -f $section, $key, $newValue, $index)
            $content[$section].Insert($index, $key, $newValue)
        }
    }
    else {
        Write-Verbose ("$($MyInvocation.MyCommand.Name):: Did not find '{0}' key in {1} section to uncomment." -f $key, $section)
    }
}
##############################################################
Function Add-IniComment {
    <#
    .Synopsis
        Comments out specified content of an INI file
 
    .Description
        Comments out specified keys in all sections or certain sections.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.
 
    .Notes
        Author : Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
        Source : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version : 1.0.0 - 2016/08/18 - SS - Initial release
                    : 1.0.1 - 2016/12/29 - SS - Removed need for delimiters by making Sections and Keys string arrays.
 
        #Requires -Version 2.0
 
    .Inputs
        System.String
        System.Collections.IDictionary
 
    .Outputs
        System.Collections.Specialized.OrderedDictionary
 
    .Example
        $ini = Add-IniComment -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers','Footers'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, comments out any keys named 'Headers' or 'Footers' in the [Printers] section, and saves the modified ini to $ini.
 
    .Example
        Add-IniComment -FilePath "C:\myinifile.ini" -Sections 'Terminals','Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and comments out any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Add-IniComment -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Add-IniComment to comment out any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Add-IniComment -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Add-IniComment to comment out any 'Updated' keys that
        are orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.
 
    .Link
        Get-IniContent
        Out-IniFile
    #>

    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    Param
    (
        # Specifies the path to the input file.
        [Parameter( Position = 0, Mandatory = $true, ParameterSetName = "File" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        # Specifies the Hashtable to be modified. Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Object" )]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]
        $InputObject,

        # String array of one or more keys to limit the changes to, separated by a comma. Optional.
        [Parameter( Mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Keys,

        # Specify what character should be used to comment out entries.
        # Note: This parameter is a char array to maintain compatibility with the other functions.
        # However, only the first character is used to comment out entries.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # String array of one or more sections to limit the changes to, separated by a comma.
        # Surrounding section names with square brackets is not necessary but is supported.
        # Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Sections
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }

    Process {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        # Specific section(s) were requested.
        if ($Sections) {
            foreach ($section in $Sections) {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]', ''

                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    Write-Debug ("Processing '{0}' key." -f $key)

                    $key = $key.Trim()

                    if ($content[$section]) {
                        $currentValue = $content[$section][$key]
                    }
                    else {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                        # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                        break
                    }

                    if ($currentValue) {
                        Convert-IniEntryToComment $content $key $section $CommentChar
                    }
                    else {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '[{0}][{1}]' does not exist." -f $section, $key)
                    }
                }
            }
        }
        else {
            # No section supplied, go through the entire ini since changes apply to all sections.
            foreach ($item in $content.GetEnumerator()) {
                $section = $item.key
                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    $key = $key.Trim()
                    Write-Debug ("Processing '{0}' key." -f $key)

                    if ($content[$section][$key]) {
                        Convert-IniEntryToComment $content $key $section $CommentChar
                    }
                    else {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '[{0}][{1}]' does not exist." -f $section, $key)
                    }
                }
            }
        }

        Write-Output $content
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias aic Add-IniComment
##############################################################
Function Get-IniContent {
    <#
    .Synopsis
        Gets the content of an INI file
 
    .Description
        Gets the content of an INI file and returns it as a hashtable
 
    .Notes
        Author : Oliver Lipkau <oliver@lipkau.net>
        Source : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version : 1.0.0 - 2010/03/12 - OL - Initial release
                      1.0.1 - 2014/12/11 - OL - Typo (Thx SLDR)
                                              Typo (Thx Dave Stiff)
                      1.0.2 - 2015/06/06 - OL - Improvment to switch (Thx Tallandtree)
                      1.0.3 - 2015/06/18 - OL - Migrate to semantic versioning (GitHub issue#4)
                      1.0.4 - 2015/06/18 - OL - Remove check for .ini extension (GitHub Issue#6)
                      1.1.0 - 2015/07/14 - CB - Improve round-tripping and be a bit more liberal (GitHub Pull #7)
                                           OL - Small Improvments and cleanup
                      1.1.1 - 2015/07/14 - CB - changed .outputs section to be OrderedDictionary
                      1.1.2 - 2016/08/18 - SS - Add some more verbose outputs as the ini is parsed,
                                                  allow non-existent paths for new ini handling,
                                                  test for variable existence using local scope,
                                                  added additional debug output.
 
        #Requires -Version 2.0
 
    .Inputs
        System.String
 
    .Outputs
        System.Collections.Specialized.OrderedDictionary
 
    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent
 
    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent
 
    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file
 
    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    Param(
        # Specifies the path to the input file.
        [ValidateNotNullOrEmpty()]
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [String]
        $FilePath,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $commentRegex = "^\s*([$($CommentChar -join '')].*)$"
        $sectionRegex = "^\s*\[(.+)\]\s*$"
        $keyRegex     = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"

        Write-Debug ("commentRegex is {0}." -f $commentRegex)
    }

    Process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        #$ini = @{}

        if (!(Test-Path $Filepath)) {
            Write-Verbose ("Warning: `"{0}`" was not found." -f $Filepath)
            Write-Output $ini
        }

        $commentCount = 0
        switch -regex -file $FilePath {
            $sectionRegex {
                # Section
                $section = $matches[1]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                $CommentCount = 0
                continue
            }
            $commentRegex {
                # Comment
                if (!$IgnoreComments) {
                    if (!(test-path "variable:local:section")) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $value = $matches[1]
                    $CommentCount++
                    Write-Debug ("Incremented CommentCount is now {0}." -f $CommentCount)
                    $name = "Comment" + $CommentCount
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                    $ini[$section][$name] = $value
                }
                else {
                    Write-Debug ("Ignoring comment {0}." -f $matches[1])
                }

                continue
            }
            $keyRegex {
                # Key
                if (!(test-path "variable:local:section")) {
                    $section = $script:NoSection
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }
                $name, $value = $matches[1, 3]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                if (-not $ini[$section][$name]) {
                    $ini[$section][$name] = $value
                }
                else {
                    if ($ini[$section][$name] -is [string]) {
                        $ini[$section][$name] = [System.Collections.ArrayList]::new()
                        $ini[$section][$name].Add($ini[$section][$name]) | Out-Null
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                    else {
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                }
                continue
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Write-Output $ini
    }

    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias gic Get-IniContent
##############################################################
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
                    : 1.0.1 - 2016/12/29 - SS - Removed need for delimiters by making Sections a string array
                                                and NameValuePairs a hashtable. Thanks Oliver!
 
        #Requires -Version 2.0
 
    .Inputs
        System.String
        System.Collections.IDictionary
 
    .Outputs
        System.Collections.Specialized.OrderedDictionary
 
    .Example
        $ini = Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Printers' -NameValuePairs @{'Name With Space' = 'Value1' ; 'AnotherName' = 'Value2'}
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, adds or updates the 'Name With Space' and 'AnotherName' keys in the [Printers] section to the values specified,
        and saves the modified ini to $ini.
 
    .Example
        Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Terminals','Monitors' -NameValuePairs @{'Updated=FY17Q2'} | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and adds or updates the 'Updated' key in the [Terminals] and [Monitors] sections to the value specified.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs @{'Headers' = 'True' ; 'Update' = 'False'} | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Set-IniContent to add or update the 'Headers' and 'Update' keys in all sections
        to the specified values. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.
 
    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs @{'Updated'='FY17Q2'} -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
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
        # Specifies the path to the input file.
        [Parameter( Position = 0, Mandatory = $true, ParameterSetName = "File" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        # Specifies the Hashtable to be modified.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Object")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]
        $InputObject,

        # Hashtable of one or more key names and values to modify. Required.
        [Parameter( Mandatory = $true, ParameterSetName = "File")]
        [Parameter( Mandatory = $true, ParameterSetName = "Object")]
        [ValidateNotNullOrEmpty()]
        [HashTable]
        $NameValuePairs,

        # String array of one or more sections to limit the changes to, separated by a comma.
        # Surrounding section names with square brackets is not necessary but is supported.
        # Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.
        [Parameter( ParameterSetName = "File" )]
        [Parameter( ParameterSetName = "Object" )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Sections
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        # Update or add the name/value pairs to the section.
        Function Update-IniEntry {
            param ($content, $section)

            foreach ($pair in $NameValuePairs.GetEnumerator()) {
                if (!($content[$section])) {
                    Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist, creating it." -f $section)
                    $content[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }

                Write-Verbose ("$($MyInvocation.MyCommand.Name):: Setting '{0}' key in section {1} to '{2}'." -f $pair.key, $section, $pair.value)
                $content[$section][$pair.key] = $pair.value
            }
        }
    }
    # Update the specified keys in the list, either in the specified section or in all sections.
    Process {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        # Specific section(s) were requested.
        if ($Sections) {
            foreach ($section in $Sections) {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]', ''

                Write-Debug ("Processing '{0}' section." -f $section)

                Update-IniEntry $content $section
            }
        }
        else {
            # No section supplied, go through the entire ini since changes apply to all sections.
            foreach ($item in $content.GetEnumerator()) {
                $section = $item.key

                Write-Debug ("Processing '{0}' section." -f $section)

                Update-IniEntry $content $section
            }
        }
        Write-Output $content
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias sic Set-IniContent

##############################################################
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

##############################################################

###  here the script start

$console_install = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | foreach-object { Get-ItemProperty $_.PsPath } | Select-object DisplayName,InstallLocation | Sort-Object Displayname -Descending | where-object displayname -match console_bsq

$installedfolder = $console_install.InstallLocation

foreach ($folder in $installedfolder) {
    $ini = get-inicontent -filepath $folder"Connexion.ini" 
    write-output $ini["Serveur"]["IP","Service"]
    $ini | set-inicontent -Sections 'Serveur' -NameValuePairs 'IP=172.30.2.6,Service=172.30.2.6' 
    write-output $ini["Serveur"]["IP","Service"]
    Out-IniFile -InputObject $ini -FilePath $folder"Connexion.ini" -Debug
}



#| set-inicontent -Sections 'Serveur' -NameValuePairs 'IP=172.30.2.6,Service=172.30.2.6' 