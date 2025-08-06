#!/bin/bash

# =============================================================================
# Pull Docker Images from Docker Hub
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to pull image
pull_image() {
    local image_name=$1
    
    print_status "Pulling ${image_name} from Docker Hub..."
    
    docker pull ${image_name}
    
    if [ $? -eq 0 ]; then
        print_success "Successfully pulled ${image_name}"
    else
        print_error "Failed to pull ${image_name}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}📥 Starting Docker Pull Process from Docker Hub${NC}"
    echo "Registry: ${DOCKER_REGISTRY}"
    echo "Tag: ${DOCKER_TAG}"
    echo ""
    
    # Pre-flight checks
    check_docker
    
    # Pull all images
    print_status "Pulling images from Docker Hub..."
    
    # Pull WebLogic images
    pull_image "${WEBLOGIC_IMAGE}"
    pull_image "${DOCKER_REGISTRY}/weblogic-feature-flags:version-a"
    pull_image "${DOCKER_REGISTRY}/weblogic-feature-flags:version-b"
    
    # Pull HAProxy image
    pull_image "${HAPROXY_IMAGE}"
    
    # Pull MkDocs image
    pull_image "${MKDOCS_IMAGE}"
    
    # Pull Oracle image (from Oracle registry)
    print_status "Pulling Oracle Database image..."
    pull_image "${ORACLE_IMAGE}"
    
    # Summary
    echo ""
    echo -e "${GREEN}🎉 Pull Process Completed Successfully!${NC}"
    echo ""
    echo "Images pulled from registries:"
    echo "  • ${WEBLOGIC_IMAGE}"
    echo "  • ${DOCKER_REGISTRY}/weblogic-feature-flags:version-a"
    echo "  • ${DOCKER_REGISTRY}/weblogic-feature-flags:version-b"
    echo "  • ${HAPROXY_IMAGE}"
    echo "  • ${MKDOCS_IMAGE}"
    echo "  • ${ORACLE_IMAGE}"
    echo ""
    
    # Show pulled images
    print_status "Available images:"
    docker images | grep -E "(${DOCKER_REGISTRY}|oracle)" | awk '{print "  • " $1 ":" $2 " - " $7 $8}'
}

# Handle script arguments
case "${1:-all}" in
    "weblogic")
        check_docker
        pull_image "${WEBLOGIC_IMAGE}"
        ;;
    "haproxy")
        check_docker
        pull_image "${HAPROXY_IMAGE}"
        ;;
    "mkdocs")
        check_docker
        pull_image "${MKDOCS_IMAGE}"
        ;;
    "oracle")
        check_docker
        pull_image "${ORACLE_IMAGE}"
        ;;
    "all"|*)
        main
        ;;
esac
