# 🚀 GitHub Actions - Oracle WebLogic Docker Platform

## 📋 Workflow Overview

Este repositorio incluye un workflow completo para la plataforma Oracle WebLogic con Docker, incluyendo:

### 🔄 **Pipeline Stages**

1. **🔍 Validate Configuration**
   - Validación de Docker Compose files
   - Verificación de archivos de entorno
   - Validación de configuración HAProxy
   - Verificación de configuración MkDocs

2. **🏗️ Build Docker Images**
   - **WebLogic Feature Flags**: Servidor de aplicaciones
   - **HAProxy Advanced**: Load balancer y proxy
   - **MkDocs Server**: Servidor de documentación
   - **Oracle Express DB**: Base de datos

3. **🧪 Integration Testing**
   - Tests de integración completos
   - Verificación de conectividad entre servicios
   - Health checks automáticos
   - Validación de endpoints

4. **🐤 Canary Deployment**
   - Deploy gradual con monitoreo
   - Análisis de métricas de infraestructura
   - Rollback automático si es necesario

5. **🚩 Feature Flag Management**
   - Gestión de feature flags en WebLogic
   - Configuración dinámica de features
   - Monitoreo de uso de features

6. **🚀 Production Deployment**
   - Deploy coordinado de todos los servicios
   - Configuración de monitoreo
   - Setup de alertas

## ⚙️ **Configuración Requerida**

### Secrets de GitHub

```bash
# Docker Hub
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token

# Oracle Database
ORACLE_PASSWORD=your-oracle-password
ORACLE_SID=XE

# WebLogic
WEBLOGIC_PASSWORD=your-weblogic-password
WEBLOGIC_DOMAIN=base_domain

# Monitoring
MONITORING_WEBHOOK=your-monitoring-webhook
SLACK_WEBHOOK=your-slack-webhook
```

### Environment Variables

```bash
# Oracle Configuration
ORACLE_PASSWORD=Oracle123
ORACLE_SID=XE
ORACLE_PDB=XEPDB1

# WebLogic Configuration
WEBLOGIC_PASSWORD=Welcome123
WEBLOGIC_DOMAIN=base_domain
WEBLOGIC_ADMIN_SERVER=AdminServer

# HAProxy Configuration
HAPROXY_STATS_PASSWORD=admin123
HAPROXY_STATS_USER=admin

# Feature Flags
ENABLE_CANARY_DEPLOYMENT=true
ENABLE_ADVANCED_MONITORING=true
ENABLE_AUTO_SCALING=false
```

## 🏗️ **Arquitectura de Servicios**

### **Servicios Principales**

#### **1. WebLogic Feature Flags**
```yaml
Service: weblogic-feature-flags
Port: 7001 (Admin), 8001 (Managed)
Image: edissonz8809/weblogic-feature-flags:v1.1.0
Features:
  - Dynamic feature flag management
  - A/B testing capabilities
  - Real-time configuration updates
```

#### **2. HAProxy Advanced**
```yaml
Service: haproxy-advanced
Port: 80 (HTTP), 443 (HTTPS), 8404 (Stats)
Image: edissonz8809/haproxy-advanced:v1.1.0
Features:
  - Load balancing
  - SSL termination
  - Health checks
  - Statistics dashboard
```

#### **3. MkDocs Server**
```yaml
Service: mkdocs-server
Port: 8000
Image: edissonz8809/mkdocs-server:v1.1.0
Features:
  - Live documentation
  - Auto-reload on changes
  - Search functionality
```

#### **4. Oracle Express DB**
```yaml
Service: oracle-express-db
Port: 1521
Image: edissonz8809/oracle-express-db:v1.1.0
Features:
  - Persistent data storage
  - Automatic backup
  - Performance monitoring
```

## 🏃‍♂️ **Cómo Usar**

### **Comandos Locales**
```bash
# Validar configuración
docker-compose config

# Iniciar servicios completos
docker-compose up -d

# Usar imágenes de Docker Hub
docker-compose -f docker-compose.dockerhub.yml up -d

# Verificar estado de servicios
docker-compose ps

# Ver logs
docker-compose logs -f [service-name]

# Parar servicios
docker-compose down
```

### **Scripts de Gestión**
```bash
# Inicio rápido
./start-all.sh

# Gestión de servicios
./manage-services.sh status
./manage-services.sh restart weblogic

# Validación completa
./scripts/validation/validate-complete-system.sh

# Deploy de WAR files
./deploy-war.sh your-app.war
```

## 🧪 **Testing y Validación**

### **Integration Tests**
```bash
# Test HAProxy
curl -f http://localhost:80/health

# Test MkDocs
curl -f http://localhost:8000

# Test WebLogic Console
curl -f http://localhost:7001/console

# Test Feature Flags
curl -f http://localhost:80/feature-flags
```

### **Health Checks**
```bash
# Verificar todos los servicios
./scripts/validation/check-urls.sh

# Monitoreo continuo
./scripts/monitoring/start-url-monitoring.sh

# Validación de performance
./scripts/validation/test-performance.sh
```

## 🚩 **Feature Flag Management**

### **Available Features**
```yaml
weblogic_features:
  - canary_deployment: true/false
  - advanced_monitoring: true/false
  - auto_scaling: true/false
  - ssl_termination: true/false
  - database_clustering: true/false

haproxy_features:
  - sticky_sessions: true/false
  - rate_limiting: true/false
  - geo_blocking: true/false
  - compression: true/false

monitoring_features:
  - real_time_alerts: true/false
  - performance_analytics: true/false
  - log_aggregation: true/false
```

