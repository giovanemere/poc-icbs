# 🛠️ Guía de Troubleshooting

Esta guía proporciona soluciones para problemas comunes del sistema WebLogic con HAProxy.

## 📋 Tabla de Contenidos

- [🚨 Problemas de Inicio](#-problemas-de-inicio)
- [🔌 Problemas de Conectividad](#-problemas-de-conectividad)
- [⚖️ Problemas de Load Balancing](#️-problemas-de-load-balancing)
- [🚀 Problemas de Deployment](#-problemas-de-deployment)
- [🎯 Problemas de Canary](#-problemas-de-canary)
- [📊 Problemas de Performance](#-problemas-de-performance)
- [🔧 Herramientas de Diagnóstico](#-herramientas-de-diagnóstico)
- [🆘 Recuperación de Emergencia](#-recuperación-de-emergencia)

## 🚨 Problemas de Inicio

### ❌ Servicios No Inician

#### Síntomas
- `docker ps` no muestra los contenedores
- Error al ejecutar `./start-all.sh`
- Timeouts en el inicio

#### Diagnóstico
```bash
# Verificar logs de docker-compose
./manage-services.sh logs

# Verificar puertos en uso
netstat -tulpn | grep -E ':(7001|7002|8083|8404)'

# Verificar espacio en disco
df -h

# Verificar memoria disponible
free -h
```

#### Soluciones
```bash
# 1. Limpiar recursos Docker
./manage-services.sh clean
docker system prune -f

# 2. Verificar configuración
./scripts/validate-config-consistency.sh

# 3. Reiniciar desde cero
./manage-services.sh stop
./start-all.sh

# 4. Si persiste, verificar logs específicos
./manage-services.sh logs weblogic-a
./manage-services.sh logs weblogic-b
./manage-services.sh logs haproxy
```

### ⏱️ Servicios Tardan en Iniciar

#### Síntomas
- WebLogic tarda más de 5 minutos en iniciar
- HAProxy no puede conectar a backends

#### Diagnóstico
```bash
# Verificar recursos del sistema
docker stats

# Verificar logs de WebLogic
./manage-services.sh logs weblogic-a | grep -i "server started"
```

#### Soluciones
```bash
# 1. Aumentar memoria asignada a Docker
# Editar configuración Docker Desktop o daemon.json

# 2. Verificar configuración de JVM
docker exec weblogic-a ps aux | grep java

# 3. Esperar más tiempo o aumentar timeouts
# Editar .env y aumentar STARTUP_TIMEOUT
```

### 🔒 Problemas de Permisos

#### Síntomas
- Error "Permission denied" al ejecutar scripts
- Contenedores no pueden escribir archivos

#### Diagnóstico
```bash
# Verificar permisos de scripts
ls -la *.sh scripts/*.sh

# Verificar permisos de directorios
ls -la haproxy/config/
```

#### Soluciones
```bash
# Corregir permisos automáticamente
./scripts/validate-config-consistency.sh --fix-permissions

# O manualmente
chmod +x *.sh scripts/*.sh scripts/*/*.sh
chmod 644 .env docker-compose.yml
chmod 644 haproxy/config/haproxy.cfg
```

## 🔌 Problemas de Conectividad

### 🌐 No Se Puede Acceder a las URLs

#### Síntomas
- `curl http://localhost:8083` falla
- Browser muestra "Connection refused"
- HAProxy stats no accesible

#### Diagnóstico
```bash
# Verificar que los servicios estén corriendo
./manage-services.sh status

# Verificar puertos
netstat -tulpn | grep -E ':(8083|8404|7001|7002)'

# Verificar conectividad básica
./scripts/check-urls.sh --quick
```

#### Soluciones
```bash
# 1. Verificar configuración de puertos
./scripts/validate-config-consistency.sh --ports-only

# 2. Reiniciar servicios
./manage-services.sh restart

# 3. Verificar firewall (Linux)
sudo ufw status
sudo iptables -L

# 4. Verificar configuración de red Docker
docker network ls
docker network inspect docker-for-oracle-weblogic_default
```

### 🔗 Problemas de Red Interna

#### Síntomas
- HAProxy no puede conectar a WebLogic
- Health checks fallan
- Error 503 Service Unavailable

#### Diagnóstico
```bash
# Verificar conectividad interna
docker exec haproxy ping weblogic-a
docker exec haproxy ping weblogic-b

# Verificar configuración de red
docker network inspect docker-for-oracle-weblogic_default

# Verificar logs HAProxy
./manage-services.sh logs haproxy | grep -i "connect"
```

#### Soluciones
```bash
# 1. Reiniciar red Docker
./manage-services.sh stop
docker network prune -f
./start-all.sh

# 2. Verificar configuración HAProxy
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep -A 5 -B 5 "server weblogic"

# 3. Verificar DNS interno
docker exec haproxy nslookup weblogic-a
docker exec haproxy nslookup weblogic-b
```

## ⚖️ Problemas de Load Balancing

### 🔄 Tráfico No Se Distribuye

#### Síntomas
- Todo el tráfico va a un solo backend
- Distribución desigual persistente
- Un backend siempre aparece como "DOWN"

#### Diagnóstico
```bash
# Verificar estado de backends
curl -s "http://localhost:8404/stats" | grep -E "weblogic-[ab]"

# Verificar configuración de distribución
./scripts/canary/manage-traffic.sh status

# Verificar health checks
curl -s "http://localhost:8404/stats;csv" | grep -E "weblogic-[ab]" | cut -d',' -f1,18
```

#### Soluciones
```bash
# 1. Resetear distribución de tráfico
./scripts/canary/manage-traffic.sh reset

# 2. Verificar configuración HAProxy
docker exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

# 3. Reiniciar HAProxy
./manage-services.sh restart haproxy

# 4. Verificar que ambos WebLogic estén funcionando
./scripts/check-urls.sh --weblogic-only
```

### 📊 Health Checks Fallan

#### Síntomas
- Backends aparecen como "DOWN" en stats
- HAProxy no envía tráfico a backends saludables
- Logs muestran errores de health check

#### Diagnóstico
```bash
# Verificar configuración de health checks
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep -A 3 -B 3 "check"

# Probar health checks manualmente
curl -I http://localhost:7001/
curl -I http://localhost:7002/

# Verificar logs de health checks
./manage-services.sh logs haproxy | grep -i "health"
```

#### Soluciones
```bash
# 1. Verificar que WebLogic esté respondiendo
docker exec weblogic-a curl -I http://localhost:7001/
docker exec weblogic-b curl -I http://localhost:7001/

# 2. Ajustar configuración de health checks
# Editar haproxy/config/haproxy.cfg si es necesario

# 3. Reiniciar servicios en orden
./manage-services.sh restart weblogic-a
./manage-services.sh restart weblogic-b
./manage-services.sh restart haproxy
```

## 🚀 Problemas de Deployment

### 📦 Deployment Falla

#### Síntomas
- Script de deployment termina con error
- Aplicación no se despliega correctamente
- URLs de aplicación no responden

#### Diagnóstico
```bash
# Verificar logs de deployment
./scripts/deploy/deploy-war.sh /path/to/app.war --verbose

# Verificar logs de WebLogic
./manage-services.sh logs weblogic-a | grep -i deploy
./manage-services.sh logs weblogic-b | grep -i deploy

# Verificar espacio en disco
docker exec weblogic-a df -h
docker exec weblogic-b df -h
```

#### Soluciones
```bash
# 1. Limpiar cachés antes del deployment
./scripts/deploy/deploy-war.sh /path/to/app.war --clean

# 2. Verificar archivo WAR
jar -tf /path/to/app.war | head -10

# 3. Deployment paso a paso
./scripts/deploy/deploy-war.sh /path/to/app.war --target weblogic-a --verbose
./scripts/deploy/deploy-war.sh /path/to/app.war --target weblogic-b --verbose

# 4. Verificar URLs después del deployment
./scripts/check-urls.sh
```

### 🔄 Aplicación No Responde Después del Deployment

#### Síntomas
- Deployment reporta éxito pero aplicación no responde
- Error 404 o 500 en URLs de aplicación
- Aplicación aparece como deployed pero no funciona

#### Diagnóstico
```bash
# Verificar estado de la aplicación en WebLogic
# (Requiere acceso a consola de administración)

# Verificar logs de aplicación
./manage-services.sh logs weblogic-a | grep -i "application\|deploy"

# Verificar configuración de contexto
curl -I http://localhost:8083/myapp/
```

#### Soluciones
```bash
# 1. Verificar contexto de deployment
./scripts/deploy/deploy-war.sh --verify-only

# 2. Re-deployar con contexto específico
./scripts/deploy/deploy-war.sh /path/to/app.war --context myapp

# 3. Verificar configuración de aplicación
# Revisar web.xml y otros archivos de configuración

# 4. Reiniciar WebLogic si es necesario
./manage-services.sh restart weblogic-a
./manage-services.sh restart weblogic-b
```

## 🎯 Problemas de Canary

### 🚦 Canary No Recibe Tráfico

#### Síntomas
- Configuración canary no tiene efecto
- Todo el tráfico sigue yendo al backend principal
- Stats muestran 0% de tráfico en canary

#### Diagnóstico
```bash
# Verificar configuración actual
./scripts/canary/manage-traffic.sh status

# Verificar configuración HAProxy
curl -s "http://localhost:8404/stats;csv" | grep -E "weblogic-[ab]"

# Verificar logs HAProxy
./manage-services.sh logs haproxy | tail -20
```

#### Soluciones
```bash
# 1. Resetear y reconfigurar
./scripts/canary/manage-traffic.sh reset
./scripts/canary/manage-traffic.sh canary 20

# 2. Verificar que HAProxy recargó la configuración
docker exec haproxy kill -USR2 1

# 3. Reiniciar HAProxy si es necesario
./manage-services.sh restart haproxy

# 4. Verificar configuración manualmente
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep -A 10 -B 10 weight
```

### 📊 Métricas de Canary Inconsistentes

#### Síntomas
- Porcentajes no coinciden con configuración
- Métricas muestran valores extraños
- Tests de canary fallan inesperadamente

#### Diagnóstico
```bash
# Verificar métricas detalladas
./scripts/canary/test-canary.sh --detailed

# Verificar stats HAProxy directamente
curl -s "http://localhost:8404/stats;csv"

# Verificar configuración de pesos
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep weight
```

#### Soluciones
```bash
# 1. Limpiar y reconfigurar
./scripts/canary/manage-traffic.sh reset
sleep 10
./scripts/canary/manage-traffic.sh canary 25

# 2. Verificar con múltiples tests
./scripts/canary/test-canary.sh 100

# 3. Monitorear en tiempo real
watch -n 5 './scripts/canary/manage-traffic.sh status'
```

## 📊 Problemas de Performance

### 🐌 Respuesta Lenta

#### Síntomas
- Tiempos de respuesta altos (>3 segundos)
- Timeouts frecuentes
- Performance degradada comparada con acceso directo

#### Diagnóstico
```bash
# Tests de performance
./scripts/test-performance.sh --response-time

# Verificar recursos del sistema
docker stats

# Verificar métricas HAProxy
curl -s "http://localhost:8404/stats" | grep -E "weblogic-[ab]"

# Verificar logs de performance
./manage-services.sh logs | grep -i "slow\|timeout"
```

#### Soluciones
```bash
# 1. Verificar configuración de timeouts
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep timeout

# 2. Aumentar recursos Docker
# Editar configuración Docker para más CPU/memoria

# 3. Optimizar configuración HAProxy
# Revisar y ajustar haproxy/config/haproxy.cfg

# 4. Verificar aplicaciones WebLogic
# Revisar logs de aplicación para problemas de performance
```

### 📈 Alto Uso de Recursos

#### Síntomas
- CPU al 100% en contenedores
- Memoria agotada
- Sistema lento en general

#### Diagnóstico
```bash
# Monitorear recursos en tiempo real
docker stats

# Verificar procesos dentro de contenedores
docker exec weblogic-a top
docker exec haproxy top

# Verificar logs de memoria
./manage-services.sh logs | grep -i "memory\|oom"
```

#### Soluciones
```bash
# 1. Aumentar límites de memoria en docker-compose.yml
# Editar sección deploy.resources.limits

# 2. Optimizar configuración JVM WebLogic
# Ajustar parámetros de memoria en variables de entorno

# 3. Limpiar recursos no utilizados
./manage-services.sh clean
docker system prune -f

# 4. Reiniciar servicios para liberar memoria
./manage-services.sh restart
```

## 🔧 Herramientas de Diagnóstico

### 🔍 Scripts de Validación

```bash
# Validación completa del sistema
./scripts/validate-complete-system.sh

# Validación rápida
./scripts/validate-complete-system.sh --quick

# Validación de configuración
./scripts/validate-config-consistency.sh

# Tests de integración
./scripts/test-integration.sh

# Tests de performance
./scripts/test-performance.sh --light
```

### 📊 Comandos de Monitoreo

```bash
# Estado de servicios
./manage-services.sh status

# Logs en tiempo real
./manage-services.sh logs --follow

# Verificación de URLs
./scripts/check-urls.sh --timing

# Métricas HAProxy
curl -s "http://localhost:8404/stats;csv"

# Estado de canary
./scripts/canary/manage-traffic.sh status
```

### 🔧 Comandos Docker Útiles

```bash
# Información de contenedores
docker ps -a
docker inspect weblogic-a
docker inspect haproxy

# Logs específicos
docker logs weblogic-a --tail 50
docker logs haproxy --tail 50

# Ejecutar comandos dentro de contenedores
docker exec -it weblogic-a bash
docker exec -it haproxy sh

# Información de red
docker network ls
docker network inspect docker-for-oracle-weblogic_default

# Información de volúmenes
docker volume ls
docker volume inspect docker-for-oracle-weblogic_weblogic-data
```

## 🆘 Recuperación de Emergencia

### 🚨 Procedimiento de Emergencia

#### Paso 1: Evaluación Rápida
```bash
# Verificar qué servicios están funcionando
docker ps

# Verificar conectividad básica
curl -I http://localhost:8083/
curl -I http://localhost:8404/stats
```

#### Paso 2: Rollback Inmediato
```bash
# Si hay canary activo, hacer rollback
./scripts/canary/manage-traffic.sh rollback

# Verificar que el rollback funcionó
./scripts/check-urls.sh --quick
```

#### Paso 3: Reinicio Completo
```bash
# Parar todos los servicios
./manage-services.sh stop

# Limpiar recursos
./manage-services.sh clean

# Reiniciar desde cero
./start-all.sh

# Verificar recuperación
./scripts/validate-complete-system.sh --quick
```

#### Paso 4: Validación Post-Recuperación
```bash
# Tests completos
./scripts/run-all-tests.sh --quick

# Verificar funcionalidad crítica
./scripts/check-urls.sh
./scripts/test-integration.sh --basic
```

### 🔄 Backup y Restauración

#### Crear Backup
```bash
#!/bin/bash
# backup-system.sh

BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup de configuración
cp .env "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"
cp -r haproxy/config "$BACKUP_DIR/"

# Backup de datos WebLogic (si hay volúmenes persistentes)
docker run --rm -v docker-for-oracle-weblogic_weblogic-data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/weblogic-data.tar.gz -C /data .

echo "Backup creado en $BACKUP_DIR"
```

#### Restaurar Backup
```bash
#!/bin/bash
# restore-system.sh

BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "Uso: $0 <backup-directory>"
    exit 1
fi

# Parar servicios
./manage-services.sh stop

# Restaurar configuración
cp "$BACKUP_DIR/.env" .
cp "$BACKUP_DIR/docker-compose.yml" .
cp -r "$BACKUP_DIR/config" haproxy/

# Restaurar datos (si existe)
if [ -f "$BACKUP_DIR/weblogic-data.tar.gz" ]; then
    docker run --rm -v docker-for-oracle-weblogic_weblogic-data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/weblogic-data.tar.gz -C /data
fi

# Reiniciar servicios
./start-all.sh

echo "Sistema restaurado desde $BACKUP_DIR"
```

## 📞 Obtener Ayuda Adicional

### 📚 Documentación
- [README Principal](../README.md)
- [Guía de Deployment](DEPLOYMENT_GUIDE.md)
- [Guía de Canary](CANARY_GUIDE.md)
- [Plan de Actualización](../UPGRADE_PLAN.md)

### 🔧 Comandos de Ayuda
```bash
# Ayuda de scripts principales
./manage-services.sh --help
./scripts/deploy/deploy-war.sh --help
./scripts/canary/manage-traffic.sh --help
./scripts/validate-complete-system.sh --help
```

### 📊 Información del Sistema
```bash
# Información completa del sistema
./scripts/validate-complete-system.sh --verbose

# Información de configuración
./scripts/validate-config-consistency.sh

# Estado detallado
./manage-services.sh status --detailed
```

---

**Última actualización**: 2025-01-31

**Nota**: Si ninguna de estas soluciones resuelve tu problema, considera abrir un issue con:
- Descripción detallada del problema
- Logs relevantes
- Pasos para reproducir el problema
- Información del sistema (OS, Docker version, etc.)
