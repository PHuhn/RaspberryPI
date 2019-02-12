#!/bin/bash
#
# ----------------------------------------------------------------------------
# Install Nagios on a Raspberry PI running raspian
#  Written by: Phil Huhn
#
# Installing Nagios 4 on a Raspberry Pi
# http://www.d3noob.org/2016/04/installing-nagios-4-on-raspberry-pi.html
# How To Install Nagios 4 and Monitor Your Servers on Ubuntu 14.04
# https://www.digitalocean.com/community/tutorials/how-to-install-nagios-4-and-monitor-your-servers-on-ubuntu-14-04
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.0.3"
HOME_DIR=`pwd`
# Varialbes:
NAGIOS_VER=4.4.3
PLUGIN_VER=2.2.1
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: ${PROGNAME} [options]

  -h    this help text.
  -n    nagios version, default value: ${NAGIOS_VER}
  -p    plugin version, default value: ${PLUGIN_VER}

  Example:  ${PROGNAME} -n 4.4.2 -p 2.2.1

EOF
  exit
fi
#
echo "=- Running ${PROGNAME} ${REVISION} -="
date
#
while getopts ":n:p:" option
do
  echo "Option: ${option}  arg: ${OPTARG}"
  case "${option}"
  in
    n) NAGIOS_VER=${OPTARG};;
    p) PLUGIN_VER=${OPTARG};;
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
# ######################################################## #
# user/group
echo "=- add nagios user -="
grep nagios /etc/passwd > /dev/null
if [ $? != 0 ]; then
    useradd -m nagios
    passwd nagios
else
    echo "${LINENO} ${PROGNAME}, nagios user exists"
fi
grep nagios /etc/passwd > /dev/null
if [ $? != 0 ]; then
    echo "${LINENO} ${PROGNAME}, failed to create nagios user."
    exit 1
fi
echo "=- add nagcmd group -="
grep nagcmd /etc/group > /dev/null
if [ $? != 0 ]; then
    groupadd nagcmd
    usermod -a -G nagcmd nagios
    usermod -a -G nagcmd www-data
else
    echo "${LINENO} ${PROGNAME}, nagcmd group exists"
fi
# ######################################################## #
# apache
echo "=- install apache web server -="
apt-get install apache2 libapache2-mod-php7.0 php7.0-json php7.0-xml build-essential libgd2-xpm-dev
# ######################################################## #
# nagios
echo "=- install nagios core -="
cd /usr/local/src/
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NAGIOS_VER}.tar.gz
tar zxvf nagios-${NAGIOS_VER}.tar.gz
if [ -d "/usr/local/src/nagios-${NAGIOS_VER}" ]; then
    cd nagios-${NAGIOS_VER}
    ./configure --with-command-group=nagcmd
    make all
    make install
    make install-init
    make install-config
    make install-commandmode
    rm /usr/local/src/nagios-${NAGIOS_VER}.tar.gz
    #
    install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-enabled/nagios.conf
    mkdir /etc/httpd
    mkdir /etc/httpd/conf.d
    mkdir /etc/httpd/conf.d/nagios.conf
    make install-webconf
    echo "${LINENO} ${PROGNAME}, enter nagiosadmin password..."
    htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
    /etc/init.d/apache2 reload
    #
    cp ./startup/default-init /etc/init.d/nagios
    chmod 755 /etc/init.d/nagios
    ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios
    cat << EOF > /etc/systemd/system/nagios.service
[Unit]
Description=Nagios
BindTo=network.target

[Install]
WantedBy=multi-user.target

[Service]
User=nagios
Group=nagios
Type=simple
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
EOF
    /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
    #
    mv /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/
    service apache2 restart
    systemctl enable /etc/systemd/system/nagios.service
    systemctl start nagios
else
    echo "${LINENO} ${PROGNAME}, install of nagios failed"
fi
# ######################################################## #
# nagios plugins
echo "=- install nagios plugins -="
cd /usr/local/src/
wget http://www.nagios-plugins.org/download/nagios-plugins-${PLUGIN_VER}.tar.gz
tar zxvf nagios-plugins-${PLUGIN_VER}.tar.gz
if [ -d "nagios-plugins-${PLUGIN_VER}" ]; then
    cd nagios-plugins-${PLUGIN_VER}
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios
    make
    make install
    rm /usr/local/src/nagios-plugins-${PLUGIN_VER}.tar.gz
else
    echo "${LINENO} ${PROGNAME}, install of plugins failed"
fi
# ######################################################## #
# nagios host icon logos
if [ -d "/usr/local/nagios/share/images/logos" ]; then
	echo "Nagios installed and /usr/local/nagios/share/images exists."
	if [ -f "${HOME_DIR}/rasp-pi-logo-icon.png" ]; then
		if [ ! -f "/usr/local/nagios/share/images/logos/rasp-pi-logo-icon.png" ]; then
			echo "cp ${HOME_DIR}/rasp-pi-logo-icon.png /usr/local/nagios/share/images/logos/."
			sudo cp ${HOME_DIR}/rasp-pi-logo-icon.png /usr/local/nagios/share/images/logos/.
		fi
	fi
	if [ -f "${HOME_DIR}/win10-logo-icon.png" ]; then
		if [ ! -f "/usr/local/nagios/share/images/logos/win10-logo-icon.png" ]; then
			echo "cp ${HOME_DIR}/win10-logo-icon.png /usr/local/nagios/share/images/logos/."
			sudo cp ${HOME_DIR}/win10-logo-icon.png /usr/local/nagios/share/images/logos/.
		fi
	fi
fi
#
date
echo "=- End of install of Nagios on Raspberry PI -="
#
