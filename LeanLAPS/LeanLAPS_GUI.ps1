#leanLAPS GUI, provided AS IS as companion to the leanLAPS script
#Kindly provided by Colton Lacy https://www.linkedin.com/in/colton-lacy-826599114/

$remediationScriptID = "73de7252-e2e5-47c5-9af1-cce667ce0587" #To get this go to graph explorer https://developer.microsoft.com/en-us/graph/graph-explorer and use this https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts to get all remediation scripts and select your scripts id
$psdAdminUsername = ".\PSDAdmin" #Whatever the Admin username is

Function ConnectMSGraphModule {

    If (!(Get-Module -Name Microsoft.Graph.Intune)) {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [Windows.Forms.MessageBox]::Show("Please launch powershell as Administrator and install MSGraph Module with this cmdlet: Install-Module Microsoft.Graph", "PSD", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    }
        
    If ((Get-MSGraphEnvironment).SchemaVersion -ne "beta") {
        Write-CustomEventLog "Changing MSGraph Schema to beta"
        $null = Update-MSGraphEnvironment -SchemaVersion beta
    }
    Connect-MSGraph    
}
        
function getDeviceInfo {
        
    If($inputBox.Text) {
                        
            $outputBox.text =  "Gathering leanLAPS and Device Information for " + $inputBox.text + " - Please wait...."  | Out-String
        
            #Connect to GraphAPI and get leanLAPS for a specific device that was supplied through the GUI
            $graphApiVersion = "beta"
            $deviceInfo = '?$select=postRemediationDetectionScriptOutput&$filter=managedDevice/deviceName%20eq%20' + "`'" + $inputBox.text + "`'" + '&$expand=managedDevice($select=deviceName,operatingSystem,osVersion,emailAddress)'#Used to get device information that the script ran on 
            $resource = "deviceManagement/deviceHealthScripts/$remediationScriptID/deviceRunStates$deviceInfo"
            $urlPostRemediation = "https://graph.microsoft.com/$graphApiVersion/$graphApiVerison/$($Resource)"
                
        
            #Get information needed from MSGraph call about the Proactive Remediation Device Status
            $deviceStatus = (Invoke-MSGraphRequest -Url $urlPostRemediation -HttpMethod Get).value
                
            $deviceName = $deviceStatus.managedDevice.deviceName
            $userSignedIn = $deviceStatus.managedDevice.emailAddress
            $deviceOS = $deviceStatus.managedDevice.operatingSystem
            $deviceOSVersion = $deviceStatus.managedDevice.osVersion
            $laps = $deviceStatus.postRemediationDetectionScriptOutput -replace '(?=;).*'
            $lastChanged = $deviceStatus.postRemediationDetectionScriptOutput -replace '^[^,]*Changed '
        
            # Adding properties to object
            $deviceInfoDisplay = New-Object PSCustomObject
        
            # Add collected properties to object
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "Username" -Value $psdAdminUsername
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "Password" -Value $laps
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "Password Changed" -Value $lastChanged
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "Device Name" -Value $deviceName
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "User" -Value $userSignedIn
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "Device OS" -Value $deviceOS
            $deviceInfoDisplay | Add-Member -MemberType NoteProperty -Name "OS Version" -Value $deviceOSVersion
        
            If($deviceInfoDisplay.Password) {
                $outputBox.text = ($deviceInfoDisplay | Out-String).Trim()
            } Else {
                $TestResult= "Failed to gather information. Please check the device name."
                $outputBox.text=$TestResult
            }
        } Else {
        $TestResult= "Device name has not been provided. Please type a device name and then click Get `"Device`""
        $outputBox.text=$TestResult
    }
}
                
        
        ###################### CREATING PS GUI TOOL #############################
         
ConnectMSGraphModule
        
#### Form settings #################################################################
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  
        
$Form = New-Object System.Windows.Forms.Form
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle #Modifies the window border
$Form.Text = "leanLAPS"
$Form.Size = New-Object System.Drawing.Size(925,290)  
$Form.StartPosition = "CenterScreen" #Loads the window in the center of the screen
$Form.BackgroundImageLayout = "Zoom"
$Form.MaximizeBox = $False
$Form.WindowState = "Normal"
$Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon = $Icon
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter"){$deviceInformation.PerformClick()}}) #Allow for Enter key to be used as a click
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape"){$Form.Close()}}) #Allow for Esc key to be used to close the form
        
#### Group boxes for buttons ########################################################
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Size(10,10) 
$groupBox.size = New-Object System.Drawing.Size(180,230)
$groupBox.text = "Input Device Name:" 
$Form.Controls.Add($groupBox) 
        
###################### BUTTONS ##########################################################
        
#### Input Box with "Device name" label ##########################################
$inputBox = New-Object System.Windows.Forms.TextBox 
$inputBox.Font = New-Object System.Drawing.Font("Lucida Console",15)
$inputBox.Location = New-Object System.Drawing.Size(15,30) 
$inputBox.Size = New-Object System.Drawing.Size(150,60) 
$inputBox.ForeColor = "DarkGray"
$inputBox.Text = "Device Name"
$inputBox.Add_GotFocus({
    if ($inputBox.Text -eq 'Device Name') {
        $inputBox.Text = ''
        $inputBox.ForeColor = 'Black'
    }
})
$inputBox.Add_LostFocus({
    if ($inputBox.Text -eq '') {
        $inputBox.Text = 'Device Name'
        $inputBox.ForeColor = 'Darkgray'
    }
})
$inputBox.Add_TextChanged({$deviceInformation.Enabled = $True}) #Enable the Device Info button after the end user typed something into the inputbox
$inputBox.TabIndex = 0
$Form.Controls.Add($inputBox)
$groupBox.Controls.Add($inputBox)
        
#### Device Info Button #################################################################
$deviceInformation = New-Object System.Windows.Forms.Button
$deviceInformation.Font = New-Object System.Drawing.Font("Lucida Console",15)
$deviceInformation.Location = New-Object System.Drawing.Size(15,80)
$deviceInformation.Size = New-Object System.Drawing.Size(150,60)
$deviceInformation.Text = "Device Info"
$deviceInformation.TabIndex = 1
$deviceInformation.Add_Click({getDeviceInfo})
$deviceInformation.Enabled = $False #Disable Device Info button until end user types something into the inputbox
$deviceInformation.Cursor = [System.Windows.Forms.Cursors]::Hand
$groupBox.Controls.Add($deviceInformation)
        
###################### CLOSE Button ######################################################
$closeButton = new-object System.Windows.Forms.Button
$closeButton.Font = New-Object System.Drawing.Font("Lucida Console",15)
$closeButton.Location = New-Object System.Drawing.Size(15,150)
$closeButton.Size = New-object System.Drawing.Size(150,60)
$closeButton.Text = "Close"
$closeButton.TabIndex = 2
$closeButton.Add_Click({$Form.close()})
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$groupBox.Controls.Add($closeButton)
        
#### Output Box Field ###############################################################
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Size(200,15) 
$outputBox.Size = New-Object System.Drawing.Size(700,225)
$outputBox.Font = New-Object System.Drawing.Font("Lucida Console",15,[System.Drawing.FontStyle]::Regular)
$outputBox.MultiLine = $True
$outputBox.ScrollBars = "Vertical"
$outputBox.Text = "Type Device name and then click the `"Device Info`" button."
$Form.Controls.Add($outputBox)
        
##############################################
        
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()