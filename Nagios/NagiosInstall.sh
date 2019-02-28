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
# Nagios Core - Installing Nagios Core From Source
# https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html#Raspbian
#
# program values:
PROGNAME=$(basename "$0")
REVISION="1.0.7"
HOME_DIR=`pwd`
DIR=/usr/local/nagios
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
# nagios user and group of nagios & nagcmd
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
# apache installation
echo "=- install apache web server -="
apt-get install apache2 libapache2-mod-php7.0 php7.0-json php7.0-xml build-essential libgd2-xpm-dev
# ######################################################## #
# nagios installation
echo "=- install nagios core -="
cd /usr/local/src/
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NAGIOS_VER}.tar.gz
tar zxvf nagios-${NAGIOS_VER}.tar.gz
if [ -d "/usr/local/src/nagios-${NAGIOS_VER}" ]; then
    cd nagios-${NAGIOS_VER}
    rm /usr/local/src/nagios-${NAGIOS_VER}.tar.gz
    ./configure --with-command-group=nagcmd LIBS='-ldl'
    make all
    if [ $? != 0 ]; then
        echo "${LINENO} ${PROGNAME}, install of nagios failed, make all returned != 0"
        exit 1
    fi
    make install
    make install-init
    make install-config
    make install-commandmode
    if [ ! -f "${DIR}/bin/nagios" ]; then
        echo "${LINENO} ${PROGNAME}, install of nagios failed, no bin/nagios"
        exit 1
    fi
    #
    install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-enabled/nagios.conf
    mkdir /etc/httpd
    mkdir /etc/httpd/conf.d
    mkdir /etc/httpd/conf.d/nagios.conf
    make install-webconf
    echo "${LINENO} ${PROGNAME}, enter nagiosadmin password..."
    htpasswd -c ${DIR}/etc/htpasswd.users nagiosadmin
    /etc/init.d/apache2 reload
    # even thought using systemd, install initctl
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
    ${DIR}/bin/nagios -v ${DIR}/etc/nagios.cfg
    #
    mv /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/.
    service apache2 restart
    systemctl enable /etc/systemd/system/nagios.service
    systemctl start nagios
else
    echo "${LINENO} ${PROGNAME}, install of nagios failed"
fi
if [ ! -d /usr/local/nagios/var/spool/checkresults ]; then
    echo "${LINENO} ${PROGNAME}, install of nagios failed, no var/spool/checkresults"
    exit 1
fi
# ######################################################## #
# nagios plugins installation
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
    echo "${LINENO} ${PROGNAME}, installed of plugins"
else
    echo "${LINENO} ${PROGNAME}, install of plugins failed"
fi
# ######################################################## #
# nagios check_ncpa.py and check_state_statusjson.sh downloads
# https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/monitoring-windows.html
if [ -d "${DIR}/libexec" ]; then
    cd ${DIR}/libexec
    if [ ! -f check_ncpa.py ]; then
        wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz
        tar xvf check_ncpa.tar.gz
        rm check_ncpa.tar.gz  CHANGES.rst
        chown nagios:nagios check_ncpa.py
        chmod 755 check_ncpa.py
        echo "${LINENO} ${PROGNAME}, installed check_ncpa.py"
        # if 'command_name' and 'check_ncpa.py' is not in the objects commands file
        grep "command_name"  ${DIR}/etc/objects/commands.cfg | grep "check_ncpa" >/dev/null 2>&1
        if [ $? != "0" ]; then
            cat << _EOF >> ${DIR}/etc/objects/commands.cfg
# ************************************** #
# Commands section, defined all commands #
# ************************************** #
# defined this ncpa command
define command {
    command_name            check_ncpa
    command_line            \$USER1\$/check_ncpa.py -H \$HOSTADDRESS\$ \$ARG1\$
}
_EOF
            echo "${LINENO} ${PROGNAME}, configured check_ncpa in ${DIR}/etc/objects/commands.cfg"
        else
            echo "${LINENO} ${PROGNAME}, check_ncpa already configured."
        fi
    else
        echo "${LINENO} ${PROGNAME}, check_ncpa.py already installed"
    fi
    if [ ! -f check_state_statusjson.sh ]; then
        wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/libexec/check_state_statusjson.sh
        chmod 755 check_state_statusjson.sh
        chown nagios:nagios check_state_statusjson.sh
        echo "${LINENO} ${PROGNAME}, installed check_state_statusjson.sh"
        # if 'command_name' and 'check_statusjson_state' is not in the objects commands file
        grep "command_name"  ${DIR}/etc/objects/commands.cfg | grep "check_statusjson_state" >/dev/null 2>&1
        if [ $? != "0" ]; then
            echo "******************************************************************"
            echo "Creating statusjson web user for check_state_statusjson.sh script."
            htpasswd ${DIR}/etc/htpasswd.users statusjson
            #
            cat << _EOF >> ${DIR}/etc/objects/commands.cfg
# define statusjson state command
define command {
    command_name            check_statusjson_state
    command_line            /usr/local/nagios/libexec/check_state_statusjson.sh -H \$ARG1\$ -S \$ARG2\$ -U statusjson -P passw0rd
}
_EOF
            echo "${LINENO} ${PROGNAME}, configured check_statusjson_state in ${DIR}/etc/objects/commands.cfg"
        else
            echo "${LINENO} ${PROGNAME}, check_statusjson_state already configured."
        fi
    else
        echo "${LINENO} ${PROGNAME}, check_statusjson_state.sh already installed"
    fi
fi
# ######################################################## #
# nagios host icon logos
if [ -d "${DIR}/share/images/logos" ]; then
	echo "Nagios installed and ${DIR}/share/images exists."
	if [ -f "${HOME_DIR}/rasp-pi-logo-icon.png" ]; then
		if [ ! -f "${DIR}/share/images/logos/rasp-pi-logo-icon.png" ]; then
			echo "cp ${HOME_DIR}/rasp-pi-logo-icon.png ${DIR}/share/images/logos/."
			sudo cp ${HOME_DIR}/rasp-pi-logo-icon.png ${DIR}/share/images/logos/.
		fi
	fi
	if [ -f "${HOME_DIR}/win10-logo-icon.png" ]; then
		if [ ! -f "${DIR}/share/images/logos/win10-logo-icon.png" ]; then
			echo "cp ${HOME_DIR}/win10-logo-icon.png ${DIR}/share/images/logos/."
			sudo cp ${HOME_DIR}/win10-logo-icon.png ${DIR}/share/images/logos/.
		fi
	fi
fi
# ######################################################## #
# Summary of activities
date
echo "Files added to Nagios"
ls -l ${DIR}/bin/nagios \
    ${DIR}/libexec/check_ncpa.py \
    ${DIR}/libexec/check_state_statusjson.sh \
    ${DIR}/share/images/logos/rasp-pi-logo-icon.png \
    ${DIR}/share/images/logos/win10-logo-icon.png
echo "Commands added to ${DIR}/etc/objects/commands.cfg"
grep "command_name" ${DIR}/etc/objects/commands.cfg | grep -E "check_ncpa|check_statusjson_state"
echo "Nagios web access users in ${DIR}/etc/htpasswd.users, should have nagiosadmin and statusjson users."
cat ${DIR}/etc/htpasswd.users
echo "====================================================================================="
echo "Need to edit and change password for check_statusjson_state in ${DIR}/etc/objects/commands.cfg"
echo "=- End of install of Nagios on Raspberry PI -="
#
