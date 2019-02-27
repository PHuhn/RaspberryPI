#!/bin/bash
#
# ----------------------------------------------------------------------------
# Install Nagios NRDP on a Raspberry PI running raspian
#  Written by: Phil Huhn
#  Version 5
#
# NRDP - Installing NRDP From Source
# https://support.nagios.com/kb/article/nrdp-installing-nrdp-from-source-602.html#Raspbian
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.0.5"
NRDP_DIR=/usr/local/nrdp
SRC_DIR=/usr/local/src
# Options Varialbes:
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
if [ ! -d "${SRC_DIR}" ]; then
  mkdir -p ${SRC_DIR}
fi
if [ ! -d "${SRC_DIR}" ]; then
  echo "${LINENO} ${PROGNAME}, failed to create src dir."
  exit 1
fi
cd ${SRC_DIR}
#
wget -O nrdp-${NRDP_VER}.tar.gz https://github.com/NagiosEnterprises/nrdp/archive/${NRDP_VER}.tar.gz
tar xvf nrdp-${NRDP_VER}.tar.gz
#
if [ -d "${SRC_DIR}/nrdp-${NRDP_VER}" ]; then
  cd ${SRC_DIR}/nrdp-${NRDP_VER}
  mkdir -p ${NRDP_DIR}
  if [ -d "${NRDP_DIR}" ]; then
    apt-get update
    apt-get install -y php-xml
    cp -r clients server LICENSE* CHANGES* ${NRDP_DIR}
    chown -R nagios:nagios ${NRDP_DIR}
    cp nrdp.conf /etc/apache2/sites-enabled/.
    systemctl restart apache2.service
    # generate 8 random 64 byte tokens with python secrets
    which python3.7
    if [ $? == 0 ]; then
      python3.7 << _EOF >> token.txt
import secrets as Secrets
for i in range(0, 8):
    print('    "{0}",'.format(Secrets.token_urlsafe(64)))
_EOF
    else
      # these are farely random values, but % bad for DOS, $ bad for UNIX, ! (history) causes 'event not found'
      wget -O token.txt https://api.wordpress.org/secret-key/1.1/salt/
      sed -E -e "s/define\(.................../   /" -e "s/([$%\`\!\])/=/g" -e "s/'/\"/g" -e "s/..$/,/" -i token.txt
    fi
    # edit the nrdp config file by finding the 2 fake tokens and delete them,
    # then read in the token.txt at that point, write and quit
    ed ${NRDP_DIR}/server/config.inc.php <<EOF
/mysecrettoken/
.,+1d
.-1r token.txt
w
q
EOF
    echo ""
    echo "=- * suggested tokens for config.inc.php * -="
    cat token.txt
    #
    echo "${NRDP_DIR}/server/config.inc.php should now contain the above suggested tokens..."
    echo "You can remove them, or add additional tokens."
    echo "also edit /etc/apache2/sites-enabled/nrdp.conf to verify desired configuration."
    #
    rm token.txt
    rm ${SRC_DIR}/nrdp-${NRDP_VER}.tar.gz
  else
    echo "${LINENO} ${PROGNAME}, install of nrdp failed, no ${NRDP_DIR} directory."
  fi
  #
else
  echo "${LINENO} ${PROGNAME}, install of nrdp failed, no nrdp-${NRDP_VER} directory."
fi
#
date
echo "=- End of install of NRDP on Raspberry PI -="
# 
