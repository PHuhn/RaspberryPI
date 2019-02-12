#!/bin/bash
#
# ----------------------------------------------------------------------------
# Install Nagios NRDP on a Raspberry PI running raspian
#  Written by: Phil Huhn
#  Version 3
#
# NRDP - Installing NRDP From Source
# https://support.nagios.com/kb/article/nrdp-installing-nrdp-from-source-602.html#Raspbian
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.0.3"
# Varialbes:
NRDP_VER=1.5.2
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: ${PROGNAME} [options]

  -h    this help text.
  -n    nagios nrdp version, default value: ${NRDP_VER}

  Example:  ${PROGNAME} -n 1.5.1

EOF
  exit
fi
#
echo "=- Running ${PROGNAME} ${REVISION} -="
date
#
while getopts ":n:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    n) NRDP_VER=${OPTARG};;
  esac
done
# addon source directory
if [ ! -d "/usr/local/src/" ]; then
    mkdir -p /usr/local/src/
fi
if [ ! -d "/usr/local/src/" ]; then
    echo "${LINENO} ${PROGNAME}, failed to create src dir."
    exit 1
fi
cd /usr/local/src/
#
wget -O nrdp-${NRDP_VER}.tar.gz https://github.com/NagiosEnterprises/nrdp/archive/${NRDP_VER}.tar.gz
tar xvf nrdp-${NRDP_VER}.tar.gz
cd nrdp-${NRDP_VER}
#
if [ -d "/usr/local/src/nrdp-${NRDP_VER}" ]; then
    cd nrdp-${NRDP_VER}
    mkdir -p /usr/local/nrdp
    if [ -d "/usr/local/nrdp" ]; then
        apt-get update
        apt-get install -y php-xml
        cp -r clients server LICENSE* CHANGES* /usr/local/nrdp
        chown -R nagios:nagios /usr/local/nrdp 
        cp nrdp.conf /etc/apache2/sites-enabled/.
        systemctl restart apache2.service
        # these are farely random values, but % bad for DOS and $ bad for UNIX
        wget -O token.txt https://api.wordpress.org/secret-key/1.1/salt/
        sed -E -e "s/define\(.................../   /" -e "s/([$%\])/=/g" -e "s/'/\"/g" -e "s/..$/,/" -i token.txt
        echo ""
        echo "=- * suggested tokens for config.inc.php * -="
        cat token.txt
        #
        echo "Edit /usr/local/nrdp/server/config.inc.php and cut & paste above suggested tokens..."
        echo "also edit /etc/apache2/sites-enabled/nrdp.conf to verify desired configuration."
        #
        rm /usr/local/src/nrdp-${NRDP_VER}.tar.gz
    else
        echo "${LINENO} ${PROGNAME}, install of nrdp failed, no /usr/local/nrdp directory."
    fi
    #
else
    echo "${LINENO} ${PROGNAME}, install of nrdp failed, no nrdp-${NRDP_VER} directory."
fi
#
date
echo "=- End of install of NRDP on Raspberry PI -="
# 
