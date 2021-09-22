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

