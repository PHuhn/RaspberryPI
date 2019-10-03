# Nagios Install Scripts
## Overview

This folder contains scripts to perform Nagios installations as follows:
1. NagiosInstall.sh
1. NagiosNrdpInstall.sh

### NagiosInstall.sh

Nagios monitors availability, uptime and response time of every configured node on the network.  Nagios monitors the network for problems caused by overloaded data links or network connections, as well as monitoring routers, switches and more.  See installed web site:

http://&lt;nagios server address&gt;/nagios/

Also see the /usr/local/nagios/etc/ folder for configuration of active network nodes.

#### Installation
This will install:
- nagios
- nagios plugins
- check_ncpa.py and configure check command
- check_state_statusjson.sh and configure check command
- rasp-pi-logo-icon.png icon
- py-logger-logo-icon.png icon
- win10-logo-icon.png icon
- win-server-logo-icon.png icon

Installation example as follows:

```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/NagiosInstall.sh
$ chmod 755 NagiosInstall.sh
$ sudo ./NagiosInstall.sh -h
  Usage: NagiosInstall.sh [options]

  -h    this help text.
  -n    nagios version, default value: 4.4.3
  -p    plugin version, default value: 2.2.1

  Example:  NagiosInstall.sh -n 4.4.2 -p 2.2.1

$ sudo ./NagiosInstall.sh
$
```

If you want to use **check_statusjson_state.sh** command script you will need to edit /usr/local/nagios/etc/objects/commands.cfg and change the password for nagiosadmin or add your own user and password.

### NagiosNrdpInstall.sh

Installation of Nagios NRDP passive plugin.  Allow one to restfully send passive events to Nagios.  See installed web site:

http://&lt;nagios server address&gt;/nrdp/

Also see the /usr/local/nrdp/clients folder for utilities for sending passive events:

* send_nrdp.php
* send_nrdp.py
* send_nrdp.sh

Java and perl versions are available on Nagios Exchange.

This installs a seperate web site for handling incoming requests that
are then written to Nagios spool directory.  This also creates
'secret' security tokens to be used in sending passive events.

#### Installation

Installation example as follows:

```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/NagiosNrdpInstall.sh
$ chmod 755 NagiosNrdpInstall.sh
$ sudo ./NagiosNrdpInstall.sh -h
  Usage: NagiosNrdpInstall.sh [options]

  -h    this help text.
  -n    nagios nrdp version, default value: 1.5.2

  Example:  NagiosNrdpInstall.sh -n 1.5.1

$ sudo ./NagiosNrdpInstall.sh
=- Running NagiosNrdpInstall.sh 1.0.2 -=
    ...
=- * suggested tokens for config.inc.php * -=
    "OyfMCh8SJvMtjbuhMnN99-HqMMfGWPH1IA1hMmi9kmdP2SLYOpvAAsnFxTServ8sXzSfzmUI08IBP1oHTPNANA",
    "bwDdGLFmw0nkEkWO2zHpkifOqM0L3BquqIqdZqdVNqFO3qsqTpbrTfIKVOtb02TvEvDd7NAjI8KHDtVimaU9Lw",
    "1ObVCv9HW3smeYFisxA-VdSWHZ9PN8AUNGxBsK0i3-oc3P7DAdlOh4TxOkLYn6hXf9IiyrZKdg5jXwfp7fZaiQ",
    "I2zgZjpUNkErVgQ2gpLj0vZGRJSJPBHOIs2K729yxPAQ__ZybMnT-iPbsBKC6GHygu-JVfqMgiOaYo0r5osSaw",
    "7PVgnBjkPMS5G1U8YINKknqzejjwWDsMyWxrpCB2qPFf7MDXheOTsapqifcBIn3vTHJhI4PeVrK-IK53ZisWjA",
    "zLkZovjeqblWabvhmL3uHAG1NVfD1zVDoe3_rjW0LR4u6NHY-l94mXkgQt6-qaQEkIzOvBuBU2Z0f2qANlg-SQ",
    "YIBq0JdR0yyItX-jwlTJCozlbIOKK6Ks3xmXpWZw7s2-OgNHJnr6kVwoUUtMBLynDsglPzwMo-pbPjgPT-67fw",
    "Jf6vR5KnEinno-8nrhRV77kyf2SapcbTuUFOA4A69LJjE3TlsL4tK3GPzGvoE05R1xU7T0L43kSTBc9Jm5DYMw",
/usr/local/nrdp/server/config.inc.php should now contain the above suggested tokens...
You can remove them, or add additional tokens.
also edit /etc/apache2/sites-enabled/nrdp.conf to verify desired configuration.
Sat 16 Feb 15:27:01 EST 2019
=- End of install of NRDP on Raspberry PI -=
$ sudo vi /usr/local/nrdp/server/config.inc.php
```

Some other things still need to be completed.  The following two file should be reviewed and edited (use your faviorite editor 'vi', 'nano', ...):

* /usr/local/nrdp/server/config.inc.php
* /etc/apache2/sites-enabled/nrdp.conf

##### config.inc.php

The following are the fake tokens in the NRDP configuration file (around line 12):
```
// NOTE: Tokens are just alphanumeric strings - make them hard to guess!
$cfg['authorized_tokens'] = array(
    //"mysecrettoken",  // <-- not a good token
    //"90dfs7jwn3",   // <-- a better token (don't use this exact one, make your own)
);
```

I replaced them with a number of random tokens, either from python 3.7's secrets or from wordpress salt creation.  I replaced all $, %, ` and !, so the token can be eaily used on a DOS or UNIX command line.

##### nrdp.conf

Additionally, should edit **nrdp.conf** to verify desired configuration.

Good luck, Phil
