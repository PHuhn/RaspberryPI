#!/bin/bash
#
# ----------------------------------------------------------------------------
#
# version of:
# https://gist.githubusercontent.com/SeppPenner/6a5a30ebc8f79936fa136c524417761d/raw/3060da171c0653daac52b17e1598919a0ecb17e6/setup.sh
#
PROGNAME=$(basename "$0")
REVISION="1.0.4"
#
PY_VER=3.7.2
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: $0 [options]

  -h    this help text.
  -p    python version, default value: ${PY_VER}

  Example:  $0 -p 3.8.0a2

EOF
  exit
fi
#
# process of arguments
#
while getopts ":p:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    p) PY_VER=${OPTARG};;
  esac
done
#
PY_CMD=`echo ${PY_VER} | grep -Po '^\d.\d'`
PY_DIR=`echo ${PY_VER} | grep -Po '^\d.\d.\d'`
echo "${LINENO} ${PROGNAME}, Install Python ${PY_VER}"
date
#
cd /tmp
echo "${LINENO} ${PROGNAME}, apply updates"
sudo apt update
sudo apt upgrade
echo "${LINENO} ${PROGNAME}, pip for python3"
sudo apt install gcc python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev g++
sudo apt-get update -y
echo "${LINENO} ${PROGNAME}, build-essential, ..."
sudo apt-get install build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y
#
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
# sudo apt-get --purge remove tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y
sudo apt-get autoremove -y
sudo apt-get clean
#
sudo python${PY_CMD} -m pip install --upgrade pip
#
sudo apt update
sudo apt upgrade
sudo apt install gcc python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev g++
# python3-pyodbc for python3
sudo apt-get install unixodbc-dev python3-pyodbc
#
sudo python${PY_CMD} -m pip install gpiozero
sudo python${PY_CMD} -m pip install rpi.gpio
sudo python${PY_CMD} -m pip install pigpio
sudo python${PY_CMD} -m pip install RPIO
#
sudo python${PY_CMD} -m pip install pyodbc
#
cd ~
echo "now use python${PY_CMD} command to use this version."
#
