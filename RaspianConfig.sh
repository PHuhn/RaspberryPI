#!/bin/bash
#
# ----------------------------------------------------------------------------
# Miniumum configuration Raspberry PI running raspian
#  Written by: Phil Huhn
#  Version 5
#
# Varialbes:
COUNTRY=US
TIMEZONE="michigan"
SERIAL_BT=false
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: $0 [options]

  -h    this help text.
  -c    country code,     default value: ${COUNTRY}
  -t    timezone code,    default value: ${TIMEZONE}
  -s    serial bluetooth, default value: ${SERIAL_BT}

  Example:  $0 -c canada -t eastern -s true

EOF
  exit
fi
#
echo "=- Configure Raspberry PI -="
date
#
# process of arguments
#
while getopts ":c:s:t:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    c) COUNTRY=${OPTARG};;
    t) TIMEZONE=${OPTARG};;
    s) SERIAL_BT=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
  esac
done
#
# Change pi password
#
echo "=- Change password -="
echo "  ^d to break out of passwd..."
passwd
#
COUNTRY_L=$(echo "${COUNTRY}" | tr '[:upper:]' '[:lower:]')
COUNTRY_U=$(echo "${COUNTRY}" | tr '[:lower:]' '[:upper:]')
COUNTRY_M="${COUNTRY_U:0:1}${COUNTRY_L:1}"
# echo ${COUNTRY_L} ${COUNTRY_U} ${COUNTRY_M}
#
TIMEZONE_L=$(echo "${TIMEZONE}" | tr '[:upper:]' '[:lower:]')
TIMEZONE_U=$(echo "${TIMEZONE}" | tr '[:lower:]' '[:upper:]')
TIMEZONE_M="${TIMEZONE_U:0:1}${TIMEZONE_L:1}"
# echo ${TIMEZONE_L} ${TIMEZONE_U} ${TIMEZONE_M}
#
# Some countries are just uppercase and some are mixed case,
# some are directories and some are files.
echo "=- Set timezone -="
if [ -d "/usr/share/zoneinfo/${COUNTRY_U}" ]; then
  echo ${COUNTRY_U}/${TIMEZONE_M}
  sudo ln -sf /usr/share/zoneinfo/${COUNTRY_U}/${TIMEZONE_M} /etc/localtime
else
  if [ -d "/usr/share/zoneinfo/${COUNTRY_M}" ]; then
    echo ${COUNTRY_M}/${TIMEZONE_M}
    sudo ln -sf /usr/share/zoneinfo/${COUNTRY_M}/${TIMEZONE_M} /etc/localtime
  else
    if [ -f "/usr/share/zoneinfo/${COUNTRY_U}" ]; then
      echo ${COUNTRY_U}
      sudo ln -sf /usr/share/zoneinfo/${COUNTRY_U} /etc/localtime
    else
      if [ -f "/usr/share/zoneinfo/${COUNTRY_M}" ]; then
        echo ${COUNTRY_M}
        sudo ln -sf /usr/share/zoneinfo/${COUNTRY_M} /etc/localtime
      else
        echo "Timezone of ${COUNTRY_U} and ${TIMEZONE_M}, not set."
      fi
    fi
  fi
fi
if [ ! -e /etc/localtime ] ; then
  ls -l /etc/localtime
  echo "Broken timezone link."
  echo sudo ln -sf /usr/share/zoneinfo/{COUNTRY}/{TIMEZONE} /etc/localtime
  ls /usr/share/zoneinfo/
fi
#
# Configure bluetooth serial connection
#
if [ "${SERIAL_BT}" == "true" ]; then
  BT_DIR=/usr/local/bluetooth
  if [ ! -d "${BT_DIR}" ]; then
    echo "=- Created ${BT_DIR} directory -="
    sudo mkdir ${BT_DIR}
  fi
  if [ ! -f ${BT_DIR}/btserial.sh ]; then
    cd ${BT_DIR}
    sudo wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/btserial.sh
    sudo chmod 755 ./btserial.sh
    echo "=- Created ${BT_DIR}/btserial.sh file -="
    # now edit /etc/rc.local
    grep btserial /etc/rc.local > /dev/null
    if [ $? != 0 ]; then
      # go to the last line and come up one line and insert commands and then save.
      sudo ed /etc/rc.local <<EOF
$
.-1i

# Launch bluetooth service startup script /home/pi/btserial.sh
sudo /usr/local/bluetooth/btserial.sh &
.
w
q
EOF
      echo "=- Added ${BT_DIR}/btserial.sh to /etc/rc.local -="
    fi
  fi
fi
#
# Set keyboard locale
#
echo "=- Set keyboard locale -="
sudo sed -i -e "s/^XKBLAYOUT=\"gb\"/XKBLAYOUT=\"${COUNTRY_L}\"/" /etc/default/keyboard
# sudo dpkg-reconfigure keyboard-configuration
# sudo service keyboard-setup restart
grep "XKBLAYOUT" /etc/default/keyboard
#
# Update various Raspian packages
#
echo "=- Update the Raspian O/S -="
sudo apt-get update
sudo apt-get dist-upgrade
#
date
echo "=- End of Configure Raspberry PI -="
# End of script