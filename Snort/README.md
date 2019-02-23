# Snort on Raspberry PI (Stretch)
## Overview

This repository contains scripts to configure Snort project as follows:
- snort - three bash scripts for installing and configuring snort.
  1. SnortDepend.sh
  2. SnortInstall.sh
  3. SnortConfig.sh

At the time of creation, these scripts were designed be executed without any paramenters.  I tried to make the scripts, also work as versions change, so I allowed passing parameters.  Even from Oct to Nov of 2018, things changed that caused me to have to change these scripts.

### Snort Installation and Configuration

#### SnortDepend.sh
install snort dependenies of 
bison, flex, libpcap-dev, libpcre3-dev, libdumbnet-dev, Checkinstall, LauJIT, OpenSSL, DAQ (data acquistion)
```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortDepend.sh
$ chmod 755 SnortDepend.sh
$ ./SnortDepend.sh -h
  Usage: ./SnortDepend.sh [options]

  -h    this help text.
  -l    LuaJIT version, default example 2.0.5
  -o    OpenSSL version, default example 1.1.1
  -d    DAQ version, default example 2.0.6

$ ./SnortDepend.sh
```

#### SnortInstall.sh
download, compile and install snort 
```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortInstall.sh
$ chmod 755 SnortInstall.sh
$ ./SnortInstall.sh -h
  Usage: ./SnortInstall.sh [options]

  -h    this help text.
  -s    snort version, default example 2.9.12

$ ./SnortInstall.sh
```

#### SnortConfig.sh
snort configuration as follows:
- create snort directory (/etc/snort),
- load rules snapshot,
- download, edit (sed) and load some community rules to local.rules,
- copy stuff to snort directory,
- set permissions and owner,
- edit (sed) snort.conf file,
- test configuration.

to get snapshot to the PI:
```
> pscp snortrules-snapshot-2990.tar.gz pi@192.168.0.10:./sourcecode/snort_src/.
```

to run the configuration script:
```
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Snort/SnortConfig.sh
$ chmod 755 SnortConfig.sh
$ ./SnortConfig.sh -h
  Usage: ./SnortConfig.sh [options]

  -h    this help text.
  -s    snort version, default example 2.9.12
  -r    rules version, example 2990
        required for downloading snapshot rules
  -o    oink code, example 7b11111111111111111111111111111111111015
        required for downloading snapshot rules

$ ./SnortConfig.sh
```

The config script will accept a secure copy snapshot rule, passing no rules version and oink code, or the script can get the snapshot rules by passing both snapshot rule version and oink code.

Good luck, Phil
