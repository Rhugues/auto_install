#!/bin/bash
# Centreon poller install script for Raspbian Buster
# v 1.55
# 17/09/2020
# Thanks to Remy, Justice81 and Pixelabs
#
export DEBIAN_FRONTEND=noninteractive
# Variables
## Versions
VERSION_BATCH="v 1.55"
CLIB_VER="19.10.0"
CONNECTOR_VER="19.10.1"
ENGINE_VER="19.10.15"
PLUGIN_VER="2.2"
PLUGIN_CENTREON_VER="20200602"
BROKER_VER="19.10.5"
CENTREON_VER="19.10.15"
# MariaDB Series
MARIADB_VER='10.0'
## Sources URL
BASE_URL="http://files.download.centreon.com/public"
CLIB_URL="${BASE_URL}/centreon-clib/centreon-clib-${CLIB_VER}.tar.gz"
CONNECTOR_URL="${BASE_URL}/centreon-connectors/centreon-connectors-${CONNECTOR_VER}.tar.gz"
ENGINE_URL="${BASE_URL}/centreon-engine/centreon-engine-${ENGINE_VER}.tar.gz"
PLUGIN_URL="https://www.monitoring-plugins.org/download/monitoring-plugins-${PLUGIN_VER}.tar.gz"
PLUGIN_CENTREON_URL="${BASE_URL}/centreon-plugins/centreon-plugins-${PLUGIN_CENTREON_VER}.tar.gz"
BROKER_URL="${BASE_URL}/centreon-broker/centreon-broker-${BROKER_VER}.tar.gz"
CENTREON_URL="${BASE_URL}/centreon/centreon-web-${CENTREON_VER}.tar.gz"
CLAPI_URL="${BASE_URL}/Modules/CLAPI/centreon-clapi-${CLAPI_VER}.tar.gz"
## nrpe
NRPE_VERSION="3.2.1"
NRPE_URL="https://github.com/NagiosEnterprises/nrpe/archive/nrpe-3.2.1.tar.gz"
## Temp install dir
DL_DIR="/usr/local/src"
## Install dir
INSTALL_DIR="/usr/share"
## Log install file
INSTALL_LOG="/usr/local/src/centreon-install.log"
## Set mysql-server root password
MYSQL_PASSWORD="password"
## Users and groups
ENGINE_USER="centreon-engine"
ENGINE_GROUP="centreon-engine"
BROKER_USER="centreon-broker"
BROKER_GROUP="centreon-broker"
CENTREON_USER="centreon"
CENTREON_GROUP="centreon"
## TMPL file (template install file for Centreon)
CENTREON_TMPL="centreon_engine.tmpl"
## TimeZone php
VARTIMEZONE="Europe/Paris"
## verbose script
SCRIPT_VERBOSE=false

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} -n=[yes|no] -v

This program create Central Centreon

    -n|--nrpe     : add check_nrpe
    -v|--verbose  : add messages
    -h|--help     : help
EOF
}

function text_params () {
  ESC_SEQ="\x1b["
  bold=`tput bold`
  normal=`tput sgr0`
  COL_RESET=$ESC_SEQ"39;49;00m"
  COL_GREEN=$ESC_SEQ"32;01m"
  COL_RED=$ESC_SEQ"31;01m"
  STATUS_FAIL="[$COL_RED${bold}FAIL${normal}$COL_RESET]"
  STATUS_OK="[$COL_GREEN${bold} OK ${normal}$COL_RESET]"
}


function clib_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                          Install Clib
======================================================================
" | tee -a ${INSTALL_LOG}

apt-get install -y build-essential wget cmake >> ${INSTALL_LOG}

cd ${DL_DIR}
if [[ -e centreon-clib-${CLIB_VER}.tar.gz ]] ;
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget ${CLIB_URL} -O ${DL_DIR}/centreon-clib-${CLIB_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf centreon-clib-${CLIB_VER}.tar.gz
cd centreon-clib-${CLIB_VER}

# add directive compilation
sed -i '32i\set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++98 -fpermissive")' ${DL_DIR}/centreon-clib-${CLIB_VER}/build/CMakeLists.txt

cmake \
   -DWITH_TESTING=0 \
   -DWITH_PREFIX=/usr \
   -DWITH_SHARED_LIB=1 \
   -DWITH_STATIC_LIB=0 \
   -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig . >> ${INSTALL_LOG}
make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}

}

function centreon_connectors_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
               Install Centreon Perl and SSH connectors
======================================================================
" | tee -a ${INSTALL_LOG}

apt-get install -y libperl-dev >> ${INSTALL_LOG}

