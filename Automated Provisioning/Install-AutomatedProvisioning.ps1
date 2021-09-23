#requires -version 5
<#
.SYNOPSIS
  This script will create the database and the tables required for the Autotmated Provisioning
.DESCRIPTION
  This script will go through and create the Database and all the table structure needed to get the backend setup for the automated provisioning of devices
.PARAMETER SiteServer
    Enter the FQDN of your MEMCM site server
.PARAMETER SiteCode
    Enter your MEMCM Site Code
.PARAMETER ServerInstance
    Enter your FQDn and instance where you want to install the database to
.PARAMETER DBName
    Specify a name for the database that will be created
.PARAMETER DBStorage
    Specify where you would like to store the database file
.PARAMETER LogStorage
    Specify where you would like to store the database log files
.INPUTS
  <None>
.OUTPUTS
  <None>
.NOTES
  Version:        1.0
  Author:         <John Yoakum>
  Creation Date:  <09092021>
  Purpose/Change: Initial script development
  
.EXAMPLE
  <.\Install-AutomatedProvisioning.ps1 -SiteServer 'sccm.siteserver.com' -SiteCode 'CM1' -ServerInstance 'viamonstra\sql01' -DBName 'Provisioning'-DBStorage 'E:\Database' -LogStorage 'E:\Logs' >
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"
param (
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true,
		HelpMessage="Enter your MEMCM site server FQDN.",
        Position = 0
    )]
    [string[]]$SiteServer,       
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true,
		HelpMessage="Enter your MEMCM site code.",
        Position = 1
    )]
    [string[]]$SiteCode,
    [parameter (
        Mandatory = $false,
        ValueFromPipeline = $true,
		HelpMessage="Enter the name of the hostname and instance if needed of the SQL Server for the Provisioning System.",
        Position = 2
    )]
    [string[]]$ServerInstance = "$env:Computername",
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true,
		HelpMessage="Enter the database name you would like to use for the Provisioning System.",
        Position = 3
    )]
    [string[]]$DBName,
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true,
		HelpMessage="Enter where you would like to store the database for the Provisioning System.",
        Position = 4
    )]
    [string[]]$DBStorage,
    [parameter (
        Mandatory = $true,
        ValueFromPipeline = $true,
		HelpMessage="Enter where you would like to store the log file for the Provisioning System.",
        Position = 5
    )]
    [string[]]$LogStorage
)
#----------------------------------------------------------[Declarations]----------------------------------------------------------
$SQLLogFileName = "$($DBName)_log"
$sqlCreateDatabase = "
CREATE DATABASE [$DBName]
ON ( NAME = N'$DBName', FILENAME = N'$DBStorage\$DBName.mdf', size = 1048576KB, FILEGROWTH = 262144KB )
LOG ON ( NAME = N'$SQLLogFileName', FILENAME = N'$LogStorage\$SQLLogFileName.ldf', size = 524288KB, FILEGROWTH = 131072KB )
GO

