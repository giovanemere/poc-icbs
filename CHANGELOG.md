# Changelog

All notable changes to this project will be documented in this file.

## [v2.2.0] - 2025-09-08

### 🚀 Major Improvements
- **Fixed WebLogic container startup issues** - Resolved domain configuration problems
- **Corrected HAProxy configuration** - Now properly routes to WebLogic backends instead of static content
- **Complete application deployment** - All WAR files deployed to both WebLogic nodes
- **Functional load balancing** - Real traffic distribution between WebLogic A and B

### ✅ Applications Working
- `version-a` → http://localhost:8100/version-a/ (WebLogic A)
- `version-b` → http://localhost:8100/version-b/ (WebLogic B)
- `feature-flags` → http://localhost:8100/feature-flags/ (Balanced A/B)
- `ff4j-simple` → http://localhost:8100/ff4j-simple/ (Balanced A/B)
- `weblogic-features-a/b` → Node-specific applications

### 🔧 Technical Changes
- Updated HAProxy configuration for proper backend routing
- Fixed WebLogic domain startup script
- Added automatic .env loading in smart-start.sh
- Simplified Docker network configuration
- Enhanced troubleshooting documentation

### 📊 System Status
- ✅ Oracle Database: Ports 1521/5500 (healthy)
- ✅ WebLogic A: Port 7001 (running)
- ✅ WebLogic B: Port 7002 (running)
- ✅ HAProxy: Port 8100 (load balancing active)
- ✅ Dashboards: Ports 8084, 8085, 8092, 8093 (operational)

## [v2.0.0] - Previous Release
- Initial Docker setup for Oracle WebLogic
- Basic HAProxy configuration
- Dashboard system implementation

## [v4.0.1] - Previous Release
- MkDocs documentation updates
- ICBD version updates
