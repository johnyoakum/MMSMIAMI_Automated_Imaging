New-PSUEndpoint -Url "/SerialNumber/:serialnumber" -Endpoint {
param($serialnumber)
    $SN = "N'$serialnumber'"

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "EXEC Prov_GetProvisionGroupHardware @SerialNumber=$SN" -Verbose | ConvertTo-Json
} 
New-PSUEndpoint -Url "/ApplicationLists/:applicationid" -Endpoint {
param($applicationid)
    $appid = $applicationid -as [int]

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "EXEC Prov_GetApplicationProfileAppsSynced @ApplicationProfileID=$appid" -Verbose | ConvertTo-Json
} 
New-PSUEndpoint -Url "/VariableList/:variableid" -Endpoint {
param($variableid)
    $varid = $variableid -as [int]

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "EXEC Prov_GetApplicationProfileVars @ApplicationProfileID=$varid" -Verbose | ConvertTo-Json
} 
New-PSUEndpoint -Url "/RemoteControl" -Method "POST" -Endpoint {
param($SerialNumber,$RemoteCode,$IP,$Port)
    $SN = "N'$SerialNumber'"
    $RC = "N'$RemoteCode'"
    $IPAddress = "N'$IP'"
    $RemotePort = "N'$Port'"

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "EXEC Prov_HardwareRemoteCodeAdd @SerialNumber=$SN,@RemoteCode=$RC,@IP=$IPAddress,@Port=$RemotePort"
} 
New-PSUEndpoint -Url "/RemoveRemote/:serialnumber" -Endpoint {
param($serialnumber)

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "EXEC Prov_HardwareRemoteCodeDelete @SerialNumber=$serialnumber"
} 
New-PSUEndpoint -Url "/InAD/:Hostname" -Endpoint {
param($Hostname)
    $ComputerExist = ""
    Try {$ComputerExist = Get-ADComputer -Identity $Hostname }
    Catch {$ComputerExist = $False}
    If ( [string]::IsNullOrWhiteSpace($ComputerExist) ) { $ComputerExist = $False }
    $ComputerExist
} 
New-PSUEndpoint -Url "/CheckOU/:OUName" -Endpoint {
param($OUName)
    Try {
        Get-ADOrganizationalUnit -Identity "$OUName" -ErrorAction stop
        $CheckOU = $True
    } catch {
        $CheckOU=$False
    }
    $CheckOU
} 
New-PSUEndpoint -Url "/ApplicationProfile" -Endpoint {

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "Select ID,ApplicationProfileName From dbo.ApplicationProfile" -Verbose | ConvertTo-Json
}  
New-PSUEndpoint -Url "/MoveComputerObject/:ComputerName/:NewOU" -Endpoint {
param([string]$ComputerName,[string]$NewOU)
    
    $ComputerObject = Get-ADComputer -Identity "$ComputerName" -Properties DistinguishedName

    Move-ADObject -Identity "$ComputerObject.DistinguishedName" -TargetPath "$NewOU"
} 
New-PSUEndpoint -Url "/VerifyAccess/:UserName" -Endpoint {
param([string]$UserName)

    $members = Get-ADGroupMember -Identity "anc_sccm_tier_1" -Recursive | Select-Object -ExpandProperty Name

    If ($members -contains $UserName) {
        $Approved = $True
    } Else {
        $Approved = $False
    }
    $Approved
} 
New-PSUEndpoint -Url "/AllApplications" -Endpoint {
Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "Select PkgId,Name from [dbo].[ProvisioningCiInterface]" | Convertto-Json
} 
New-PSUEndpoint -Url "/Locations" -Endpoint {

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database <SQLDB> -Query "Select rtrim(locationName) as locationName, rtrim(campusCode) as campusCode, rtrim(searchBase) as searchBase, display, rtrim(adwsServer) as adwsServer, rtrim(webService) as webService FROM Locations" | ConvertTo-Json
} 
New-PSUEndpoint -Url "/TaskSequences" -Description "Get all Task Sequences Available" -Endpoint {

    Invoke-Sqlcmd -ServerInstance <SQLHOST> -Database [cm_<SITECODE>] -Query "Select rtrim(AdvertisementID) as AdvertisementID,rtrim(PackageName) as PackageName FROM v_AdvertisementInfo WHERE PackageID IN(SELECT PkgID FROM vSMS_TaskSequencePackage Where TS_Type = 2) AND (CollectionID = 'SMS000US' or CollectionID = '04900A68' or CollectionID = '04900A69' or CollectionID = '04900AC0')" | ConvertTo-Json
} 
New-PSUEndpoint -Url "/Debug" -Endpoint {
$False
} 
New-PSUEndpoint -Url "/SearchBase/:OUCampus" -Endpoint {
param($OUCampus)
    $APILocations = Invoke-RestMethod "<UNIVERSALSERVER>/Locations"
    $Locations = $APILocations | Select-Object -Property locationName,campusCode,searchBase,display,adwsServer,webService | Sort-Object -Property locationName
    $SearchBase = $Locations | Where-Object { $_.campusCode -eq $OUCampus }
    $OUStructure = Get-ADOrganizationalUnit  -Filter "*" -SearchBase $($SearchBase).searchBase -SearchScope Subtree | Select-Object -Property DistinguishedName | Where-Object {$_.DistinguishedName -ne $SearchBase.searchBase}
    $OUStructure | ConvertTo-Json
} 