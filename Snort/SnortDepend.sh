#
# Snort Dependency Installation
#  Written by: Phil Huhn
#  Version 8
#
echo "=- Snort dependency installation -="
# Variables:
luajit_ver=LuaJIT-2.0.5
openssl_ver=openssl-1.1.1
daq_ver=2.0.6
daq_file=daq-${daq_ver}
arm_pkg="-1_armhf"
#
mkdir -p ~/sourcecode/snort_src/
cd ~/sourcecode/snort_src/
#
# If we try to compile this source code at this moment, it will fail because there are missing dependencies.  You can try running ./configure and piecing together the required  dependencies, or use the following commands to easily install them.  Luckily, Raspian�s package manager contains all of the required packages making this an easy task. 
# To download and install the dependencies required to compile code, run the following commands
#
pkg_not_exists=$(dpkg-query -W bison)
if [ $? != 0 ]; then
  echo "=- Installing bison -="
  sudo apt-get install bison -y
else
  echo "=- Skipping bison -="
  dpkg-query -W bison
fi
pkg_not_exists=$(dpkg-query -W flex)
if [ $? != 0 ]; then
  echo "=- Installing flex -="
  sudo apt-get install flex -y
else
  echo "=- Skipping flex -="
  dpkg-query -W flex
fi
#
# There are also three software packages that you may already have.  However, you likely don�t have the required header files, so you will have to also download and install these.  The package manager will make this a trivially easy task.  Run the following commands
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
if [ $? != 0 ]; then
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
  echo "Package: ${luajit_ver}"
  #
  cd ~/sourcecode/snort_src/
  wget http://luajit.org/download/${luajit_ver}.tar.gz
  tar zxf ${luajit_ver}.tar.gz
  #
  # change into extracted directory
  cd ${luajit_ver}
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
  echo "Package: ${openssl_ver}"
  cd ~/sourcecode/snort_src/
  #
  wget https://www.openssl.org/source/${openssl_ver}.tar.gz
  tar zxf ${openssl_ver}.tar.gz
  #
  # change into extracted directory
  cd ${openssl_ver}
  #
  ./config
  make && sudo make install
else
  echo "=- Skipping openssl -="
fi
#
pkg-config --list-all | grep -i openssl
#
# Nice, all of our dependencies should now be in order to compile the DAQ.  Usually, you will run the standard ./configure; make; sudo make install; to compile and install source code.   This will definitely work, but I think it is better practice to make everything into an easily manageable package.  The package �checkinstall� will do this automatically.  We will first need to get it from our package manager.
# Run the following command
#
cd ~/sourcecode/snort_src/
if [ -f ${daq_file}.tar.gz ]; then
  rm ${daq_file}.tar.gz
  rm -rf ${daq_file}
fi
echo "get ${daq_file}"
wget https://snort.org/downloads/snort/${daq_file}.tar.gz
#
# Since this is a compressed tar file, we will need to extract it using the following command
#
echo "tar ${daq_file}"
tar xvfz ${daq_file}.tar.gz
#
# We will now move into the directory we just extracted to begin running scripts to install the software.
#
cd ${daq_file}/
#
# We can now get to compiling and installing our code.  Run the following commands
#
./configure
make
sudo checkinstall -D --install=no --fstrans=no
#
# Checkinstall will ask you some questions about the package to create.  Use the defaults.  Give the description something like �snort-daq� and hit enter again.  Keep all default settings.
# You will notice that if you list the directory contents, there will be a a file with .deb extension.  This is the package that checkinstall generated.  The name of this file can vary, so don�t copy the following command verbatim.  Install it using the following command.  If you are unsure, list the contents of the directory.
#
echo "=- Installing daq_${daq_ver} -="
sudo dpkg -i daq_${daq_ver}${arm_pkg}.deb
#
# The DAQ is now installed and we can get back to installing Snort.
#
echo "=- End of Snort dependency installation -="
#
