#requires -version 5
<#
    .SYNOPSIS
    This script brings a new world of imaging to Microsoft Endpoint Management Configuration Manager Deployments

    .DESCRIPTION
    THis script combines two different aspects of deployments... automated and custom. The process works in tandem with API calls to retrieve dynamic data for automated deployment as well as a custom manual deployment interface.
    This replaces the current process and boot images that are widely used and combine to one dynamic one.

    .INPUTS
    <Inputs if any, otherwise state None>

    .OUTPUTS
    <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

    .NOTES
    Version:        1.0
    Author:         <Name>
    Creation Date:  <Date>
    Purpose/Change: Initial script development
  
    .EXAMPLE
    <Example goes here. Repeat this attribute for more than one example>
#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------
#region Functions

function Write-CMLogEntry {
    param (
        [parameter(Mandatory = $true, HelpMessage = 'Value added to the log file.')]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $true, HelpMessage = 'Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('1', '2', '3')]
        [string]$Severity,
        [parameter(Mandatory = $false, HelpMessage = 'Name of the log file that the entry will written to.')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "$ScriptName-$(get-date -format yyyyMMdd).log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $LogPath -ChildPath $FileName
		
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format 'HH:mm:ss.fff'), '+', (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
		
    # Construct date for log entry
    $Date = (Get-Date -Format 'MM-dd-yyyy')
		
    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DellConFigurationCenter"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
    # Add value to log file
    try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Continue
    }
    catch {
        Write-Warning -Message "Unable to append log entry to DellConfigurationCenter.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

function Start-TaskSequence {
    Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=0)]
		[String]$OSDComputerName,
        [Parameter(Mandatory=$true,Position=1)]
		[String]$MachineObjectOU,
        [Parameter(Mandatory=$true,Position=2)]
		$TaskSequenceID,
        [Parameter(Mandatory=$False,Position=3)]
		[String]$SelectedTS
	)
		$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
        Write-Host $OSDComputerName
        Write-Host $MachineObjectOU
        Write-Host $TaskSequenceID
        Write-Host $SelectedTS
        $tsenv.Value("OSDCOmputerName") = "$OSDComputerName"
        #$tsenv.Value("_SMSTSMachineName") = "$OSDComputerName"
        $tsenv.Value("MACHINEOBJECTOU") = "$MachineObjectOU"
        $tsenv.Value("SMSTSPreferredAdvertID") = "$TaskSequenceID"
}

Function Store-Password {
    param(
        $UserName,
        $Password
        )
    # Need to fix the line below to match your domain
    If ($UserName -notlike "ua\*"){$username = "ua\$UserName"}
    Return New-Object System.Management.Automation.PSCredential ($UserName,$Password)
}

Function Get-StartingLocations {
    param($Locations)
    $StartingLocations = $Locations | Where-Object {$_.display -eq $True }
    Return $StartingLocations
}

Function Get-OUStructure {
    param($OUCampus)
    Write-host $OUCampus
    $SearchBase = $Locations | Where-Object { $_.locationName -eq $OUCampus }
    Write-Host $($SearchBase.campusCode)
    # ********** Add Auth here when availalbe *********
	$OUList = Invoke-RestMethod "$Script:BaseURL/SearchBase/$($SearchBase.campusCode)"
    $OUStructure = $OUList | Select-Object -Property DistinguishedName
    $SearchLength = $($SearchBase.SearchBase).Length + 1
    $objectCollection = @()
    $CustomObject = New-Object PsObject
    Add-Member -InputObject $CustomObject -MemberType NoteProperty -Name 'TSOU' -Value ""
    Add-Member -InputObject $CustomObject -MemberType NoteProperty -Name 'DisplayName' -Value ""
    Foreach ($SearchItem in $OUStructure) {
            $CustomObject = New-Object PsObject
            Add-Member -InputObject $CustomObject -MemberType NoteProperty -Name 'TSOU' -Value ""
            Add-Member -InputObject $CustomObject -MemberType NoteProperty -Name 'DisplayName' -Value ""
            $CleanedUpDisplay = $($($SearchItem.DistinguishedName).substring(0,$($SearchItem.DistinguishedName).Length - $SearchLength)).Replace("OU=","")
            $CustomObject.TSOU = "$($SearchItem.DistinguishedName)"
            $CustomObject.DisplayName =  $CleanedUpDisplay
            $objectCollection += $CustomObject
    }
    # Organize the data better
        Foreach ($object in $objectCollection){
            $temp = $($object.DisplayName).split(",")
            If ($temp.count -eq 2){
                $Object.DisplayName = $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 3) {
                $Object.DisplayName = $temp[2] + "--" + $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 4) {
                $Object.DisplayName = $temp[3] + "--" + $temp[2] + "--" + $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 5) {
                $Object.DisplayName = $temp[4] + "--" + $temp[3] + "--" + $temp[2] + "--" + $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 6) {
                $Object.DisplayName = $temp[5] + "--" + $temp[4] + "--" + $temp[3] + "--" + $temp[2] + "--" + $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 7) {
                $Object.DisplayName = $temp[6] + "--" + $temp[5] + "--" + $temp[4] + "--" + $temp[3] + "--" + $temp[2] + "--" + $temp[1] + "--" + $temp[0]
            } elseif ($temp.count -eq 1) {
                $Object.DisplayName = $temp[0]
            } 
        }
    # Sort the data
    $SortedData = $objectCollection | Sort-Object -Property DisplayName
    Return $SortedData
}

