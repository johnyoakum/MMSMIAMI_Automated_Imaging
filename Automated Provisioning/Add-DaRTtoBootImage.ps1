<#
.SYNOPSIS
  This script will install the DaRT tools on the boot image for remote connections
.DESCRIPTION
  This script will install the DaRT tools on the boot image for remote connections
.PARAMETER BootImagename
    Specify the name of the boot image that you would like to modify
.PARAMETER MountPath
    Specify the empty directory to mount the boot image to
.PARAMETER DartCAB
    Specify the location of the darttoolsx64.cab file you want to use
.PARAMETER MDTInstallationPath
    Specify directory where MDT is installed
.PARAMETER SampleFiles
    Specify the directory where the sample files are stored
.PARAMETER SiteServer
    Specify the FQDN of your MEMCM site server
.PARAMETER SiteCode
    Specify the site code for your MEMCM site
.INPUTS
  <None>
.OUTPUTS
  <None>
.NOTES
  Version:        1.0
  Author:         <John Yoakum>
  Creation Date:  <09092021>
  Purpose/Change: Initial script development
  
  Pre-Requisites:
    The following items need to be installed on the machine that you are creating this from:
        MEMCM Console
        Microsoft Windows ADK
        Microsoft Dart Tools
        Microsoft MDT
  
  References
    https://www.deploymentresearch.com/software-assurance-pays-off-remote-connection-to-winpe-during-mdt-sccm-deployments/
    How to create the dartconfig.dat file

    https://www.deploymentresearch.com/adding-dart-to-configmgr-boot-images-and-starting-it-earlier-than-early/
    Basis for script for adding Dart to boot image

    Other references:
    https://msendpointmgr.com/2019/12/23/integrate-dart-in-a-configmgr-boot-image-using-powershell/

    The powershell script to start dart and send the remote code to the API is mine though. I used the examples to create the script and make sure that I was
    getting the right information.
.EXAMPLE
  < .\Add-DaRTtoBootImage.ps1 -BootImagename "bootx64" -MountPath "c:\Mount" -DartCAB "C:\Program Files\Microsoft\" -MDTInstallationPath "C:\Program Files\MDT" -SampleFiles "C;\Temp" -SiteServer 'sccm.siteserver.com' -SiteCode 'CM1' >
#>

# Set some variables to resources
param (
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]$BootImageName,
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]$MountPath,
    [parameter (
        Mandatory = $false,
        ValueFromPipeline = $true
    )]
    [string]$DartCab = "C:\Program Files\Microsoft DaRT\v10\Toolsx64.cab",
    [parameter (
        Mandatory = $false,
        ValueFromPipeline = $true
    )]
    [string]$MDTInstallationPath = "C:\Program Files\Microsoft Deployment Toolkit",
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]$SampleFiles,
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]$SiteServer,
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true
    )]
    [string]$SiteCode
)

# Check for elevation
Write-Host "Checking for elevation"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oops, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}
$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
# Connect to ConfigMgr
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer 
}
Set-Location "$($SiteCode):\" 

# Get Boot image from ConfigMgr
$BootImage = Get-CMBootImage -Name $BootImageName
$BootImagePath = $BootImage.ImagePath

# Some basic sanity checks
Set-Location C:
if (!(Test-Path -Path "$BootImagePath")) {Write-Warning "Could not find boot image, aborting...";Break}
if (!(Test-Path -Path "$MountPath")) {Write-Warning "Could not find mount path, aborting...";Break}
if (!(Test-Path -Path "$DartCab")) {Write-Warning "Could not find DaRT Toolsx64.cab, aborting...";Break}
if (!(Test-Path -Path "$MDTInstallationPath")) {Write-Warning "Could not find MDT, aborting...";Break}
if (!(Test-Path -Path "$ScriptPath\SampleFiles\EnableDart.wsf")) {Write-Warning "Could not find EnableDart.wsf, aborting...";Break}
if (!(Test-Path -Path "$ScriptPath\SampleFiles\Unattend.xml")) {Write-Warning "Could not find Unattend.xml, aborting...";Break}

# Mount the boot image
Mount-WindowsImage -ImagePath $BootImagePath -Index 1 -Path $MountPath  

# Add the needed files to the boot image
expand.exe $DartCab -F:* $MountPath
Remove-Item $MountPath\etfsboot.com -Force
Copy-Item $ScriptPath\SampleFiles\DartConfig.dat $MountPath\Windows\System32\DartConfig.dat

if (!(Test-Path -Path "$MountPath\Deploy\Scripts")) {New-Item -ItemType directory $MountPath\Deploy\Scripts}
if (!(Test-Path -Path "$MountPath\Deploy\Scripts\x64")) {New-Item -ItemType directory $MountPath\Deploy\Scripts\x64}
Copy-Item $SampleFiles\EnableDart.wsf $MountPath\Deploy\Scripts
Copy-Item $SampleFiles\Unattend.xml $MountPath
Copy-Item $ScriptPath\SampleFiles\WinPE_Dart.ps1 $MountPath\Windows\System32\WinPE_Dart.ps1
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIDataAccess.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIUtility.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIGather.wsf" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIGather.xml" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ztiRunCommandHidden.wsf" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Scripts\ZTIDiskUtility.vbs" $MountPath\Deploy\Scripts
Copy-Item "$MDTInstallationPath\Templates\Distribution\Tools\x64\Microsoft.BDD.Utility.dll" $MountPath\Deploy\Scripts\x64

# Save changes to the boot image
Dismount-WindowsImage -Path $MountPath -Save


# Update the boot image in ConfigMgr
Set-Location "$($SiteCode):\" 
$GetDistributionStatus = $BootImage | Get-CMDistributionStatus
$OriginalUpdateDate = $GetDistributionStatus.LastUpdateDate
Write-Output "Updating distribution points for the boot image..."
Write-Output "Last update date was: $OriginalUpdateDate"
$BootImage | Update-CMDistributionPoint

# Wait until distribution is done
Write-Output ""
Write-Output "Waiting for distribution status to update..."

Do { 
$GetDistributionStatus = $BootImage | Get-CMDistributionStatus
$NewUpdateDate = $GetDistributionStatus.LastUpdateDate
 if ($NewUpdateDate -gt $OriginalUpdateDate) {
  Write-Output ""
  Write-Output "Yay, boot image distribution status updated. New update date is: $NewUpdateDate"
  Write-Output "Happy Deployment!"
 } else {
  Write-Output "Boot image distribution status not yet updated, waiting 10 more seconds"
 }
 Start-Sleep -Seconds 10
}
Until ($NewUpdateDate -gt $OriginalUpdateDate)