cd ${DL_DIR}
if [[ -e centreon-connectors-${CONNECTOR_VER}.tar.gz ]]
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget ${CONNECTOR_URL} -O ${DL_DIR}/centreon-connectors-${CONNECTOR_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf centreon-connectors-${CONNECTOR_VER}.tar.gz
cd ${DL_DIR}/centreon-connectors-${CONNECTOR_VER}/perl/build

# add directive compilation
sed -i '27i\set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++98 -fpermissive")' ${DL_DIR}/centreon-connectors-${CONNECTOR_VER}/perl/build/CMakeLists.txt

cmake \
 -DWITH_PREFIX=/usr  \
 -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector  \
 -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
 -DWITH_TESTING=0 . >> ${INSTALL_LOG}
make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}

# install Centreon SSH Connector
apt-get install -y libssh2-1-dev libgcrypt-dev >> ${INSTALL_LOG}

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}/centreon-connectors-${CONNECTOR_VER}/ssh/build

# add directive compilation
sed -i '27i\set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++98 -fpermissive")' ${DL_DIR}/centreon-connectors-${CONNECTOR_VER}/ssh/build/CMakeLists.txt

cmake \
 -DWITH_PREFIX=/usr  \
 -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector  \
 -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
 -DWITH_TESTING=0 . >> ${INSTALL_LOG}
make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}
}

function centreon_engine_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                    Install Centreon Engine
======================================================================
" | tee -a ${INSTALL_LOG}

groupadd -g 6001 ${ENGINE_GROUP}
useradd -u 6001 -g ${ENGINE_GROUP} -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" -s /bin/bash ${ENGINE_USER}

apt-get install -y libcgsi-gsoap-dev zlib1g-dev libssl-dev libxerces-c-dev >> ${INSTALL_LOG}

# Cleanup to prevent space full on /var
apt-get clean >> ${INSTALL_LOG}

cd ${DL_DIR}
if [[ -e centreon-engine-${ENGINE_VER}.tar.gz ]]
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget ${ENGINE_URL} -O ${DL_DIR}/centreon-engine-${ENGINE_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf centreon-engine-${ENGINE_VER}.tar.gz
cd ${DL_DIR}/centreon-engine-${ENGINE_VER}


cmake \
   -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
   -DWITH_CENTREON_CLIB_LIBRARY_DIR=/usr/lib \
   -DWITH_PREFIX=/usr \
   -DWITH_PREFIX_BIN=/usr/sbin \
   -DWITH_PREFIX_CONF=/etc/centreon-engine \
   -DWITH_USER=${ENGINE_USER} \
   -DWITH_GROUP=${ENGINE_GROUP} \
   -DWITH_LOGROTATE_SCRIPT=1 \
   -DWITH_VAR_DIR=/var/log/centreon-engine \
   -DWITH_RW_DIR=/var/lib/centreon-engine/rw \
   -DWITH_STARTUP_SCRIPT=systemd  \
   -DWITH_STARTUP_DIR=/lib/systemd/system  \
   -DWITH_PKGCONFIG_SCRIPT=1 \
   -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig \
   -DWITH_TESTING=0 . >> ${INSTALL_LOG}
make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}

systemctl enable centengine.service >> ${INSTALL_LOG}
systemctl daemon-reload >> ${INSTALL_LOG}
}

function monitoring_plugin_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                     Install Monitoring Plugins
======================================================================
" | tee -a ${INSTALL_LOG}

apt-get install --force-yes -y libgnutls28-dev libssl-dev libkrb5-dev libldap2-dev libsnmp-dev gawk \
        libwrap0-dev libmcrypt-dev smbclient fping gettext dnsutils libmodule-build-perl libmodule-install-perl \
        libnet-snmp-perl >> ${INSTALL_LOG}

# Cleanup to prevent space full on /var
apt-get clean >> ${INSTALL_LOG}

cd ${DL_DIR}
if [[ -e monitoring-plugins-${PLUGIN_VER}.tar.gz ]]
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget --no-check-certificate ${PLUGIN_URL} -O ${DL_DIR}/monitoring-plugins-${PLUGIN_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf monitoring-plugins-${PLUGIN_VER}.tar.gz
cd ${DL_DIR}/monitoring-plugins-${PLUGIN_VER}

./configure --with-nagios-user=${ENGINE_USER} --with-nagios-group=${ENGINE_GROUP} \
--prefix=/usr/lib/nagios/plugins --libexecdir=/usr/lib/nagios/plugins --enable-perl-modules --with-openssl=/usr/bin/openssl \
--enable-extra-opts >> ${INSTALL_LOG}

make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}
}

