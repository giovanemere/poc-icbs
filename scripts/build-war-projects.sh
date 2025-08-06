#!/bin/bash

# =============================================================================
# Build WAR Projects Script
# Compiles all war-projects into deployable WAR files
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAR_PROJECTS_DIR="${PROJECT_ROOT}/war-projects"
DEPLOY_DIR="${PROJECT_ROOT}/applications/weblogic-feature-flags/deploy"

echo -e "${BLUE}🔨 Building WAR Projects...${NC}"
echo "Project Root: ${PROJECT_ROOT}"
echo "WAR Projects: ${WAR_PROJECTS_DIR}"
echo "Deploy Directory: ${DEPLOY_DIR}"

# Create deploy directory if it doesn't exist
mkdir -p "${DEPLOY_DIR}"

# Function to create WAR file from directory
create_war() {
    local project_dir="$1"
    local war_name="$2"
    
    echo -e "${YELLOW}📦 Creating ${war_name}.war from ${project_dir}...${NC}"
    
    if [ ! -d "${WAR_PROJECTS_DIR}/${project_dir}" ]; then
        echo -e "${RED}❌ Directory ${project_dir} not found!${NC}"
        return 1
    fi
    
    cd "${WAR_PROJECTS_DIR}/${project_dir}"
    
    # Create WAR file (ZIP format)
    jar -cf "${DEPLOY_DIR}/${war_name}.war" *
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${war_name}.war created successfully${NC}"
        ls -lh "${DEPLOY_DIR}/${war_name}.war"
    else
        echo -e "${RED}❌ Failed to create ${war_name}.war${NC}"
        return 1
    fi
}

# Build all WAR projects
echo -e "${BLUE}🚀 Starting WAR compilation...${NC}"

# WebLogic Features A
create_war "weblogic-features-a" "weblogic-features-a"

# WebLogic Features B  
create_war "weblogic-features-b" "weblogic-features-b"

# Feature Flags
create_war "feature-flags" "feature-flags"

# Version A
create_war "version-a" "version-a"

# Version B
create_war "version-b" "version-b"

# FF4J Simple
create_war "ff4j-simple" "ff4j-simple"

echo -e "${GREEN}🎉 All WAR files built successfully!${NC}"
echo -e "${BLUE}📁 WAR files location: ${DEPLOY_DIR}${NC}"
ls -lh "${DEPLOY_DIR}/"*.war

echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Run: ./manage-services.sh build"
echo "2. Run: ./manage-services.sh start"
