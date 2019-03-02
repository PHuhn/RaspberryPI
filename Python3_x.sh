#!/bin/bash
#
# ----------------------------------------------------------------------------
#
# version of:
# https://gist.githubusercontent.com/SeppPenner/6a5a30ebc8f79936fa136c524417761d/raw/3060da171c0653daac52b17e1598919a0ecb17e6/setup.sh
#
PROGNAME=$(basename "$0")
REVISION="1.0.5"
#
PY_VER=3.7.2
GPIO=true
ODBC=false
FORCE=false
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: $0 [options]

  -h    this help text.
  -p    python version, default value: ${PY_VER}
  -f    force python,   default value: ${FORCE}
  -g    install GPIO,   default value: ${GPIO}
  -o    install ODBC,   default value: ${ODBC}

  Example:  $0 -p 3.8.0a2 -o true

EOF
  exit
fi
#
# process of arguments
#
while getopts ":p:f:g:o:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    p) PY_VER=${OPTARG};;
    f) FORCE=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
    g) GPIO=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
    o) ODBC=`echo ${OPTARG} | tr '[:upper:]' '[:lower:]'`;;
  esac
done
#
PY_CMD=`echo ${PY_VER} | grep -Po '^\d.\d'`
PY_DIR=`echo ${PY_VER} | grep -Po '^\d.\d.\d'`
echo "force python value: ${FORCE}"
echo "install GPIO value: ${GPIO}"
echo "install ODBC value: ${ODBC}"
echo "${LINENO} ${PROGNAME}, Install Python ${PY_VER}, command python${PY_CMD}"
date
#
cd /tmp
echo "${LINENO} ${PROGNAME}, apply updates, ..."
sudo apt update
sudo apt upgrade
echo "${LINENO} ${PROGNAME}, requirements, ..."
sudo apt install gcc libxml2-dev libxslt1-dev zlib1g-dev g++
sudo apt-get update -y
echo "${LINENO} ${PROGNAME}, build-essential, ..."
sudo apt-get install build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y
#
which "python${PY_CMD}" > /dev/null
if [ $? != 0 ] || [ "x${FORCE}" == "xtrue"]; then
  echo "${LINENO} ${PROGNAME}, download and build Python ${PY_VER}"
  wget https://www.python.org/ftp/python/${PY_DIR}/Python-${PY_VER}.tar.xz
  tar xf Python-${PY_VER}.tar.xz
  cd Python-${PY_VER}
  ./configure
  make -j 4
  sudo make altinstall
  cd ..
  sudo rm -r Python-${PY_VER}
  rm Python-${PY_VER}.tar.xz
  #
  sudo python${PY_CMD} -m pip install --upgrade pip
  #
else
  echo "${LINENO} ${PROGNAME}, skipping python download and build, ..."
fi
#
sudo apt update
sudo apt upgrade
sudo apt-get install unixodbc-dev
#
if [ "x${GPIO}" == "xtrue" ]; then
  echo "${LINENO} ${PROGNAME}, installing GPIO, ..."
  sudo python${PY_CMD} -m pip install gpiozero
  sudo python${PY_CMD} -m pip install rpi.gpio
  sudo python${PY_CMD} -m pip install pigpio
  sudo python${PY_CMD} -m pip install RPIO
else
  echo "${LINENO} ${PROGNAME}, skipping GPIO, ..."
fi
#
if [ "x${ODBC}" == "xtrue" ]; then
  echo "${LINENO} ${PROGNAME}, installing ODBC, ..."
  sudo python${PY_CMD} -m pip install pyodbc
else
  echo "${LINENO} ${PROGNAME}, skipping ODBC, ..."
fi
#
sudo apt-get --purge remove tk-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y
sudo apt-get autoremove -y
sudo apt-get clean
#
cd ~
echo "Now use python${PY_CMD} command to use this version,"
echo "or link python3 to point to python${PY_CMD} version."
echo "Do NOT link python to point to another version and do NOT delete python2.7"
#
