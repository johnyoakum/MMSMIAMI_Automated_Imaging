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
  * DaRT Tools

