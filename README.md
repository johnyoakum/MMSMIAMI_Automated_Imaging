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
* Microsoft Deployment Toolkit (MDT)

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

* Line 639
  * Change to the color you would like your background???
* Line 640
  * Change to what color you would want your foreground???
* Line 643
  * Change the base64 string for the logo that you want to display across the system (for manual deployments)

I added the ability to have a default automated build if the device falls between a set IP Range.
This ensures that there won't be any failures during the process if the device had not been preprovisioned.

We needed this in our environment so that no matter what devices go to the Dell Configuration Center,
it would always get imaged with out image and we could reduce the number of calls back and forth when a device got missed
in the pre-provisioning process. This particular section will NOT run, unless the device falls between the range.
In order to accomodate this, we need to add a few specific items staged in the script.

* Line 415
  * Change IP range of automated computers???
* Line 442, 443, and 491
  * Change what you want the default computer name to be???

> You will need to add a single device in the portal called DellDefault (you can rename to whatever you like, but make sure that you change it in the script as well) which includes your default task sequence to run with the default application profile as well as default OU???

## Remote Tool Integration
This process has DaRT Tools installed on the boot.wim file so that we can connect to the machine during OSD, but still
in the WinPE phase. I will also go through the process of configuring VNC for connecting to the remote machine during OSD
after the WinPE phase. The dashboard stores all the information needed to connect to those machines. In the "Configuring 
Task Sequence" section, I will cover the additional steps you will want to add for facilitating this.

## Configure Boot Image
I am not gonna go into the details of how to create a brand new boot image, however, 
I will cover the steps after the base boot image is created. In a nutshell, we will cover the following things:
* Add Components to boot image
  * Powershell
  * .NET
  * MDAC
* Drivers (if desired)
* DaRT Tools (see links and attached scripts)
* Startup Script Settings and Package

### Add the Optional Components
![Optinal Components](/images/optionalcomponents.JPG)
![Components to Add](/images/allcomponents.jpg)

### Add Drivers (if desired)
You may already work with drivers so I won't go into deep detail, but here is where you would add drivers.
![Drivers](/images/drivers.jpg)

