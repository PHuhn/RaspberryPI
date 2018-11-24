#
# Configuring Snort
#  Written by: Phil Huhn
#  Version 3
#
echo "=- Snort configuration -="
# Varialbes:
snort_file=snort-2.9.12
#

cd ~/sourcecode/snort_src/

#
# If you see something like this, you have done the previous steps correctly.
# Snort is now mostly installed.  There are two problems now.  
# * The first is that we don't want Snort running as root user.
# * The second is that if you try to run Snort now, it will fail due to missing configuration and log file locations.
#
# We are now going to make a Snort user and group.  This will be a system user that the process will run as.  The following two commands will generate the user and group that Snort will run as.
#
sudo groupadd snort
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

#
# Install the downloaded rules snapshot, if exists.
#
if [ ! -d "/etc/snort" ]; then
  sudo mkdir -p /etc/snort
fi
cd ~/sourcecode/snort_src/
rules_file=$(find -name "snortrules-snapshot*.gz" | sort | tail -1)
if [ $? == 0 ]; then
  if [ $rules_file ]; then
    echo "Processing ${rules_file} rules file."
    mkdir -p snortrules
    tar -xvzf ${rules_file} -C snortrules
    if [ -d snortrules/etc ]; then
      cd snortrules
      echo "Moving ${rules_file} rules."
      sudo mv * /etc/snort
    else
      echo "snortrules etc directory not found"
    fi
  fi
  #
else
  echo "snortrules-snapshot g-zip not found"
fi
#
# We will now create the directories that will hold the configuration files

echo "=- Create the directories -="
if [ ! -d "/etc/snort/rules" ]; then
  sudo mkdir -p /etc/snort/rules
fi
if [ ! -d "/etc/snort/preproc_rules" ]; then
  sudo mkdir -p /etc/snort/preproc_rules
fi
if [ ! -d "/usr/local/lib/snort_dynamicrules" ]; then
  sudo mkdir /usr/local/lib/snort_dynamicrules
fi
if [ ! -d "/etc/snort/so_rules" ]; then
  sudo mkdir /etc/snort/so_rules
fi
#
# Just download the community rules, load into local.rules
#
cd ~/sourcecode/snort_src/
if [ -f ${community_file}.tar.gz ]; then
  rm ${community_file}.tar.gz
fi
#
wget https://snort.org/downloads/community/${community_file}.tar.gz
if [ -f ${community_file}.tar.gz ]; then
  tar xvfz ${community_file}.tar.gz
  echo "Community rules: ${community_file}, over-writing local.rules"
  echo "# ---------------" >  comm.rules
  echo "# Community Rules" >> comm.rules
  echo "# ---------------" >> comm.rules
  # Grab commented out rules and then only the IIS server and SQL Injection ones.
  #  Then uncomment them and convert $EXTERNAL_NET to any.
  grep "^#" ${community_file}/community.rules | grep -E "SQL inj|SERVER-IIS" | sed -e "s/^# //" -e "s/ \$EXTERNAL_NET / any /" >> comm.rules
  sudo cp comm.rules /etc/snort/rules/local.rules
  #
fi
#
# With these directories created, we will now generate some empty rule files for Snort

echo "=- Create empty rules -="
sudo touch /etc/snort/rules/local.rules
sudo touch /etc/snort/rules/white_list.rules
sudo touch /etc/snort/rules/black_list.rules
#
# Snort will also need a folder to output log files

if [ ! -d "/var/log/snort" ]; then
  sudo mkdir /var/log/snort
fi
#
# The Snort user and group will not be able to write log files or read configuration without modifying the privileges of the directories we just created.

echo "=- chmod commands -="
sudo chmod -R 5775 /etc/snort
sudo chmod -R 5775 /var/log/snort
sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules
sudo chown -R snort:snort /etc/snort
sudo chown -R snort:snort /var/log/snort
sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules
#
# We are getting close to having a working IDS on our Raspberry Pi.  All that is left is some configuration.  Luckily, we don't have to build the configuration from scratch.  The tar file that contained the source code also contains various config files for running Snort.  All we have to do is move these to the /etc/snort/ directory.  Change the working directory to the /etc/ directory in the extracted Snort tar

cd ~/sourcecode/snort_src/${snort_file}/etc
#
# We only want to copy configuration related to Snort.  This excludes any of the makefile(s)

echo "=- copy configuration file -="
sudo cp *.conf /etc/snort
sudo cp *.config /etc/snort
sudo cp *.map /etc/snort
#
# We will not be utilizing preprocessor rules in this tutorial.  It would still be a good idea to bring them in however, should you choose to implement them at a later time.  I will explore this topic in future tutorials.

cd ~/sourcecode/snort_src/${snort_file}/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor
sudo cp * /usr/local/lib/snort_dynamicpreprocessor
#
# Configuring and Running Snort
# Snort's main configuration file is /etc/snort/snort.conf
# We will be changing lines within this .conf file to modify Snort's configuration.  You can use any text editor you are comfortable with: emacs, vi, nano, etc' I will be using the nano text editor to change this file, so it would be a good idea to read up on nano if you are unfamiliar with the program.
# If you 'cat' the snort.conf file, and scroll all the way down, you will see numerous lines with a 'include $RULE_PATH' prefix.  We will not be using these rules at the moment so you should just comment them out.  The following command makes use of the stream editor, or sed, tool to automatically do this

echo "=- sed snort.conf -="
# leave include uncommented, will load from rules snapshot
# Change the HOME_NET and EXTERNAL_NET, and root directory to /etc/snort
sudo sed -i -e "s/^ipvar HOME_NET any/ipvar HOME_NET 192\.168\.0\.0\/24/" \
	-e "s/^ipvar EXTERNAL_NET any/ipvar EXTERNAL_NET !$HOME_NET/" \
	-e "s/ \.\.\// \/etc\/snort\//" /etc/snort/snort.conf
#
# We will now run Snort with the configuration validation flag to test all of our settings.  Hopefully it will state that everything validated successfully
#
sudo snort -T -c /etc/snort/snort.conf -i eth0
#
# Lets run snort with the following command
#
#	sudo snort -A console -u snort -g snort -c /etc/snort/snort.conf -l /var/log/snort -i eth0
# The following flags imply: -A means output to console -u means run as the snort user -g means run as snort group -c means run the following config file -l means log to the following directory, -i means detect traffic on the following ethernet interface
# -Holden Kilbride
echo "=- End of Snort configuration -="
#