# 📦 Guía de Despliegue

## Introducción

Esta guía te ayudará a desplegar el sistema Docker Oracle WebLogic de manera exitosa, desde la configuración inicial hasta el despliegue en producción.

## Prerrequisitos

### Software Requerido
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- Bash shell
- 8GB RAM mínimo
- 20GB espacio en disco

### Puertos Requeridos
Asegúrate de que estos puertos estén disponibles:
- `7001-7002`: WebLogic servers
- `1521`: Oracle Database
- `8000`: MkDocs
- `8081-8087`: HAProxy interfaces
- `8404`: HAProxy Stats
- `8444`: HAProxy HTTPS

## Despliegue Rápido

### 1. Clonar el Repositorio
```bash
git clone <repository-url>
cd docker-for-oracle-weblogic
```

### 2. Configurar Variables de Entorno
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar configuración
nano .env
```

### 3. Iniciar Servicios
```bash
# Opción 1: Inicio completo
./scripts/start-all.sh

# Opción 2: Inicio con auto-actualización
./scripts/start-with-auto-update.sh

# Opción 3: Inicio manual por servicios
./scripts/core/docker-compose-wrapper.sh up -d
```

## Despliegue Detallado

### Paso 1: Preparación del Entorno

#### Verificar Dependencias
```bash
./scripts/validation/check-dependencies.sh
```

#### Configurar Variables
```bash
# Variables principales en .env
WEBLOGIC_ADMIN_PASSWORD=welcome123
ORACLE_PASSWORD=oracle123
HAPROXY_ADMIN_PASSWORD=admin123

# Variables de red
WEBLOGIC_NETWORK=weblogic-haproxy_weblogic-network
```

### Paso 2: Construcción de Imágenes

#### Construir Todas las Imágenes
```bash
./scripts/build/build.sh
```

#### Construir Imágenes Específicas
```bash
# Solo WebLogic
./scripts/core/docker-compose-wrapper.sh build weblogic-a weblogic-b

# Solo HAProxy
./scripts/core/docker-compose-wrapper.sh build haproxy

# Solo MkDocs
./scripts/core/docker-compose-wrapper.sh build mkdocs-server
```

### Paso 3: Despliegue de Servicios

#### Orden de Inicio Recomendado
1. **Oracle Database**
   ```bash
   ./scripts/core/docker-compose-wrapper.sh up -d oracle-db
   ```

2. **WebLogic Servers**
   ```bash
   ./scripts/core/docker-compose-wrapper.sh up -d weblogic-a weblogic-b
   ```

3. **MkDocs Documentation**
   ```bash
   ./scripts/core/docker-compose-wrapper.sh up -d mkdocs-server
   ```

4. **HAProxy Load Balancer**
   ```bash
   ./scripts/core/docker-compose-wrapper.sh up -d haproxy
   ```

### Paso 4: Verificación del Despliegue

#### Verificar Estado de Contenedores
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

#### Verificar Conectividad
```bash
./scripts/validation/check-urls.sh
```

#### Verificar Health Checks
```bash
# HAProxy health
curl http://localhost:8083/health

# WebLogic health
curl http://localhost:7001/console

# Oracle health
docker exec oracle-db sqlplus sys/oracle123@localhost:1521/XE as sysdba
```

## Despliegues Canary

### Configuración Canary
```bash
# Configurar porcentajes de tráfico
./scripts/canary/setup-canary.sh

# Controlar tráfico
./scripts/canary/manage-traffic.sh --weblogic-a 70 --weblogic-b 30
```

### Monitoreo Canary
```bash
# Simular tráfico
./scripts/canary/simulate-traffic.sh

# Verificar métricas
curl http://localhost:8404/stats
```

## Configuración Avanzada

### HAProxy Personalizado
```bash
# Editar configuración
nano haproxy/config/haproxy.cfg

# Aplicar cambios
./scripts/auto-update-haproxy.sh
```

### WebLogic Personalizado
```bash
# Configurar dominios
nano weblogic/config/domain-config.py

# Reconstruir
./scripts/core/docker-compose-wrapper.sh build --no-cache weblogic-a
```

## Troubleshooting

### Problemas Comunes

#### Contenedores no Inician
```bash
# Verificar logs
docker logs <container-name>

# Verificar recursos
docker system df
docker system prune
```

#### Problemas de Red
```bash
# Verificar redes
docker network ls
docker network inspect weblogic-haproxy_weblogic-network

# Recrear red
docker network rm weblogic-haproxy_weblogic-network
./scripts/start-all.sh
```

#### Problemas de Puertos
```bash
# Verificar puertos en uso
netstat -tlnp | grep -E ":(7001|7002|1521|8000|808[0-9])"

# Liberar puertos
./scripts/stop-all-services.sh
```

### Logs y Diagnóstico
```bash
# Logs de todos los servicios
./scripts/utilities/diagnose-and-fix.sh

# Logs específicos
docker logs haproxy --tail 50
docker logs weblogic-a --tail 50
docker logs oracle-db --tail 50
```

## Mantenimiento

### Actualizaciones
```bash
# Actualizar configuración HAProxy
./scripts/auto-update-haproxy.sh

# Actualizar documentación
./scripts/docs/build-docs.sh
```

### Backup y Restore
```bash
# Backup de configuración
tar -czf backup-$(date +%Y%m%d).tar.gz config/ haproxy/ weblogic/

# Backup de base de datos
docker exec oracle-db exp system/oracle123 file=backup.dmp full=y
```

### Limpieza
```bash
# Limpieza completa
./scripts/maintenance/cleanup-all.sh

# Limpieza selectiva
./scripts/maintenance/master-cleanup.sh
```

## Despliegue en Producción

### Consideraciones de Seguridad
- Cambiar contraseñas por defecto
- Configurar SSL/TLS
- Implementar firewall
- Configurar logs centralizados

### Monitoreo en Producción
- Configurar alertas
- Implementar métricas personalizadas
- Configurar backup automático
- Implementar health checks externos

### Escalabilidad
- Configurar múltiples instancias
- Implementar auto-scaling
- Configurar load balancing externo
- Optimizar recursos

---

## Enlaces Relacionados

- [Arquitectura del Sistema](arquitectura.md)
- [Guía Canary Detallada](deployment/canary-guide.md)
- [Configuración HAProxy](guides/haproxy-setup.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Scripts de Automatización](scripts/index.md)