### Add DaRT Tools
Here is the blog posts that I followed to add the DaRT Tools to the boot image: 
[Integrate DaRT in a ConfigMgr boot image using PowerShell](https://msendpointmgr.com/2019/12/23/integrate-dart-in-a-configmgr-boot-image-using-powershell/), [Adding DaRT to ConfigMgr Boot Images ??? And starting it earlier than early](https://www.deploymentresearch.com/adding-dart-to-configmgr-boot-images-and-starting-it-earlier-than-early/)
 and [DaRT & VNC Remote during OSD without Integration](https://garytown.com/dart-vnc-remote-during-osd-without-integration)

Run the script "Add-DaRTtoBootImage.ps1" using the following command line, replacing the {} sections with your own data, 
to add the DaRT Tools to the boot wim and also confure it so that it starts when the boot image first starts up. 
When the DaRT tools starts, it will also add an entry to the dashboard under remote control codes so that you have the 
Ticket Number, IP Address, and port needed to connect. Using the attached DartConfig.dat file, it will always use port 3389.

> .\Add-DaRTtoBootImage.ps1 -BootImageName '{Name of Boot Image to Use}' -MountPath {Mount Path} -DartCAB {Path to toolscabx64.cab} -SampleFiles .\SampleFiles\ -SiteServer {SiteServer} -SiteCode {SiteCode}

### Added Startup Command and Package
Copy the AutoDeploy.ps1 and the diskpart.txt files to a shared folder for use in the pre-start command

Add the following prestart command:

> powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File X:\sms\PKG\SMS10000\AutoDeploy.ps1

![Prestart Command](/images/prestart.png)

### Finalize Boot Image
Once done, don't forget up distribute/update your boot images on the Distribution Point(s).

## Configure VNC for connecting remotely during Task Sequence (after WinPE)(OPTIONAL)
I did not figure this process out myself. I had a good blog post to follow:
[Remote Control During SCCM OSD (Without Modifying the Boot.wim)](http://syswow.blogspot.com/2012/05/remote-control-during-sccm-osd-without.html)
And this one for some more information:
[DaRT & VNC Remote during OSD without Integration](https://garytown.com/dart-vnc-remote-during-osd-without-integration)

If you decide to add this section, be sure to change the WinPE_Dart.ps1 file to the correct VNC
password so that your Remote Code in the dashboard is using the correct one. This would be better if done
before you add DaRT Tools to your boot image or you will need to mount the boot image to change it and 
then dismount and then update the distribution points again.

### Configure Task Sequence for VNC
After every reboot, add a step that runs the package that has the VNC Viewer in it.

## Dashboard Walkthrough
### Main Screen
![Dashboard Home Screen](/images/portalhome.png)

This is the home screen for the Dashboard. From here you will navigate to any of the other pages
for what you want to do.

### Hardware Devices
![Hardware Devices](/images/hardwarepage1.png)

On this screen, you will see all devices that have been provisioned. Here you will also add devices
to the system. To add a single device, choose the button to add a single device. This system also allows
you to add devices in bulk... the requirements to use the bulk add are that the devices must be
going into the same OU, have the same task sequence and have the same Application profile. An example of 
this would be a computer lab that all get the same build.

#### Single Computer Addition
![Add Single Device](/images/addsinglecomputer.png)

Enter the hostname, serial number, and distinguishedName of the destination OU, then choose the task sequence and Application 
Profile. You can add notes if you'd like for this entry.

#### Bulk Computer Addition
![Add Computers in Bulk](/images/computerbulkentry.png)

Enter the distinguishedName of where you would like to store the items in AD, then choose the Task Sequence 
and Application Profile you wish to use. Have a CSV file of the Serial Numbers and Hostnames you would like 
and then copy and paste into the box.

### Application Profiles
![Application Profiles](/images/applicationprofiles.png)

Here is where you will find all the Application Profiles that you have created or where you can create new 
ones. To create a new one, just click the button to add a profile.

#### Add Application Profile
![Add Application Profile](/images/addappprofile.png)

Enter the Application Profile Name and any notes you wish to add and then press Add. This will take you 
to the next page where you will add applications or variables to the profile.

#### Application Profile Editor
![Application Profile Editor](/images/appprofileedit.png)

Edit the Profile or choose the add button under Applications or Variables to add either to your profile.

#### Add Application
![Add Application](/images/addapplication.png)

This is a multi-value selection that you can choose all the applications you wish to add to the profle. 
Choose the applications you want and then click OK.

#### Add Variables
![Add Variables](/images/addvariable.png)

Enter the Task Sequence Variable that you wish to create and choose the drop down for True or False and click OK.

### Hardware Remote Codes
![Remote Codes](/images/remotecodes.png)

Here you will find all the connection information to connect to the device while it is imaging.

### Locations
![Locations](/images/locations.png)

Here is where you will see all the Locations that you have defined and you can add more. To add more 
click the button to add location.

#### Add Locations
![Add Location](/images/addlocation.png)

Enter the location name, prefix for that location, and the Base OU in AD that you want to search and store devices in AD for, and click OK.

## First Time Setup in Dashboard
* Create your location(s)
* Add Application Profile(s)
* Add your default computer setting

### Create your location(s)
* In your dashboard, click the link on the left for Locations.
* Click the 'Add Location' button
* Enter the Location Name
* Enter a Prefix
  * In this scenario, the prefix is associated with Task Sequences if doing a manual build. In task sequences, the prefix will help filter down available task sequences.
* Enter the distinguishedName of the OU that you want to start the search for populating the OU structure when performing manual builds
* Choose whether the Location is Active or not

> The AutoDeploy.ps1 script provides for performing manual builds and this is the basis for some of it, however I don't cover it in this walkthrough.

### Add Application Profile(s)
* In your dashboard, click the link for Application Profiles
* Click the Plus (+) sign to add an Application Profile
* Enter in an Application Profile Name and if desired a Description
* Press the 'OK' Button
* On the screen that pops up, click the Plus (+) for Application
* Select the applications you would like to add to the profile
* If wanted to, you can add a custom Task Sequence variable that is also associated with this profile
  * Click Add and then Enter your variable. I only have them set for True/False values. So, if true do something in the TS.

The apps save automatically when you add them, but once done, you can click Update, but it is not necessary.

### Add your default computer setup
* Click 'Hardware Devices' link
* Click 'Add Single Computer'
* Enter 'DellDefault' in the Computer Name field (this will not be used during OSD)
* Enter 'DellDefault' in the Serial Number field
* Enter the DisguishedName of the OU that you wish to put default machines in
* Choose the Default Task Sequence that you would like to use
* Choose the Default Application Profile that you our like to use
* Click 'Add Computer'

> The default computer setup is for when the automated provisioning runs and the device falls within the given range, AND it is not provisioned in the portal.


## Reference Links
[Adding DaRT to ConfigMgr Boot Images ??? And starting it earlier than early](https://www.deploymentresearch.com/adding-dart-to-configmgr-boot-images-and-starting-it-earlier-than-early/)

[Integrate DaRT in a ConfigMgr boot image using PowerShell](https://msendpointmgr.com/2019/12/23/integrate-dart-in-a-configmgr-boot-image-using-powershell/)

[Remote Control During SCCM OSD (Without Modifying the Boot.wim)](http://syswow.blogspot.com/2012/05/remote-control-during-sccm-osd-without.html)

[DaRT & VNC Remote during OSD without Integration](https://garytown.com/dart-vnc-remote-during-osd-without-integration)


