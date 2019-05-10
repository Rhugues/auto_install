#!/bin/bash
# create_template_snmp.sh
# Version 1.01
# 10/05/2019 Ajout STPL Disk_name,Traffic,Processcount + Uptime W+3Mois C+9mois 
# Test Centreon 19.04 -> Debian9.9 + Raspbian(Poller)
# -> CMD Mode traffic "interface's'"  + "--name " dans la commande --> à revalider ...
# version 1.00
# 09/04/2019

create_cmd_snmp() {
  #-----------------------------------------------------------------------------------------------------------------------------------

  # check_centreon_plugin_load_SNMP
  exist_object CMD cmd_os_linux_snmp_load
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_load;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=load --warning=$_SERVICEWARNING$ --critical=$_SERVICECRITICAL$ --host=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_HOSTOPTION$ $_SERVICEOPTION$'

  # check_centreon_plugin_cpu_SNMP
  exist_object CMD cmd_os_linux_snmp_cpu 
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_cpu;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=cpu --warning-average=$_SERVICEWARNINGAVERAGE$ --critical-average=$_SERVICECRITICALAVERAGE$ --warning-core=$_SERVICEWARNINGCORE$ --critical-core=$_SERVICECRITICALCORE$ --host=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_HOSTOPTION$ $_SERVICEOPTION$'

  # check_centreon_plugin_memory_SNMP
  exist_object CMD cmd_os_linux_snmp_memory
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_memory;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=memory --warning-usage=$_SERVICEWARNING$ --critical-usage=$_SERVICECRITICAL$ --host=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_HOSTOPTION$ $_SERVICEOPTION$'


  #check_centreon_plugin_SNMP_traffic
  exist_object CMD cmd_os_linux_snmp_traffic  
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_traffic;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=interfaces --speed-in=$_SERVICESPEEDIN$ --speed-out=$_SERVICESPEEDOUT$ --interface=$_SERVICEINTERFACE$ --warning-in-traffic=$_SERVICEWARNINGIN$ --critical-in-traffic=$_SERVICECRITICALIN$ --warning-out-traffic=$_SERVICEWARNINGOUT$ --critical-out-traffic=$_SERVICECRITICALOUT$ --host=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_SERVICEOPTION$'

  #check centreon_plugin_SNMP_processcount 
  exist_object CMD cmd_os_linux_snmp_process
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_process;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=processcount --hostname=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_HOSTOPTION$ --process-name=$_SERVICEPROCESSNAME$ --process-path=$_SERVICEPROCESSPATH$ --process-args=$_SERVICEPROCESSARGS$ --regexp-name --regexp-path --regexp-args --warning=$_SERVICEWARNING$ --critical=$_SERVICECRITICAL$ $_SERVICEOPTION$' 

  # cmd_os_linux_SNMP_disk_name
  exist_object CMD cmd_os_linux_snmp_disk_name
  [ $? -ne 0 ] && $CLAPI -o CMD -a ADD -v 'cmd_os_linux_snmp_disk_name;check;$CENTREONPLUGINS$/centreon_plugins.pl --plugin=os::linux::snmp::plugin --mode=storage --hostname=$HOSTADDRESS$ --snmp-version=$_HOSTSNMPVERSION$ --snmp-community=$_HOSTSNMPCOMMUNITY$ $_HOSTOPTION$ --name=$_SERVICEDISKNAME$ --warning-usage=$_SERVICEWARNING$ --critical-usage=$_SERVICECRITICAL$ $_SERVICEOPTION$ '

}

