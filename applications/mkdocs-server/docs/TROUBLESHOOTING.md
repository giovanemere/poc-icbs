# 🆘 Guía de Troubleshooting

## Introducción

Esta guía proporciona soluciones para los problemas más comunes que puedes encontrar al trabajar con el sistema Docker Oracle WebLogic.

## Problemas de Contenedores

### Contenedores No Inician

#### Síntomas
- `docker ps` no muestra el contenedor
- Errores al ejecutar `docker-compose up`
- Contenedores en estado "Exited"

#### Diagnóstico
```bash
# Verificar logs del contenedor
docker logs <container-name>

# Verificar estado detallado
docker inspect <container-name>

# Verificar recursos del sistema
docker system df
free -h
df -h
```

#### Soluciones
```bash
# Limpiar recursos
docker system prune -f

# Reiniciar Docker daemon
sudo systemctl restart docker

# Reconstruir imágenes
./scripts/core/docker-compose-wrapper.sh build --no-cache
```

### Contenedores Se Detienen Inesperadamente

#### Causas Comunes
- Falta de memoria
- Errores de configuración
- Dependencias no disponibles

#### Solución
```bash
# Verificar recursos
docker stats

# Aumentar límites de memoria
# Editar docker-compose.yml:
# mem_limit: 2g
# memswap_limit: 2g

# Verificar dependencias
./scripts/validation/check-dependencies.sh
```

## Problemas de Red

### Contenedores No Se Comunican

#### Síntomas
- Errores de conexión entre servicios
- DNS resolution failures
- Timeouts de conexión

#### Diagnóstico
```bash
# Verificar redes Docker
docker network ls
docker network inspect weblogic-haproxy_weblogic-network

# Test de conectividad
docker exec <container> ping <target-container>
docker exec <container> nc -zv <target-container> <port>
```

#### Soluciones
```bash
# Recrear red
docker network rm weblogic-haproxy_weblogic-network
./scripts/start-all.sh

# Verificar configuración de red en docker-compose.yml
# Asegurar que todos los servicios estén en la misma red
```

### Problemas de Puertos

#### Síntomas
- "Port already in use"
- Servicios no accesibles desde host
- Conflictos de puertos

#### Diagnóstico
```bash
# Verificar puertos en uso
netstat -tlnp | grep -E ":(7001|7002|1521|8000|808[0-9])"
lsof -i :8080

# Verificar mapeo de puertos
docker port <container-name>
```

#### Soluciones
```bash
# Liberar puertos
./scripts/stop-all-services.sh

# Cambiar puertos en .env
# Editar variables WEBLOGIC_PORT_A, WEBLOGIC_PORT_B, etc.

# Verificar firewall
sudo ufw status
sudo iptables -L
```

## Problemas de WebLogic

### WebLogic No Inicia

#### Síntomas
- Console no accesible en puerto 7001/7002
- Errores en logs de WebLogic
- Timeout al acceder a aplicaciones

#### Diagnóstico
```bash
# Verificar logs de WebLogic
docker logs weblogic-a --tail 50
docker logs weblogic-b --tail 50

# Verificar configuración de dominio
docker exec weblogic-a ls -la /u01/oracle/user_projects/domains/
```

#### Soluciones
```bash
# Reiniciar WebLogic
./scripts/core/docker-compose-wrapper.sh restart weblogic-a weblogic-b

# Limpiar cache de WebLogic
./scripts/canary/clear-weblogic-cache.sh

# Reconstruir dominio
./scripts/core/docker-compose-wrapper.sh build --no-cache weblogic-a
```

### Problemas de Despliegue de Aplicaciones

#### Síntomas
- WAR files no se despliegan
- Aplicaciones en estado "Failed"
- Errores 404 en aplicaciones

#### Diagnóstico
```bash
# Verificar estado de aplicaciones
curl http://localhost:7001/console

# Verificar archivos WAR
docker exec weblogic-a ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/

# Verificar logs de despliegue
docker exec weblogic-a tail -f /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs/AdminServer.log
```

