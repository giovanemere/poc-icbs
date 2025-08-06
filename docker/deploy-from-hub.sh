#!/bin/bash

# =============================================================================
# Deploy from Docker Hub Images
# Registry: edissonz8809
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✅ Environment variables loaded${NC}"
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed or not in PATH"
        exit 1
    fi
    print_success "docker-compose is available"
}

# Function to pull latest images
pull_latest_images() {
    print_status "Pulling latest images from Docker Hub..."
    
    ./pull-from-hub.sh all
    
    if [ $? -eq 0 ]; then
        print_success "All images pulled successfully"
    else
        print_error "Failed to pull some images"
        exit 1
    fi
}

# Function to stop existing services
stop_services() {
    print_status "Stopping existing services..."
    
    docker-compose -f docker-compose.yml down --remove-orphans
    
    if [ $? -eq 0 ]; then
        print_success "Services stopped successfully"
    else
        print_warning "Some services may not have been running"
    fi
}

# Function to start services
start_services() {
    print_status "Starting services from Docker Hub images..."
    
    # Use --no-build to ensure we use pulled images
    docker-compose -f docker-compose.yml up -d --no-build
    
    if [ $? -eq 0 ]; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Function to wait for services to be healthy
wait_for_services() {
    print_status "Waiting for services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local healthy_count=0
        local total_services=5
        
        # Check each service
        if docker ps --filter "name=orcldb" --filter "health=healthy" | grep -q orcldb; then
            ((healthy_count++))
        fi
        
        if docker ps --filter "name=weblogic-a" --filter "status=running" | grep -q weblogic-a; then
            ((healthy_count++))
        fi
        
        if docker ps --filter "name=weblogic-b" --filter "status=running" | grep -q weblogic-b; then
            ((healthy_count++))
        fi
        
        if docker ps --filter "name=haproxy" --filter "status=running" | grep -q haproxy; then
            ((healthy_count++))
        fi
        
        if docker ps --filter "name=mkdocs-server" --filter "status=running" | grep -q mkdocs-server; then
            ((healthy_count++))
        fi
        
        if [ $healthy_count -eq $total_services ]; then
            print_success "All services are healthy and running"
            return 0
        fi
        
        echo -n "."
        sleep 10
        ((attempt++))
    done
    
    print_warning "Some services may still be starting up"
    return 1
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    echo ""
    
    docker-compose -f docker-compose.yml ps
    
    echo ""
    print_status "Service URLs:"
    echo "  • WebLogic A Console: http://localhost:${WEBLOGIC_EXTERNAL_PORT_A}/console"
    echo "  • WebLogic B Console: http://localhost:${WEBLOGIC_EXTERNAL_PORT_B}/console"
    echo "  • HAProxy Admin UI: http://localhost:${HAPROXY_ADMIN_PORT}"
    echo "  • HAProxy Stats: http://localhost:${HAPROXY_STATS_PORT}/stats"
    echo "  • Load Balancer: http://localhost:${HAPROXY_WEB_PORT}"
    echo "  • MkDocs Documentation: http://localhost:${MKDOCS_PORT}"
    echo "  • Oracle EM Express: http://localhost:${ORACLE_EM_PORT}/em"
    echo ""
}

# Function to run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    local failed_checks=0
    
    # Check MkDocs
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${MKDOCS_PORT} | grep -q "200"; then
        print_success "MkDocs is responding"
    else
        print_error "MkDocs health check failed"
        ((failed_checks++))
    fi
    
    # Check HAProxy Stats
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HAPROXY_STATS_PORT}/stats | grep -q "401\|200"; then
        print_success "HAProxy Stats is responding"
    else
        print_error "HAProxy Stats health check failed"
        ((failed_checks++))
    fi
    
    # Check HAProxy Admin UI
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:${HAPROXY_ADMIN_PORT} | grep -q "200"; then
        print_success "HAProxy Admin UI is responding"
    else
        print_error "HAProxy Admin UI health check failed"
        ((failed_checks++))
    fi
    
    if [ $failed_checks -eq 0 ]; then
        print_success "All health checks passed"
    else
        print_warning "$failed_checks health checks failed"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Deployment from Docker Hub${NC}"
    echo "Registry: ${DOCKER_REGISTRY}"
    echo "Environment: ${DEPLOY_ENVIRONMENT}"
    echo ""
    
    # Pre-flight checks
    check_docker
    check_docker_compose
    
    # Change to docker directory
    cd "$(dirname "$0")"
    
    # Pull latest images
    if [ "${1}" != "--no-pull" ]; then
        pull_latest_images
    else
        print_warning "Skipping image pull (--no-pull flag used)"
    fi
    
    # Stop existing services
    stop_services
    
    # Start services
    start_services
    
    # Wait for services to be healthy
    wait_for_services
    
    # Show status
    show_status
    
    # Run health checks
    sleep 30  # Give services time to fully start
    run_health_checks
    
    # Summary
    echo ""
    echo -e "${GREEN}🎉 Deployment Completed Successfully!${NC}"
    echo ""
    echo "All services are running from Docker Hub images:"
    echo "  • Registry: https://hub.docker.com/repositories/${DOCKER_REGISTRY}"
    echo "  • Environment: ${DEPLOY_ENVIRONMENT}"
    echo "  • Platform: ${DOCKER_PLATFORM}"
    echo ""
    echo "To stop all services: docker-compose -f docker-compose.yml down"
    echo "To view logs: docker-compose -f docker-compose.yml logs -f [service-name]"
    echo ""
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy"|"")
        main
        ;;
    "--no-pull")
        main --no-pull
        ;;
    "status")
        cd "$(dirname "$0")"
        show_status
        ;;
    "health")
        run_health_checks
        ;;
    "stop")
        cd "$(dirname "$0")"
        stop_services
        ;;
    *)
        echo "Usage: $0 [deploy|--no-pull|status|health|stop]"
        echo ""
        echo "Commands:"
        echo "  deploy     - Pull latest images and deploy (default)"
        echo "  --no-pull  - Deploy without pulling latest images"
        echo "  status     - Show service status"
        echo "  health     - Run health checks"
        echo "  stop       - Stop all services"
        exit 1
        ;;
esac
