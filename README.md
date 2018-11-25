# Raspberry PI
## Overview
This repository contains one project as follows:
- snort - three bash scripts for installing and configuring snort.

### Snort

#### SnortDepend.sh
install snort dependenies of 
bison, flex, libpcap-dev, libpcre3-dev, libdumbnet-dev, Checkinstall, LauJIT, OpenSSL, DAQ (data acquistion)
```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortDepend.sh
$ chmod 755 SnortDepend.sh
$ ./SnortDepend.sh
```

#### SnortInstall.sh
download, compile and install snort 
```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortInstall.sh
$ chmod 755 SnortInstall.sh
$ ./SnortInstall.sh
```

#### SnortConfig.sh
snort configuration
- create /etc/snort
- load rules snapshot
- download and load some community rules to local.rules
- copy stuff to snort directory
- set permissions and owner
- edit (sed) snort.conf file

```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortConfig.sh
$ chmod 755 SnortConfig.sh
$ ./SnortConfig.sh
```

Good luck, Phil
