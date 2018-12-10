#!/bin/bash
#
# Miniumum configuration Raspberry PI running raspian
#  Written by: Phil Huhn
#  Version 1
#
# Varialbes:
COUNTRY=US
TIMEZONE="michigan"
#
read -d '' HELP <<-"_EOF_"
  Usage: $0 [options]

  -h    this help text.
  -c    country code,  default value: ${COUNTRY}
  -t    timezone code, default value: ${TIMEZONE}

  Example:  $0 -c canada -t eastern

_EOF_

if [ "$1" == "-h" ]; then
  echo $HELP
  cat <<EOF
  Usage: $0 [options]

  -h    this help text.
  -c    country code,  default value: ${COUNTRY}
  -t    timezone code, default value: ${TIMEZONE}

  Example:  $0 -c canada -t eastern

EOF
  exit
fi
#
echo "=- Configure Raspberry PI -="
date
#
while getopts ":c:t:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    c) COUNTRY=${OPTARG};;
    t) TIMEZONE=${OPTARG};;
  esac
done
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
echo "=- Set keyboard locale -="
# sudo sed -i -e "s/^XKBLAYOUT=\"gb\"/XKBLAYOUT=\"${COUNTRY_L}\"/" /etc/default/keyboard
sudo dpkg-reconfigure keyboard-configuration
sudo service keyboard-setup restart
grep "XKBLAYOUT" /etc/default/keyboard
#
echo "=- Update the Raspian O/S -="
sudo apt-get update && sudo apt-get dist-upgrade –y
#
echo "=- Change password -="
echo "  ^d to beark out of passwd..."
passwd
#
date
echo "=- End of Configure Raspberry PI -="
#