create_stpl_snmp() {

  ## CPU snmp
  #stpl_os_linux_snmp_cpu
  exist_object STPL stpl_os_linux_snmp_cpu
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_cpu;cpu;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_cpu;check_command;cmd_os_linux_snmp_cpu"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_cpu;WARNING;70"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_cpu;CRITICAL;90"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_cpu;graphtemplate;CPU"
  fi


  ## LOAD SNMP
  #stpl_os_linux_snmp_load
  exist_object STPL stpl_os_linux_snmp_load
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_load;Load;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_load;check_command;cmd_os_linux_snmp_load"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_load;WARNING;4,3,2"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_load;CRITICAL;6,5,4"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_load;graphtemplate;LOAD_Average"
  fi

  ## MEMORY SNMP
  #stpl_os_linux_snmp_memory
  exist_object STPL stpl_os_linux_snmp_memory
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_memory;Memory;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_memory;check_command;cmd_os_linux_snmp_memory"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_memory;WARNING;70"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_memory;CRITICAL;90"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_memory;graphtemplate;Memory"
  fi

  ## SNMP_traffic
  #stpl_os_linux_snmp_traffic
  exist_object STPL stpl_os_linux_snmp_traffic
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_traffic;Traffic;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_traffic;check_command;cmd_os_linux_snmp_traffic"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;INTERFACE;'eth0'"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;SPEEDIN;1000"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;SPEEDOUT;1000"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;WARNINGIN;70"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;CRITICALIN;80"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;WARNINGOUT;70"
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_traffic;CRITICALOUT;90"
    #$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_network;OPTION; "
	$CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_traffic;graphtemplate;Traffic"
	
  # Option Ligne Nagvis Wearthemap ...
	$CLAPI -o STPL -a add -v "stpl_os_linux_snmp_traffic-NgvWmp;Traffic;stpl_os_linux_snmp_traffic"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_network-NgvWmp;OPTION; --change-perfdata=traffic,target,,bps --extend-perfdata='target_(in|out),nagvis_$1L,percent()' --extend-perfdata='target_(in|out),nagvis_$1T,scale(auto)' --extend-perfdata=target,traffic --filter-perfdata='nagvis|traffic' "


##
  ## SNMP_ Uptime 
  #stpl_os_linux_snmp_uptime 
  # 1 Month = 2629800s  WARNING->3Month CRITICAL->9Month
  exist_object STPL stpl_os_linux_snmp_uptime 
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_ uptime;uptime;service-generique-actif"
	$CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_uptime;check_command;cmd_os_linux_snmp_uptime"
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_uptime;WARNING;7889400"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_uptime;CRITICAL;23668200"
	$CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_uptime;graphtemplate;Uptime"
	

  ##SNMP_processcount ( IDEM STPL POOLER )
  #stpl_os_linux_snmp_processcount	
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_processcount;Processcount;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_processcount;check_command;cmd_os_linux_snmp_process"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;WARNING;70"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;CRITICAL;90"
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;PROCESSNAME; "
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;PROCESSPATH; "
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;PROCESSARGS; "
	$CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_processcount;OPTION; "
	# $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_processcount;graphtemplate;??????" <->  Grph Template ?
	
		
		### ----- WWW-SERVER -------
	#stpl_os_linux_snmp_processcount_Apache2
	#stpl_os_linux_snmp_processcount_Nginx
	#stpl_os_linux_snmp_processcount_lighthhpd
	#stpl_os_linux_snmp_processcount_php-fpm
	    ### -----            -------
	#stpl_os_linux_snmp_processcount_UFW
	#stpl_os_linux_snmp_processcount_Sshd
	#stpl_os_linux_snmp_processcount_
	    ### -----  Bdd          -------
	#stpl_os_linux_snmp_processcount_Mysql ->mysqld
	#stpl_os_linux_snmp_processcount_
	#stpl_os_linux_snmp_processcount_
	   ####
	#       -> python
	#		-> java
	# 		->snmpd





  ##SNMP_disk_name
  #stpl_os_linux_snmp_disk_name
  if [ $? -ne 0 ]
  then
    $CLAPI -o STPL -a add -v "stpl_os_linux_snmp_disk_name;Memory;service-generique-actif"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_disk_name;check_command;stpl_os_linux_snmp_disk_name"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_disk_name;WARNING;70"
    $CLAPI -o STPL -a setmacro -v "stpl_os_linux_snmp_disk_name;CRITICAL;90"
    $CLAPI -o STPL -a setparam -v "stpl_os_linux_snmp_disk_name;graphtemplate;Storage"

# DISK
# Model Disk
clapi -o STPL -a add -v "disk-remote-Model-Service;disk-remote-model;Model-service-active"
clapi -o STPL -a setparam -v "disk-remote-Model-Service;check_command;check_centreon_plugin_remote_os"
clapi -o STPL -a setmacro -v "disk-remote-Model-Service;PLUGIN;os::linux::local::plugin"
clapi -o STPL -a setmacro -v "disk-remote-Model-Service;USERNAME;remote_centreon"
clapi -o STPL -a setmacro -v "disk-remote-Model-Service;WARNING;80"
clapi -o STPL -a setmacro -v "disk-remote-Model-Service;CRITICAL;90"
clapi -o STPL -a setmacro -v "disk-remote-Model-Service;MODE;storage"
clapi -o STPL -a setparam -v "disk-remote-Model-Service;graphtemplate;Storage"

# DISK
# Disk home
clapi -o STPL -a add -v "disk-remote-home-Model-Service;Disk-remote-Home;disk-remote-Model-Service"
clapi -o STPL -a setmacro -v "disk-remote-home-Model-Service;OPTION;--name /home"

# DISK
# Disk root
clapi -o STPL -a add -v "disk-remote-root-Model-Service;Disk-remote-Root;disk-remote-Model-Service"
clapi -o STPL -a setmacro -v "disk-remote-root-Model-Service;OPTION;--name /"


}

create_linux_snmp () {
  
  ##OS-Linux-snmp
  exist_object HTPL htpl_OS-Linux-SNMP
  if [ $? -ne 0 ]
  then
    $CLAPI -o HTPL -a add -v "htpl_OS-Linux-SNMP;HTPL_OS-Linux-SNMP;;;;"
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_cpu;htpl_OS-Linux-SNMP"
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_load;htpl_OS-Linux-SNMP"
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_memory;htpl_OS-Linux-SNMP"
    
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_traffic;htpl_OS-Linux-SNMP"
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_processcount;htpl_OS-Linux-SNMP"
    $CLAPI -o STPL -a addhost -v "stpl_os_linux_snmp_disk_name;htpl_OS-Linux-SNMP"

    $CLAPI -o HTPL -a addtemplate -v "htpl_OS-Linux-SNMP;generic-host"
  fi
}
