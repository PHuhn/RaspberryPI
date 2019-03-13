#!/bin/bash
# 2019-01-30 V1.0.0 Phil of Northern Software Group
# Return the current state/status of the service or escalates from warning to
# critical state.
#    this uses the following to obtain state/status information
#    1) curl localhost/nagios/cgi-bin/statusjson.cgi
#    2) awk script against nagios/var/status.dat
# ============================================================================
# 2019-02-05 V1.0.8 Phil
# 2019-03-12 V1.0.9 Phil empty PASSWD forces only awk script
#
# program values
PROGNAME=$(basename "$0")
REVISION="1.0.9"
# exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
# parameter values
HOST=localhost
SERVICE=unknown
USERID=nagiosadmin
PASSWD=
ESCALATE=true
LOGGING=true
VERBOSE=false
#
print_help() {
    print_version
    cat <<EOF

Usage: ${PROGNAME} [options]
  -H    service hostname,     default value: ${HOST}
  -S    service description,  default value: ${SERVICE}
  -U    cgi user name,        default value: ${USERID}
  -P    cgi password,         default value: ${PASSWD}
  -e    escalate to critical, default value: ${ESCALATE}
  -l    logging to /tmp,      default value: ${LOGGING}
  -v    logging to stdout,    default value: ${VERBOSE}

  Example: ${PROGNAME} -H SensorHost -S "sensor-19" -U nagiosuser -P passw0rd
EOF
}
#
print_version() {
    echo "Script: ${PROGNAME}, version: ${REVISION}"
}
#
# Information options
case "${1}" in
    --help)
        print_help
        exit "${STATE_OK}"
        ;;
    -h)
        print_help
        exit "${STATE_OK}"
        ;;
    --version)
        print_version
        exit "${STATE_OK}"
        ;;
    -V)
        print_version
        exit "${STATE_OK}"
        ;;
esac
#
while getopts ":e:H:l:S:U:P:v:" option
do
    case "${option}"
        in
        H) HOST=${OPTARG};;
        S) SERVICE=${OPTARG};;
        U) USERID=${OPTARG};;
        P) PASSWD=${OPTARG};;
        e) ESCALATE=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
        l) LOGGING=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
        v) VERBOSE=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
    esac
done
#
if [ "${LOGGING}" == "true" ]; then
    LOG_FILE=/tmp/${PROGNAME}.log
    if [ ! -f ${LOG_FILE} ]; then
        echo "$$ ${PROGNAME} initializing ..." >> ${LOG_FILE}
        chmod 666 ${LOG_FILE}
    fi
else
    # if don't want LOG_FILE then change to /dev/null
    LOG_FILE=/dev/null
fi
# This overrides LOGGING value
if [ "${VERBOSE}" == "true" ]; then
    LOG_FILE=/dev/stdout
fi
echo "$$ ${PROGNAME} starting at $(date '+%Y-%m-%d %H:%M:%S') ..." >> ${LOG_FILE}
#
QUERY="query=service&hostname=${HOST}&servicedescription=${SERVICE}"
echo "$$ ${PROGNAME} ${QUERY}" >> ${LOG_FILE}
FILE=/tmp/check_${SERVICE}_$$
STATUS_FILE=/usr/local/nagios/var/status.dat
STATE=
OUTPUT=
# can test with wrong password
if [ "X${PASSWD}" != "X" ]; then
    curl -v "http://${USERID}:${PASSWD}@localhost/nagios/cgi-bin/statusjson.cgi?${QUERY}" 1> ${FILE} 2> /dev/null
    if [ -s ${FILE} ]; then
        grep "last_hard_state.:" ${FILE} >/dev/null 2>&1
        if [ $? == "0" ]; then
            echo "$$ ${PROGNAME} processing statusjson.cgi" >> ${LOG_FILE}
            STATE=`grep "last_hard_state.:" ${FILE} | cut -d ":" -f 2 | tr -cd [:digit:]` 2> /dev/null
            OUTPUT=`grep "\"plugin_output.:" ${FILE} | tr -s ' ' | tr -d '"' |  sed -e 's/ plugin_output: //' -e 's/,$//'` 2> /dev/null
        fi
    else
        echo "$$ ${PROGNAME} statusjson.cgi empty, awk command against ${STATUS_FILE}" >> ${LOG_FILE}
    fi
fi
if [ "${STATE}X" == "X" ]; then
    awk -v FS='\n' -v RS='\n\n' -v h_name="${HOST}" -v s_name="${SERVICE}" 'BEGIN {host="host_name="h_name; service="service_description="s_name; print host", "service;}{ if (match($0,host) && match($0,service)) { print "##" $0; } }' ${STATUS_FILE} > ${FILE}
    STATE=`grep "last_hard_state=" ${FILE} | cut -d "=" -f 2 | tr -cd [:digit:]` 2> /dev/null
    OUTPUT=`grep "plugin_output=" ${FILE} | cut -d "=" -f 2 | sed 's/,$//'` 2> /dev/null
fi
chmod 666 ${FILE}
#
echo "$$ ${PROGNAME} state: ${STATE}, output: ${OUTPUT}" >> ${LOG_FILE}
# move output file to a single 'last' file
cp -f ${FILE} /tmp/check_${SERVICE}_last
rm ${FILE}
#
if [ "${STATE}X" != "X" ]; then
    if [ "${STATE}" == "${STATE_OK}" ]; then
        if [ "${OUTPUT}X" != "X" ]; then
            echo "${OUTPUT}"
        else
            echo "OK"
        fi
        exit "${STATE_OK}"
    elif [ "${STATE}" == "${STATE_WARNING}" ]; then
        if [ "${OUTPUT}X" != "X" ]; then
            echo "${OUTPUT}"
        else
            if [ ${ESCALATE} == "true" ]; then
                echo "CRITICAL"
            else
                echo "WARNING"
            fi
        fi
        if [ ${ESCALATE} == "true" ]; then
            exit "${STATE_CRITICAL}"
        fi
        exit "${STATE_WARNING}"
    elif [ "${STATE}" == "${STATE_CRITICAL}" ]; then
        if [ "${OUTPUT}X" != "X" ]; then
            echo "${OUTPUT}"
        else
            echo "CRITICAL"
        fi
        exit "${STATE_CRITICAL}"
    else
        echo "UNKNOWN"
        exit "${STATE_UNKNOWN}"
    fi
else
    echo "UNKNOWN"
    exit "${STATE_UNKNOWN}"
fi
# == end-of-script ==