### **Feature Management Commands**
```bash
# Listar features disponibles
./scripts/feature-flags/list-features.sh

# Habilitar feature
./scripts/feature-flags/enable-feature.sh canary_deployment

# Deshabilitar feature
./scripts/feature-flags/disable-feature.sh auto_scaling

# Validar configuración de features
./scripts/feature-flags/validate-features.sh
```

## 📊 **Monitoreo y Métricas**

### **Métricas Recopiladas**

#### **WebLogic Metrics**
- 🔄 **Thread Pool Usage**: Uso del pool de threads
- 💾 **Memory Consumption**: Consumo de memoria JVM
- 📊 **Request Throughput**: Throughput de requests
- ⏱️ **Response Time**: Tiempo de respuesta promedio

#### **HAProxy Metrics**
- 🌐 **Connection Count**: Número de conexiones activas
- ⚖️ **Load Distribution**: Distribución de carga
- 🔍 **Health Check Status**: Estado de health checks
- 📈 **Traffic Volume**: Volumen de tráfico

#### **Oracle DB Metrics**
- 💾 **Database Size**: Tamaño de base de datos
- 🔄 **Connection Pool**: Estado del pool de conexiones
- 📊 **Query Performance**: Performance de queries
- 💿 **Disk Usage**: Uso de disco

#### **System Metrics**
- 🖥️ **CPU Usage**: Uso de CPU por servicio
- 💾 **Memory Usage**: Uso de memoria por servicio
- 💿 **Disk I/O**: I/O de disco
- 🌐 **Network Traffic**: Tráfico de red

### **Dashboards Disponibles**
- **HAProxy Stats**: http://localhost:8404/stats
- **WebLogic Console**: http://localhost:7001/console
- **MkDocs Documentation**: http://localhost:8000
- **System Monitoring**: Custom dashboard

## 🔧 **Personalización**

### **Añadir Nuevo Servicio**
```yaml
# docker-compose.yml
new-service:
  build: ./applications/new-service
  ports:
    - "9000:9000"
  depends_on:
    - oracle-db
  environment:
    - SERVICE_ENV=production
```

### **Modificar Configuración HAProxy**
```bash
# Editar configuración
vim haproxy/config/haproxy.cfg

# Validar configuración
docker run --rm -v $(pwd)/haproxy/config:/usr/local/etc/haproxy:ro \
  haproxy:2.4 haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

# Recargar configuración
docker-compose restart haproxy
```

### **Custom WebLogic Domain**
```bash
# Crear nuevo dominio
./scripts/weblogic/create-domain.sh my-custom-domain

# Deploy aplicación
./scripts/weblogic/deploy-app.sh my-app.war my-custom-domain
```

## 🆘 **Troubleshooting**

### **Servicios No Inician**
```bash
# Verificar logs
docker-compose logs weblogic-server

# Verificar recursos
docker stats

# Limpiar y reiniciar
docker-compose down -v
docker system prune -f
docker-compose up -d
```

### **Problemas de Conectividad**
```bash
# Verificar red Docker
docker network ls
docker network inspect docker-for-oracle-weblogic_default

# Test conectividad entre servicios
docker-compose exec weblogic-server ping oracle-db
docker-compose exec haproxy ping weblogic-server
```

### **Performance Issues**
```bash
# Análisis de performance
./scripts/validation/test-performance.sh

# Monitoreo de recursos
./scripts/monitoring/system-monitor.sh

# Optimización automática
./scripts/optimization/auto-optimize.sh
```

### **Oracle Database Issues**
```bash
# Verificar estado de Oracle
docker-compose exec oracle-db sqlplus sys/Oracle123@XE as sysdba

# Backup de base de datos
./scripts/database/backup-db.sh

# Restaurar base de datos
./scripts/database/restore-db.sh backup-file.dmp
```

## 🚀 **Deployment Strategies**

### **Local Development**
```bash
# Desarrollo con hot-reload
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### **Staging Environment**
```bash
# Deploy a staging
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

### **Production Deployment**
```bash
# Deploy a producción con imágenes de Docker Hub
docker-compose -f docker-compose.dockerhub.yml up -d

# Verificar deployment
./scripts/validation/validate-production.sh
```

## 📊 **CI/CD Integration**

### **GitHub Actions Triggers**
- **Push to main**: Full deployment pipeline
- **Push to develop**: Development environment deployment
- **Pull Request**: Integration tests only
- **Manual**: Custom deployment with parameters

### **Deployment Environments**
- **Development**: Auto-deploy from develop branch
- **Staging**: Manual approval required
- **Production**: Manual approval + additional validations

## 📞 **Soporte y Documentación**

### **Documentación Disponible**
- **MkDocs Site**: http://localhost:8000
- **Architecture Docs**: `docs/architecture/`
- **Deployment Guides**: `docs/deployment/`
- **Troubleshooting**: `docs/troubleshooting/`

### **Logs y Debugging**
```bash
# Logs centralizados
./scripts/monitoring/collect-logs.sh

# Debug mode
DEBUG=true docker-compose up -d

# Análisis de logs
./scripts/monitoring/analyze-logs.sh
```

---

**🏗️ La plataforma Oracle WebLogic está lista para producción!** 

Todos los servicios están configurados, monitoreados y listos para escalar según tus necesidades.