#### Soluciones
```bash
# Redesplegar aplicaciones
./scripts/deploy/deploy-war.sh

# Limpiar y redesplegar
./scripts/deploy/clean-redeploy.sh

# Verificar permisos de archivos
docker exec weblogic-a chown -R oracle:oracle /u01/oracle/user_projects/
```

## Problemas de Oracle Database

### Base de Datos No Inicia

#### Síntomas
- Puerto 1521 no responde
- Errores de conexión ORA-
- Contenedor oracle-db en estado "Exited"

#### Diagnóstico
```bash
# Verificar logs de Oracle
docker logs oracle-db --tail 50

# Verificar espacio en disco
df -h

# Verificar archivos de base de datos
docker exec oracle-db ls -la /opt/oracle/oradata/
```

#### Soluciones
```bash
# Reiniciar Oracle
./scripts/core/docker-compose-wrapper.sh restart oracle-db

# Verificar configuración
docker exec oracle-db sqlplus sys/oracle123@localhost:1521/XE as sysdba

# Recrear base de datos (CUIDADO: Borra datos)
docker volume rm $(docker volume ls -q | grep oracle)
./scripts/core/docker-compose-wrapper.sh up -d oracle-db
```

### Problemas de Conectividad a Oracle

#### Síntomas
- WebLogic no puede conectar a Oracle
- Errores de datasource
- Timeouts de conexión

#### Diagnóstico
```bash
# Test de conectividad
docker exec weblogic-a nc -zv oracle-db 1521

# Verificar configuración de datasource
docker exec weblogic-a cat /u01/oracle/user_projects/domains/base_domain/config/config.xml | grep -A 10 -B 10 datasource
```

#### Soluciones
```bash
# Verificar red
docker network inspect weblogic-haproxy_weblogic-network

# Reiniciar servicios en orden
./scripts/core/docker-compose-wrapper.sh restart oracle-db
sleep 30
./scripts/core/docker-compose-wrapper.sh restart weblogic-a weblogic-b
```

## Problemas de HAProxy

### HAProxy No Balancea Correctamente

#### Síntomas
- Todo el tráfico va a un servidor
- Servidores marcados como "DOWN"
- Errores 503 Service Unavailable

#### Diagnóstico
```bash
# Verificar estado en Stats UI
curl -u admin:admin123 http://localhost:8404/stats

# Verificar configuración
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg

# Verificar logs
docker logs haproxy --tail 50
```

#### Soluciones
```bash
# Actualizar configuración HAProxy
./scripts/auto-update-haproxy.sh

# Verificar health checks
curl http://localhost:7001/console
curl http://localhost:7002/console

# Reiniciar HAProxy
./scripts/core/docker-compose-wrapper.sh restart haproxy
```

### Interfaces de Admin No Accesibles

#### Síntomas
- Admin UI (8082) no responde
- Stats UI (8404) no responde
- Errores de autenticación

#### Diagnóstico
```bash
# Verificar puertos
netstat -tlnp | grep -E ":(8082|8404)"

# Verificar configuración de admin
docker exec haproxy grep -A 10 -B 5 "stats" /usr/local/etc/haproxy/haproxy.cfg
```

#### Soluciones
```bash
# Verificar credenciales (admin:admin123)
curl -u admin:admin123 http://localhost:8404/stats

# Reiniciar HAProxy
./scripts/core/docker-compose-wrapper.sh restart haproxy

# Verificar configuración de stats
# Editar haproxy/config/haproxy.cfg si es necesario
```

## Problemas de MkDocs

### Documentación No Accesible

#### Síntomas
- Puerto 8000 no responde
- Errores 404 en /docs
- MkDocs no inicia

#### Diagnóstico
```bash
# Verificar contenedor MkDocs
docker logs mkdocs-server --tail 20

# Verificar archivos de documentación
docker exec mkdocs-server ls -la /app/docs/

# Verificar configuración
docker exec mkdocs-server cat /app/mkdocs.yml
```

#### Soluciones
```bash
# Reconstruir MkDocs
./scripts/core/docker-compose-wrapper.sh build --no-cache mkdocs-server
./scripts/core/docker-compose-wrapper.sh up -d mkdocs-server

# Verificar archivos de documentación
# Asegurar que docs/index.md existe

# Verificar integración con HAProxy
curl http://localhost:8083/docs
```

