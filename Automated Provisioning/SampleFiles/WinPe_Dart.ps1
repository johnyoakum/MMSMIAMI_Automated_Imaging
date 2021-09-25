#requires -version 2
<#
.SYNOPSIS
  Posts dart shortcuts to API
.DESCRIPTION
  This script will start DaRT and then post the IP address and ticket information to the database for connecting remotely.
.PARAMETER <Parameter_Name>
  None
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:        John Yoakum
  Creation Date:  09132021
  Purpose/Change: Initial script development
.EXAMPLE
  .\WinPE_Dart.ps1
#>


$siteserver = "<UNIVERSALSERVER>"
$UniversalServer = "<UNIVERSALSERVERNAME>"

#Wait for network
do {
  Write-Host "Starting Dart  - Waiting for Network To Be Ready....". -ForegroundColor Yellow
  sleep 3      
} until(Test-Connection -computer $UniversalServer | Where-Object { $_.StatusCode -like "0" } )

# Start Remote Recovery
Write-Host "Launching Dart" -ForegroundColor Yellow
& "X:\Windows\System32\RemoteRecovery.exe" -ArgumentList "-nomessage" -WindowStyle Minimized -PassThru
 
# Wait until the inv32.xml file exists
While (!(Test-Path -Path "X:\Windows\System32\inv32.xml")) {
    Start-Sleep -Seconds 1
}
 
# Get data from inv32.xml file
[XML]$inv32XML = Get-Content -Path "X:\Windows\System32\inv32.xml"
$ticketID = $inv32XML.SelectSingleNode("//A").ID
$connections = $inv32XML.SelectNodes("//L")
$port = "3389"
 
$connections | ForEach-Object {
    if (($_.N -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}") -and ($_.N -notmatch "169\..+")) {
        $ip = $_.N
    }
}
 
# Check system for name formatting
$SerialNumber = Get-WmiObject -Class win32_bios | Select-Object SerialNumber
$SN = "$($SerialNumber.SerialNumber)"
# Publish information to the database
Invoke-RestMethod <UNIVERSALSERVER>/RemoteControl -Method POST -Body @{SerialNumber = "$SN"; RemoteCode = "$ticketID"; IP = "$ip"; Port = "$port"}
