Priority-Hub
============

Sort lockscreen notifications on your iPhone by app! Inspired by the Blackberry 10 priority hub feature. It's available on Cydia in the BigBoss repo, depiction here: http://moreinfo.thebigboss.org/moreinfo/depiction.php?file=priorityhubDp

![screen1](https://raw.githubusercontent.com/thomasfinch/Priority-Hub/master/screenshots\ &\ icon/screenshot%201.png)


### Building
Priority Hub is built with [Ryan Petrich's theos fork](https://github.com/rpetrich/theos) and uses [the HashBang header repository](https://github.com/hbang/headers) for headers. To install, clone the theos repo, then cd into that directory and clone the headers repo into "include". Make sure that the environment variables THEOS and THEOS_MAKE_PATH are set correctly (usually in .bash_profile).
