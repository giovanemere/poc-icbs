#!/bin/bash
echo "Initializing WebLogic Server with Feature Flags..."

# Wait for WebLogic to be ready
echo "Waiting for WebLogic Server to start..."
sleep 30

# Check if WebLogic is running
if curl -f http://localhost:7001/console > /dev/null 2>&1; then
    echo "WebLogic Server is running"
    
    # Deploy feature-enabled applications
    /app/scripts/deploy-features.sh
    
    echo "WebLogic initialization completed successfully"
else
    echo "Warning: WebLogic Server may not be fully ready"
fi
