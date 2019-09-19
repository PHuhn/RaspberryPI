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
REVISION="1.0.8"
INST_DIR=/usr/local/nagios
# Variables:
NAGIOS_VER=4.4.5
PLUGIN_VER=2.2.1
#
if [ "$1" == "-h" ]; then
  cat <<EOF
  Usage: ${PROGNAME} [options]

    -h    this help text.
    -n    nagios version, default value: ${NAGIOS_VER}
    -p    plugin version, default value: ${PLUGIN_VER}

    Example:  ${PROGNAME} -n 4.4.3 -p 2.2.1

EOF
  exit
fi
#
echo "=- Running ${PROGNAME} ${REVISION} -="
date
#
while getopts ":n:p:" option
do
    case "${option}"
    in
        n) NAGIOS_VER=${OPTARG};;
        p) PLUGIN_VER=${OPTARG};;
        *) echo "Invalid option: ${option} arg: ${OPTARG}"
            exit 1
            ;;
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
apt-get install apache2 libapache2-mod-php7.3 php7.3-json php7.3-xml build-essential libgd-dev
if [ ! -f /usr/sbin/apache2 ]; then
    echo "${LINENO} ${PROGNAME}, install of apache failed, no /usr/sbin/apache2 file."
    exit 1
fi
# ######################################################## #
# nagios installation
echo "=- install nagios core -="
cd /usr/local/src/ || exit
wget "https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NAGIOS_VER}.tar.gz"
tar zxvf "nagios-${NAGIOS_VER}.tar.gz"
if [ -d "/usr/local/src/nagios-${NAGIOS_VER}" ]; then
    cd "nagios-${NAGIOS_VER}" || exit
    rm "/usr/local/src/nagios-${NAGIOS_VER}.tar.gz"
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
    if [ ! -f "${INST_DIR}/bin/nagios" ]; then
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
    htpasswd -c ${INST_DIR}/etc/htpasswd.users nagiosadmin
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
    ${INST_DIR}/bin/nagios -v ${INST_DIR}/etc/nagios.cfg
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
cd /usr/local/src/ || exit
wget "http://www.nagios-plugins.org/download/nagios-plugins-${PLUGIN_VER}.tar.gz"
tar zxvf "nagios-plugins-${PLUGIN_VER}.tar.gz"
if [ -d "nagios-plugins-${PLUGIN_VER}" ]; then
    cd "nagios-plugins-${PLUGIN_VER}" || exit
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios
    make
    make install
    rm "/usr/local/src/nagios-plugins-${PLUGIN_VER}.tar.gz"
    echo "${LINENO} ${PROGNAME}, installed of plugins"
else
    echo "${LINENO} ${PROGNAME}, install of plugins failed"
fi
# ######################################################## #
# nagios check_ncpa.py and check_state_statusjson.sh downloads
# https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/monitoring-windows.html
if [ -d "${INST_DIR}/libexec" ]; then
    cd "${INST_DIR}/libexec" || exit
    if [ ! -f check_ncpa.py ]; then
        wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz
        tar xvf check_ncpa.tar.gz
        rm check_ncpa.tar.gz  CHANGES.rst
        chown nagios:nagios check_ncpa.py
        chmod 755 check_ncpa.py
        echo "${LINENO} ${PROGNAME}, installed check_ncpa.py"
        # if 'command_name' and 'check_ncpa.py' is not in the objects commands file
        grep "command_name"  ${INST_DIR}/etc/objects/commands.cfg | grep "check_ncpa" >/dev/null 2>&1
        if [ $? != "0" ]; then
            cat << _EOF >> ${INST_DIR}/etc/objects/commands.cfg
# ************************************** #
# Commands section, defined all commands #
# ************************************** #
# defined this ncpa command
define command {
    command_name            check_ncpa
    command_line            \$USER1\$/check_ncpa.py -H \$HOSTADDRESS\$ \$ARG1\$
}
_EOF
            echo "${LINENO} ${PROGNAME}, configured check_ncpa in ${INST_DIR}/etc/objects/commands.cfg"
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
        grep "command_name"  ${INST_DIR}/etc/objects/commands.cfg | grep "check_statusjson_state" >/dev/null 2>&1
        if [ $? != "0" ]; then
            echo "******************************************************************"
            echo "Creating statusjson web user for check_state_statusjson.sh script."
            htpasswd ${INST_DIR}/etc/htpasswd.users statusjson
            #
            cat << _EOF >> ${INST_DIR}/etc/objects/commands.cfg
# define statusjson state command
define command {
    command_name            check_statusjson_state
    command_line            /usr/local/nagios/libexec/check_state_statusjson.sh -H \$ARG1\$ -S \$ARG2\$
}
_EOF
            echo "${LINENO} ${PROGNAME}, configured check_statusjson_state in ${INST_DIR}/etc/objects/commands.cfg"
        else
            echo "${LINENO} ${PROGNAME}, check_statusjson_state already configured."
        fi
    else
        echo "${LINENO} ${PROGNAME}, check_statusjson_state.sh already installed"
    fi
else
    echo "${LINENO} ${PROGNAME}, directory ${INST_DIR}/libexec does not exist"
fi
# ######################################################## #
# nagios host icon logos
if [ -d "${INST_DIR}/share/images/logos" ]; then
    echo "Nagios installed and ${INST_DIR}/share/images exists."
    cd "${INST_DIR}/share/images/logos" || exit
    if [ ! -f rasp-pi-logo-icon.png ]; then
        echo "getting ${INST_DIR}/rasp-pi-logo-icon.png"
        sudo wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/rasp-pi-logo-icon.png
        sudo chown nagios:nagios rasp-pi-logo-icon.png
    fi
    if [ ! -f win10-logo-icon.png ]; then
        echo "getting ${INST_DIR}/win10-logo-icon.png"
        sudo wget https://raw.githubusercontent.com/PHuhn/RaspberryPI/master/Nagios/win10-logo-icon.png
        sudo chown nagios:nagios win10-logo-icon.png
    fi
    cd "${INST_DIR}" || exit
else
    echo "${LINENO} ${PROGNAME}, directory ${INST_DIR}/share/images/logos does not exist"
fi
# ######################################################## #
# Summary of activities
date
echo "Files added to Nagios"
ls -l ${INST_DIR}/bin/nagios \
    ${INST_DIR}/libexec/check_ncpa.py \
    ${INST_DIR}/libexec/check_state_statusjson.sh \
    ${INST_DIR}/share/images/logos/rasp-pi-logo-icon.png \
    ${INST_DIR}/share/images/logos/win10-logo-icon.png
echo "Commands added to ${INST_DIR}/etc/objects/commands.cfg"
grep "command_name" ${INST_DIR}/etc/objects/commands.cfg | grep -E "check_ncpa|check_statusjson_state"
echo "Nagios web access users in ${INST_DIR}/etc/htpasswd.users, should have nagiosadmin and statusjson users."
cat ${INST_DIR}/etc/htpasswd.users
echo "====================================================================================="
echo "If you would like to use the check_state_statusjson.sh to call to the cgi interface"
echo "you need to edit the check_statusjson_state command in the"
echo "${INST_DIR}/etc/objects/commands.cfg file and add"
echo "' -U statusjson -P passw0rd' to the command_line.  Empty password, use awk script."
echo "=- End of install of Nagios on Raspberry PI -="
#
