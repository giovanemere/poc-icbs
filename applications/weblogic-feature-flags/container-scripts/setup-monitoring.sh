#!/bin/bash
# =============================================================================
# WebLogic Monitoring Setup Script
# Sets up log monitoring and health checks
# =============================================================================

set -e

export DOMAIN_HOME=/u01/oracle/user_projects/domains/base_domain
export MONITORING_DIR=/u01/oracle/logs/weblogic-monitoring
export VERSION=${VERSION:-A}

echo "Setting up WebLogic monitoring for Version $VERSION..."

# Create monitoring directories
mkdir -p $MONITORING_DIR
mkdir -p $DOMAIN_HOME/servers/AdminServer/logs

# Set permissions
chown -R oracle:oracle $MONITORING_DIR
chown -R oracle:oracle $DOMAIN_HOME/servers/AdminServer/logs

# Create monitoring log file
MONITOR_LOG="$MONITORING_DIR/weblogic-$VERSION-monitor.log"
touch $MONITOR_LOG
chown oracle:oracle $MONITOR_LOG

echo "$(date): Monitoring setup started for WebLogic Version $VERSION" >> $MONITOR_LOG

# Monitor WebLogic logs in background
if [ -f "$DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log" ]; then
    tail -f "$DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log" >> $MONITOR_LOG &
    echo "Log monitoring started for AdminServer.log"
fi

# Monitor startup log
if [ -f "$DOMAIN_HOME/servers/AdminServer/logs/startup.log" ]; then
    tail -f "$DOMAIN_HOME/servers/AdminServer/logs/startup.log" >> $MONITOR_LOG &
    echo "Log monitoring started for startup.log"
fi

echo "Monitoring setup completed. Logs directory is ready."
echo "Monitor log: $MONITOR_LOG"
