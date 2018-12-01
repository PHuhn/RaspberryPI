#!/bin/bash
#
# Snort Dependency Installation
#  Derived from https://blog.holdenkilbride.com/index.php/tag/snort/
#  Written by: Phil Huhn
#  Version 12
#
echo "=- Snort dependency installation -="
date
# Variables:
LUAJIT_VER=2.0.5
OPENSSL_VER=1.1.1
DAQ_VER=2.0.6
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: $0 [options]

  -h    this help text.
  -l    LuaJIT version, example 2.0.5
  -o    OpenSSL version, example 1.1.1
  -d    DAQ version, example 2.0.6

EOF
  exit
fi
#
while getopts ":l:o:d:" option
do
  case "${option}"
  in
    l) LUAJIT_VER=${OPTARG};;
    o) OPENSSL_VER=${OPTARG};;
    d) DAQ_VER=${OPTARG};;
  esac
done
#
LUAJIT_FILE=LuaJIT-${LUAJIT_VER}
OPENSSL_FILE=openssl-${OPENSSL_VER}
DAQ_FILE=daq-${DAQ_VER}
ARM_PKG="-1_armhf"
#
if [ ! -d "~/sourcecode/snort_src/" ]; then
  mkdir -p ~/sourcecode/snort_src/
fi
cd ~/sourcecode/snort_src/
#
# If we try to compile this source code at this moment, it will fail because there are missing dependencies.  You can try running ./configure and piecing together the required  dependencies, or use the following commands to easily install them.  Luckily, Raspian's package manager contains all of the required packages making this an easy task. 
# To download and install the dependencies required to compile code, run the following commands
#
pkg_not_exists=$(dpkg-query -W bison)
if [ $? != 0 ] || [ $(echo ${pkg_not_exists} | tr -d "\t") == "bison" ]; then
  echo "=- Installing bison -="
  sudo apt-get install bison -y
else
  echo "=- Skipping bison -="
  dpkg-query -W bison
fi
pkg_not_exists=$(dpkg-query -W flex)
if [ $? != 0 ] || [ $(echo ${pkg_not_exists} | tr -d "\t") == "flex" ]; then
  echo "=- Installing flex -="
  sudo apt-get install flex -y
else
  echo "=- Skipping flex -="
  dpkg-query -W flex
fi
#
# There are also three software packages that you may already have.  However, you likely don't have the required header files, so you will have to also download and install these.  The package manager will make this a trivially easy task.  Run the following commands
#
pkg_not_exists=$(dpkg-query -W libpcap-dev)
if [ $? != 0 ]; then
  echo "=- Installing libpcap-dev -="
  sudo apt-get install libpcap-dev -y
else
  echo "=- Skipping libpcap-dev -="
  dpkg-query -W libpcap-dev
fi
pkg_not_exists=$(dpkg-query -W libpcre3-dev)
if [ $? != 0 ] || [ $(echo ${pkg_not_exists} | tr -d "\t") == "libpcre3-dev" ]; then
  echo "=- Installing libpcre3-dev -="
  sudo apt-get install libpcre3-dev -y
else
  echo "=- Skipping libpcre3-dev -="
  dpkg-query -W libpcre3-dev
fi
pkg_not_exists=$(dpkg-query -W libdumbnet-dev)
if [ $? != 0 ]; then
  echo "=- Installing libdumbnet-dev -="
  sudo apt-get install libdumbnet-dev -y
else
  echo "=- Skipping libdumbnet-dev -="
  dpkg-query -W libdumbnet-dev
fi
#
pkg_not_exists=$(dpkg-query -W checkinstall)
if [ $? != 0 ]; then
  echo "=- Installing checkinstall -="
  sudo apt-get install checkinstall
else
  echo "=- Skipping checkinstall -="
  dpkg-query -W checkinstall
fi
#
# New requirement for DAQ ...
pkg_not_exists=$(pkg-config --list-all | grep -i luajit)
if [ $? != 0 ]; then
  #
  echo "=- Installing LuaJIT package -="
  echo "Package: ${LUAJIT_FILE}"
  #
  cd ~/sourcecode/snort_src/
  wget http://luajit.org/download/${LUAJIT_FILE}.tar.gz
  tar zxf ${LUAJIT_FILE}.tar.gz
  #
  # change into extracted directory
  cd ${LUAJIT_FILE}
  #
  ./config
  make && sudo make install
  #
else
  echo "=- Skipping LuaJIT package -="
fi
pkg-config --list-all | grep -i luajit
#
# New requirement for DAQ ...
pkg_not_exists=$(pkg-config --list-all | grep -i ^openssl)
if [ $? != 0 ]; then
  #
  echo "=- Installing openssl package -="
  echo "Package: ${OPENSSL_FILE}"
  cd ~/sourcecode/snort_src/
  #
  wget https://www.openssl.org/source/${OPENSSL_FILE}.tar.gz
  tar zxf ${OPENSSL_FILE}.tar.gz
  #
  # change into extracted directory
  cd ${OPENSSL_FILE}
  #
  ./config
  make && sudo make install
else
  echo "=- Skipping openssl -="
fi
#
pkg-config --list-all | grep -i openssl
#
# Nice, all of our dependencies should now be in order to compile the DAQ.  Usually, you will run the standard ./configure; make; sudo make install; to compile and install source code.   This will definitely work, but I think it is better practice to make everything into an easily manageable package.  The package 'checkinstall' will do this automatically.  We will first need to get it from our package manager.
# Run the following command
#
cd ~/sourcecode/snort_src/
if [ -f ${DAQ_FILE}.tar.gz ]; then
  rm ${DAQ_FILE}.tar.gz
  rm -rf ${DAQ_FILE}
fi
echo "get ${DAQ_FILE}"
wget https://snort.org/downloads/snort/${DAQ_FILE}.tar.gz
#
# Since this is a compressed tar file, we will need to extract it using the following command
#
echo "tar ${DAQ_FILE}"
tar xvfz ${DAQ_FILE}.tar.gz
#
# We will now move into the directory we just extracted to begin running scripts to install the software.
#
cd ${DAQ_FILE}/
#
# We can now get to compiling and installing our code.  Run the following commands
#
./configure
make
sudo checkinstall -D --install=no --fstrans=no
#
# Checkinstall will ask you some questions about the package to create.  Use the defaults.  Give the description something like 'snort-daq' and hit enter again.  Keep all default settings.
# You will notice that if you list the directory contents, there will be a a file with .deb extension.  This is the package that checkinstall generated.  The name of this file can vary, so don't copy the following command verbatim.  Install it using the following command.  If you are unsure, list the contents of the directory.
#
echo "=- Installing daq_${DAQ_VER} -="
sudo dpkg -i daq_${DAQ_VER}${ARM_PKG}.deb
#
# The DAQ is now installed and we can get back to installing Snort.
#
date
echo "=- End of Snort dependency installation -="
#
