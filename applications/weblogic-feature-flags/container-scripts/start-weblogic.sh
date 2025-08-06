#!/bin/bash
# =============================================================================
# WebLogic Server Startup Script - ARQUITECTURA CORREGIDA
# Handles domain creation and server startup with new volume structure
# =============================================================================

set -e

# Environment variables
export ORACLE_HOME=/u01/oracle
export DOMAIN_HOME=/u01/oracle/user_projects/domains/base_domain
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-welcome1}
export VERSION=${VERSION:-A}

echo "=========================================="
echo "Starting WebLogic Server Version: $VERSION"
echo "Oracle Home: $ORACLE_HOME"
echo "Domain Home: $DOMAIN_HOME"
echo "Architecture: CORREGIDA - Sin conflictos"
echo "=========================================="

# Function to wait for domain creation
wait_for_domain() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [ -f "$DOMAIN_HOME/bin/startWebLogic.sh" ]; then
            echo "Domain is ready!"
            return 0
        fi
        echo "Waiting for domain creation... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Domain creation timeout!"
    return 1
}

# Function to check if WebLogic is running
check_weblogic_status() {
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:7001/console > /dev/null 2>&1; then
            echo "WebLogic Server is ready and responding!"
            return 0
        fi
        echo "Waiting for WebLogic to start... (attempt $attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: WebLogic Server failed to start properly!"
    return 1
}

# Create domain if it doesn't exist
if [ ! -f "$DOMAIN_HOME/bin/startWebLogic.sh" ]; then
    echo "Domain not found. Creating domain with new architecture..."
    
    # Ensure parent directory exists with correct permissions
    mkdir -p /u01/oracle/user_projects/domains
    chown -R oracle:oracle /u01/oracle/user_projects/domains
    
    # Create domain using WLST
    cd $ORACLE_HOME
    echo "Executing domain creation script..."
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh /u01/oracle/config/create-domain.py
    
    # Wait for domain creation to complete
    wait_for_domain
    
    # Set proper permissions
    chown -R oracle:oracle $DOMAIN_HOME
    chmod -R 755 $DOMAIN_HOME
    
    echo "✅ Domain created successfully with new architecture!"
else
    echo "Domain already exists at: $DOMAIN_HOME"
fi

# Create necessary directories with new structure
echo "Creating necessary directories with new architecture..."
mkdir -p $DOMAIN_HOME/autodeploy
mkdir -p $DOMAIN_HOME/servers/AdminServer/logs
mkdir -p /u01/oracle/logs/weblogic-monitoring

# Set permissions
chown -R oracle:oracle $DOMAIN_HOME/autodeploy
chown -R oracle:oracle $DOMAIN_HOME/servers/AdminServer/logs
chown -R oracle:oracle /u01/oracle/logs/weblogic-monitoring

# Deploy applications from external-apps directory (NEW ARCHITECTURE)
echo "Setting up application deployments with new architecture..."
if [ -d "/u01/oracle/external-apps" ]; then
    echo "Found external applications directory..."
    
    if [ "$VERSION" = "A" ]; then
        echo "Configuring for Version A..."
        # Copy applications from external-apps to autodeploy
        if [ -d "/u01/oracle/external-apps/weblogic-features-a" ]; then
            cp -r /u01/oracle/external-apps/weblogic-features-a/* $DOMAIN_HOME/autodeploy/ 2>/dev/null || true
            echo "Deployed applications from weblogic-features-a"
        fi
    elif [ "$VERSION" = "B" ]; then
        echo "Configuring for Version B..."
        # Copy applications from external-apps to autodeploy
        if [ -d "/u01/oracle/external-apps/weblogic-features-b" ]; then
            cp -r /u01/oracle/external-apps/weblogic-features-b/* $DOMAIN_HOME/autodeploy/ 2>/dev/null || true
            echo "Deployed applications from weblogic-features-b"
        fi
    fi
else
    echo "External applications directory not found, using built-in applications..."
    # Fallback to built-in WAR files
    if [ "$VERSION" = "A" ]; then
        if [ -f "/u01/oracle/deploy/weblogic-features-a.war" ]; then
            cp /u01/oracle/deploy/weblogic-features-a.war $DOMAIN_HOME/autodeploy/
            echo "Deployed built-in weblogic-features-a.war"
        fi
    elif [ "$VERSION" = "B" ]; then
        if [ -f "/u01/oracle/deploy/weblogic-features-b.war" ]; then
            cp /u01/oracle/deploy/weblogic-features-b.war $DOMAIN_HOME/autodeploy/
            echo "Deployed built-in weblogic-features-b.war"
        fi
    fi
fi

# Set permissions for deployed applications
chown -R oracle:oracle $DOMAIN_HOME/autodeploy
chmod -R 644 $DOMAIN_HOME/autodeploy/*.war 2>/dev/null || true

# Configure logging
echo "Configuring logging..."
mkdir -p /u01/oracle/logs/weblogic-monitoring/$VERSION
chown -R oracle:oracle /u01/oracle/logs/weblogic-monitoring/$VERSION

# Start WebLogic Server
echo "Starting WebLogic Server..."
echo "Domain: $DOMAIN_HOME"
echo "Version: $VERSION"
echo "Admin Password: [HIDDEN]"

# Change to domain directory
cd $DOMAIN_HOME

# Start WebLogic in background
echo "Executing startWebLogic.sh..."
nohup $DOMAIN_HOME/bin/startWebLogic.sh > /u01/oracle/logs/weblogic-monitoring/$VERSION/startup.log 2>&1 &

# Wait for WebLogic to be ready
echo "Waiting for WebLogic Server to be ready..."
check_weblogic_status

# Keep container running and show logs
echo "=========================================="
echo "✅ WebLogic Server $VERSION started successfully!"
echo "Console URL: http://localhost:7001/console"
echo "Username: weblogic"
echo "Password: $ADMIN_PASSWORD"
echo "Architecture: CORREGIDA - Funcionando"
echo "=========================================="

# Tail logs to keep container running
tail -f /u01/oracle/logs/weblogic-monitoring/$VERSION/startup.log $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log
