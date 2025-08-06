#!/bin/bash
# =============================================================================
# WebLogic Health Check Script
# Continuous health monitoring for WebLogic Server
# =============================================================================

set -e

export VERSION=${VERSION:-A}
export HEALTH_LOG="/u01/oracle/logs/weblogic-monitoring/health-check-$VERSION.log"

echo "Starting health check monitoring for WebLogic Version $VERSION..."

# Create health check log
mkdir -p /u01/oracle/logs/weblogic-monitoring
touch $HEALTH_LOG
chown oracle:oracle $HEALTH_LOG

# Function to check WebLogic health
check_weblogic_health() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if WebLogic console is accessible
    if curl -s -f http://localhost:7001/console > /dev/null 2>&1; then
        echo "$timestamp [INFO] WebLogic Server Version $VERSION - Health Check: HEALTHY" >> $HEALTH_LOG
        return 0
    else
        echo "$timestamp [ERROR] WebLogic Server Version $VERSION - Health Check: UNHEALTHY" >> $HEALTH_LOG
        return 1
    fi
}

# Function to check deployed applications
check_deployed_apps() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local apps_healthy=0
    
    # Check version-specific applications
    if [ "$VERSION" = "A" ]; then
        if curl -s -f http://localhost:7001/weblogic-features-a/ > /dev/null 2>&1; then
            echo "$timestamp [INFO] Application weblogic-features-a: HEALTHY" >> $HEALTH_LOG
            apps_healthy=$((apps_healthy + 1))
        else
            echo "$timestamp [WARN] Application weblogic-features-a: NOT ACCESSIBLE" >> $HEALTH_LOG
        fi
        
        if curl -s -f http://localhost:7001/version-a/ > /dev/null 2>&1; then
            echo "$timestamp [INFO] Application version-a: HEALTHY" >> $HEALTH_LOG
            apps_healthy=$((apps_healthy + 1))
        else
            echo "$timestamp [WARN] Application version-a: NOT ACCESSIBLE" >> $HEALTH_LOG
        fi
    elif [ "$VERSION" = "B" ]; then
        if curl -s -f http://localhost:7001/weblogic-features-b/ > /dev/null 2>&1; then
            echo "$timestamp [INFO] Application weblogic-features-b: HEALTHY" >> $HEALTH_LOG
            apps_healthy=$((apps_healthy + 1))
        else
            echo "$timestamp [WARN] Application weblogic-features-b: NOT ACCESSIBLE" >> $HEALTH_LOG
        fi
        
        if curl -s -f http://localhost:7001/version-b/ > /dev/null 2>&1; then
            echo "$timestamp [INFO] Application version-b: HEALTHY" >> $HEALTH_LOG
            apps_healthy=$((apps_healthy + 1))
        else
            echo "$timestamp [WARN] Application version-b: NOT ACCESSIBLE" >> $HEALTH_LOG
        fi
    fi
    
    # Check common applications
    if curl -s -f http://localhost:7001/feature-flags/ > /dev/null 2>&1; then
        echo "$timestamp [INFO] Application feature-flags: HEALTHY" >> $HEALTH_LOG
        apps_healthy=$((apps_healthy + 1))
    else
        echo "$timestamp [WARN] Application feature-flags: NOT ACCESSIBLE" >> $HEALTH_LOG
    fi
    
    echo "$timestamp [INFO] Applications healthy: $apps_healthy" >> $HEALTH_LOG
}

echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Health check monitoring started for WebLogic Version $VERSION" >> $HEALTH_LOG

# Continuous health monitoring
while true; do
    check_weblogic_health
    check_deployed_apps
    sleep 60  # Check every minute
done
