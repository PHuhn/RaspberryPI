#!/bin/bash
#
# ----------------------------------------------------------------------------
# Create a basic hosts.cfg file
#  Written by: Phil Huhn
#  Version 1
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.0.0"
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
    ${PROGNAME} version: ${REVISION}

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
if [ "${IP_SEG: -1}" != "." ]; then
    IP_SEG=${IP_SEG}.
fi
COUNTER=1
while [  $COUNTER -lt 255 ]; do
    IP_ADDR=${IP_SEG}${COUNTER}
    PG=$(ping -c 1 -a "${IP_ADDR}")
    if [ $? == 0 ]; then
        ALIAS=$(echo "${PG}" | head -n 1 | cut -d ' ' -f 2 | tr '.' '_')
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
    (( COUNTER++ ))
done
# end-of-script
