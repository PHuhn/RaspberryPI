#!/bin/bash
#
# ----------------------------------------------------------------------------
# Generalized and expanded version of:
# https://gist.githubusercontent.com/SeppPenner/6a5a30ebc8f79936fa136c524417761d/raw/3060da171c0653daac52b17e1598919a0ecb17e6/setup.sh
# By Phil Huhn
#
PROGNAME=$(basename "$0")
REVISION="1.0.6"
# Options variables:
PY_VER=3.7.2
GPIO=true
ODBC=false
FORCE=false
LINK=false
#
if [ "$1" == "-h" ]; then
  cat <<EOF

  Usage: $0 [options]

  -h    this help text.
  -p    python version, default value: ${PY_VER}
  -f    force python,   default value: ${FORCE}
  -l    link python3,   default value: ${LINK}
  -g    install GPIO,   default value: ${GPIO}
  -o    install ODBC,   default value: ${ODBC}

  Example:  $0 -p 3.8.0a2 -o true -l true

EOF
  exit
fi
#
# process of arguments
#
while getopts ":p:f:l:g:o:" option
do
  case "${option}"
  in
    p) PY_VER=${OPTARG};;
    f) FORCE=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
    l) LINK=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
    g) GPIO=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
    o) ODBC=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]');;
    *) echo "Invalid option: ${option}  arg: ${OPTARG}"
      exit 1
      ;;
  esac
done
#
echo "=- Running ${PROGNAME} ${REVISION} -="
date
#
PY_CMD=$(echo "${PY_VER}" | grep -Po '^\d.\d')
PY_DIR=$(echo "${PY_VER}" | grep -Po '^\d.\d.\d')
echo "force python value: ${FORCE}"
echo "link install, value: ${LINK}"
echo "install GPIO value: ${GPIO}"
echo "install ODBC value: ${ODBC}"
echo "${LINENO} ${PROGNAME}, Install Python ${PY_VER}, command python${PY_CMD}"
date
#
cd /tmp || exit 1
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
if [ $? != 0 ] || [ "x${FORCE}" == "xtrue" ]; then
  echo "${LINENO} ${PROGNAME}, download and build Python ${PY_VER}"
  wget "https://www.python.org/ftp/python/${PY_DIR}/Python-${PY_VER}.tar.xz"
  tar xf "Python-${PY_VER}.tar.xz"
  cd "Python-${PY_VER}" || exit 2
  ./configure
  make -j 4
  sudo make altinstall
  cd .. || exit 3
  sudo rm -r "Python-${PY_VER}"
  rm "Python-${PY_VER}.tar.xz"
  #
  which "python${PY_CMD}" > /dev/null
  if [ $? != 0 ]; then
    echo "${LINENO} ${PROGNAME}, python failed to build, ..."
    exit 1
  fi
  sudo apt install python3-pip
  #
  if [ "X${LINK}" == Xtrue ]; then
    sudo rm /usr/bin/python3
    sudo ln -s "/usr/local/bin/python${PY_CMD}" /usr/bin/python3
    echo "${LINENO} ${PROGNAME}, current python version, ..."
    python3 -V
  fi
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
  sudo apt-get update -y
  echo "${LINENO} ${PROGNAME}, installing GPIO, ..."
  sudo apt install python3-gpiozero
  # sudo apt install python3-rpi.gpio (now automatically installed)
  sudo "python${PY_CMD}" -m pip install pigpio
  sudo "python${PY_CMD}" -m pip install RPIO
else
  echo "${LINENO} ${PROGNAME}, skipping GPIO, ..."
fi
#
if [ "x${ODBC}" == "xtrue" ]; then
  echo "${LINENO} ${PROGNAME}, installing ODBC, ..."
  sudo "python${PY_CMD}" -m pip install pyodbc
else
  echo "${LINENO} ${PROGNAME}, skipping ODBC, ..."
fi
#
sudo apt-get --purge remove tk-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y
sudo apt-get autoremove -y
sudo apt-get clean
#
cd ~ || exit 4
echo "Now use python${PY_CMD} command to use this version."
echo "Do NOT link python to point to another version and do NOT delete python2.7"
if [ "X${LINK}" == Xfalse ]; then
  echo "To link this version to python3, do the following:"
  echo "  $ sudo rm /usr/bin/python3"
  echo "  $ sudo ln -s /usr/local/bin/python3.7 /usr/bin/python3"
  echo "  $ python3 -V"
  echo "  Python 3.7.2"
else
  echo "Now python${PY_CMD} command is linked to python3 command."
  echo "To remove python${PY_CMD}, you must first relinked previous version to python3."
fi
#