## Problemas de Performance

### Sistema Lento

#### Síntomas
- Respuestas lentas
- Timeouts frecuentes
- Alta utilización de recursos

#### Diagnóstico
```bash
# Verificar recursos del sistema
top
htop
docker stats

# Verificar métricas de HAProxy
curl -u admin:admin123 "http://localhost:8404/stats;csv"

# Verificar logs de performance
./scripts/testing/test-performance.sh
```

#### Soluciones
```bash
# Optimizar configuración de HAProxy
# Aumentar maxconn en haproxy.cfg
# Ajustar timeouts

# Optimizar WebLogic
# Aumentar heap size en docker-compose.yml
# Ajustar thread pools

# Optimizar sistema
# Aumentar límites de archivos abiertos
# Optimizar configuración de red
```

### Memoria Insuficiente

#### Síntomas
- Contenedores se detienen por OOM
- Sistema swap activo
- Performance degradada

#### Diagnóstico
```bash
# Verificar memoria
free -h
docker stats --no-stream

# Verificar logs del sistema
dmesg | grep -i "killed process"
journalctl -u docker --since "1 hour ago"
```

#### Soluciones
```bash
# Aumentar límites de memoria en docker-compose.yml
# Ejemplo:
# mem_limit: 2g
# memswap_limit: 2g

# Optimizar configuración de JVM
# -Xmx1024m -Xms512m

# Limpiar recursos no utilizados
docker system prune -f
docker volume prune -f
```

## Scripts de Diagnóstico Automático

### Diagnóstico Completo
```bash
# Script principal de diagnóstico
./scripts/utilities/diagnose-and-fix.sh

# Validación completa del sistema
./scripts/validation/validate-complete-system.sh

# Verificación de URLs
./scripts/validation/check-urls.sh
```

### Diagnóstico Específico
```bash
# Solo HAProxy
./scripts/validation/debug-haproxy.sh

# Solo dependencias
./scripts/validation/check-dependencies.sh

# Solo configuración
./scripts/validation/validate-config-consistency.sh
```

## Recuperación de Emergencia

### Backup y Restore

#### Crear Backup
```bash
# Backup completo
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  config/ haproxy/ weblogic/ docs/ scripts/ .env

# Backup de base de datos
docker exec oracle-db exp system/oracle123 file=/tmp/backup.dmp full=y
docker cp oracle-db:/tmp/backup.dmp ./oracle-backup-$(date +%Y%m%d).dmp
```

#### Restaurar desde Backup
```bash
# Detener servicios
./scripts/stop-all-services.sh

# Restaurar archivos
tar -xzf backup-YYYYMMDD-HHMMSS.tar.gz

# Restaurar base de datos
docker cp oracle-backup-YYYYMMDD.dmp oracle-db:/tmp/
docker exec oracle-db imp system/oracle123 file=/tmp/oracle-backup-YYYYMMDD.dmp full=y

# Reiniciar servicios
./scripts/start-all.sh
```

### Reset Completo del Sistema
```bash
# CUIDADO: Esto borra todo
./scripts/maintenance/comprehensive-cleanup.sh

# Reiniciar desde cero
./scripts/setup.sh
./scripts/start-all.sh
```

## Contacto y Soporte

### Logs para Soporte
```bash
# Generar reporte completo
./scripts/utilities/diagnose-and-fix.sh > system-report-$(date +%Y%m%d).txt

# Incluir información del sistema
echo "=== SYSTEM INFO ===" >> system-report-$(date +%Y%m%d).txt
uname -a >> system-report-$(date +%Y%m%d).txt
docker version >> system-report-$(date +%Y%m%d).txt
docker-compose version >> system-report-$(date +%Y%m%d).txt
```

### Información de Debug
- Versión del sistema
- Logs de todos los contenedores
- Configuración actual
- Estado de recursos del sistema

---

## Enlaces Relacionados

- [Guía de Despliegue](deployment.md)
- [Arquitectura del Sistema](arquitectura.md)
- [Configuración HAProxy](haproxy.md)
- [Scripts de Automatización](scripts/index.md)
- [Soporte Técnico](support.md)
