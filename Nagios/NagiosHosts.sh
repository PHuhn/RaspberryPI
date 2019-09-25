#!/bin/bash
#
# ----------------------------------------------------------------------------
# Create a basic hosts.cfg file
#  Written by: Phil Huhn
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.1.0"
# Varialbes:
IP_SEG=192.168.0.
CHECK_ALIVE=true
FILE=./hosts.cfg
#
MY_IP=$(ifconfig | grep "inet " | grep -v 127.0.0 | tr -s " " | cut -d " " -f 3 | head -n 1)
echo "My ip address is: ${MY_IP}"
echo ""
#
if [ "$1" == "-h" ]; then
    cat <<EOF

    Usage: ${PROGNAME} [options]

    -h    this help text.
    -i    IP segment,  default value: ${IP_SEG}
    -c    check alive, default value: ${CHECK_ALIVE}
    -f    file name,   default value: ${FILE}

    Example:  $0 -i 192.168.1. -f hosts.1.cfg

    Created the following for each host on the network:

    define host {
        use                   generic-host
        host_name             192_168_0_1
        alias                 192_168_0_1
        address               192.168.0.1
        check_command         check-host-alive
        active_checks_enabled 1
    }
    #
EOF
    exit
fi
#
while getopts ":i:c:f:" option
do
    case "${option}"
    in
        i) IP_SEG=${OPTARG};;
        c) CHECK_ALIVE=${OPTARG};;
        f) FILE=${OPTARG};;
        *) echo "Invalid option: ${option}  arg: ${OPTARG}"
            exit 1
            ;;
    esac
done
#
echo "=- Running ${PROGNAME} ${REVISION} -="
date
# ===============================
# Install nbtscan (netbios scan)
# ===============================
pkg_not_exists=$(dpkg-query -W nbtscan)
if [ $? != 0 ] || [ $(echo ${pkg_not_exists} | cut -d" " -f1) != "nbtscan" ]; then
    echo "=- Installing nbtscan -="
    sudo apt-get install nbtscan
else
    echo "=- Skipping nbtscan install -="
    echo ${pkg_not_exists}
    echo ""
fi
#
# 'arp -a' is returning the following:
# ? (192.168.0.26) at 34:f6:4b:6c:31:d0 [ether] on wlan0
for IP_ADDR in $(arp -a | cut -d" " -f2 | sed -e 's/^.//' -e 's/.$//' | sort); do
    echo ${IP_ADDR}
    PG=$(ping -c 1 -a "${IP_ADDR}")
    if [ $? == 0 ]; then
        ALIAS=""
        NB_NAME_LINE=`nbtscan ${IP_ADDR} | tail -n 1`
        if [[ ${NB_NAME_LINE:0:4} == "----" ]]; then
            ALIAS=$(echo "${PG}" | head -n 1 | cut -d ' ' -f 2 | tr '.' '_')
        else
            ALIAS=`echo $NB_NAME_LINE | cut -f2 -d " "`
        fi
        IP=$(echo "${PG}" | head -n 1 | cut -d ' ' -f 3 | tr -d '\(\)')
        if [ "X${IP_ADDR}" == "X${IP}" ]; then
            echo "define host {"                          | tee -a "${FILE}"
            echo "    use                   generic-host" | tee -a "${FILE}"
            echo "    host_name             ${ALIAS}"     | tee -a "${FILE}"
            echo "    alias                 ${ALIAS}"     | tee -a "${FILE}"
            echo "    address               ${IP_ADDR}"   | tee -a "${FILE}"
            if [ "X${CHECK_ALIVE}" == "Xtrue" ]; then
                echo "    check_command         check-host-alive" | tee -a "${FILE}"
                echo "    active_checks_enabled 1"                | tee -a "${FILE}"
                echo "    max_check_attempts    1"                | tee -a "${FILE}"
            fi
            echo "    register              1"   | tee -a "${FILE}"
            echo "}"                                      | tee -a "${FILE}"
            echo "#"                                      | tee -a "${FILE}"
        else
            echo "Error is ${IP_ADDR} and ${IP} are different?"
        fi
    else
        echo "IP ${IP_ADDR} not active..."
    fi
done
# end-of-script
