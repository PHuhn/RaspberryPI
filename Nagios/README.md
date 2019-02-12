# Nagios Install Scripts
## Overview

This folder contains scripts to perform Nagios installations as follows:
1. NagiosInstall.sh
1. NagiosNrdpInstall.sh

### NagiosInstall.sh

#### Installation
Installation example as follows:

```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/NagiosInstall.sh
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/rasp-pi-logo-icon.png
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/win10-logo-icon.png
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

### NagiosNrdpInstall.sh

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
    "8gN:hyTs7p`0P}i&6[.i~x-! me!j8e^nySlTWSR DkU{;-}+TY_fy-t=Ih7M+do",
    "5y|fEwd{oo]7/R_!cxm?h`r8Z/-|hJmx}Z=au>O>Q]1Xiw,kIA]vT!^hx-w{ZArE",
    "1O#&.VU-!)&K~Cv+T48/=F9#dX-+<B6E|_m;0R:w#`9-v7zh1CmU-`1.uNCZ4s!K",
    " -3AB=.9X7Rzfyh<F5zAY,Ty=l *ZQSSH#CJh_~&g3((_,{8d-_2q.GX+G*bECJm",
    "hc#a6F9TQEq6du/h=EG.^_L};-4M>!&d=jMK 4kfGM^*JU`=51@a=c*FSQxKR-!J",
    "FyYJ6P(3RB{>F@Q}2l-_}ozz~*U2vPQ[Fa3{HA6Jlw)TqAt~K|;I2~+o(e-mgv+n",
    "7lG7nIs5Y:()5lyAOf+Y|710+e*+KzBurDAJ?<S)N+5)v-cHa!,: hu<bdchFSB>",
    ")3,gU-0&7+6:V^>OX|!I6a|-IdD-[Uq<GW]rfd<GTN0:x/,K+7-^A.DJQVK)Pe7l",
Edit /usr/local/nrdp/server/config.inc.php and cut & paste above suggested tokens...
also edit /etc/apache2/sites-enabled/nrdp.conf to verify desired configuration.
Tue 12 Feb 09:06:21 EST 2019
=- End of install of NRDP on Raspberry PI -=
$ sudo vi /usr/local/nrdp/server/config.inc.php
```

* Need to edit **/usr/local/nrdp/server/config.inc.php** file and define security tokens.  Suggested values are supplied. 
* Additionally, should edit **/etc/apache2/sites-enabled/nrdp.conf** to verify desired configuration.


Good luck, Phil
