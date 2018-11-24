#
# Installing Snort
#  Written by: Phil Huhn
#  Version 2
#
echo "=- Snort installation -="
# Varialbes:
snort_ver=2.9.12
snort_file=snort-${snort_ver}
arm_pkg='-1_armhf'
#
# Let's move back to the directory where we have been downloading our source code

cd ~/sourcecode/snort_src/
#
# We now need to obtain the tar file of source code for Snort and decompress the file.  If you recall from earlier, go to snort.org to find this download.  Run the following commands to download and extract the tar file
if [ -f ${snort_file}.tar.gz ]; then
  rm ${snort_file}.tar.gz
  rm -rf ${snort_file}
fi
echo "=- get ${snort_file} -="
wget https://snort.org/downloads/snort/${snort_file}.tar.gz
tar xvfz ${snort_file}.tar.gz
#
# Installing Snort follows a similar process to compiling and installing the DAQ.  Lets move into the extracted directory. 

cd ~/sourcecode/snort_src/${snort_file}
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

sudo dpkg -i snort_${snort_ver}${arm_pkg}.deb
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
echo "=- End of Snort installation -="
#