USE [master]
GO
ALTER DATABASE [$DBName] SET RECOVERY SIMPLE WITH NO_WAIT
GO
"
$sqlCreateTableStructure="
USE [$DBname]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ApplicationProfile](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationProfileName] [nvarchar](100) NULL,
	[ApplicationProfileDesc] [nvarchar](max) NULL,
	[CreateUser] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[UpdateUser] [nvarchar](50) NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_ApplicationProfile] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[ApplicationProfileApplication](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationProfileID] [int] NOT NULL,
	[PkgID] [nvarchar](8) NULL,
	[ApplicationID] [int] NULL,
	[CreateUser] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[UpdateUser] [nvarchar](50) NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_ApplicationProfileApplication] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ApplicationProfileVariable](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Value] [int] NULL,
	[CreateUser] [nvarchar](100) NULL,
	[CreateDate] [datetime] NULL,
	[ApplicationProfileID] [int] NULL,
	[UpdateUser] [nvarchar](100) NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_ApplicationProfileVariable] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[DebugMode](
	[DebugModeid] [int] IDENTITY(1,1) NOT NULL,
	[DebugMode] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DebugModeid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Hardware](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SerialNumber] [nvarchar](100) NOT NULL,
	[HostName] [nvarchar](15) NOT NULL,
	[TargetOU] [nvarchar](max) NOT NULL,
	[TaskSequenceID] [nvarchar](10) NOT NULL,
	[ApplicationProfileID] [int] NULL,
	[Notes] [nvarchar](max) NULL,
	[CreateUser] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[UpdateUser] [nvarchar](50) NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_Hardware] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[HardwareRemoteCode](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SerialNumber] [nvarchar](100) NULL,
	[IP] [nvarchar](50) NULL,
	[RemoteCode] [nvarchar](100) NULL,
	[CreatedDate] [datetime] NULL,
	[Port] [nvarchar](10) NULL,
	[IsActive] [int] NULL,
	[CreateUser] [nvarchar](100) NULL,
	[UpdateUser] [nvarchar](100) NULL,
	[CreateDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_HardwareRemoteCode] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Locations](
	[locationid] [int] IDENTITY(1,1) NOT NULL,
	[locationName] [nchar](35) NULL,
	[campusCode] [nchar](4) NOT NULL,
	[searchBase] [nchar](255) NOT NULL,
	[display] [bit] NOT NULL
PRIMARY KEY CLUSTERED 
(
	[locationid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE VIEW [dbo].[ProvisioningCiInterface] AS 
SELECT DISTINCT
	[cm_$SiteCode].dbo.SMSPackages.PkgID, 
	[cm_$SiteCode].dbo.SMSPackages.Name, 
	[cm_$SiteCode].dbo.SMSPackages.Version
FROM [cm_$SiteCode].dbo.[CI_Models] 
INNER JOIN (([cm_$SiteCode].dbo.[SMSPackages] INNER JOIN [cm_$SiteCode].dbo.[CIContentPackage] ON [cm_$SiteCode].dbo.[SMSPackages].PkgID = [cm_$SiteCode].dbo.[CIContentPackage].[PkgID]) INNER JOIN [cm_$SiteCode].dbo.[CI_ConfigurationItems] ON [cm_$SiteCode].dbo.[CIContentPackage].CI_ID = [cm_$SiteCode].dbo.[CI_ConfigurationItems].CI_ID) ON [cm_$SiteCode].dbo.[CI_Models].ModelId = [cm_$SiteCode].dbo.[CI_ConfigurationItems].ModelId
GO
"
$sqlLinkedServer = "
USE master;  
GO  
EXEC sp_addlinkedserver   
   N'$SiteServer',
   N'SQL Server';  
GO
"
$sqlCreateFunctions="
USE [$DBname]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Prov_GetApplicationProfileAppsSynced]
@ApplicationProfileID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Select [PkgID] as Id
        ,[Name] as ApplicationName
        ,[Version]
	FROM [$SiteServer].[CM_$SiteCode].dbo.SMSPackages_G  a                    
	WHERE [PackageType] = 8
    AND		a.[PkgID] IN (SELECT apa.[PkgID] FROM ApplicationProfileApplication apa WHERE apa.ApplicationProfileID = @ApplicationProfileID)
   
     ORDER BY	a.[Name]
END
GO

CREATE PROCEDURE [dbo].[Prov_GetProvisionGroupHardware]

@SerialNumber nvarchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT
		    *
    FROM	Hardware h
    WHERE	h.SerialNumber = @SerialNumber
		    
END
GO

Create PROCEDURE [dbo].[Prov_GetApplicationProfileVars]
@ApplicationProfileID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT		*
    FROM		ApplicationProfileVariable AVR
    WHERE		AVR.ApplicationProfileID = @ApplicationProfileID
    ORDER BY	AVR.[Name]
END
GO

CREATE PROCEDURE [dbo].[Prov_HardwareRemoteCodeAdd]
@SerialNumber nvarchar(100)
,@RemoteCode nvarchar(100)
,@IP nvarchar(50)
,@Port nvarchar(10)

AS
BEGIN

INSERT INTO [dbo].[HardwareRemoteCode]
           (
		   [SerialNumber]
           ,[IP]
           ,[RemoteCode]
           ,[Port])
     VALUES
           (
		   @SerialNumber
           ,@IP
           ,@RemoteCode
		   ,@Port
           )
select SCOPE_IDENTITY() AS HardwareRemoteCodeID


END
GO

CREATE PROCEDURE [dbo].[Prov_HardwareRemoteCodeDelete]
@SerialNumber nvarchar(50)

AS
BEGIN


DELETE FROM [dbo].[HardwareRemoteCode]
      WHERE SerialNumber = @SerialNumber

END
GO
"
$UniversalServerHostName = $([System.Net.Dns]::GetHostByName($env:computerName).HostName)
$UniversalHost = "http://$([System.Net.Dns]::GetHostByName($env:computerName).HostName):5000"
$UniversalHostLenth = $($UniversalHost -split "\.")[0].Length
$DomainFQDN = $UniversalHost.Substring(($UniversalHostLenth +1))
$DomainWINS = $($UniversalHost -split "\.")[1]

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Write-Host "Starting to install the project for the automated imaging..."

Write-Host "Attempting to connect to remote SQL Server..."
Try {
	$IsSQLInstalled =  Invoke-Command -Computername $ServerInstance { Get-Service -Name MSSQL* | Where-Object {$_.status -eq "Running" -and ($_.name -ne 'MSSQLFDLauncher')} | Select-Object -Property PSComputerName, @{label='InstanceName';expression={$_.Name -replace '^.*\$'}} } -ErrorAction Stop
	$SQLRemote = $True
	$SQLServer = $ServerInstance
} Catch {
	Write-Host "Could not connect to remote server or could not find MSSQL installed on remote machine, attempting locally..." -ForegroundColor Cyan
	$SQLRemote = $False
}
If ($SQLRemote = $False) {
	Write-Host "Checking to make sure that SQL Server or SQL Server Express is installed locally..."
	$IsSQLInstalled =  Get-Service -Name MSSQL* | Where-Object {$_.status -eq "Running" -and ($_.name -ne 'MSSQLFDLauncher')} | Select-Object -Property PSComputerName, @{label='InstanceName';expression={$_.Name -replace '^.*\$'}}
}
If ($IsSQLInstalled.Count -eq 0 ) {
	Write-Host "Could not find an instace of SQL on the machine chosen. Please install and try again." -ForegroundColor 'red'
	Pause
	exit
} else {
	$SQLServer = $env:COMPUTERNAME
}
# Get and store the credential for creating the database and table structure
$Credential = $(Get-Credential -Message "Please enter credentials with sysadmin permissions for SQL Server")
# Check that the SQL Server Commandlets are installed
Write-Host "Checking to see if the SqlServer Module is installed"
$SqlServerInstalled = Get-Module -name SqlServer
If ($SqlServerInstalled.Count -eq 0) {
    Write-Host "Installing the SqlServer Module"
    # Import the SQL Server Commandlets Module
    Install-Module -Name SqlServer -AllowClobber -Force
}

Write-Host "Creating the database to host the tables necessary for the Automated Imaging... for $SQLServer"
# Create the database on the server
Invoke-SqlCmd -ServerInstance "$SQLServer" -Credential $Credential -Query $sqlCreateDatabase | Out-Null

Write-host "Creating the table structure for the Automated Imaging..."
# Create the table structure
Invoke-SqlCmd -ServerInstance "$SQLServer" -Credential $Credential -Query $sqlCreateTableStructure | Out-Null

If ($SiteServer -like "$($SQLServer)%" ) {
    Write-host "Creating the linked server to the Site Server"
    # Create the table structure
    Invoke-SqlCmd -ServerInstance "$SQLServer" -Credential $Credential -Query $sqlLinkedServer | Out-Null
}

Write-host "Creating the Stored Procedures"
# Create the table structure
Invoke-SqlCmd -ServerInstance "$SQLServer" -Credential $Credential -Query $sqlCreateFunctions | Out-Null

Write-Host "Downloading and installing Powershell Universal"
# Install Powershell Universal with all the default settings
Invoke-WebRequest https://imsreleases.blob.core.windows.net/universal/production/2.3.1/PowerShellUniversal.2.3.1.msi -OutFile Universal.msi | Out-Null
& msiexec /i Universal.msi /qn | Out-Null

Write-Host "Updating APIs with correct Powershell Universal Server..."
# Search through the endpoint and replace server name for API calls
$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
(Get-Content -path $ScriptPath\endpoints.ps1) | ForEach-Object {$_ -replace '<SQLHOST>',"$($SQLServer)" } | Set-Content -path $ScriptPath\endpoints.ps1 | Out-Null
(Get-Content -path $ScriptPath\endpoints.ps1) | ForEach-Object {$_ -replace '<SITECODE>',"$($SiteCode)" } | Set-Content -path $ScriptPath\endpoints.ps1 | Out-Null
(Get-Content -path $ScriptPath\endpoints.ps1) | ForEach-Object {$_ -replace '<SQLDB>',"$($DBName)" } | Set-Content -path $ScriptPath\endpoints.ps1 | Out-Null
(Get-Content -path $ScriptPath\endpoints.ps1) | ForEach-Object {$_ -replace '<UNIVERSALSERVER>',"$($UniversalHost)" } | Set-Content -path $ScriptPath\endpoints.ps1 | Out-Null

Write-Host "Updating References in Dashboard for server names, based on default Powershell Universal Installation..."
# Search through Dashboard and replace references to Invoke-Restmethod
(Get-Content -path $ScriptPath\Provisioning_Portal.ps1) | ForEach-Object {$_ -replace '<UNIVERSALSERVER>',"$($UniversalHost)" } | Set-Content -path $ScriptPath\Provisioning_Portal.ps1 | Out-Null
(Get-Content -path $ScriptPath\Provisioning_Portal.ps1) | ForEach-Object {$_ -replace '<SQLHOST>',"$($SQLServer)" } | Set-Content -path $ScriptPath\Provisioning_Portal.ps1 | Out-Null
(Get-Content -path $ScriptPath\Provisioning_Portal.ps1) | ForEach-Object {$_ -replace '<SQLDB>',"$($DBName)" } | Set-Content -path $ScriptPath\Provisioning_Portal.ps1 | Out-Null

Write-Host "Updating Boot image script with correct API references based on default Powershell Universal Installation..."
# Search through Powershell Boot script for API references and replace with right server
(Get-Content -path $ScriptPath\AutoDeploy.ps1) | ForEach-Object {$_ -replace '<UNIVERSALSERVER>',"$($UniversalHost)" } | Set-Content -path $ScriptPath\AutoDeploy.ps1 | Out-Null

Write-Host "Updating WinPE_Dart script with correct API references based on default Powershell Universal Installation..."
# Search through Powershell Boot script for API references and replace with right server
(Get-Content -path $ScriptPath\SampleFiles\WinPE_Dart.ps1) | ForEach-Object {$_ -replace '<UNIVERSALSERVER>',"$($UniversalHost)" } | Set-Content -path $ScriptPath\SampleFiles\WinPE_Dart.ps1 | Out-Null

Write-Host "Updating AutoDeploy script with correct Domain references based on default Powershell Universal Installation..."
# Search through Powershell Boot script for API references and replace with right server
(Get-Content -path $ScriptPath\AutoDeploy.ps1) | ForEach-Object {$_ -replace '<DN>',"$($DomainWINS)" } | Set-Content -path $ScriptPath\AutoDeploy.ps1 | Out-Null
(Get-Content -path $ScriptPath\AutoDeploy.ps1) | ForEach-Object {$_ -replace '<UNIVERSALSERVERNAME>',"$($UniversalServerHostName)" } | Set-Content -path $ScriptPath\AutoDeploy.ps1 | Out-Null
(Get-Content -path $ScriptPath\AutoDeploy.ps1) | ForEach-Object {$_ -replace '<DOMAINFQDN>',"$($DomainFQDN)" } | Set-Content -path $ScriptPath\AutoDeploy.ps1 | Out-Null

Write-Host "Creating the directory Structure for the Powershell Universal Files"
New-Item -Path C:\ProgramData\UniversalAutomation -Name "Repository" -ItemType "directory"
New-Item -Path C:\ProgramData\UniversalAutomation\Repository -Name ".universal" -ItemType "directory"
New-Item -Path C:\ProgramData\UniversalAutomation\Repository -Name "Dashboards" -ItemType "directory"
New-Item -Path C:\ProgramData\UniversalAutomation\Repository\Dashboards -Name "Provisioning_Portal" -ItemType "directory"

Write-Host "Coping over the APIs and Dashboard to Powershell Universal"
# Copy over the APIs and Dashboard files
Copy-Item .\endpoints.ps1 c:\ProgramData\UniversalAutomation\Repository\.universal\endpoints.ps1 -Recurse -force | Out-Null
Copy-Item .\dashboards.ps1 c:\ProgramData\UniversalAutomation\Repository\.universal\dashboards.ps1 -Recurse -force | Out-Null
Copy-Item .\Provisioning_Portal.ps1 c:\ProgramData\UniversalAutomation\Repository\Dashboards\Provisioning_Portal\Provisioning_Portal.ps1 -Recurse -force | Out-Null

Write-Host "Opening the firewall for traffic into the Dashboard and API service"
# Open the firewall so that clients can hit the API and dashboard
New-NetFirewallRule -DisplayName 'Powershell Universal API and Dashboard Access' -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5000 | Out-Null

Write-Host "Restarting Powershell Universal Service"
# Restarting Powershell Universal
Get-Service -Name "PowerShellUniversal" | Restart-Service -Force

Write-Host "Automated Provisioning is now fully installed. Once you click enter, then a browser will open and take to to the sign in." -ForegroundColor Cyan
Write-Host "Use the username of 'admin' with any password" -ForegroundColor Cyan
Write-Host "You will need to navigate to the 'User Interfaces' section and then start your dashboard" -ForegroundColor Cyan
Pause

Start-Process $UniversalHost

