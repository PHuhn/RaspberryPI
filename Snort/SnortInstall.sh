#!/bin/bash
#
# Installing Snort
#  Derived from https://blog.holdenkilbride.com/index.php/tag/snort/
#  Written by: Phil Huhn
#  Version 3
#
echo "=- Snort installation -="
date
# Varialbes:
SNORT_VER=2.9.12
#
while getopts snort_ver: option
do
  case "${option}"
  in
    snort_ver) SNORT_VER=${OPTARG};;
  esac
done
#
SNORT_FILE=snort-${SNORT_VER}
ARM_PKG='-1_armhf'
#
# Let's move back to the directory where we have been downloading our source code

cd ~/sourcecode/snort_src/
#
# We now need to obtain the tar file of source code for Snort and decompress the file.  If you recall from earlier, go to snort.org to find this download.  Run the following commands to download and extract the tar file
if [ -f ${SNORT_FILE}.tar.gz ]; then
  rm ${SNORT_FILE}.tar.gz
  rm -rf ${SNORT_FILE}
fi
echo "=- get ${SNORT_FILE} -="
wget https://snort.org/downloads/snort/${SNORT_FILE}.tar.gz
tar xvfz ${SNORT_FILE}.tar.gz
#
# Installing Snort follows a similar process to compiling and installing the DAQ.  Lets move into the extracted directory. 

cd ~/sourcecode/snort_src/${SNORT_FILE}
#
# Once inside the source directory, we can now begin the compile and install process.  Run the following commands

echo "=- ./configure -="
./configure --enable-sourcefire
echo "=- make -="
make
echo "=- checkinstall -="
sudo checkinstall -D --install=no --fstrans=no
#
# Checkinstall will ask you some questions about the package to create.  Make the description something like 'snort' and hit enter again.  Follow the prompts and use the defaults.  As we are not distributing the package, you will not have to worry about dependency identification.  Checkinstall will be useful should you choose to remove Snort and the DAQ at a later time
# You will notice that if you list the directory contents, there will be a a file with .deb extension.  This is the package that checkinstall generated.  The name of this file can vary, so don't follow the previous command verbatim.  Install it using the following command

sudo dpkg -i snort_${SNORT_VER}${ARM_PKG}.deb
#
# Let's move back to the directory where we have been downloading our source code

sudo ldconfig
#
# Run the following command to verify that Snort has been installed in the proper usr/local/bin/ location

which snort
#
# Snort will run from the usr/local/bin location.  We also want to add a symlink in /usr/sbin that points to /usr/local/bin/snort.  The purpose of this is when we later add the snort user and group, the system process will be able to locate the Snort binary.

sudo ln -s /usr/local/bin/snort /usr/sbin/snort
#
# We can finally check to see if Snort works by verifying the version

snort --version

#
date
echo "=- End of Snort installation -="
#
