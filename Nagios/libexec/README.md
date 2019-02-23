# Nagios Check Script
## Overview

This folder contains scripts to perform Nagios checks as follows:
1. check_state_statusjson.sh

### check_state_statusjson.sh

NRDP (Nagios Remote Data Processor) and NSCA (Nagios Service Check Acceptor) addons allow Nagios to integrate passive alerts and checks from remote machines and applications.

This check_state_statusjson.sh script is meant as a replacement for check_dummy script in a passive service that has **check_freshness** is enabled.

#### Installation
Installation example as follows:

```
$ sudo -i
$ cd /usr/local/nagios/libexec/
$ wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/libexec/check_state_statusjson.sh
--2019-02-05 20:08:16--  https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/libexec/check_state_statusjson.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 151.101.184.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|151.101.184.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4777 (4.7K) [text/plain]
Saving to: ‘check_state_statusjson.sh’

check_state_statusjson. 100%[===============================>]   4.67K  --.-KB/s    in 0s

2019-02-05 20:08:17 (9.12 MB/s) - ‘check_state_statusjson.sh’ saved [4777/4777]

$ chmod 755 check_state_statusjson.sh
$ chown nagios:nagios check_state_statusjson.sh
$ ./check_state_statusjson.sh -h
Script: check_state_statusjson.sh, version: 1.0.8

Usage: check_state_statusjson.sh [options]
  -e    escalate to critical, default value: true
  -l    logging to /tmp,      default value: true
  -H    service hostname,     default value: localhost
  -S    service description,  default value: unknown
  -U    user name,            default value: nagiosadmin
  -P    password,             default value: password
  -v    logging to stdout,    default value: false

Example: check_state_statusjson.sh -H SensorHost -S "sensor-19" -U nagiosuser -P passw0rd

$ ./check_state_statusjson.sh -H raspberrypi -S sensor-19 -P passw0rd
2019-02-05 14:17:30,sensor-19,Sensor,115,OK,OK: Sensor at location: 115 is closed
$
```
#### Configuration
Information on Nagios configuration values can be found [here](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/objectdefinitions.html).  Configuration of check_state_statusjson.sh as follows:

##### commands.cfg

The following is an example of a Nagios command configuration for the check_state_statusjson.sh script:

```
define command{
    command_name check_statusjson_state
    command_line /usr/local/nagios/libexec/check_state_statusjson.sh -H $ARG1$ -S $ARG2$ -P passw0rd
}
```

In production one might want to turn off logging with **-l false**

##### services.cfg

The following is an example of a Nagios service configuration for the check_state_statusjson.sh script:

```
define service {
    use                     passive_service
    service_description     sensor-19
    host_name               raspberrypi
    servicegroups           sensor-logger-services
    check_command           check_statusjson_state!raspberrypi!sensor-19
    obsess_over_service     0
    event_handler_enabled   0
    # *** notification ***
    # enable sending out notification
    notifications_enabled   1
    notification_interval   15
    contact_groups          sensor-contact-group
    # freshness check enabled
    check_freshness         1
    # if 5 minutes elapses (300 seconds) go critical
    freshness_threshold     300
}
```
One should change the **service_description**, **host_name**, **servicegroups** and **check_command** values approprately per your configuration.  The **check_freshness** and **freshness_threshold** values cause the **check_command** script/command to be called.

Good luck, Phil
