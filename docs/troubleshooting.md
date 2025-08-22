# 🔧 Solución de Problemas

Esta guía te ayudará a resolver los problemas más comunes del sistema WebLogic.

## 🚨 Problemas Comunes

### 1. Servicios No Inician

#### Síntomas
- Error al ejecutar `./start.sh`
- Contenedores no se crean
- Puertos ocupados

#### Soluciones

=== "Verificar Estado"
    ```bash
    # Ver estado detallado
    ./status.sh
    
    # Ver contenedores Docker
    docker ps -a
    
    # Ver logs de Docker Compose
    docker-compose -f config/docker-compose.yml logs
    ```

=== "Limpiar y Reiniciar"
    ```bash
    # Parar todo
    ./stop.sh
    
    # Limpiar contenedores huérfanos
    docker system prune -f
    
    # Reinicio forzado
    ./force-restart.sh
    ```

=== "Verificar Puertos"
    ```bash
    # Ver puertos ocupados
    netstat -tlnp | grep -E ':(8084|8085|8092|8093|8100|8404)'
    
    # Matar procesos si es necesario
    sudo kill -9 <PID>
    ```

### 2. URLs No Cargan

#### Síntomas
- Error 404 o 503 en las URLs
- Páginas no responden
- Timeout de conexión

#### Soluciones

=== "Verificar URLs"
    ```bash
    # Script de verificación automática
    ./verify-updated-urls.sh
    
    # Verificación manual
    curl -I http://localhost:8085/unified-dashboard-fixed.html
    curl -I http://localhost:8084/
    curl -I http://localhost:8092/
    ```

=== "Reiniciar Servicios"
    ```bash
    # Reiniciar servicios específicos
    docker-compose -f config/docker-compose.yml restart unified-dashboard
    docker-compose -f config/docker-compose.yml restart traffic-dashboard
    docker-compose -f config/docker-compose.yml restart haproxy-admin-panel
    ```

=== "URLs de Respaldo"
    Si HAProxy falla, usa estas URLs independientes:
    
    - ✅ `http://localhost:8085/unified-dashboard-fixed.html`
    - ✅ `http://localhost:8084/`
    - ✅ `http://localhost:8092/index-functional.html`
    - ✅ `http://localhost:8093/api/health`

### 3. HAProxy No Funciona

#### Síntomas
- Frontend Principal (8100) no responde
- Error 503 Service Unavailable
- HAProxy Stats no accesible

#### Soluciones

=== "Verificar HAProxy"
    ```bash
    # Ver logs de HAProxy
    docker logs haproxy-integrated
    
    # Verificar configuración
    docker exec haproxy-integrated haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
    
    # Reiniciar HAProxy
    docker-compose -f config/docker-compose.yml restart haproxy
    ```

=== "Verificar Backends"
    ```bash
    # Verificar WebLogic A
    curl -I http://localhost:7001/console
    
    # Verificar WebLogic B  
    curl -I http://localhost:7002/console
    
    # Ver estado de contenedores WebLogic
    docker logs weblogic-a-integrated --tail 20
    docker logs weblogic-b-integrated --tail 20
    ```

### 4. WebLogic No Responde

#### Síntomas
- Consolas WebLogic no cargan
- Aplicaciones no desplegadas
- Timeout en conexiones

#### Soluciones

=== "Verificar WebLogic"
    ```bash
    # Ver logs de WebLogic A
    docker logs weblogic-a-integrated --tail 50
    
    # Ver logs de WebLogic B
    docker logs weblogic-b-integrated --tail 50
    
    # Verificar health checks
    docker inspect weblogic-a-integrated | grep -A 10 Health
    ```

=== "Reiniciar WebLogic"
    ```bash
    # Reiniciar WebLogic A
    docker-compose -f config/docker-compose.yml restart weblogic-a
    
    # Reiniciar WebLogic B
    docker-compose -f config/docker-compose.yml restart weblogic-b
    
    # Esperar a que inicien (puede tomar varios minutos)
    ./status.sh
    ```

### 5. Oracle Database Problemas

#### Síntomas
- WebLogic no puede conectar a la base de datos
- Error de conexión JDBC
- Oracle EM no accesible

#### Soluciones

=== "Verificar Oracle"
    ```bash
    # Ver logs de Oracle
    docker logs orcldb-integrated --tail 50
    
    # Verificar conexión
    docker exec orcldb-integrated sqlplus system/welcome1@localhost:1521/XE
    
    # Verificar health check
    docker inspect orcldb-integrated | grep -A 10 Health
    ```

=== "Reiniciar Oracle"
    ```bash
    # Reiniciar Oracle (CUIDADO: puede tomar tiempo)
    docker-compose -f config/docker-compose.yml restart orcldb
    
    # Esperar a que inicie completamente
    docker logs orcldb-integrated -f
    ```

## 🔍 Comandos de Diagnóstico

### Estado General del Sistema

```bash
# Estado completo
./status.sh

# Estado de contenedores
docker-compose -f config/docker-compose.yml ps

# Uso de recursos
docker stats --no-stream

# Espacio en disco
df -h
```

### Logs Detallados