function centreon_plugins_install() {
[ "$SCRIPT_VERBOSE" = true ] && echo "
=======================================================================
                    Install Centreon Plugins
=======================================================================
" | tee -a ${INSTALL_LOG}

cd ${DL_DIR}
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes monitoring-plugins libxml-libxml-perl \
            libjson-perl libwww-perl libxml-xpath-perl \
            libxml-simple-perl libdatetime-perl libdate-manip-perl libnet-ldap-perl \
            libnet-telnet-perl libnet-ntp-perl libnet-dns-perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl git-core >> ${INSTALL_LOG}

#modify plugin check_icmp
chown -R root:${ENGINE_GROUP} /usr/lib/nagios/plugins/check_icmp
chmod u+s /usr/lib/nagios/plugins/check_icmp

cd ${DL_DIR}
if [[ -e centreon-plugins-${PLUGIN_CENTREON_VER}.tar.gz ]]
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget ${PLUGIN_CENTREON_URL} -O ${DL_DIR}/centreon-plugins-${PLUGIN_CENTREON_VER}.tar.gz >> ${INSTALL_LOG}
fi

tar xzf centreon-plugins-${PLUGIN_CENTREON_VER}.tar.gz
cd ${DL_DIR}/centreon-plugins-${PLUGIN_CENTREON_VER}

chown -R ${ENGINE_USER}:${ENGINE_GROUP} *
chmod +x *
mkdir -p /usr/lib/centreon/plugins
cp -Rp * /usr/lib/centreon/plugins/

#bug plugin 20191016
if [[ ${PLUGIN_CENTREON_VER} == "20191016" ]]; then
  cd ${DL_DIR}
  if [[ -e centreon-plugins-20190704.tar.gz ]]
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget http://files.download.centreon.com/public/centreon-plugins/centreon-plugins-20190704.tar.gz -O ${DL_DIR}/centreon-plugins-20190704.tar.gz >> ${INSTALL_LOG}
  fi

  tar xzf centreon-plugins-20190704.tar.gz
  cd ${DL_DIR}/centreon-plugins-20190704
  chown -R ${ENGINE_USER}:${ENGINE_GROUP} *
  chmod +x *
  cp centreon_centreon_database.pl /usr/lib/centreon/plugins/
  cp centreon_mysql.pl /usr/lib/centreon/plugins/
fi
}

