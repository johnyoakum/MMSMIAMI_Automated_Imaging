# MMSMIAMI Automated Imaging Process
## History
This all started when one of my bosses heard about how we could have our machines imaged at 
Dell and have limited interaction with it once it came onsite.
Sure it could be done, but what was the best way.
Our environment can be complex, multiple task sequences, multiple application builds, etc...

We wanted to maintain our flexibility of having different builds for each machine. 
Dell wants it limited to one or two fixed task sequences plus they dont' have a good 
process for flexibility with different models.

Out of that, I created this process that gives everybody exactly what they wanted.

I am not going to get into the nitty gritty of the options that Dell has and how it all works, but the option 
we chose was to send an ASA, Switch and Server to their factory where all imaging takes place.

The ASA provides a dedicated VPN connection back to our facility and the server is a MP/DP for ConfigMgr.

This solution provides us the ability to stage the devices (without having to import into ConfigMgr), but only by 
the serial number. We can specify the hostname we want, what OU to put it in, in AD. as well as the ability to choose 
what task sequence and also what apps we wanted. Also allows us to store the information that we would need 
in order to access the machines remotely while they were imaging. All on a per machine basis.
## Pre-Requisites
* MEMCM Environment
* Sql Server or SQL Server Express
* Permissions to create Database Structure
* Admin permissions
* DaRT Tools (for remote access)
## Setup Database, APIs and Provisioning Dashboard
Contained in this repo are all the files necessary to make this solution work for you. Run the script 
Install-AutomatedProvisioning.ps1 with the following syntax:
> .\Install-AutomatedProvisioning.ps1 -SiteServer 'sccm.siteserver.com' -SiteCode 'CM1' -ServerInstance 'viamonstra\sql01' -DBName 'Provisioning' -DBStorage 'E:\Database' -LogStorage 'E:\Logs'

It takes the following parameters
* -SiteServer 
  * This is the FQDN of your ConfigMgr Site Server
* -SiteCode
  * This is the site code for your ConfigMgr System
* -ServerInstance
  * This is the location of your SQL Server
  * This will attempt to install on a remote system, if one is provided. In order to do this, you need to make sure that PSRemoting is configured on that server. If it can't connect remotely, it will try to install locally.
  * This script will fail if it cannot connect to a SQL Server and create the structure
* -DBName
  * This will be the name of the database that you wish to create
* -DBStorage
  * This is where you want to save the database file on the SQL Server
* -LogStorage
  * This is where you want to save the Log file for the database

This script will perform the following functions:
* Create the database and table structure
* Download and install Powershell Universal Community
* Create the endpoints (APIs) and Dashboard that will be used within Powershell Universal Community
* Update additional scripts used for the boot image with the values provided

## Manual Modifications to the scripts
#### There are some manual modifications to the scripts included here that help you customize the look and feel just for your environment.
Change the following lines in the AutoDeploy.ps1 file:

* Line 636
  * Change to the color you would like your background​
* Line 637
  * Change to what color you would want your foreground​
* Line 640
  * Change the base64 string for the logo that you want to display across the system (for manual deployments)

I added the ability to have a default automated build if the device falls between a set IP Range.
This ensures that there won't be any failures during the process if the device had not been preprovisioned.

We needed this in our environment so that no matter what devices go to the Dell Configuration Center,
it would always get imaged with out image and we could reduce the number of calls back and forth when a device got missed
in the pre-provisioning process. This particular section will NOT run, unless the device falls between the range.
In order to accomodate this, we need to add a few specific items staged in the script.

* Line 415
  * Change IP range of automated computers​
* Line 442, 443, and 491
  * Change what you want the default computer name to be​

> You will need to add a single device in the portal called DellDefault (you can rename to whatever you like, but make sure that you change it in the script as well) which includes your default task sequence to run with the default application profile as well as default OU​

## Remote Tool Integration
This process has DaRT Tools installed on the boot.wim file so that we can connect to the machine during OSD, but still
in the WinPE phase. I will also go through the process of configuring VNC for connecting to the remote machine during OSD
after the WinPE phase. The dashboard stores all the information needed to connect to those machines. In the "Configuring 
Task Sequence" section, I will cover the additional steps you will want to add for facilitating this.

## Congigure Boot Image

## Configure VNC for connecting remotely during Task Sequence (after WinPE)

## Configure Task Sequence

## Dashboard Walkthrough

## First Time Setup in Dashboard
* Create your location(s)
* Add Application Profile(s)
* Add your default computer setting


