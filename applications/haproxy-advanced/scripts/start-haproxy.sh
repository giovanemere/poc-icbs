#!/bin/bash

# =============================================================================
# HAProxy Advanced Startup Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting HAProxy Advanced Load Balancer${NC}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Create necessary directories
mkdir -p /var/run /var/log

# Set default values if not provided
HAPROXY_STATS_USER=${HAPROXY_STATS_USER:-admin}
HAPROXY_STATS_PASSWORD=${HAPROXY_STATS_PASSWORD:-admin123}

print_status "Configuring HAProxy with stats user: ${HAPROXY_STATS_USER}"

# Start Python admin API in background
print_status "Starting Admin API..."
python3 /scripts/admin_api.py &
ADMIN_API_PID=$!

# Start Python admin UI in background
print_status "Starting Admin UI..."
python3 /scripts/admin_ui.py &
ADMIN_UI_PID=$!

# Wait a moment for Python services to start
sleep 2

# Start HAProxy
print_status "Starting HAProxy..."
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D

# Cleanup function
cleanup() {
    print_status "Shutting down services..."
    kill $ADMIN_API_PID $ADMIN_UI_PID 2>/dev/null || true
    exit 0
}

# Set trap for cleanup
trap cleanup SIGTERM SIGINT

# Keep script running
wait