function centreon_broker_install() {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                     Install Centreon Broker
======================================================================
" | tee -a ${INSTALL_LOG}

groupadd -g 6002 ${BROKER_GROUP}
useradd -u 6002 -g ${BROKER_GROUP} -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" -s /bin/bash  ${BROKER_USER}
usermod -aG ${BROKER_GROUP} ${ENGINE_USER}

apt-get install git librrd-dev libqt4-dev libqt4-sql-mysql libgnutls28-dev lsb-release liblua5.2-dev -y >> ${INSTALL_LOG}


# Cleanup to prevent space full on /var
apt-get clean >> ${INSTALL_LOG}

cd ${DL_DIR}
if [[ -e centreon-broker-${BROKER_VER}.tar.gz ]]
  then
    echo 'File already exist !'
  else
    wget ${BROKER_URL} -O ${DL_DIR}/centreon-broker-${BROKER_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf centreon-broker-${BROKER_VER}.tar.gz
cd ${DL_DIR}/centreon-broker-${BROKER_VER}


cmake \
    -DWITH_DAEMONS='central-broker;central-rrd' \
    -DWITH_GROUP=${BROKER_GROUP} \
    -DWITH_PREFIX=/usr \
    -DWITH_PREFIX_BIN=/usr/sbin  \
    -DWITH_PREFIX_CONF=/etc/centreon-broker  \
    -DWITH_PREFIX_LIB=/usr/lib/centreon-broker \
    -DWITH_PREFIX_VAR=/var/lib/centreon-broker \
    -DWITH_PREFIX_MODULES=/usr/share/centreon/lib/centreon-broker \
    -DWITH_STARTUP_SCRIPT=systemd  \
    -DWITH_STARTUP_DIR=/lib/systemd/system  \
    -DWITH_TESTING=0 \
    -DWITH_USER=${BROKER_USER} . >> ${INSTALL_LOG}
make -j 5 >> ${INSTALL_LOG}
make install >> ${INSTALL_LOG}

if [[ -d /var/lib/centreon-broker ]]
  then
    chmod 775 /var/lib/centreon-broker
fi


# Cleanup to prevent space full on /var
apt-get clean >> ${INSTALL_LOG}
}

function create_centreon_tmpl() {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                  Centreon template generation
======================================================================
" | tee -a ${INSTALL_LOG}

cat > ${DL_DIR}/${CENTREON_TMPL} << EOF
#Centreon template
PROCESS_CENTREON_WWW=0
PROCESS_CENTSTORAGE=0
PROCESS_CENTCORE=0
PROCESS_CENTREON_PLUGINS=1
PROCESS_CENTREON_SNMP_TRAPS=1

LOG_DIR="$BASE_DIR/log"
LOG_FILE="$LOG_DIR/install_centreon.log"
TMPDIR="/tmp/centreon-setup"
SNMP_ETC="/etc/snmp/"
PEAR_MODULES_LIST="pear.lst"
PEAR_AUTOINST=1

INSTALL_DIR_CENTREON="${INSTALL_DIR}/centreon"
CENTREON_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREON_DATADIR="${INSTALL_DIR}/centreon/data"
CENTREON_USER=${CENTREON_USER}
CENTREON_GROUP=${CENTREON_GROUP}
PLUGIN_DIR="/usr/lib/nagios/plugins"
CENTREON_LOG="/var/log/centreon"
CENTREON_ETC="/etc/centreon"
CENTREON_RUNDIR="/var/run/centreon"
CENTREON_GENDIR="/var/cache/centreon"
CENTSTORAGE_RRD="/var/lib/centreon"
CENTREON_CACHEDIR="/var/cache/centreon"
CENTSTORAGE_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTCORE_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREON_VARLIB="/var/lib/centreon"
CENTPLUGINS_TMP="/var/lib/centreon/centplugins"
CENTPLUGINSTRAPS_BINDIR="${INSTALL_DIR}/centreon/bin"
SNMPTT_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTCORE_INSTALL_INIT=1
CENTCORE_INSTALL_RUNLVL=1
CENTSTORAGE_INSTALL_INIT=0
CENTSTORAGE_INSTALL_RUNLVL=0
CENTREONTRAPD_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREONTRAPD_INSTALL_INIT=1
CENTREONTRAPD_INSTALL_RUNLVL=1
CENTREON_PLUGINS=/usr/lib/centreon/plugins

INSTALL_DIR_NAGIOS="/usr/bin"
CENTREON_ENGINE_USER="${ENGINE_USER}"
MONITORINGENGINE_USER="${CENTREON_USER}"
MONITORINGENGINE_LOG="/var/log/centreon-engine"
MONITORINGENGINE_INIT_SCRIPT="centengine"
MONITORINGENGINE_BINARY="/usr/sbin/centengine"
MONITORINGENGINE_ETC="/etc/centreon-engine"
NAGIOS_PLUGIN="/usr/lib/nagios/plugins"
FORCE_NAGIOS_USER=1
NAGIOS_GROUP="${CENTREON_USER}"
FORCE_NAGIOS_GROUP=1
NAGIOS_INIT_SCRIPT="/etc/init.d/centengine"
CENTREON_ENGINE_CONNECTORS="/usr/lib/centreon-connector"
BROKER_USER="${BROKER_USER}"
BROKER_ETC="/etc/centreon-broker"
BROKER_INIT_SCRIPT="cbd"
BROKER_LOG="/var/log/centreon-broker"
SERVICE_BINARY="/usr/sbin/service"

DIR_APACHE="/etc/apache2"
DIR_APACHE_CONF="/etc/apache2/conf-available"
APACHE_CONF="apache.conf"
WEB_USER="www-data"
WEB_GROUP="www-data"
APACHE_RELOAD=1wget http://files.download.centreon.com/public/centreon/centreon-web-19.10.1.tar.gz
BIN_RRDTOOL="/usr/bin/rrdtool"
BIN_MAIL="/usr/bin/mail"
BIN_SSH="/usr/bin/ssh"
BIN_SCP="/usr/bin/scp"
PHP_BIN="/usr/bin/php"
GREP="/bin/grep"
CAT="/bin/cat"
SED="/bin/sed"
CHMOD="/bin/chmod"
CHOWN="/bin/chown"

RRD_PERL="/usr/lib/perl5"
SUDO_FILE="/etc/sudoers.d/centreon"
FORCE_SUDO_CONF=1
INIT_D="/etc/init.d"
CRON_D="/etc/cron.d"
PEAR_PATH="/usr/share/php/"
EOF
}

function centreon_maj () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                  Maj Centreon Web Interface
======================================================================
" | tee -a ${INSTALL_LOG}

cd ${DL_DIR}

if [[ -e centreon-web-${CENTREON_VER}.tar.gz ]]
  then
    echo 'File already exist!' | tee -a ${INSTALL_LOG}
  else
    wget ${CENTREON_URL} -O ${DL_DIR}/centreon-web-${CENTREON_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf centreon-web-${CENTREON_VER}.tar.gz
cd ${DL_DIR}/centreon-web-${CENTREON_VER}


# clean /tmp
rm -rf /tmp/*



  [ "$SCRIPT_VERBOSE" = true ] && echo " Apply Centreon template " | tee -a ${INSTALL_LOG}

  #./install.sh -u /etc/centreon -f ${DL_DIR}/${CENTREON_TMPL} >> ${INSTALL_LOG}
 

}

function centreon_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
======================================================================
                  Install Centreon Web Interface
======================================================================
" | tee -a ${INSTALL_LOG}

DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes sudo tofrodos bsd-mailx \
  lsb-release apache2  \
  librrds-perl libconfig-inifiles-perl libcrypt-des-perl \
  libdigest-hmac-perl libdigest-sha-perl libcrypt-des-ede3-perl libdbd-sqlite3-perl \
  snmp snmpd snmptrapd libnet-snmp-perl libsnmp-perl snmp-mibs-downloader ntp  >> ${INSTALL_LOG}


# Cleanup to prevent space full on /var
apt-get clean >> ${INSTALL_LOG}

ln -s /usr/share/mibs/ /usr/share/snmp/mibs

echo "# This file controls the activity of snmpd

# Don\'t load any MIBs by default.
# You might comment this lines once you have the MIBs downloaded.
export MIBDIRS=/usr/share/mibs
export MIBS=ALL

# snmpd control (yes means start daemon).
SNMPDRUN=yes

# snmpd options (use syslog, close stdin/out/err).
SNMPDOPTS='-LS4d -Lf /dev/null -u snmp -g snmp -I -smux,mteTrigger,mteTriggerConf -p /run/snmpd.pid'" > /etc/default/snmpd

echo "# This file controls the activity of snmptrapd

# snmptrapd control (yes means start daemon).  As of net-snmp version
# 5.0, master agentx support must be enabled in snmpd before snmptrapd
# can be run.  See snmpd.conf(5) for how to do this.
TRAPDRUN=yes

# snmptrapd options (use syslog).
TRAPDOPTS='-On -Lsd -p /run/snmptrapd.pid'" > /etc/default/snmptrapd

sed -i -e "s/view   systemonly/#view   systemonly/g" /etc/snmp/snmpd.conf;
sed -i -e "s/#rocommunity public  localhost/rocommunity public  localhost/g" /etc/snmp/snmpd.conf;
sed -i -e "s/rocommunity public  default    -V systemonly/# rocommunity public  default    -V systemonly/g" /etc/snmp/snmpd.conf;
sed -i -e "s/defaultMonitors/#defaultMonitors/g" /etc/snmp/snmpd.conf;
sed -i -e "s/linkUpDownNotifications/#linkUpDownNotifications/g" /etc/snmp/snmpd.conf;

sed -i -e "s/mibs/#mibs/g" /etc/snmp/snmp.conf;

service snmpd restart >> ${INSTALL_LOG}

service snmptrapd restart >> ${INSTALL_LOG}

cd ${DL_DIR}

if [[ -e centreon-web-${CENTREON_VER}.tar.gz ]]
  then
    echo 'File already exist!' | tee -a ${INSTALL_LOG}
  else
    wget ${CENTREON_URL} -O ${DL_DIR}/centreon-web-${CENTREON_VER}.tar.gz >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

groupadd -g 6000 ${CENTREON_GROUP}
useradd -u 6000 -g ${CENTREON_GROUP} -m -r -d /var/lib/centreon -c "Centreon Web user" -s /bin/bash ${CENTREON_USER}
usermod -aG ${CENTREON_GROUP} ${ENGINE_USER}
usermod -aG ${ENGINE_GROUP} ${CENTREON_USER}
usermod -aG ${BROKER_GROUP} ${CENTREON_USER}
usermod -aG ${CENTREON_GROUP} ${BROKER_USER}
usermod -aG ${BROKER_GROUP} ${ENGINE_USER}

tar xzf centreon-web-${CENTREON_VER}.tar.gz
cd ${DL_DIR}/centreon-web-${CENTREON_VER}

# clean /tmp
rm -rf /tmp/*

[ "$SCRIPT_VERBOSE" = true ] && echo " Generate Centreon template " | tee -a ${INSTALL_LOG}

/bin/bash ${DL_DIR}/centreon-web-${CENTREON_VER}/install.sh -i -f ${DL_DIR}/${CENTREON_TMPL} >> ${INSTALL_LOG}
}

function post_install () {
[ "$SCRIPT_VERBOSE" = true ] && echo "
=====================================================================
                          Post install
=====================================================================
" | tee -a ${INSTALL_LOG}

# Add /etc/sudoers.d/centreon
echo "## BEGIN: CENTREON SUDO

User_Alias      CENTREON=%centreon
Defaults:CENTREON !requiretty

# centreontrapd
CENTREON   ALL = NOPASSWD: /usr/sbin/service centreontrapd start
CENTREON   ALL = NOPASSWD: /usr/sbin/service centreontrapd stop
CENTREON   ALL = NOPASSWD: /usr/sbin/service centreontrapd restart
CENTREON   ALL = NOPASSWD: /usr/sbin/service centreontrapd reload

# Centreon Engine
CENTREON   ALL = NOPASSWD: /usr/sbin/service centengine start
CENTREON   ALL = NOPASSWD: /usr/sbin/service centengine stop
CENTREON   ALL = NOPASSWD: /usr/sbin/service centengine restart
CENTREON   ALL = NOPASSWD: /usr/sbin/service centengine reload
CENTREON   ALL = NOPASSWD: /usr/sbin/centengine -v *

# Centreon Broker
CENTREON   ALL = NOPASSWD: /usr/sbin/service cbd start
CENTREON   ALL = NOPASSWD: /usr/sbin/service cbd stop
CENTREON   ALL = NOPASSWD: /usr/sbin/service cbd restart
CENTREON   ALL = NOPASSWD: /usr/sbin/service cbd reload

## END: CENTREON SUDO" > /etc/sudoers.d/centreon


## Workarounds
## config:  cannot open '/var/lib/centreon-broker/module-temporary.tmp-1-central-module-output-master-failover'
## (mode w+): Permission denied)
chown centreon: /var/log/centreon
chmod 775 /var/log/centreon
chown centreon-broker: /etc/centreon-broker
chmod 775 /etc/centreon-broker
chmod -R 775 /etc/centreon-engine
chmod 775 /var/lib/centreon-broker
chown centreon: /etc/centreon-broker/*

####usermod -aG ${ENGINE_GROUP} www-data
usermod -aG ${ENGINE_GROUP} ${CENTREON_USER}
usermod -aG ${ENGINE_GROUP} ${BROKER_USER}
chown ${ENGINE_USER}:${ENGINE_GROUP} /var/lib/centreon-engine/
chmod g-w /var/lib/centreon
chmod ${CENTREON_USER}:${CENTREON_GROUP} /var/lib/centreon/centplugins

mkdir /var/log/centreon-broker
chown ${BROKER_USER}: /var/log/centreon-broker
chmod 775 /var/log/centreon-broker

#add cgroup centreon
echo '[Unit]
Description=Cgroup Centreon

[Service]
Type=oneshot
ExecStart=/bin/true
ExecReload=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' > /lib/systemd/system/centreon.service

systemctl daemon-reload
systemctl enable centreon
}

function add_check_nrpe() {
[ "$SCRIPT_VERBOSE" = true ] && echo "
=======================================================================
                         Install check_nrpe3
=======================================================================
" | tee -a ${INSTALL_LOG}

apt-get install -y libssl-dev >> ${INSTALL_LOG}	
cd ${DL_DIR}
if [[ -e nrpe.tar.gz ]] ;
  then
    echo 'File already exist !' | tee -a ${INSTALL_LOG}
  else
    wget --no-check-certificate -O nrpe.tar.gz ${NRPE_URL} >> ${INSTALL_LOG}
    [ $? != 0 ] && return 1
fi

tar xzf nrpe.tar.gz
cd ${DL_DIR}/nrpe-nrpe-${NRPE_VERSION}

[ "$SCRIPT_VERBOSE" = true ] && echo "====> Compilation" | tee -a ${INSTALL_LOG}

./configure --with-nagios-user=${ENGINE_USER} --with-nrpe-user=${ENGINE_USER} --with-nagios-group=${ENGINE_USER} --with-nrpe-group=${ENGINE_USER} --libexecdir=/usr/lib/nagios/plugins  >> ${INSTALL_LOG}
make all  >> ${INSTALL_LOG}
make install-plugin  >> ${INSTALL_LOG}
}

function main () {
  if [ "$ADD_NRPE" == "yes" ]
  then
echo "
================| Centreon Poller Install details $VERSION_BATCH |============
                  Clib       : ${CLIB_VER}
                  Connector  : ${CONNECTOR_VER}
                  Engine     : ${ENGINE_VER}
                  Plugins    : ${PLUGIN_VER} & ${PLUGIN_CENTREON_VER}
                  Broker     : ${BROKER_VER}
                  Centreon   : ${CENTREON_VER}
                  NRPE       : ${NRPE_VERSION}
                  Install dir: ${INSTALL_DIR}
                  Source dir : ${DL_DIR}
======================================================================
"
  else
echo "
================| Centreon Poller Install details $VERSION_BATCH |============
                  Clib       : ${CLIB_VER}
                  Connector  : ${CONNECTOR_VER}
                  Engine     : ${ENGINE_VER}
                  Plugins    : ${PLUGIN_VER} & ${PLUGIN_CENTREON_VER}
                  Broker     : ${BROKER_VER}
                  Centreon   : ${CENTREON_VER}
                  Install dir: ${INSTALL_DIR}
                  Source dir : ${DL_DIR}
======================================================================
"
  fi

text_params

verify_version "$CLIB_VER" "$CLIB_VER_OLD"
if [[ $? -eq 1 ]];
  then
    clib_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step1${normal}  => Clib install                                          ${STATUS_FAIL}"
      else
        echo -e "${bold}Step1${normal}  => Clib install                                          ${STATUS_OK}"
        maj_conf "CLIB_VER" "$CLIB_VER_OLD" "$CLIB_VER"
    fi
  else
    echo -e "${bold}Step1${normal}  => Clib already installed                                ${STATUS_OK}"
fi

verify_version "$CONNECTOR_VER" "$CONNECTOR_VER_OLD"
if [[ $? -eq 1 ]];
  then
    centreon_connectors_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step2${normal}  => Centreon Perl and SSH connectors install              ${STATUS_FAIL}"
      else
        echo -e "${bold}Step2${normal}  => Centreon Perl and SSH connectors install              ${STATUS_OK}"
        maj_conf "CONNECTOR_VER" "$CONNECTOR_VER_OLD" "$CONNECTOR_VER"
    fi
  else
    echo -e  "${bold}Step2${normal}  => Centreon Perl and SSH connectors already installed    ${STATUS_OK}"
fi

verify_version "$ENGINE_VER" "$ENGINE_VER_OLD"
if [[ $? -eq 1 ]];
  then
    centreon_engine_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step3${normal}  => Centreon Engine install                               ${STATUS_FAIL}"
      else
        echo -e "${bold}Step3${normal}  => Centreon Engine install                               ${STATUS_OK}"
        maj_conf "ENGINE_VER" "$ENGINE_VER_OLD" "$ENGINE_VER"
    fi
  else
    echo -e     "${bold}Step3${normal}  => Centreon Engine already installed                     ${STATUS_OK}"
fi

verify_version "$PLUGIN_VER" "$PLUGIN_VER_OLD"
if [[ $? -eq 1 ]];
  then
    monitoring_plugin_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step4${normal}  => Monitoring plugins install                            ${STATUS_FAIL}"
      else
        echo -e "${bold}Step4${normal}  => Monitoring plugins install                            ${STATUS_OK}"
        maj_conf "PLUGIN_VER" "$PLUGIN_VER_OLD" "$PLUGIN_VER"    
    fi
  else
    echo -e     "${bold}Step4${normal}  => Monitoring plugins already installed                  ${STATUS_OK}"
fi    

verify_version "$PLUGIN_CENTREON_VER" "$PLUGIN_CENTREON_VER_OLD"
if [[ $? -eq 1 ]];
  then
    centreon_plugins_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step5${normal}  => Centreon plugins install                              ${STATUS_FAIL}"
      else
        echo -e "${bold}Step5${normal}  => Centreon plugins install                              ${STATUS_OK}"
        maj_conf "PLUGIN_CENTREON_VER" "$PLUGIN_CENTREON_VER_OLD" "$PLUGIN_CENTREON_VER"    
      fi
  else
    echo -e     "${bold}Step5${normal}  => Centreon plugins already installed                    ${STATUS_OK}"
fi

verify_version "$BROKER_VER" "$BROKER_VER_OLD"
if [[ $? -eq 1 ]];
  then
    centreon_broker_install 2>>${INSTALL_LOG}
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step6${normal}  => Centreon Broker install                               ${STATUS_FAIL}"
      else
        echo -e "${bold}Step6${normal}  => Centreon Broker install                               ${STATUS_OK}"
        maj_conf "BROKER_VER" "$BROKER_VER_OLD" "$BROKER_VER"    
    fi
  else
    echo -e     "${bold}Step6${normal}  => Centreon Broker already installed                     ${STATUS_OK}"
fi

verify_version "$CENTREON_VER" "$CENTREON_VER_OLD"
if [[ $? -eq 1 ]];
  then
    if [ -z "$CENTREON_VER_OLD" ]; 
    then
      create_centreon_tmpl 2>>${INSTALL_LOG}
      if [[ $? -ne 0 ]];
        then
          echo -e "${bold}Step7${normal}  => Centreon template generation                          ${STATUS_FAIL}"
        else
         echo -e "${bold}Step7${normal}  => Centreon template generation                          ${STATUS_OK}"
      fi
    else 
      create_centreon_tmpl 2>>${INSTALL_LOG}
      echo -e "${bold}Step7${normal}  => Centreon template generation                          ${STATUS_OK}"
    fi
  else
    echo -e   "${bold}Step7${normal}  => Centreon template already installed                   ${STATUS_OK}"
fi

verify_version "$CENTREON_VER" "$CENTREON_VER_OLD"
if [[ $? -eq 1 ]];
  then
    if [ -z "$CENTREON_VER_OLD" ]; 
    then
      centreon_install 2>>${INSTALL_LOG}
      if [[ $? -ne 0 ]];
       then
         echo -e "${bold}Step8${normal}  => Centreon web interface install                        ${STATUS_FAIL}"
       else
         echo -e "${bold}Step8${normal}  => Centreon web interface install                        ${STATUS_OK}"
        maj_conf "CENTREON_VER" "$CENTREON_VER_OLD" "$CENTREON_VER"    
      fi
    else 
      centreon_maj 2>>${INSTALL_LOG}
      if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step8${normal}  => Centreon web interface maj                            ${STATUS_FAIL}"
      else
        echo -e "${bold}Step8${normal}  => Centreon web interface maj                           ${STATUS_OK}"
        maj_conf "CENTREON_VER" "$CENTREON_VER_OLD" "$CENTREON_VER"    
      fi
    fi
  else
    echo -e   "${bold}Step8${normal}  => Centreon web already installed                   ${STATUS_OK}"
fi

post_install 2>>${INSTALL_LOG}
if [[ $? -ne 0 ]];
  then
    echo -e "${bold}Step9${normal} => Post install                                          ${STATUS_FAIL}"
  else
    echo -e "${bold}Step9${normal} => Post install                                          ${STATUS_OK}"
fi

if [ "$ADD_NRPE" == "yes" ]
then
  add_check_nrpe 2>>${INSTALL_LOG}
  if [[ $? -ne 0 ]];
  then
    echo -e "${bold}Step10${normal} => Nrpe install                                          ${STATUS_FAIL}"
  else
    echo -e "${bold}Step10${normal} => Nrpe install                                          ${STATUS_OK}"
  fi

fi
echo ""
echo "##### Install completed #####" >> ${INSTALL_LOG} 2>&1
}

# verify version
# parameter $1:new version $2:old version
# return 0:egal 1:update/install 2:newer version installed 
function verify_version () {
   if [ -z "$2" ]; then
     return 1
   fi
   if [[ $1 == $2 ]]
   then
     return 0
   fi
       local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# maj conf
# parameter $1: name variable $2: old value $3: new value
function maj_conf () {
	/bin/cat /etc/centreon/install_auto.conf | grep "^$1$"
	if [[ $? -ne 0 ]];
	then
	  echo "$1=$3" >> /etc/centreon/install_auto.conf
	else
	  sed -i "s/$1=$2/$1=$3/" /etc/centreon/install_auto.conf
	fi
}

function exist_conf () {
	if [ ! -f /etc/centreon/install_auto.conf ] ;
	then
	  if [ ! -d /etc/centreon ] ;
	  then
	    mkdir /etc/centreon
	  fi
	  touch /etc/centreon/install_auto.conf
	else
          IFS="="
	  while read -r var value
          do
            export "${var}_OLD"="$value"
          done < /etc/centreon/install_auto.conf
	fi 
	
}

for i in "$@"
do
  case $i in
    -n=*|--nrpe=*)
      ADD_NRPE="${i#*=}"
      shift # past argument=value
      ;;
    -v|--verbose)
      SCRIPT_VERBOSE=true
      ;;
    -h|--help)
      show_help
      exit 2
      ;;
    *)
            # unknown option
    ;;
  esac
done

# Exec main function
exist_conf
main
echo -e ""
echo -e "${bold}Go to Central Server for configuration${normal} "
echo -e ""
