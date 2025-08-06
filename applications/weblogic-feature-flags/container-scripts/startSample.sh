#!/bin/bash
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#

# Define default command to create medrec domain 
USERNAME=${USERNAME:-weblogic}
PASSWORD=${PASSWORD:-welcome1}

# Create WebLogic domain
mkdir -p /u01/oracle/user_projects/domains/base_domain

# Set environment variables
export DOMAIN_HOME=/u01/oracle/user_projects/domains/base_domain
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

echo "Creating WebLogic domain..."
$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning << EOF
readTemplate("$ORACLE_HOME/wlserver/common/templates/wls/wls.jar")
set('AdminUserName', '${USERNAME}')
set('AdminPassword', '${PASSWORD}')
set('ServerStartMode', 'dev')
set('JavaHome', '${JAVA_HOME}')
cd('/Security/base_domain/User/${USERNAME}')
cmo.setPassword('${PASSWORD}')
cd('/Server/AdminServer')
set('ListenAddress', '')
set('ListenPort', 7001)
writeDomain('${DOMAIN_HOME}')
closeTemplate()
exit()
EOF

echo "WebLogic domain created"

# Start WebLogic Admin Server
echo "Starting WebLogic Admin Server..."
$DOMAIN_HOME/bin/startWebLogic.sh &

# Keep container running
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log