```bash
# Logs de todos los servicios
docker-compose -f config/docker-compose.yml logs -f

# Logs de un servicio específico
docker logs <container_name> -f --tail 100

# Logs con timestamps
docker-compose -f config/docker-compose.yml logs -f -t
```

### Verificación de Red

```bash
# Verificar conectividad entre contenedores
docker exec haproxy-integrated ping weblogic-a
docker exec weblogic-a-integrated ping oracle-db

# Verificar puertos internos
docker exec haproxy-integrated netstat -tlnp
```

## 🛠️ Herramientas de Reparación

### Script de Reparación Automática

```bash
#!/bin/bash
# repair-system.sh

echo "🔧 Iniciando reparación automática..."

# 1. Parar todo
./stop.sh

# 2. Limpiar recursos
docker system prune -f
docker volume prune -f

# 3. Verificar imágenes
./check-images.sh

# 4. Reinicio forzado
./force-restart.sh

# 5. Verificar estado
sleep 30
./status.sh
```

### Limpieza Completa

```bash
# CUIDADO: Esto eliminará todos los datos
docker-compose -f config/docker-compose.yml down -v
docker system prune -a -f
docker volume prune -f
```

## 📊 Monitoreo Preventivo

### Verificaciones Regulares

```bash
# Crear script de monitoreo
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): Verificando sistema..."
    ./verify-updated-urls.sh > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "⚠️ Problema detectado, reiniciando..."
        ./start.sh
    fi
    sleep 300  # Verificar cada 5 minutos
done
EOF

chmod +x monitor.sh
```

### Alertas por Email

```bash
# Configurar alertas (requiere mailutils)
if ! ./verify-updated-urls.sh > /dev/null 2>&1; then
    echo "Sistema WebLogic con problemas" | mail -s "Alerta Sistema" admin@empresa.com
fi
```

## 🚨 Escenarios de Emergencia

### Sistema Completamente Caído

```bash
# 1. Diagnóstico rápido
docker ps -a
docker-compose -f config/docker-compose.yml ps

# 2. Logs de error
docker-compose -f config/docker-compose.yml logs --tail 50

# 3. Reinicio de emergencia
./force-restart.sh

# 4. Si persiste, reconstruir
./build-latest.sh
./start.sh
```

### Corrupción de Datos

```bash
# 1. Backup de volúmenes (si es posible)
docker run --rm -v weblogic_oracle-data:/data -v $(pwd):/backup alpine tar czf /backup/oracle-backup.tar.gz /data

# 2. Recrear volúmenes
docker-compose -f config/docker-compose.yml down -v
docker volume create weblogic_oracle-data

# 3. Restaurar desde backup
docker run --rm -v weblogic_oracle-data:/data -v $(pwd):/backup alpine tar xzf /backup/oracle-backup.tar.gz -C /
```

### Problemas de Red

```bash
# Recrear red Docker
docker network rm config_weblogic-network
docker-compose -f config/docker-compose.yml up -d
```

## 📞 Contacto y Soporte

### Información de Debug

Cuando reportes un problema, incluye:

```bash
# Información del sistema
./status.sh > debug-info.txt

# Logs recientes
docker-compose -f config/docker-compose.yml logs --tail 100 >> debug-info.txt

# Configuración
cat config/docker-compose.yml >> debug-info.txt
cat .env >> debug-info.txt
```

### Logs Útiles para Soporte

- **Sistema general**: `./status.sh`
- **Contenedores**: `docker-compose logs`
- **HAProxy**: `docker logs haproxy-integrated`
- **WebLogic**: `docker logs weblogic-a-integrated`
- **Oracle**: `docker logs orcldb-integrated`

## ✅ Checklist de Verificación

Antes de reportar un problema, verifica:

- [ ] ¿Ejecutaste `./status.sh`?
- [ ] ¿Probaste `./force-restart.sh`?
- [ ] ¿Verificaste los logs con `docker-compose logs`?
- [ ] ¿Hay suficiente espacio en disco?
- [ ] ¿Están todos los puertos libres?
- [ ] ¿Las imágenes Docker están disponibles?

## 💡 Consejos de Prevención

!!! tip "Mejores Prácticas"
    
    - **Ejecuta `./status.sh` regularmente** para monitorear el sistema
    - **Usa `./verify-updated-urls.sh`** para verificar URLs
    - **Mantén backups** de configuraciones importantes
    - **Monitorea el espacio en disco** regularmente
    - **Actualiza las imágenes** periódicamente

!!! warning "Evita Estos Errores"
    
    - No uses `docker-compose down -v` a menos que quieras perder datos
    - No modifiques archivos de configuración mientras el sistema está corriendo
    - No fuerces el apagado de contenedores Oracle (puede corromper datos)

## 🎯 Solución Rápida por Síntoma

| Síntoma | Comando Rápido |
|---------|----------------|
| URLs no cargan | `./verify-updated-urls.sh` |
| Servicios caídos | `./force-restart.sh` |
| Logs de error | `docker-compose logs -f` |
| Sistema lento | `docker stats` |
| Puertos ocupados | `netstat -tlnp \| grep 80` |
| Espacio lleno | `df -h && docker system prune -f` |

¡Con esta guía deberías poder resolver la mayoría de problemas del sistema! 🎉