function Test-Credential {
  [CmdletBinding()]
  [OutputType([Bool])]
  param (
    [Parameter(Mandatory = $true,HelpMessage='Please provide a Windows Credential object.')]
    [Alias('PSCredential')]
    [ValidateNotNull()]
    [PSCredential]$Credential,
    [Parameter()]
    [String]$Domain = $Credential.GetNetworkCredential().Domain
  )
  $null = Add-Type -AssemblyName System.DirectoryServices.AccountManagement
  $principalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList (
    [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain
  )
  $networkCredential = $Credential.GetNetworkCredential()
  Write-Output -InputObject $(
    $principalContext.ValidateCredentials(
      $networkCredential.UserName, $networkCredential.Password
    )
  )
  $principalContext.Dispose()
}

Function Start-MainForm {
    $Time = Measure-Command {
    $XMLUserForm.Close()
    # Define the locations for deployments
    $StartingLocations = Get-StartingLocations($locations)
    #Write-Host $StartingLocations.locationName
    #***********************************************************
    # Start the Main Form Processing
    #***********************************************************
    # Create Main frontend form
    $XMLReader = (New-Object System.Xml.XMLNodeReader $Form)
    $XMLForm = [Windows.Markup.XamlReader]::Load($XMLReader)

    # Load Controls for reference later
    $ComputerName = $XMLForm.FindName('textComputerName')
    $CampusLocation = $XMLForm.FindName('comboLocation')
    $OrganizationalUnit = $XMLForm.FindName('comboOU')
    $Tasks = $XMLForm.FindName('comboTS')
    $StartWorkflow = $XMLForm.FindName('buttonStart')
    $CancelWorkflow = $XMLForm.FindName('buttonCancel')
    $MainImage = $XMLForm.FindName('image')

    $CampusLocation.Focus()

    # Add the different locations to the Location Drop Down
    $StartingLocations.locationName | ForEach-Object {$CampusLocation.AddChild($_)}

     

     #Add in the Image
     $MainImage.Source = $iconImage

     $StartWorkflow.add_click({
            #Move Computer to correct OU
            $OUList = Get-OUStructure($CampusLocation.SelectedItem)
            $Destination = $OUList | Where-Object { $_.DisplayName -eq $OrganizationalUnit.SelectedItem }
			# Check to see if the onject already exists in AD
			$Member = Invoke-RestMethod $Script:BaseURL/InAD/$($ComputerName.Text)
            #$Member = $WebService.GetADComputer($SecretKey, $($ComputerName.Text))
			If ($Member -ne $False) { $ComputerExists = $True } else { $ComputerExists = $False }
			
			#If the object already exists, move it to the correct OU
            # *********************** Need to fix this so that it works correctly  ****************************
            If ($ComputerExists -eq $True) { 
                Invoke-RestMethod $Script:BaseURL/MoveComputerObject/$ComputerName/$($Destination.TSOU)
				#$WebService.SetADOrganizationalUnitForComputer($SecretKey, $($Destination.TSOU),$ComputerName)
			}
			
            # If Drive C doesn't exist, Create it and set it correctly
            If (!(Test-Path c:)){ & diskpart /s x:\diskpart.txt | Out-Null }
			
			# Add the Campus Location to a Task Sequence Variable for use further in the Task Sequence
			$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
			$tsenv.Value("Location") = $CampusLocation.SelectedItem
			
            #Kick off the task sequence
            $AssignedAdID = $Script:TaskSequenceList | Where-Object { $_.PackageName -eq $Tasks.SelectedItem }
			Write-host "The computer name used will be: $($ComputerName.Text)"
			Write-Host "The OU it will go in will be: $($Destination.TSOU)"
			Write-Host "The selected task sequence is: $Tasks.SelectedItem"
			Write-Host "The task sequence id that will be used is: $AssignedAdID.AdvertisementID"
            Start-TaskSequence -OSDComputerName $($ComputerName.Text) -MachineObjectOU $($Destination.TSOU) -SelectedTS $Tasks.SelectedItem -TaskSequenceID $AssignedAdID.AdvertisementID
            exit
            })

    $CampusLocation.add_selectionchanged({
        
        param($sender, $args)
        $selected = $sender.SelectedItem
        #Write-Host $Selected
        $OUList = Get-OUStructure($sender.selecteditem)
        $OrganizationalUnit.items.Clear()
        $Tasks.items.Clear()
        ForEach ($OUItem in $OUList) {$OrganizationalUnit.AddChild($($OUItem.DisplayName))}
        $CampusCode = $StartingLocations | Where-Object { $_.locationName -eq $Selected }
        $ComputerName.Text = $($CampusCode).campusCode + "-" + $StartDefaultName

        # Add the Task Sequences Available for Deployment
		If (!$Debug) { $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment }
		If (!$Debug) { $tsenv.Value("CampusLocation") = $($CampusCode.campusCode) }
		
        $AssignedTaskSequences = $TaskSequenceList | where-Object { $_.PackageName.Substring(0,3) -eq $($CampusCode.campusCode) } | Sort-Object -Property PackageName
        ForEach ($TaskSequenceItem in $AssignedTaskSequences) {$Tasks.AddChild($($TaskSequenceItem.PackageName))}
    })

    $CancelWorkflow.add_click({
        #This is what happens when you click the button
        If (!$Debug) { & wpeutil reboot }
        $XMLForm.Close()

        })

    $XMLForm.ShowDialog()
    }
}

Function Start-ErrorMessage {
    $XMLUserForm.Close()

    $XMLErrorReader = (New-Object System.Xml.XMLNodeReader $ErrorForm)
    $XMLErrorForm = [Windows.Markup.XamlReader]::Load($XMLErrorReader)

    # Load Controls for reference later
    $RestartButton = $XMLErrorForm.FindName('buttonRestart')
    $ErrorImage = $XMLErrorForm.FindName('imageLogo')
    $ErrorImage.Source = $iconImage

    $RestartButton.add_click({
         & wpeutil reboot
        $XMLErrorForm.Close()
        break
    })

    $XMLErrorForm.ShowDialog()
}

Function Start-NoServerMessage {
    $XMLUserForm.Close()

    $XMLNoServerReader = (New-Object System.Xml.XMLNodeReader $NoServerForm)
    $XMLNoServerForm = [Windows.Markup.XamlReader]::Load($XMLNoServerReader)

    # Load Controls for reference later
    $RestartButton = $XMLNoServerForm.FindName('buttonRestart')
    $NoServerImage = $XMLNoServerForm.FindName('imageLogo')
    $NoServerImage.Source = $iconImage

    $RestartButton.add_click({
         & wpeutil reboot
        $XMLErrorForm.Close()
        break
    })

    $XMLNoServerForm.ShowDialog()
}

Function Start-AuthenticationForm {
    $XMLoadingForm.Close()
    
    $XMLUserReader = (New-Object System.Xml.XMLNodeReader $AuthForm)
    $XMLUserForm = [Windows.Markup.XamlReader]::Load($XMLUserReader)

    # Load Controls for reference later
    $Password = $XMLUserForm.FindName('passwordBox')
    $SubmitButton = $XMLUserForm.FindName('buttonSubmit')
    $UserName = $XMLUserForm.FindName('textBoxUsername')
    $BadWarning = $XMLUserForm.FindName('labelWarning')
    $AuthImage = $XMLUserForm.FindName('image')
    $AuthImage.Source = $iconImage

    $UserName.Focus()

    $SubmitButton.add_click({
        $Credential = Store-Password -UserName $Username.Text -Password $Password.SecurePassword
        
        $result = Test-Credential -Credential $Credential -Domain $Domain
        
        If (($result -eq $false) -and ($BadPassword -lt 5)){
            $BadWarning.Content = "Warning: Invalid Username or Password!"
            $BadPassword = $BadPassword + 1
        } elseif ($BadPassword -eq 5) {
            $BadWarning.Content = "You have tried too many times, rebooting!"
            Start-Sleep -s 15
            & wpeutil reboot
            Break
        } else {
            $BadWarning.Content = ""
        }

        If ($Result -eq $True){
            $User = $($Credential.Username).substring(3,$($Credential.Username).Length - 3)
            $SecurityAccess = Invoke-RestMethod $Script:BaseURL/VerifyAccess/$User
                If ($SecurityAccess -eq $True){Start-MainForm}
                else {Start-ErrorMessage}
        }
        })

    $XMLUserForm.ShowDialog()
}

Function Start-Loading {
    $XMLLoadingReader = (New-Object System.Xml.XMLNodeReader $LoadingForm)
    $XMLoadingForm = [Windows.Markup.XamlReader]::Load($XMLLoadingReader)
    $LoadImage = $XMLoadingForm.FindName('image')
    $LoadImage.Source = $iconImage
    $XMLoadingForm.Show()
    Write-CMLogEntry -Value "Showing the Message about waiting for an IP Address " -Severity 1
	Write-Host "Showing the Message about waiting for an IP Address "
    DO {$Connected = Test-Connection -ComputerName 137.229.138.132 -Count 1 -Quiet} while ($Connected -ne "True")

    Write-CMLogEntry -Value "Got an IP Address, checking to see if an automated deployment has been configured for this device. " -Severity 1
	Write-Host "Got an IP Address, checking to see if an automated deployment has been configured for this device. "
    # Enter auto start feature here
    Check_For_Automated_Deployment

    If (!$Script:Automated) { 
		Write-CMLogEntry -Value "No Automated deployment found, starting a regular deployment. " -Severity 1 
		Write-Host "No Automated deployment found, starting a regular deployment. "
	}
    If (!$Script:Automated) { Start-AuthenticationForm }
}

function IsIpAddressInRange {
param(
        [string] $ipAddress,
        [string] $fromAddress,
        [string] $toAddress
    )

    $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
    [array]::Reverse($ip)
    $ip = [system.BitConverter]::ToUInt32($ip, 0)

    $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
    [array]::Reverse($from)
    $from = [system.BitConverter]::ToUInt32($from, 0)

    $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
    [array]::Reverse($to)
    $to = [system.BitConverter]::ToUInt32($to, 0)

    $from -le $ip -and $ip -le $to
}

Function Check_For_Automated_Deployment {
    
    # Call the API to see if it is an automated deployment
    # ********** Add Auth here when availalbe *********
    $CurrentDevice = Try { Invoke-RestMethod -Uri "$Script:BaseURL/SerialNumber/$($SerialNumber.SerialNumber)" } catch {}
    #$CurrentIPAddress = Get-NetIPAddress -AddressFamily IPv4 | Select -Property IPAddress
    [XML]$inv32XML = Get-Content -Path "X:\Windows\System32\inv32.xml"
    $connections = $inv32XML.SelectNodes("//L")

    $connections | ForEach-Object {
        if (($_.N -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}") -and ($_.N -notmatch "169\..+")) {
            $CurrentIPAddress = $_.N
        }
    }
    
    $IPWithinRange = IsIpAddressInRange $CurrentIPAddress "192.168.54.0" "192.168.54.254"

    # If device is found, then run the other two rest calls in order to get the data needed.
    If ($CurrentDevice -ne $null){
        $XMLoadingForm.Close()
        # ********** Add Auth here when availalbe *********
        $ApplicationList = Try { Invoke-RestMethod -Uri "$Script:BaseURL/ApplicationLists/$($CurrentDevice.ApplicationProfileID)" } catch {}
        $VariableList = Try { Invoke-RestMethod -Uri "$Script:BaseURL/VariableList/$($CurrentDevice.ApplicationProfileID)" } catch {}
        Write-CMLogEntry -Value 'Device was found when calling the API for the automated deployment' -Severity 1
		Write-Host 'Device was found when calling the API for the automated deployment'
        Write-CMLogEntry -Value "New Hostname will be:      $($CurrentDevice.HostName)" -Severity 1
		Write-Host "New Hostname will be:      $($CurrentDevice.HostName)"
        Write-CMLogEntry -Value "Associated Task Sequence is:      $($CurrentDevice.TaskSequenceName)" -Severity 1
		Write-Host "Associated Task Sequence is:      $($CurrentDevice.TaskSequenceName)"
        Write-CMLogEntry -Value "Associated Task Sequence ID is:      $($CurrentDevice.TaskSequenceID)" -Severity 1
		Write-Host "Associated Task Sequence ID is:      $($CurrentDevice.TaskSequenceID)"
        Write-CMLogEntry -Value "Machine will be stored in:      $($CurrentDevice.TargetOU)" -Severity 1
		Write-Host "Machine will be stored in:      $($CurrentDevice.TargetOU)"
    }
    elseif (($($CurrentDevice.length) -eq 0) -and ($IPWithinRange -eq $True)) {
        $XMLoadingForm.Close()
        # ********** Add Auth here when availalbe *********
        $CurrentDevice = Try { Invoke-RestMethod -Uri "$Script:BaseURL/SerialNumber/DellDefault" } catch {}
        $ApplicationList = Try { Invoke-RestMethod -Uri "$Script:BaseURL/ApplicationLists/$($CurrentDevice.ApplicationProfileID)" } catch {}
        $VariableList = Try { Invoke-RestMethod -Uri "$Script:BaseURL/VariableList/$($CurrentDevice.ApplicationProfileID)" } catch {}
        Write-CMLogEntry -Value 'Device was not found when calling the API for the automated deployment, but falls in the approved IP addresses' -Severity 1
		Write-Host 'Device was not found when calling the API for the automated deployment, but falls in the approved IP addresses'
        Write-CMLogEntry -Value "New Hostname will be:      ua-$($SerialNumber.SerialNumber)" -Severity 1
		Write-Host "New Hostname will be:      ua-$($SerialNumber.SerialNumber)"
        Write-CMLogEntry -Value "Associated Task Sequence is:      $($CurrentDevice.TaskSequenceName)" -Severity 1
		Write-Host "Associated Task Sequence is:      $($CurrentDevice.TaskSequenceName)"
        Write-CMLogEntry -Value "Associated Task Sequence ID is:      $($CurrentDevice.TaskSequenceID)" -Severity 1
		Write-Host "Associated Task Sequence ID is:      $($CurrentDevice.TaskSequenceID)"
        Write-CMLogEntry -Value "Machine will be stored in:      $($CurrentDevice.TargetOU)" -Severity 1
		Write-Host "Machine will be stored in:      $($CurrentDevice.TargetOU)"
        $DellDefault = $True
    }
    else {
        # If the device isn't found return to the previous function and keep going
        Return
    }

    # Secton to run if the device is found stored in the DB

		If (!$Debug) {$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment}
        # Set a task sequence variable to denote that this workflow started from this script
        If (!$Debug) { $tsenv.Value("Automated") = 'True' }
        $Script:Automated = $True
        Write-CMLogEntry -Value 'Set Task Sequence Variable to True meaning that this workflow was ran Automatically' -Severity 1
		Write-Host 'Set Task Sequence Variable to True meaning that this workflow was ran Automatically'
		
        # Section to set task sequence variables if necessary
        If ($VariableList -ne $null ) {
            # Code to set the task sequence variables from the API
            ForEach ($Variable in $VariableList) {
                If ($($Variable.Value) -eq 1 ) { $Value = $True } else { $Value = $False }
                If (!$Debug) { $tsenv.Value("$($Variable.Name)") = $Value }
                Write-CMLogEntry -Value "Setting $($Variable.Name) Task Sequence Variable to $Value " -Severity 1
				Write-Host "Setting $($Variable.Name) Task Sequence Variable to $Value "
            }
        }

        #Reset initial application count to 0
        $Count = 1

        # Section of code to set the task sequence value for the newly installed apps
        foreach ($ApplicationName in $ApplicationList.ApplicationName) {
            $Id = "{0:D2}" -f $Count
            $AppId = "XApplications$Id" 
            If (!$Debug) { $tsenv.Value($AppId) = $ApplicationName }
            Write-CMLogEntry -Value "Task Sequence Variable Name: $AppID     -----   Application: $($ApplicationName) " -Severity 1
			Write-Host "Task Sequence Variable Name: $AppID     -----   Application: $($ApplicationName) "
            $Count = $Count + 1
    
        }
        If ($DellDefault -eq $True) {
            If (!$Debug) { Start-TaskSequence -OSDComputerName "ua-$($SerialNumber.SerialNumber)" -MachineObjectOU "$($CurrentDevice.TargetOU)" -SelectedTS "$($CurrentDevice.TaskSequenceName)" -TaskSequenceID "$($CurrentDevice.TaskSequenceID)" }
        }
        Else {
            If (!$Debug) { Start-TaskSequence -OSDComputerName "$($CurrentDevice.HostName)" -MachineObjectOU "$($CurrentDevice.TargetOU)" -SelectedTS "$($CurrentDevice.TaskSequenceName)" -TaskSequenceID "$($CurrentDevice.TaskSequenceID)" }
        }
}

#endregion

# ---------------------------------------------------------[Initializations]--------------------------------------------------------
#region Initializations
# Set Error Action to Silently Continue
#$ErrorActionPreference = 'SilentlyContinue'
#endregion

# ---------------------------------------------------------[Declarations]---------------------------------------------------------
#region Declarations

# Set Debug Mode
# ********** Add Auth here when availalbe *********
$DebugMode = Invoke-RestMethod $Script:BaseURL/Debug
$Debug = $DebugMode.DebugMode

# Script Author Name
$AuthorName = 'John Yoakum'

# Script Modifier Name
$ModifiedByName = ''

# Script Creation Date
$ScriptCreationDate = '9/5/2019'

# Script Version
$ScriptVersion = '1.0.0'

# Set Automated Variable to Start as False
$Script:Automated = $False

# Stores the full path to this powershell script (e.g. C:\Scripts\ScriptDirectory\ScriptName.ps1)
$ScriptPath =  $MyInvocation.MyCommand.Definition

# Stores the name of this powershell script
$ScriptName = $MyInvocation.MyCommand.Name

# Strips off the trailing '.ps1' value from the script name.
$ScriptName = $ScriptName -replace '.ps1', ''

# Start the Task Sequence Environment
If (!$Debug) {$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment}

# Stores the full path to the directory to store the logs (e.g. C:\Scripts\ScriptDirectory\LOGS)
$LogPath = Join-Path -Path $env:SystemRoot -ChildPath "Temp"

# The log file name is saved to the same directory this script is ran from.
$script:logfile = "$LogPath\$ScriptName-$(get-date -format yyyyMMdd).log"
$script:summaryLogFile = "$LogPath\$ScriptName-Summary-$(get-date -format yyyyMMdd).log"

# Write some log entries
Write-CMLogEntry -Value "Set the log path to:          $script:LogPath" -Severity 1
Write-CMLogEntry -Value "Set the log path to:          $script:logfile" -Severity 1
Write-CMLogEntry -Value "Set the log path to:          $script:summaryLogFile" -Severity 1

# Check to see if the log directory exists, if not then create the log directory. 
#if (!(Test-Path -Path $script:LogPath)) { New-Item -Path $script:LogPath -ItemType directory -Force }

# Check to see if the script is being run interactively
$script:IsInteractive = [environment]::userinteractive

# Defines the header information that is placed at the begin of each log file.
$script:Separator = @"

$('-' * 25)

"@
$script:loginitialized = $false
$script:FileHeader = @"
$separator
***Application Information***
Filename:       $ScriptName
Created by:     $AuthorName
Modified By:    $ModifiedByName
Version:        $ScriptVersion
Date Created:   $ScriptCreationDate
Last Modified:  $(Get-Date -Date (get-item $scriptPath).LastWriteTime -f MM/dd/yyyy)
$separator
"@

# Define the Base URL for API system
$Script:BaseURL = "<UNIVERSALSERVER>"

#Define the Domain for authenticating to
$Domain = '[replace domain name here]'

# Define the search base for each location
# ********** Add Auth here when availalbe *********
$APILocations = Invoke-RestMethod $Script:BaseURL/Locations
$Script:Locations = $APILocations | Select-Object -Property locationName,campusCode,searchBase,display,adwsServer,webService | Sort-Object -Property locationName

# Specify the Simple Front End Web Service Location
$Script:url = $null
$script:AssignedAdID = $null

# Retrieve Machine Info for the Frontend
$SerialNumber = Get-WmiObject -Class win32_bios | Select-Object SerialNumber
$Make = Get-WmiObject -Class win32_ComputerSystem | Select-Object Manufacturer
$Model = Get-WmiObject -Class win32_ComputerSystem | Select-Object Model
$MAC = Get-WmiObject -Class win32_networkadapter | Where-Object {$_.AdapterType -like "Ethernet*"} | Select-Object MACAddress
$StartDefaultName = $($($SerialNumber.SerialNumber).substring($($SerialNumber.SerialNumber).length-7,7)).ToLower()

# Write some log data for the computer that is being worked on.
Write-CMLogEntry -Value "The serial number of the machine is:          $($SerialNumber.SerialNumber)" -Severity 1
Write-Host "The serial number of the machine is:          $($SerialNumber.SerialNumber)"
Write-CMLogEntry -Value "The make of the machine is:          $($Make.Manufacturer)" -Severity 1
Write-Host "The make of the machine is:          $($Make.Manufacturer)"
Write-CMLogEntry -Value "The model of the machine is:          $($Model.Model)" -Severity 1
Write-Host "The model of the machine is:          $($Model.Model)"
Write-CMLogEntry -Value "The mac address of the machine is:          $($MAC.MACAddress)" -Severity 1
Write-Host "The mac address of the machine is:          $($MAC.MACAddress)"

# Load Assembly and Library
$Env:ADPS_LoadDefaultDrive = 0
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
#Import-Module ActiveDirectory

# Initialize the Credential Variable for the script
$Script:Credential = $null

# Initialize the Number of password attempts
$Script:BadPassword = 0

# Get all the available Task Sequences
Write-CMLogEntry -Value "Retrieving all available task sequences and storing them in a variable." -Severity 1
Write-Host "Retrieving all available task sequences and storing them in a variable."
# ********** Add Auth here when availalbe *********
$AvailableTaskSequences = Invoke-RestMethod $Script:BaseURL/TaskSequences
$Script:TaskSequenceList = $AvailableTaskSequences | Select-Object -Property AdvertisementID,PackageName | Sort-Object -Property PackageName

# Initialize the Form Variables for the script
$Script:XMLoadingForm = $null
$Script:XMLUserForm = $null
$Script:XMLForm = $null
$Script:XMLErrorForm = $null
$Script:OUList = $null
$Script:TaskSequenceEnvironment = $null
$Script:BackgroundColor = "#FF235183"
$Script:ForegroundColor = "white"

#Create the image from base64
$StringWithImage = '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'

# Create a streaming image by streaming the base64 string to a bitmap streamsource
$iconImage = New-Object System.Windows.Media.Imaging.BitmapImage
$iconImage.BeginInit()
$iconImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($StringWithImage)
$iconImage.EndInit()
 
# Freeze() prevents memory leaks.
$iconImage.Freeze()

# XAML Authorization Screen
[xml]$AuthForm = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Credentials" Height="314" Width="726" BorderBrush="White" Background="$Script:BaseColor" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Label Name="labelWelcome" Content="Please Enter your Username and Password" HorizontalAlignment="Left" Margin="39,10,0,0" VerticalAlignment="Top" Height="39" Width="411" FontSize="20" FontWeight="Bold" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelUsername" Content="Username:" HorizontalAlignment="Left" Margin="10,66,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelPassword" Content="Password:" HorizontalAlignment="Left" Margin="10,122,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <TextBox Name="textBoxUsername" HorizontalAlignment="Left" Height="37" Margin="118,66,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="332" FontSize="20" Background="$Script:ForegroundColor" />
        <PasswordBox Name="passwordBox" HorizontalAlignment="Left" Margin="118,122,0,0" VerticalAlignment="Top" Width="332" Height="37" FontSize="20" Background="$Script:ForegroundColor" />
        <Button Name="buttonSubmit" Content="Submit" HorizontalAlignment="Left" Margin="300,215,0,0" VerticalAlignment="Top" Width="150" Height="40" FontSize="20" IsDefault="True"/>
        <Label Name="labelWarning" Content="" HorizontalAlignment="Left" Margin="86,173,0,0" VerticalAlignment="Top" FontSize="20" Foreground="#FFD10E0E"/> 
        <Image Name="image" HorizontalAlignment="Left" Height="130" Margin="472,47,0,0" VerticalAlignment="Top" Width="177" />

    </Grid>
</Window>
"@

# XAML Loading Form
[xml]$LoadingForm = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Loading.........." Height="450" Width="800" BorderBrush="$Script:ForegroundColor" Background="$Script:BackgroundColor" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Grid>
        <Label Name="labelWarning" Content="Currently Waiting for an IP Address" HorizontalAlignment="Center" Margin="10,33,0,0" VerticalAlignment="Top" Height="58" Width="684" FontSize="24" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelTSC" Content="Please be patient, we will be there soon." Height="43" Margin="138,96,158,0" VerticalAlignment="Top" FontSize="20" HorizontalAlignment="Center" Foreground="$Script:ForegroundColor"/>
        <Image Name="image" HorizontalAlignment="Left" Height="241" Margin="385,144,0,0" VerticalAlignment="Top" Width="359" />
    </Grid>
</Window>

"@

# XAML Main Form
[xml]$Form = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="IT Services Deployments" Height="480" Width="805" BorderBrush="$Script:ForegroundColor" Background="$Script:BackgroundColor" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="88*"/>
            <ColumnDefinition Width="309*"/>
        </Grid.ColumnDefinitions>
        <TextBox Name="textComputerName" HorizontalAlignment="Left" Margin="322,35,0,0" TextWrapping="Wrap" Text="$($StartDefaultName)" VerticalAlignment="Top" Height="33" FontSize="20" Background="$Script:ForegroundColor" RenderTransformOrigin="0.5,0.5" Width="270" TextOptions.TextFormattingMode="Display" Grid.Column="1" Foreground="$Script:BackgroundColor" Focusable="True" MaxLength="15" />
        <ComboBox Name="comboLocation" HorizontalAlignment="Left" Margin="123,33,0,0" VerticalAlignment="Top" Width="200" FontSize="20" Height="33" Background="$Script:ForegroundColor" BorderBrush="$Script:ForegroundColor" Foreground="$Script:BackgroundColor" Grid.ColumnSpan="2" />
        <Label Name="labelComputerName" Content="Computer Name" HorizontalAlignment="Left" Margin="154,33,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor" Grid.Column="1"/>
        <Label Name="labelLocation" Content="Location" HorizontalAlignment="Left" Margin="10,29,0,0" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <ComboBox Name="comboOU" HorizontalAlignment="Left" Margin="1.429,88,0,0" VerticalAlignment="Top" Width="592" Height="33" Background="$Script:ForegroundColor" BorderBrush="$Script:ForegroundColor" FontSize="20" Grid.Column="1" Foreground="$Script:BackgroundColor"/>
        <Label Name="labelOU" Content="Organization OU" HorizontalAlignment="Left" Margin="10,84,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelTS" Content="Task Sequence" HorizontalAlignment="Left" Margin="10,139,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <ComboBox Name="comboTS" HorizontalAlignment="Left" Margin="1.429,143,0,0" VerticalAlignment="Top" Width="592" Height="33" Background="$Script:ForegroundColor" BorderBrush="$Script:ForegroundColor" FontSize="20" Grid.Column="1" Foreground="$Script:BackgroundColor"/>
        <Label Name="labelNote" Content="Note: If the computer account already exists, it will be moved to the target OU." HorizontalAlignment="Left" Margin="10,193,0,0" VerticalAlignment="Top" FontSize="20" Grid.ColumnSpan="2" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelSN" Content="Serial Number:" HorizontalAlignment="Left" Margin="10,241,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelMake" Content="Make:" HorizontalAlignment="Left" Margin="10,278,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelModel" Content="Model:" HorizontalAlignment="Left" Margin="10,315,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelMAC" Content="MAC Address:" HorizontalAlignment="Left" Margin="10,352,0,0" VerticalAlignment="Top" FontSize="20" Foreground="$Script:ForegroundColor"/>
        <TextBlock Name="textSN" HorizontalAlignment="Left" Margin="0,243,0,0" TextWrapping="Wrap" Text="$($SerialNumber.SerialNumber)" VerticalAlignment="Top" Height="33" FontSize="20" RenderTransformOrigin="0.5,0.5" Width="359" TextOptions.TextFormattingMode="Display" Grid.Column="1" Foreground="$Script:ForegroundColor">
            <TextBlock.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.151"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBlock.RenderTransform>
        </TextBlock>
        <TextBlock Name="textMake" HorizontalAlignment="Left" Margin="0,280,0,0" TextWrapping="Wrap" Text="$($Make.Manufacturer)" VerticalAlignment="Top" Height="33" FontSize="20" RenderTransformOrigin="0.5,0.5" Width="270" TextOptions.TextFormattingMode="Display" Grid.Column="1" Foreground="$Script:ForegroundColor">
            <TextBlock.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.151"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBlock.RenderTransform>
        </TextBlock>
        <TextBlock Name="textModel" HorizontalAlignment="Left" Margin="0,317,0,0" TextWrapping="Wrap" Text="$($Model.Model)" VerticalAlignment="Top" Height="33" FontSize="20" RenderTransformOrigin="0.5,0.5" Width="270" TextOptions.TextFormattingMode="Display" Grid.Column="1" Foreground="$Script:ForegroundColor">
            <TextBlock.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.151"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBlock.RenderTransform>
        </TextBlock>
        <TextBlock Name="textMAC" HorizontalAlignment="Left" Margin="0,354,0,0" TextWrapping="Wrap" Text="$($MAC.MACAddress)" VerticalAlignment="Top" Height="33" FontSize="20" RenderTransformOrigin="0.5,0.5" Width="270" TextOptions.TextFormattingMode="Display" Grid.Column="1" Foreground="$Script:ForegroundColor">
            <TextBlock.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.108"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBlock.RenderTransform>
        </TextBlock>
        <Image Name="image" Grid.Column="1" HorizontalAlignment="Left" Height="130" Margin="370,251,0,0" VerticalAlignment="Top" Width="177" />
        <Button Name="buttonStart" Content="Start Task" Grid.Column="1" HorizontalAlignment="Left" Height="37" Margin="241,398,0,0" VerticalAlignment="Top" Width="176" Foreground="$Script:BackgroundColor" FontSize="20" FontWeight="Bold" IsDefault="True"/>
        <Button Name="buttonCancel" Content="Cancel Task" Grid.Column="1" HorizontalAlignment="Left" Height="37" Margin="432,398,0,0" VerticalAlignment="Top" Width="176" Foreground="$Script:BackgroundColor" FontSize="20" FontWeight="Bold"/>
    </Grid>
</Window>
"@

# XAML Error Form
[xml]$ErrorForm = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Unauthorized to Deploy Task Sequences" Height="450" Width="800" BorderBrush="$Script:ForegroundColor" Background="$Script:BackgroundColor" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Label Name="labelWarning" Content="I'm Sorry. You are not authorized to deploy any task sequences." HorizontalAlignment="Center" Margin="10,33,0,0" VerticalAlignment="Top" Height="58" Width="684" FontSize="24" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelTSC" Content="If you think you have reached this page in error, &#xA;please contact the IT Services Technical Support Center." Height="75" Margin="138,96,158,0" VerticalAlignment="Top" FontSize="20" HorizontalAlignment="Center" Foreground="$Script:ForegroundColor"/>
        <Button Name="buttonRestart" Content="Restart Computer" HorizontalAlignment="Left" Height="37" Margin="550,356,0,0" VerticalAlignment="Top" Width="194" FontSize="20"/>
        <Image Name="imageLogo" HorizontalAlignment="Left" Height="174" Margin="60,190,0,0" VerticalAlignment="Top" Width="237" />

    </Grid>
</Window>

"@

# XAML No Server Form
[xml]$NoServerForm = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="No Server Available" Height="450" Width="800" BorderBrush="$Script:ForegroundColor" Background="$Script:BackgroundColor" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Label Name="labelWarning" Content="I'm Sorry. There are currently no servers available to process this request." HorizontalAlignment="Center" Margin="10,33,0,0" VerticalAlignment="Top" Height="58" Width="684" FontSize="24" Foreground="$Script:ForegroundColor"/>
        <Label Name="labelTSC" Content="If you think you have reached this page in error, &#xA;please contact the IT Services Technical Support Center." Height="75" Margin="138,96,158,0" VerticalAlignment="Top" FontSize="20" HorizontalAlignment="Center" Foreground="$Script:ForegroundColor"/>
        <Button Name="buttonRestart" Content="Restart Computer" HorizontalAlignment="Left" Height="37" Margin="550,356,0,0" VerticalAlignment="Top" Width="194" FontSize="20"/>
        <Image Name="imageLogo" HorizontalAlignment="Left" Height="174" Margin="60,190,0,0" VerticalAlignment="Top" Width="237" />

    </Grid>
</Window>

"@

#endregion

#-----------------------------------------------------------[Execution]------------------------------------------------------------
#region Execution

Start-Loading

#endregion