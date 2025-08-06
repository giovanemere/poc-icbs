#!/bin/bash

# =============================================================================
# Build and Push Docker Images to Docker Hub
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

# Function to check Docker Hub login
check_docker_login() {
    if ! docker info | grep -q "Username: ${DOCKER_REGISTRY}"; then
        print_warning "Not logged in to Docker Hub. Attempting login..."
        echo "Please enter your Docker Hub password for ${DOCKER_REGISTRY}:"
        docker login -u ${DOCKER_REGISTRY}
        if [ $? -eq 0 ]; then
            print_success "Successfully logged in to Docker Hub"
        else
            print_error "Failed to login to Docker Hub"
            exit 1
        fi
    else
        print_success "Already logged in to Docker Hub as ${DOCKER_REGISTRY}"
    fi
}

# Function to build image
build_image() {
    local dockerfile=$1
    local image_name=$2
    local context=$3
    local build_args=$4
    
    print_status "Building ${image_name}..."
    
    if [ -n "$build_args" ]; then
        docker build \
            --platform ${DOCKER_PLATFORM} \
            --file ${dockerfile} \
            --tag ${image_name} \
            ${build_args} \
            ${context}
    else
        docker build \
            --platform ${DOCKER_PLATFORM} \
            --file ${dockerfile} \
            --tag ${image_name} \
            ${context}
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Successfully built ${image_name}"
    else
        print_error "Failed to build ${image_name}"
        exit 1
    fi
}

# Function to push image
push_image() {
    local image_name=$1
    
    print_status "Pushing ${image_name} to Docker Hub..."
    
    docker push ${image_name}
    
    if [ $? -eq 0 ]; then
        print_success "Successfully pushed ${image_name}"
    else
        print_error "Failed to push ${image_name}"
        exit 1
    fi
}

# Function to tag image with additional tags
tag_image() {
    local source_image=$1
    local target_image=$2
    
    print_status "Tagging ${source_image} as ${target_image}..."
    
    docker tag ${source_image} ${target_image}
    
    if [ $? -eq 0 ]; then
        print_success "Successfully tagged ${target_image}"
    else
        print_error "Failed to tag ${target_image}"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Docker Build and Push Process${NC}"
    echo "Registry: ${DOCKER_REGISTRY}"
    echo "Platform: ${DOCKER_PLATFORM}"
    echo "Tag: ${DOCKER_TAG}"
    echo ""
    
    # Pre-flight checks
    check_docker
    check_docker_login
    
    # Change to project root
    cd "$(dirname "$0")/.."
    
    # Build WebLogic Feature Flags Image
    print_status "Building WebLogic Feature Flags Application..."
    build_image \
        "${DOCKERFILE_WEBLOGIC}" \
        "${WEBLOGIC_IMAGE}" \
        "${BUILD_CONTEXT}" \
        "--build-arg VERSION=A --build-arg ADMIN_PASSWORD=${WEBLOGIC_ADMIN_PASSWORD}"
    
    # Tag with version A and B
    tag_image "${WEBLOGIC_IMAGE}" "${DOCKER_REGISTRY}/weblogic-feature-flags:version-a"
    tag_image "${WEBLOGIC_IMAGE}" "${DOCKER_REGISTRY}/weblogic-feature-flags:version-b"
    
    # Build HAProxy Advanced Image
    print_status "Building HAProxy Advanced Load Balancer..."
    build_image \
        "${DOCKERFILE_HAPROXY}" \
        "${HAPROXY_IMAGE}" \
        "${BUILD_CONTEXT}"
    
    # Build MkDocs Server Image
    print_status "Building MkDocs Documentation Server..."
    build_image \
        "${DOCKERFILE_MKDOCS}" \
        "${MKDOCS_IMAGE}" \
        "${BUILD_CONTEXT}"
    
    # Push all images to Docker Hub
    print_status "Pushing images to Docker Hub..."
    
    push_image "${WEBLOGIC_IMAGE}"
    push_image "${DOCKER_REGISTRY}/weblogic-feature-flags:version-a"
    push_image "${DOCKER_REGISTRY}/weblogic-feature-flags:version-b"
    push_image "${HAPROXY_IMAGE}"
    push_image "${MKDOCS_IMAGE}"
    
    # Create manifest for multi-arch support (if needed)
    if [ "${DOCKER_PLATFORM}" != "linux/amd64" ]; then
        print_status "Creating multi-architecture manifests..."
        # This would be expanded for multi-arch builds
    fi
    
    # Summary
    echo ""
    echo -e "${GREEN}🎉 Build and Push Process Completed Successfully!${NC}"
    echo ""
    echo "Images pushed to Docker Hub:"
    echo "  • ${WEBLOGIC_IMAGE}"
    echo "  • ${DOCKER_REGISTRY}/weblogic-feature-flags:version-a"
    echo "  • ${DOCKER_REGISTRY}/weblogic-feature-flags:version-b"
    echo "  • ${HAPROXY_IMAGE}"
    echo "  • ${MKDOCS_IMAGE}"
    echo ""
    echo "Docker Hub Repository: https://hub.docker.com/repositories/${DOCKER_REGISTRY}"
    echo ""
    
    # Show image sizes
    print_status "Image sizes:"
    docker images | grep "${DOCKER_REGISTRY}" | awk '{print "  • " $1 ":" $2 " - " $7 $8}'
}

# Handle script arguments
case "${1:-all}" in
    "weblogic")
        check_docker
        check_docker_login
        cd "$(dirname "$0")/.."
        build_image "${DOCKERFILE_WEBLOGIC}" "${WEBLOGIC_IMAGE}" "${BUILD_CONTEXT}" "--build-arg VERSION=A --build-arg ADMIN_PASSWORD=${WEBLOGIC_ADMIN_PASSWORD}"
        push_image "${WEBLOGIC_IMAGE}"
        ;;
    "haproxy")
        check_docker
        check_docker_login
        cd "$(dirname "$0")/.."
        build_image "${DOCKERFILE_HAPROXY}" "${HAPROXY_IMAGE}" "${BUILD_CONTEXT}"
        push_image "${HAPROXY_IMAGE}"
        ;;
    "mkdocs")
        check_docker
        check_docker_login
        cd "$(dirname "$0")/.."
        build_image "${DOCKERFILE_MKDOCS}" "${MKDOCS_IMAGE}" "${BUILD_CONTEXT}"
        push_image "${MKDOCS_IMAGE}"
        ;;
    "all"|*)
        main
        ;;
esac
