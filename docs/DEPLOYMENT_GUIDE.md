# 📋 Guía Completa de Despliegue

## Introducción

Esta guía detallada te llevará paso a paso a través del proceso completo de despliegue del sistema Docker Oracle WebLogic, desde la preparación inicial hasta la puesta en producción.

## Tabla de Contenidos

1. [Preparación del Entorno](#preparación-del-entorno)
2. [Configuración Inicial](#configuración-inicial)
3. [Despliegue por Fases](#despliegue-por-fases)
4. [Verificación y Testing](#verificación-y-testing)
5. [Configuración Avanzada](#configuración-avanzada)
6. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)
7. [Troubleshooting](#troubleshooting)

## Preparación del Entorno

### Requisitos del Sistema

#### Hardware Mínimo
- **CPU**: 4 cores
- **RAM**: 8GB (16GB recomendado)
- **Disco**: 50GB libres
- **Red**: Conexión estable a internet

#### Software Requerido
```bash
# Verificar versiones
docker --version          # >= 20.10
docker-compose --version  # >= 2.0
git --version            # >= 2.0
bash --version           # >= 4.0
```

#### Puertos Requeridos
Verificar que estos puertos estén libres:
```bash
# Verificar puertos
netstat -tlnp | grep -E ":(1521|7001|7002|8000|808[0-9]|8444)"

# Si hay conflictos, detener servicios o cambiar puertos en .env
```

### Preparación del Sistema

#### 1. Actualizar Sistema
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### 2. Configurar Docker
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Reiniciar sesión o ejecutar
newgrp docker

# Verificar acceso
docker run hello-world
```

#### 3. Configurar Límites del Sistema
```bash
# Aumentar límites de archivos abiertos
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Configurar kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Configuración Inicial

### 1. Clonar Repositorio
```bash
# Clonar proyecto
git clone <repository-url>
cd docker-for-oracle-weblogic

# Verificar estructura
ls -la
```

### 2. Configurar Variables de Entorno

#### Crear archivo .env
```bash
# Copiar template
cp .env.example .env

# Editar configuración
nano .env
```

#### Variables Principales
```bash
# Configuración de WebLogic
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome123
WEBLOGIC_DOMAIN_NAME=base_domain

# Configuración de Oracle
ORACLE_SID=XE
ORACLE_PASSWORD=oracle123
ORACLE_CHARACTERSET=AL32UTF8

# Configuración de HAProxy
HAPROXY_ADMIN_USER=admin
HAPROXY_ADMIN_PASSWORD=admin123

# Puertos (modificar si hay conflictos)
WEBLOGIC_PORT_A=7001
WEBLOGIC_PORT_B=7002
ORACLE_PORT=1521
MKDOCS_PORT=8000
HAPROXY_HTTP_PORT=8083
HAPROXY_ADMIN_PORT=8082
HAPROXY_STATS_PORT=8404
HAPROXY_HTTPS_PORT=8444

# Red Docker
WEBLOGIC_NETWORK=weblogic-haproxy_weblogic-network
```

### 3. Verificar Dependencias
```bash
# Ejecutar verificación automática
./scripts/validation/check-dependencies.sh

# Verificar manualmente
docker info
docker-compose version
```

## Despliegue por Fases

### Fase 1: Infraestructura Base

#### 1.1 Crear Red Docker
```bash
# La red se crea automáticamente, pero verificar
docker network ls | grep weblogic
```

#### 1.2 Construir Imágenes Base
```bash
# Construir todas las imágenes
./scripts/build/build.sh

# O construir individualmente
./scripts/core/docker-compose-wrapper.sh build oracle-db
./scripts/core/docker-compose-wrapper.sh build weblogic-a
./scripts/core/docker-compose-wrapper.sh build weblogic-b
./scripts/core/docker-compose-wrapper.sh build haproxy
./scripts/core/docker-compose-wrapper.sh build mkdocs-server
```

### Fase 2: Base de Datos

#### 2.1 Iniciar Oracle Database
```bash
# Iniciar Oracle
./scripts/core/docker-compose-wrapper.sh up -d oracle-db

# Verificar logs (puede tomar varios minutos)
docker logs -f oracle-db
```

#### 2.2 Verificar Oracle
```bash
# Esperar hasta que aparezca "DATABASE IS READY TO USE!"
# Luego verificar conectividad
docker exec oracle-db sqlplus sys/oracle123@localhost:1521/XE as sysdba <<EOF
SELECT 'Oracle is ready!' FROM dual;
EXIT;
EOF
```

#### 2.3 Configurar Esquemas (Opcional)
```bash
# Crear esquemas de aplicación si es necesario
docker exec oracle-db sqlplus sys/oracle123@localhost:1521/XE as sysdba <<EOF
CREATE USER appuser IDENTIFIED BY apppass;
GRANT CONNECT, RESOURCE TO appuser;
EXIT;
EOF
```

### Fase 3: Servidores WebLogic

#### 3.1 Iniciar WebLogic A
```bash
# Iniciar primer servidor
./scripts/core/docker-compose-wrapper.sh up -d weblogic-a

# Verificar logs
docker logs -f weblogic-a
```

#### 3.2 Verificar WebLogic A
```bash
# Esperar hasta que aparezca "Server started in RUNNING mode"
# Verificar console
curl -I http://localhost:7001/console

# Debería devolver HTTP 200 o 302
```

#### 3.3 Iniciar WebLogic B
```bash
# Iniciar segundo servidor
./scripts/core/docker-compose-wrapper.sh up -d weblogic-b

# Verificar
curl -I http://localhost:7002/console
```

### Fase 4: Documentación

#### 4.1 Iniciar MkDocs
```bash
# Iniciar servidor de documentación
./scripts/core/docker-compose-wrapper.sh up -d mkdocs-server

# Verificar
curl -I http://localhost:8000
```

#### 4.2 Verificar Documentación
```bash
# Verificar que la documentación se genera correctamente
docker logs mkdocs-server --tail 10

# Debería mostrar "Serving on http://0.0.0.0:8000/"
```

### Fase 5: Load Balancer

#### 5.1 Iniciar HAProxy
```bash
# Iniciar HAProxy
./scripts/core/docker-compose-wrapper.sh up -d haproxy

# Verificar logs
docker logs haproxy --tail 20
```

#### 5.2 Configurar HAProxy
```bash
# Ejecutar auto-configuración
./scripts/auto-update-haproxy.sh

# Verificar configuración
curl -I http://localhost:8083
```

## Verificación y Testing

### Verificación Básica

#### 1. Estado de Contenedores
```bash
# Verificar que todos los contenedores estén UP
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Todos deberían mostrar "Up X minutes/hours"
```

#### 2. Conectividad de Servicios
```bash
# Ejecutar verificación automática
./scripts/validation/check-urls.sh

# Verificar manualmente
curl http://localhost:8083          # HAProxy LB
curl http://localhost:8082          # HAProxy Admin
curl http://localhost:8404/stats    # HAProxy Stats
curl http://localhost:8083/docs     # Documentación
curl http://localhost:7001/console  # WebLogic A
curl http://localhost:7002/console  # WebLogic B
```

#### 3. Verificación de Red
```bash
# Verificar comunicación interna
docker exec haproxy nc -zv weblogic-a 7001
docker exec haproxy nc -zv weblogic-b 7002
docker exec haproxy nc -zv mkdocs-server 8000
docker exec weblogic-a nc -zv oracle-db 1521
```

### Testing Avanzado

#### 1. Test de Load Balancing
```bash
# Simular tráfico
./scripts/canary/simulate-traffic.sh

# Verificar distribución en Stats UI
curl -u admin:admin123 "http://localhost:8404/stats;csv" | grep weblogic
```

#### 2. Test de Failover
```bash
# Detener WebLogic A
./scripts/core/docker-compose-wrapper.sh stop weblogic-a

# Verificar que el tráfico va a WebLogic B
curl http://localhost:8083

# Reiniciar WebLogic A
./scripts/core/docker-compose-wrapper.sh start weblogic-a
```

#### 3. Test de Performance
```bash
# Ejecutar test de performance
./scripts/testing/test-performance.sh

# Verificar métricas
curl -u admin:admin123 "http://localhost:8404/stats;csv"
```

## Configuración Avanzada

### Despliegues Canary

#### 1. Configurar Canary
```bash
# Configurar distribución de tráfico
./scripts/canary/setup-canary.sh

# Configurar pesos (ejemplo: 70% A, 30% B)
./scripts/canary/manage-traffic.sh --weblogic-a 70 --weblogic-b 30
```

#### 2. Monitorear Canary
```bash
# Verificar distribución
curl -u admin:admin123 "http://localhost:8404/stats;csv" | grep -E "(weblogic-a|weblogic-b)"

# Simular tráfico para testing
./scripts/canary/simulate-traffic.sh
```

### SSL/HTTPS Configuration

#### 1. Generar Certificados
```bash
# Crear directorio para certificados
mkdir -p haproxy/certs

# Generar certificado self-signed (para testing)
openssl req -x509 -newkey rsa:2048 -keyout haproxy/certs/server.key \
  -out haproxy/certs/server.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Combinar para HAProxy
cat haproxy/certs/server.crt haproxy/certs/server.key > haproxy/certs/server.pem
```

#### 2. Configurar HTTPS
```bash
# Editar haproxy.cfg para habilitar SSL
# Reiniciar HAProxy
./scripts/auto-update-haproxy.sh

# Verificar HTTPS
curl -k https://localhost:8444
```

### Configuración de Aplicaciones

#### 1. Desplegar Aplicaciones WAR
```bash
# Copiar WAR files
cp your-app.war weblogic/deployments/

# Desplegar
./scripts/deploy/deploy-war.sh your-app.war

# Verificar despliegue
curl http://localhost:8083/your-app
```

#### 2. Configurar DataSources
```bash
# Editar configuración de WebLogic
# Los datasources se configuran automáticamente para Oracle
# Verificar en WebLogic Console: http://localhost:7001/console
```

## Monitoreo y Mantenimiento

### Configurar Monitoreo

#### 1. Logs Centralizados
```bash
# Configurar log rotation
sudo nano /etc/logrotate.d/docker

# Contenido:
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
```

#### 2. Health Checks Automáticos
```bash
# Configurar cron job para health checks
crontab -e

# Agregar:
*/5 * * * * /path/to/docker-for-oracle-weblogic/scripts/validation/check-urls.sh > /dev/null 2>&1
```

#### 3. Alertas por Email (Opcional)
```bash
# Instalar mailutils
sudo apt install mailutils

# Configurar script de alertas
./scripts/monitoring/setup-complete-monitoring.sh
```

### Mantenimiento Rutinario

#### 1. Backup Automático
```bash
# Crear script de backup
cat > backup-daily.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
tar -czf /backups/weblogic-backup-$DATE.tar.gz \
  config/ haproxy/ weblogic/ docs/ .env
docker exec oracle-db exp system/oracle123 file=/tmp/backup-$DATE.dmp full=y
docker cp oracle-db:/tmp/backup-$DATE.dmp /backups/
EOF

chmod +x backup-daily.sh

# Configurar cron
crontab -e
# 0 2 * * * /path/to/backup-daily.sh
```

#### 2. Limpieza Automática
```bash
# Limpiar logs antiguos y recursos no utilizados
cat > cleanup-weekly.sh << 'EOF'
#!/bin/bash
docker system prune -f
docker volume prune -f
find /var/log -name "*.log" -mtime +7 -delete
EOF

chmod +x cleanup-weekly.sh

# Configurar cron semanal
# 0 3 * * 0 /path/to/cleanup-weekly.sh
```

#### 3. Actualizaciones
```bash
# Script de actualización
./scripts/maintenance/auto-maintain.sh

# Verificar después de actualizaciones
./scripts/validation/validate-complete-system.sh
```

## Troubleshooting

### Problemas Comunes Durante el Despliegue

#### 1. Oracle No Inicia
```bash
# Verificar espacio en disco
df -h

# Verificar memoria
free -h

# Verificar logs
docker logs oracle-db --tail 50

# Solución: Aumentar memoria o limpiar espacio
```

#### 2. WebLogic Timeout
```bash
# WebLogic puede tomar hasta 10 minutos en iniciar
# Verificar progreso en logs
docker logs weblogic-a --tail 20

# Si persiste, verificar memoria y CPU
docker stats
```

#### 3. HAProxy No Encuentra Backends
```bash
# Verificar que WebLogic esté completamente iniciado
curl http://localhost:7001/console
curl http://localhost:7002/console

# Actualizar configuración HAProxy
./scripts/auto-update-haproxy.sh
```

### Scripts de Diagnóstico
```bash
# Diagnóstico completo
./scripts/utilities/diagnose-and-fix.sh

# Validación del sistema
./scripts/validation/validate-complete-system.sh

# Debug específico
./scripts/validation/debug-haproxy.sh
```

## Despliegue en Producción

### Consideraciones de Seguridad

#### 1. Cambiar Contraseñas por Defecto
```bash
# Editar .env con contraseñas seguras
WEBLOGIC_ADMIN_PASSWORD=<strong-password>
ORACLE_PASSWORD=<strong-password>
HAPROXY_ADMIN_PASSWORD=<strong-password>
```

#### 2. Configurar Firewall
```bash
# Permitir solo puertos necesarios
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8083/tcp
sudo ufw deny 7001/tcp  # Solo acceso interno
sudo ufw deny 7002/tcp  # Solo acceso interno
sudo ufw enable
```

#### 3. SSL/TLS en Producción
```bash
# Usar certificados válidos (Let's Encrypt, etc.)
# Configurar HTTPS redirect
# Deshabilitar protocolos inseguros
```

### Escalabilidad

#### 1. Múltiples Instancias WebLogic
```bash
# Agregar más instancias en docker-compose.yml
# Configurar HAProxy para balancear entre todas
```

#### 2. Base de Datos Externa
```bash
# Configurar conexión a Oracle RAC o RDS
# Actualizar variables de conexión en .env
```

#### 3. Load Balancer Externo
```bash
# Configurar nginx o AWS ALB delante de HAProxy
# Configurar SSL termination externa
```

## Checklist de Despliegue

### Pre-Despliegue
- [ ] Verificar requisitos del sistema
- [ ] Configurar variables de entorno
- [ ] Verificar puertos disponibles
- [ ] Crear backups si es actualización

### Durante el Despliegue
- [ ] Construir imágenes exitosamente
- [ ] Iniciar Oracle Database
- [ ] Iniciar WebLogic servers
- [ ] Iniciar MkDocs
- [ ] Iniciar HAProxy
- [ ] Configurar HAProxy automáticamente

### Post-Despliegue
- [ ] Verificar estado de todos los contenedores
- [ ] Probar conectividad de todos los servicios
- [ ] Verificar load balancing
- [ ] Probar failover
- [ ] Configurar monitoreo
- [ ] Documentar configuración específica

---

## Enlaces Relacionados

- [Arquitectura del Sistema](arquitectura.md)
- [Configuración HAProxy](haproxy.md)
- [Guía de Troubleshooting](TROUBLESHOOTING.md)
- [Scripts de Automatización](scripts/index.md)
- [Soporte Técnico](support.md)
