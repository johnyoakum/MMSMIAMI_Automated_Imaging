$Navigation = @(
    New-UdListItem -Label "Home" -OnClick {Invoke-UDRedirect '/Provisioning-Portal'}
    New-UdListItem -Label "Hardware Devices" -OnClick {Invoke-UDRedirect '/Hardware-Devices'}
    New-UDListItem -Label "Application Profiles" -OnClick {Invoke-UDRedirect '/Application-Profiles'}
    New-UDListItem -Label "Hardware Remote Codes" -OnClick {Invoke-UDRedirect '/Hardware-Remote-Codes'}
)
$Pages = @()
# Change the base URL below to specify API locations
$BaseURL = "<UNIVERSALSERVER>"
$SQLServer = "<SQLHOST>"
$SQLDB = "<SQLDB>"

$Pages += New-UDPage -Name "Provisioning Portal" -Title "Provisioning Portal" -Content {
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Welcome to the Automated Deployment Provisioning Portal" -Variant "h5"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "This site is designed to assist in automating the imaging of devices across the Facility." -Variant "subtitle1"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Use the navigation at the side to go to the pages that you would like to go to." -Variant "subtitle1"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Use the 'Hardware Devices' page to add, remove, or modify the hardware devices and what Task Sequences, Application Profiles, OU for Devices, Hostname, and Serial Numbers for each device." -Variant "subtitle1"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Use the 'Application Profiles' page to add, remove, or modify the Application Profiles. This is where you specify all the applications and variables you would like for that profile in which you will apply to the deviecs." -Variant "subtitle1"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Use the 'Hardware Remote Codes' page to see the data needed in order to remote into a machine." -Variant "subtitle1"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "If you have any issues, please contact the System Engineering Team." -Variant "subtitle1"
} -NavigationLayout permanent -Navigation $Navigation
$Pages += New-UDPage -Name "Hardware Devices" -Title "Provisioning Portal" -Content {
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Hardware Provisioning" -Variant "h3"
    New-UDElement -tag 'p' # This adds a blank line
    $TaskSequences = Invoke-RestMethod $BaseURL/TaskSequences
    $ApplicationProfiles = Invoke-RestMethod $BaseURL/ApplicationProfile
    $table = New-Object System.Data.DataTable 'SelectedServices'
    $newcol = New-Object System.Data.DataColumn HardwareID,([string]);$table.Columns.add($newcol)
    New-UDDynamic -Id 'HardwareDevices' -Content{
    New-UDTable -Title 'Computer Hardware' -ShowSelection -Dense -LoadData {
        $TableData1 = ConvertFrom-Json $Body
        $OrderBy = $TableData1.orderBy.field
        If ($OrderBy -eq $null){
            $OrderBy = 'HostName'
            }
        $OrderDirection = $TableData1.orderDirection
        If ($OrderDirection -eq $null){
            $OrderDirection = "asc"
            }

        $Where = ""
        If ($TableData1.Filters){
            $Where = "WHERE "
            ForEach($filter in $TableData1.Filters){
                $Where += $filter.id + " LIKE '%" + $filter.value + "%' AND "
                }
            $Where += " 1 = 1"
            }
        $PageSize = $TableData1.PageSize
        # Calculate the number of rows to skip
        $Offset = $TableData1.Page * $PageSize
        $CountHW = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "Select COUNT(*) as count from dbo.Hardware $WHERE" 
            $AllHardware = @()
            $HardwareData = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "Select a.Id,SerialNumber,TargetOU,HostName,TaskSequenceID,ApplicationProfileName,a.applicationProfileID,a.Notes from dbo.Hardware as a left join dbo.ApplicationProfile as b on b.Id = a.ApplicationProfileID $WHERE ORDER BY $OrderBy $OrderDirection OFFSET $Offset ROWS FETCH NEXT $PageSize ROWS ONLY"
            ForEach ($HardwareItem in $HardwareData){
                $TempID = $HardwareItem.TaskSequenceID
                $TempAppID = $HardwareItem.ApplicationProfileID
                $AllHardware += @{
                    HostName = $HardwareItem.HostName
                    SerialNumber = $HardwareItem.SerialNumber
                    TaskSequenceName = $($TaskSequences | Where-Object {$_.AdvertisementID -eq $TempID}).PackageName
                    ApplicationProfileName = $($ApplicationProfiles | Where-Object {$_.ID -eq $TempAppID}).ApplicationProfileName
                    TaskSequenceId = $TempID
                    ApplicationProfileId = $TempAppID
                    HardwareID = $HardwareItem.Id
                    TargetOU = $HardwareItem.TargetOU
                    Notes = $HardwareItem.Notes
                }
            }
            $AllHardware | Out-UDTableData -Page $TableData1.Page -TotalCount $CountHW.count -Properties $TableData1.Properties
        } -Columns @(
            New-UDTableColumn -Property 'HostName' -Title 'Computer Name' -Sort -Filter -DefaultSortColumn -IncludeInExport
            New-UDTableColumn -Property 'SerialNumber' -Title 'Serial Number' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'TargetOU' -Title 'Destination OU' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'TaskSequenceName' -Title 'Task Sequence' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'ApplicationProfileName' -Title 'Application Profile' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'HardwareID' -Title 'Action' -Render {
                New-UDButton -Icon (New-UDIcon -Icon edit) -OnClick {
                    Show-UDModal -Persistent -FullWidth -MaxWidth 'md' -Content {
                        New-UDTypography -Text "Edit Hardware Entry" -variant 'h4'
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTextBox -Id 'txtHardwareID' -Disabled -Value $Eventdata.HardwareID
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTextBox -Id 'txtHostName' -Label 'Computer Name' -Value $Eventdata.HostName
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTextBox -Id 'txtSerialNumber' -Label 'Serial Number' -Value $EventData.SerialNumber
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTextBox -Id 'txtOU' -Label 'Destination OU' -FulLWidth -Value $EventData.TargetOU
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDSelect -Id 'comboTaskSequences' -Label 'Task Sequence' -DefaultValue $EventData.TaskSequenceID -Option {
                            $AvailableTaskSequences = $TaskSequences | Sort-Object -Property PackageName
                            ForEach ($TaskSequence in $AvailableTaskSequences){
                                New-UDSelectOption -Name $TaskSequence.PackageName -Value $TaskSequence.AdvertisementID
                            }
                        }
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDSelect -Id 'comboApplicationProfile' -Label 'Application Profile' -DefaultValue $EventData.ApplicationProfileID -Option {
                            $AllApplicationProfiles = $ApplicationProfiles | Sort-Object -Property ApplicationProfileName
                            ForEach ($Profile in $AllApplicationProfiles) {
                                New-UDSelectOption -Name $Profile.ApplicationProfileName -Value $Profile.ID
                            }
                        }
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTextBox -Id 'txtNotes' -Label 'Notes' -Value $EventData.Notes -Multiline -Rows 4 -FullWidth
                    } -Footer {
                        New-UDButton -Text "Update Computer" -Icon (New-UDIcon -Icon plus_square -Color 'green' -Size 'lg') -OnClick {
                            $NewHardwareID = $(Get-UDElement -Id 'txtHardwareID').Value
                            $NewHostName1 = $(Get-UDElement -Id 'txtHostName').Value
                            $NewTargetOU1 = $(Get-UDElement -Id 'txtOU').Value
                            $NewSerialNumber1 = $(Get-UDElement -Id 'txtSerialNumber').Value
                            $NewTaskSequence1 = $(Get-UDElement -Id 'comboTaskSequences').Value
                            If ($NewTaskSequence1 -eq $null -or $NewTaskSequence1 -eq '') {
                                $NewTaskSequence1 = $($EventData.TaskSequenceID)
                            }
                            $NewApplicationProfile1 = $(Get-UDElement -Id 'comboApplicationProfile').Value
                            If ($NewApplicationProfile1 -eq $null -or $NewApplicationProfile1 -eq '') {
                                $NewApplicationProfile1 = $EventData.ApplicationProfileID
                            }
                            $NewNotes1 = $(Get-UDElement -Id 'txtNotes').Value
                            # Adding section to check to see if serial number already exists
                            $DoesSerialExist = Invoke-RestMethod $BaseURL/SerialNumber/$NewSerialNumber1
                            If ($DoesSerialExist.Count -gt 0 ) { $SerialExist = $True } else { $SerialExist = $False }
                            If ($NewHostName1 -eq $null -or $NewHostName1 -eq ''){
                                Show-UDToast -Message "Hostname must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($NewHostName1.Length -gt 15){
                                Show-UDToast -Message "Hostname must not be more than 15 characters." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($NewSerialNumber1 -eq $null -or $NewSerialNumber1 -eq '') {
                                Show-UDToast -Message "Serial Number must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($SerialExist -eq $True ) {
                                Show-UDToast -Message "Serial Number already exists in the system. Please enter a new serial number" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($NewTargetOU1 -eq $null -or $NewTargetOU1 -eq '') {
                                Show-UDToast -Message "Destination OU must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ((Invoke-RestMethod "$BaseURL/CheckOU/$NewTargetOU1") -eq $False) {
                                Show-UDToast -Message "Destination OU does not exist, please specify an existing OU." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($NewTaskSequence11 -eq 0) {
                                Show-UDToast -Message "You must choose an Task Sequence" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($NewApplicationProfile1 -eq 0) {
                                Show-UDToast -Message "You must choose an Application Profile" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } else {
                                Try {
                                    #Show-UDToast "TaskSequenceID = '$NewTaskSequence1', ApplicationProfileID = $NewApplicationProfile1" -Duration 60000 -Position 'bottomCenter'
                                    Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "UPDATE dbo.Hardware 
                                    SET SerialNumber = '$($NewSerialNumber1)', HostName = '$($NewHostName1)', TargetOU = '$($NewTargetOU1)', TaskSequenceID = '$($NewTaskSequence1)', ApplicationProfileID = $($NewApplicationProfile1), Notes = '$($NewNotes1)', UpdateUser = '$User', UpdateDate = '$(Get-Date)' 
                                    WHERE Id = $($NewHardwareID)" -ErrorAction stop
                                    #Show-UDToast -Message $TestSQL -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                                    #$TestSQL
                                    Sync-UDElement -Id 'HardwareDevices'
                                    Hide-UDModal
                                } catch {
                                    Show-UDToast -Message "Failed to update Computer Object" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                                }
                            }
                        }
                        New-UDButton -Text "Close" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick { 
                            Hide-UDModal
                        }
                    }
                }   
                New-UDButton -Icon (New-UDIcon -Icon trash) -OnClick {
                    Show-UDModal -Content { 
                        New-UDTypography -Text "Are you sure you wish to delete this entry?" -variant 'h5'
                        New-UDElement -tag 'p' # This adds a blank line
                        New-UDTypography -Text "$($EventData.HostName)" -variant 'h5'
                    } -footer {
                        New-UDButton -Text "YES" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                            Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "DELETE FROM dbo.Hardware WHERE Id = $($EventData.HardwareId)"
                            Show-UDToast -Message "You have successfully deleted $($EventData.HostName)"
                            Hide-UDModal
                        }
                        New-UDButton -Text "NO" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                            Hide-UDModal
                        }
                    }
                }
            }
            ) -showSort -showPagination -showFilter -showExport -OnRowSelection {
                $Item = $EventData
                #$Item | Export-CSV C:\temp\hardwaretesting.csv
                If ($($Item.Selected) -eq $true){
                    #Show-UDToast -Message "$($Item.SerialNumber)"
                    $row = $table.NewRow()
                    $row.HardwareID = "$($Item.SerialNumber)"
                    $table.rows.add($row)
                } else {
                    $table.Select("HardwareID = '" + $($Item.SerialNumber) + "'").Delete()
                }
            }
        }
    New-UDButton -Icon (New-UDIcon -Icon plus -Size '2x') -Text 'Add Single Computer' -OnClick {
        Show-UDModal -Persistent -FullWidth -MaxWidth 'md' -Content {
            New-UDTypography -Text "Add Hardware Entry" -variant 'h4'
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'etxtHostName' -Label 'Computer Name'
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'etxtSerialNumber' -Label 'Serial Number'
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'etxtOU' -Label 'Destination OU' -FulLWidth
            New-UDElement -tag 'p' # This adds a blank line
            New-UDSelect -Id 'ecomboTaskSequences' -Label 'Task Sequence' -DefaultValue 0 -Option {
                $AvailableTaskSequences = $TaskSequences | Sort-Object -Property PackageName
                New-UDSelectOption -Name 'Choose a Task Sequence' -Value 0
                ForEach ($TaskSequence in $AvailableTaskSequences){
                    New-UDSelectOption -Name $TaskSequence.PackageName -Value $TaskSequence.AdvertisementID
                }
            }
            New-UDElement -tag 'p' # This adds a blank line
            New-UDSelect -Id 'ecomboApplicationProfile' -Label 'Application Profile' -DefaultValue 0 -Option {
                $AllApplicationProfiles = $ApplicationProfiles | Sort-Object -Property ApplicationProfileName
                New-UDSelectOption -Name 'Choose an Application Profile' -value 0
                ForEach ($Profile in $AllApplicationProfiles) {
                    New-UDSelectOption -Name $Profile.ApplicationProfileName -Value $Profile.ID
                }
            }
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'eNotes' -Label 'Notes' -FulLWidth -Multiline -Rows 4
        } -Footer {
            New-UDButton -Text "Add Computer" -Icon (New-UDIcon -Icon plus_square -Color 'green' -Size 'lg') -OnClick {
                $NewHostName = (Get-UDElement -Id 'etxtHostName').Value
                $NewTargetOU = (Get-UDElement -Id 'etxtOU').Value
                $NewSerialNumber = (Get-UDElement -Id 'etxtSerialNumber').Value
                $NewTaskSequence = (Get-UDElement -Id 'ecomboTaskSequences').Value
                $NewApplicationProfile = (Get-UDElement -Id 'ecomboApplicationProfile').Value
                $NewNotes = (Get-UDElement -Id 'eNotes').Value
                $DoesSerialExist1 = Invoke-RestMethod $BaseURL/SerialNumber/$NewSerialNumber
                If ($DoesSerialExist1.Count -gt 0 ) { $SerialExist1 = $True } else { $SerialExist1 = $False }
                If ($NewHostName -eq $null -or $NewHostName -eq ''){
                    Show-UDToast -Message "Hostname must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewHostName.Length -gt 15){
                    Show-UDToast -Message "Hostname must not be more than 15 characters." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewSerialNumber -eq $null -or $NewSerialNumber -eq '') {
                    Show-UDToast -Message "Serial Number must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($SerialExist1 -eq $True ) {
                    Show-UDToast -Message "Serial Number already exists in the system. Please enter a new serial number" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewTargetOU -eq $null -or $NewTargetOU -eq '') {
                    Show-UDToast -Message "Destination OU must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ((Invoke-RestMethod "$BaseURL/CheckOU/$NewTargetOU") -eq $False) {
                    Show-UDToast -Message "Destination OU does not exist, please specify an existing OU." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewTaskSequence -eq 0) {
                    Show-UDToast -Message "You must choose an Task Sequence" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewApplicationProfile -eq 0) {
                    Show-UDToast -Message "You must choose an Application Profile" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } else {
                    Try {
                        Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "INSERT INTO dbo.Hardware (SerialNumber,HostName,TargetOU,TaskSequenceID,ApplicationProfileID,Notes,CreateUser,CreateDate,UpdateUser,UpdateDate) VALUES ('$NewSerialNumber', '$NewHostName', '$NewTargetOU', '$NewTaskSequence', $NewApplicationProfile,'$NewNotes','$User','$(Get-Date)','$User','$(Get-Date)')"
                        Sync-UDElement -Id 'HardwareDevices'
                        Hide-UDModal
                    } catch {
                        Show-UDToast -Message "Failed to create Computer Object." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                    }
                }
            }
            New-UDButton -Text "Close" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick { 
                Hide-UDModal
            }
        }
    }
    New-UDButton -Icon (New-UDIcon -Icon plus -Size '2x') -Text 'Add Computers in Bulk' -OnClick {
        Show-UDModal -FullWidth -MaxWidth 'md' -Content {
            New-UDTypography -Text "Add Hardware Entries in Bulk" -variant 'h4'
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'btxtOU' -Label 'Destination OU' -FulLWidth
            New-UDElement -tag 'p' # This adds a blank line
            New-UDSelect -Id 'bcomboTaskSequences' -Label 'Task Sequence' -DefaultValue 0 -Option {
                $AvailableTaskSequences = $TaskSequences | Sort-Object -Property PackageName
                New-UDSelectOption -Name 'Choose a Task Sequence' -Value 0
                ForEach ($TaskSequence in $AvailableTaskSequences){
                    New-UDSelectOption -Name $TaskSequence.PackageName -Value $TaskSequence.AdvertisementID
                }
            }
            New-UDElement -tag 'p' # This adds a blank line
            New-UDSelect -Id 'bcomboApplicationProfile' -Label 'Application Profile' -DefaultValue 0 -Option {
                $AllApplicationProfiles = $ApplicationProfiles | Sort-Object -Property ApplicationProfileName
                New-UDSelectOption -Name 'Choose an Application Profile' -value 0
                ForEach ($Profile in $AllApplicationProfiles) {
                    New-UDSelectOption -Name $Profile.ApplicationProfileName -Value $Profile.ID
                }
            }
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'bNotes' -Label 'Notes' -FulLWidth -Multiline -Rows 4
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'bComputers' -Label 'Computers to Add' -Multiline -Rows 4 -Fullwidth
            New-UDHTML -Markup "<dl><dt>SerialNumber1,HostName1</dt><dt>SerialNumber2,HostName2</dt><dt>SerialNumber3,HostName3</dt></dl>"
        } -Footer {
            New-UDButton -Text "Add Computers in Bulk" -Icon (New-UDIcon -Icon plus_square -Color 'green' -Size 'lg') -OnClick {
                $NewTaskSequence = (Get-UDElement -Id 'bcomboTaskSequences').Value
                $NewApplicationProfile = (Get-UDElement -Id 'bcomboApplicationProfile').Value
                $NewTargetOU = (Get-UDElement -Id 'btxtOU').Value
                $NewNotes = (Get-UDElement -Id 'bNotes').Value
                $NewComputers = (Get-UDElement -Id 'bComputers').Value
                $ComputersToAdd = @()
                $AllNewComputers = $NewComputers -Split "`n"
                ForEach ( $Item in $AllNewComputers ) {
                    #Write-Host "Item is: $Item"
                    $ComputersToAdd += [PSCustomObject]@{
                        HostName         = $($Item.Split(','))[1]
                        SerialNumber = $($Item.Split(','))[0]
                    }
                }
                if ($NewTargetOU -eq $null -or $NewTargetOU -eq '') {
                    Show-UDToast -Message "Destination OU must not be empty." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ((Invoke-RestMethod "$BaseURL/CheckOU/$NewTargetOU") -eq $False) {
                    Show-UDToast -Message "Destination OU does not exist, please specify an existing OU." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewTaskSequence -eq 0) {
                    Show-UDToast -Message "You must choose an Task Sequence" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewApplicationProfile -eq 0) {
                    Show-UDToast -Message "You must choose an Application Profile" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } elseif ($NewComputers -eq $null -or $NewComputers -eq ''){
                        Show-UDToast -Message "You must add in computers before you can process them." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                } else {
                    Foreach ($ComputerToAdd in $ComputersToAdd) {
                        $DoesSerialExist2 = Invoke-RestMethod $BaseURL/SerialNumber/$ComputerToAdd.SerialNumber
                        If ($DoesSerialExist2.Count -gt 0 ) { $SerialExist2 = $True } else { $SerialExist2 = $False }
                        If ($ComputerToAdd.Hostname.Length -gt 15) {
                            Show-UDToast -Message "Computer Name with the name of $($ComputerToAdd.Hostname) must be less than 15 characters" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                        } elseif ($SerialExist2 -eq $True ) {
                            Show-UDToast -Message "Serial Number $($ComputerToAdd.SerialNumber) already exists in the system. Please enter a new serial number" -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                        } else {
                            $HostnameExist = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "Select Hostname FROM dbo.Hardware WHERE Hostname = $ComputerToAdd.HostName"
                            $SerialExist = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "Select SerialNumber FROM dbo.Hardware WHERE SerialNumber = $ComputerToAdd.SerialNumber"
                            If ($HostNameExist.Count -gt 0 ){
                                Show-UDToast -Message "$ComputerToAdd.Hostname already exists in the Database, please resolve and try again." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } elseif ($SerialExist.Count -gt 0 ){
                                Show-UDToast -Message "$ComputerToAdd.SerialNumber already exists in the database, please resolve and try again." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                            } else {
                                Try {
                                    Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "
                                    INSERT 
                                        INTO dbo.Hardware 
                                            (SerialNumber,
                                            HostName,
                                            TargetOU,
                                            TaskSequenceID,
                                            ApplicationProfileID,
                                            Notes,
                                            CreateUser,
                                            CreateDate,
                                            UpdateUser,
                                            UpdateDate) 
                                        VALUES 
                                            ('$($ComputerToAdd.SerialNumber)',
                                            '$($ComputerToAdd.Hostname)',
                                            '$($NewTargetOU)',
                                            '$($NewTaskSequence)',
                                            $($NewApplicationProfile),
                                            '$($NewNotes)',
                                            '$($User)',
                                            '$(Get-Date)',
                                            '$($User)',
                                            '$(Get-Date)')
                                    "
                                    Sync-UDElement -Id 'HardwareDevices'
                                    Hide-UDModal
                                } catch {
                                    Show-UDToast -Message "Failed to create Computer Object." -Duration 20000 -MessageColor 'red' -Position 'bottomCenter'
                                }
                                #Hide-UDModal
                            }
                        }
                    }
                }
            }
            New-UDButton -Text "Close" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick { 
                Hide-UDModal
            }
        }
    }
    New-UDButton -Icon (New-UDIcon -Icon minus -Size '2x') -Text 'Delete All Selected Computers' -OnClick {
        Show-UDModal -Content { 
            New-UDTypography -Text "Are you sure you wish to delete the Selected Computers?" -variant 'h5'
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTypography -Text "$EventData.HostName" -variant 'h5' $EventData.HostName 
        } -footer {
            New-UDButton -Text "YES" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                #$values = Get-UDElement -Id "HardwareDevices"
                #$SelectedRows = $( $values.selectedRows )
                ForEach ($Row in $table) {
                    Try {
                        Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "DELETE FROM dbo.Hardware WHERE SerialNumber = '$Row.HardwareID)'"
                        Show-UDToast -Message "You have successfully deleted $($Row.SerialNumber) from the Hardware Devices" -Duration 10000
                    } Catch {
                        Show-UDToast -Message "Failed to delete $Row.SerialNumber from the Hardware Devices" -MessageColor red -Duration 30000
                    }
                }
                Sync-UDElement -Id 'HardwareDevices'
                Hide-UDModal
            }
            New-UDButton -Text "NO" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                Hide-UDModal
            }
        }
    }
} -NavigationLayout permanent -Navigation $Navigation
$Pages += New-UDPage -Name "Application Profiles" -Title "Provisioning Portal" -Content {
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Application Profiles" -Variant "h3"
    New-UDElement -tag 'p' # This adds a blank line  
    New-UDDynamic -Id 'ApplicationProfiles' -Content {
        New-UDTable -Title 'Application Profiles' -Dense -LoadData {
            $TableData = ConvertFrom-Json $Body
            $OrderBy = $TableData.orderBy.field
            If ($OrderBy -eq $null){
                $OrderBy = 'ApplicationProfileName'
                }
            $OrderDirection = $TableData.orderDirection
            If ($OrderDirection -eq $null){
                $OrderDirection = "asc"
                }
            $Where = ""
            If ($TableData.Filters){
                $Where = "WHERE "
                ForEach($filter in $TableData.Filters){
                    $Where += $filter.id + " LIKE '%" + $filter.value + "%' AND "
                    }
                $Where += " 1 = 1"
                }
            $PageSize = $TableData.PageSize
            # Calculate the number of rows to skip
            $Offset = $TableData.Page * $PageSize
            $Count = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "Select COUNT(*) as count from dbo.ApplicationProfile $WHERE"
            $HardwareData = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "Select Id,ApplicationProfileName,ApplicationProfileDesc from dbo.ApplicationProfile $WHERE ORDER BY $OrderBy $OrderDirection OFFSET $Offset ROWS FETCH NEXT $PageSize ROWS ONLY" | ForEach-Object {
                    @{
                    AppProfileId = $_.Id
                    ApplicationProfileName = $_.ApplicationProfileName
                    ApplicationProfileDesc = $_.ApplicationProfileDesc
                    }
                }
                $HardwareData | Out-UDTableData -Page $TableData.page -TotalCount $Count.count -Properties $TableData.properties
            }-Columns @(
                New-UDTableColumn -Property 'ApplicationProfilename' -Title 'Application Profile Name' -Sort -Filter -DefaultSortColumn -IncludeInExport
                New-UDTableColumn -Property 'ApplicationProfileDesc' -Title 'Description' -IncludeInExport
                New-UDTableColumn -Property 'AppProfileId' -Title 'Action' -Render {
                    New-UDButton -Icon (New-UDIcon -Icon edit) -OnClick {
                        $ProfileID = $EventData.AppProfileId
                        Invoke-UDRedirect "/Applications-For-Profile?ProfileID=$ProfileID"
                    }   
                    New-UDButton -Icon (New-UDIcon -Icon trash) -OnClick {
                        Show-UDModal -Content { 
                            New-UDTypography -Text "Are you sure you wish to delete this entry?" -variant 'h5'
                            New-UDElement -tag 'p' # This adds a blank line
                            New-UDTypography -Text "$($EventData.ApplicationProfileName)" -variant 'h5'
                        } -footer {
                            New-UDButton -Text "YES" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                                Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "DELETE FROM dbo.ApplicationProfileApplication WHERE ApplicationProfileId = $($EventData.AppProfileId)"
                                Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "DELETE FROM dbo.ApplicationProfileVariable WHERE ApplicationProfileId = $($EventData.AppProfileId)"
                                Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "DELETE FROM dbo.ApplicationProfile WHERE Id = $($EventData.AppProfileId)"
                                Show-UDToast -Message "You have successfully deleted $($EventData.ApplicationProfileName)"
                                Sync-UDElement -Id 'ApplicationProfiles'
                                Hide-UDModal
                            }
                            New-UDButton -Text "NO" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                                Hide-UDModal
                            }
                        }
                    }
                }
                ) -Sort -Paging -Filter -Export
    }
    New-UDButton -Text "Add Application Profile" -Icon (New-UDIcon -Icon plus_square -Color 'green' -Size 'lg') -OnClick {
        Show-UDModal -Content {
            New-UDTextBox -Id 'NewAppProfile' -Label 'Application Profile Name' -FullWidth
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTextBox -Id 'NewProfileDesc' -label 'Description' -Multiline -Rows 2 -FullWidth
            New-UDElement -tag 'p' # This adds a blank line
            New-UDTypography -Text 'When you click OK, it will take you to a new page so that you can add applications' -variant 'h6'
            New-UDElement -tag 'p' # This adds a blank line
        } -Footer {
            
            New-UDButton -Text "OK" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                $AddProfileName = $(Get-UDElement -Id 'NewAppProfile').value
                $AddProfileDesc = $(Get-UDElement -Id 'NewProfileDesc').value
                If ($AddProfileName -eq $null -or $AddProfileName -eq '') {
                    Show-UDToast -Message 'You did not add a new profile name. Please do so and try again.' -MessageColor 'red' -Duration 10000
                } else {
                    $AppProfileReturn = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SQLDB -Query "INSERT INTO dbo.ApplicationProfile (ApplicationProfileName,ApplicationProfileDesc,CreateUser,CreateDate,UpdateUser,UpdateDate) VALUES ('$AddProfileName','$AddProfileDesc','$User','$(Get-Date)','$User','$(Get-Date)');Select SCOPE_IDENTITY();"
                    $CreatedRow = $AppProfileReturn[0]
                    Invoke-UDRedirect "/Applications-For-Profile?ProfileID=$CreatedRow"
                    Hide-UDModal
                }
            }
            New-UDButton -Text "CANCEL" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                Hide-UDModal
            }
        }
    }
} -NavigationLayout permanent -Navigation $Navigation
$Pages += New-UDPage -Name "Hardware Remote Codes" -Title "Provisioning Portal" -Id "HardwareRemoteCode" -Content {
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "On this page, you should be able to see all the available remote codes that were populated through the imaging process. This will allow you to connect to device remotely during imaging." -Variant "h5"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDElement -tag 'p' # This adds a blank line
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTable -Title 'Computer Hardware' -Id 'HardwareDevices' -LoadData {
        $TableData = ConvertFrom-Json $Body
        $OrderBy = $TableData.orderBy.field
        If ($OrderBy -eq $null){
            $OrderBy = 'SerialNumber'
        }
        $OrderDirection = $TableData.OrderDirection
        If ($OrderDirection -eq $null){
            $OrderDirection = "asc"
        }
        $Where = ""
        If ($TableData.Filters){
            $Where = "WHERE "
            ForEach($filter in $TableData.Filters){
                $Where += $filter.id + " LIKE '%" + $filter.value + "%' AND "
            }
            $Where += " 1 = 1"
        }
        $PageSize = $TableData.PageSize
        # Calculate the number of rows to skip
        $Offset = $TableData.Page * $PageSize
        $Count = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "Select COUNT(*) as count from dbo.HardwareRemoteCode $WHERE"
        $Data = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "Select SerialNumber,IP,RemoteCode,Port,CreatedDate FROM dbo.HardwareRemoteCode $WHERE ORDER BY $OrderBy $OrderDirection OFFSET $Offset ROWS FETCH NEXT $PageSize ROWS ONLY" | ForEach-Object {
            @{
                SerialNumber = $_.SerialNumber
                IP = $_.IP
                RemoteCode = $_.RemoteCode
                Port = 3389
                CreatedDate = $_.CreatedDate
                VNCPassword = "VNC@dmin"
            }
        }
        $Data | Out-UDTableData -Page $TableData.page -TotalCount $Count.count -Properties $TableData.properties
        } -Columns @(
            New-UDTableColumn -Property 'SerialNumber' -Title 'Serial Number' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'IP' -Title 'IP Address' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'RemoteCode' -Title 'Ticket Number' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'Port' -Title 'Port' -Sort -Filter
            New-UDTableColumn -Property 'CreatedDate' -Title 'Date Created' -Sort -Filter -IncludeInExport
            New-UDTableColumn -Property 'VNCPassword' -Title 'VNC Password' -Sort -Filter
        ) -Sort -Paging -Filter -Export -ShowSelection
    New-UDButton -Text "Delete Entries" -OnClick {
        $values = Get-UDElement -Id "remotecodes"
        $SelectedRows = $( $values.selectedRows )
        ForEach ($Row in $SelectedRows) {
            Try {
                Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "DELETE FROM dbo.HardwareRemoteCode WHERE SerialNumber = '$($($Row).SerialNumber)'"
                Show-UDToast -Message "You have successfully deleted $($($Row).SerialNumber) from the Remote Codes" -Duration 10000
                Sync-UDElement -Id 'DataTable'
            } Catch {
                Show-UDToast -Message "Failed to delete $($($Row).SerialNumber) from the Remote Codes" -MessageColor red -Duration 30000
            }
        }
    }
} -NavigationLayout permanent -Navigation $Navigation
$Pages += New-UDPage -Name "Applications for Profile" -Title "Provisioning Portal" -Id "ProfileApplications" -Content {
    [int]$Cache:AppProfileID = $ProfileID
    $ApplicationProfile = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "SELECT ApplicationProfileName,ApplicationProfileDesc from dbo.ApplicationProfile Where Id = $($Cache:AppProfileID)"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTypography -Text "Listed below are the applications Associated with this Application Profile" -Variant "h5"
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTextBox -Id 'txtProfileName' -Label 'Application Profile Name' -FullWidth -Value $ApplicationProfile.ApplicationProfileName 
    New-UDElement -tag 'p' # This adds a blank line
    New-UDTextBox -Id 'txtDesciption' -Label 'Description' -FullWidth -Value $ApplicationProfile.ApplicationProfileDesc -Multiline -Rows 2
    New-UDElement -tag 'p' # This adds a blank line
    New-UDButton -Icon (New-UDIcon -Icon edit -Size '2x' -Color 'green') -Text 'Update Profile Name or Description and Return to Profile Listing' -OnClick {
        $AppProName = Get-UDElement -Id 'txtProfileName'
        $AppProDesc = Get-UDElement -Id 'txtDescription'
        Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "UPDATE dbo.ApplicationProfile SET ApplicationProfileName = '$AppProName.Value',ApplicationProfileDesc = '$AppProDesc.Value', UpdateUser - '$User', UpdateDate = '$(Get-Date)' where ID = $($Cache:AppProfileID)"
        Invoke-UDRedirect '/Application-Profiles'
    }
    New-UDRow -Columns {
        New-UDGrid -MediumSize 5 -Content {
            New-UDTypography -Text "Applications" -variant 'h5'
            New-UDDynamic -Id 'ApplicationListing' -Content {
                $ApplicationNames = Invoke-RestMethod $BaseURL/AllApplications
                $ApplicationData = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "SELECT Id,PkgID from dbo.ApplicationProfileApplication where ApplicationProfileID = $($Cache:AppProfileID)" | ForEach-Object {
                    $TempID = $_.PkgID
                    @{
                    ApplicationId = $_.Id
                    ApplicationName = $($ApplicationNames | Where-Object {$_.PkgId -eq $TempID}).Name
                    }
                }
                $Columns = @(
                    New-UDTableColumn -Property ApplicationName -Title 'Application Name' -IncludeInExport
                    New-UDTableColumn -Property ApplicationId -Title 'Delete?' -Render {
                        New-UDButton -Icon (New-UDIcon -Icon trash) -OnClick {
                            Show-UDModal -Content { 
                                New-UDTypography -Text "Are you sure you wish to delete this application?" -variant 'h5'
                                New-UDElement -tag 'p' # This adds a blank line
                                New-UDTypography -Text "$($EventData.ApplicationName)" -variant 'h5'
                            } -footer {
                                New-UDButton -Text "YES" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                                    Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "DELETE FROM dbo.ApplicationProfileApplication WHERE Id = $($EventData.ApplicationID)"
                                    Sync-UDElement -Id 'ApplicationListing'
                                    Hide-UDModal
                                }
                                New-UDButton -Text "NO" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                                    Hide-UDModal
                                }
                            }
                        }
                    }
                )
                $AllAppData = $ApplicationData | Sort-Object -Property ApplicationName
                New-UDTable -Data $AllAppData -Columns $Columns -Dense -Export
            }
            New-UDButton -Icon (New-UDIcon -Icon plus -Size '2x') -Text 'Add Application(s)' -OnClick {
                Show-UDModal -Content { 
                    New-UDTypography -Text "Please Choose the Applications you wish to add." -variant 'h5'
                    New-UDElement -tag 'p' # This adds a blank line
                    New-UDSelect -Id 'AppPicker' -DefaultValue '0' -Multiple -Option {
                        $AllApplicationNames = Invoke-RestMethod $BaseURL/AllApplications
                        $AllApplicationsAvailable = $AllApplicationNames | Sort-Object -Property Name
                        ForEach ($AllAppsAvail in $AllApplicationsAvailable) {
                            New-UDSelectOption -Name $AllAppsAvail.Name -Value $AllAppsAvail.PkgId
                        }
                    }
                } -footer {
                    New-UDButton -Text "OK" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                        $AppsChosen = Get-UDElement -Id 'AppPicker'
                        #If ($AppsChosen.Values) {
                        $NumberOfApps = $AppsChosen.Value.Count - 1
                        $ArrayOfApps = $AppsChosen.Value
                        If ($NumberOfApps -gt 0) {
                            #Do something with the values
                            $ChosenApps = $ArrayOfApps | Where-Object { $_ -ne 0 }
                            ForEach ($App in $ChosenApps) {
                                Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "INSERT INTO dbo.ApplicationProfileApplication (ApplicationProfileId,PkgId,CreateUser,CreateDate) VALUES ($($Cache:AppProfileID),'$App','$User','$(Get-Date)')"
                            }
                            Sync-UDElement -Id 'ApplicationListing'
                            Hide-UDModal
                        } else {
                            Show-UDToast -Message 'You did not choose any applications' -Duration 10000
                        }
                    }
                    New-UDButton -Text "CANCEL" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                        Hide-UDModal
                    }
                }
            }
        }
        New-UDGrid -MediumSize 1 -Content {}
        New-UDGrid -MediumSize 6 -Content {
            New-UDTypography -Text "Variables" -variant 'h5'
            New-UDDynamic -Id 'VariableListing' -Content {
                $VariableData = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "SELECT Id,Name,Value from dbo.ApplicationProfileVariable where ApplicationProfileID = $($Cache:AppProfileID)" | ForEach-Object {
                    @{
                    VariableId = $_.Id
                    VariableName = $_.Name
                    VariableValue = If ($_.Value -eq 1 ) {"True"} else {"False"}
                    }
                }
                $Columns = @(
                    New-UDTableColumn -Property VariableName -Title 'Variable Name'
                    New-UDTableColumn -Property VariableValue -Title 'Value'
                    New-UDTableColumn -Property VariableId -Title 'Delete?' -Render {
                        New-UDButton -Icon (New-UDIcon -Icon trash) -OnClick {
                            Show-UDModal -Content { 
                                New-UDTypography -Text "Are you sure you wish to delete this application?" -variant 'h5'
                                New-UDElement -tag 'p' # This adds a blank line
                                New-UDTypography -Text "$($EventData.VariableName)" -variant 'h5'
                            } -footer {
                                New-UDButton -Text "YES" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                                    Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "DELETE FROM dbo.ApplicationProfileVariable WHERE Id = $($EventData.VariableID)"
                                    Sync-UDElement -Id 'VariableListing'
                                    Hide-UDModal
                                }
                                New-UDButton -Text "NO" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                                    Hide-UDModal
                                }
                            }
                        }
                    }
                )
                New-UDTable -Data $VariableData -Columns $Columns -Dense
            }
            New-UDButton -Icon (New-UDIcon -Icon plus -Size '2x') -Text 'Add Variable(s)' -OnClick {
                Show-UDModal -Content { 
                    New-UDTypography -Text "Please Enter the Variable you wish to add." -variant 'h5'
                    New-UDElement -tag 'p' # This adds a blank line
                    New-UDTextBox -Label 'Variable Name' -Id 'VariableName'
                    New-UDElement -tag 'p' # This adds a blank line
                    New-UDSelect -Id 'VariableValue' -DefaultValue 9 -Option {
                        New-UDSelectOption -Name 'Choose Value' -Value 9
                        New-UDSelectOption -Name 'True' -Value 1
                        New-UDSelectOption -Name 'False' -Value 0
                    }
                } -footer {
                    New-UDButton -Text "OK" -Icon (New-UDIcon -Icon check_circle -Color 'green' -Size 'lg') -OnClick {
                        $AddVariableName = $(Get-UDElement -Id 'VariableName').value
                        $AddVariableValue = $(Get-UDElement -Id 'VariableValue').value
                        Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDB -Query "INSERT INTO dbo.ApplicationProfileVariable (Name,Value,ApplicationProfileID,CreateUser,CreateDate) VALUES ('$AddVariableName',$AddVariableValue,$Cache:AppProfileID,'$User','$(Get-Date)')"
                        Sync-UDElement -Id 'VariableListing'
                        Hide-UDModal
                    }
                    New-UDButton -Text "CANCEL" -Icon (New-UDIcon -Icon times_circle -Color 'red' -Size 'lg') -OnClick {
                        Hide-UDModal
                    }
                }
            }
        }
    }
} -NavigationLayout permanent -Navigation $Navigation

New-UDDashboard -Title "Provisioning Portal" -Pages $Pages