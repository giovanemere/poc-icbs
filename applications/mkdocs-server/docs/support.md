# Soporte y Troubleshooting

Esta guía consolidada cubre la solución de problemas comunes y responde a las preguntas más frecuentes del proyecto.

## 🚨 Solución de Problemas

### 🔍 Diagnóstico General

#### Script de Diagnóstico Rápido

```bash
#!/bin/bash
# quick-diagnosis.sh

echo "🔍 DIAGNÓSTICO RÁPIDO DEL SISTEMA"
echo "================================="

# 1. Estado de contenedores
echo "📦 Estado de Contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(weblogic|haproxy|oracle)"

# 2. Conectividad de servicios
echo -e "\n🌐 Conectividad de Servicios:"
services=("localhost:8080" "localhost:7001" "localhost:8404" "localhost:1521")
for service in "${services[@]}"; do
    if timeout 3 bash -c "</dev/tcp/${service/:/ }" 2>/dev/null; then
        echo "✅ $service - OK"
    else
        echo "❌ $service - FAIL"
    fi
done

# 3. Uso de recursos
echo -e "\n💾 Uso de Recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6

# 4. Logs recientes con errores
echo -e "\n📋 Errores Recientes:"
docker-compose logs --tail=20 | grep -i error | tail -5

echo -e "\n✅ Diagnóstico completado"
```

### 🐛 Problemas Específicos

#### 1. WebLogic No Inicia

**Síntomas:**
- Contenedor se reinicia constantemente
- Error "OutOfMemoryError" en logs
- Timeout al acceder a consola

**Diagnóstico:**
```bash
# Verificar logs detallados
docker-compose logs weblogic-admin | grep -i error

# Verificar memoria disponible
free -h
docker stats weblogic-admin --no-stream
```

**Soluciones:**

=== "Memoria Insuficiente"
    ```bash
    # Aumentar memoria JVM
    export JAVA_OPTIONS="-Xms2g -Xmx4g -XX:MaxPermSize=512m"
    
    # O editar docker-compose.yml
    environment:
      - JAVA_OPTIONS=-Xms2g -Xmx4g
    
    # Reiniciar servicio
    docker-compose restart weblogic-admin
    ```

=== "Puerto Ocupado"
    ```bash
    # Verificar puertos en uso
    netstat -tulpn | grep :7001
    
    # Cambiar puerto en docker-compose.yml
    ports:
      - "7002:7001"  # Usar puerto diferente
    ```

=== "Permisos de Archivos"
    ```bash
    # Verificar y corregir permisos
    sudo chown -R 1000:1000 oracle/
    chmod -R 755 oracle/
    ```

#### 2. HAProxy No Balancea

**Síntomas:**
- Todo el tráfico va a un servidor
- Error 503 Service Unavailable
- Health checks fallan

**Diagnóstico:**
```bash
# Verificar configuración
cat haproxy/haproxy.cfg | grep -A 10 backend

# Ver estadísticas
curl http://localhost:8404/stats | grep -E "(main|canary)"

# Verificar logs
docker-compose logs haproxy-lb | tail -20
```

**Soluciones:**

=== "Servidores Backend Inactivos"
    ```bash
    # Verificar estado de WebLogic servers
    curl -I http://weblogic-managed-1:7003/health
    curl -I http://weblogic-managed-2:7005/health
    
    # Reiniciar servidores managed
    docker-compose restart weblogic-managed-1 weblogic-managed-2
    ```

=== "Configuración Incorrecta"
    ```bash
    # Validar configuración HAProxy
    docker exec haproxy-lb haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
    
    # Recargar configuración
    docker-compose restart haproxy-lb
    ```

#### 3. Base de Datos No Conecta

**Síntomas:**
- Error JDBC en logs de WebLogic
- Aplicaciones no acceden a datos
- Timeout de conexión

**Diagnóstico:**
```bash
# Verificar contenedor BD
docker ps | grep oracle

# Test conectividad
telnet localhost 1521

# Verificar logs BD
docker logs oracle-db | tail -20
```

**Soluciones:**

=== "Contenedor BD No Iniciado"
    ```bash
    # Iniciar contenedor Oracle
    docker-compose up -d oracle-db
    
    # Verificar inicialización
    docker logs -f oracle-db
    ```

=== "Credenciales Incorrectas"
    ```bash
    # Verificar variables de entorno
    cat .env | grep DB_
    
    # Test manual de conexión
    sqlplus system/oracle@localhost:1521/XE
    ```

#### 4. Feature Flags No Funcionan

**Síntomas:**
- FF4J console no accesible
- Feature flags no cambian comportamiento
- Error al guardar configuración

**Diagnóstico:**
```bash
# Verificar aplicación FF4J
curl -I http://localhost:7001/ff4j-web-console

# Verificar logs
docker-compose logs weblogic-admin | grep -i ff4j

# Verificar BD FF4J
sqlplus ff4j/ff4j@localhost:1521/XE
```

**Soluciones:**

=== "Aplicación FF4J No Desplegada"
    ```bash
    # Redesplegar aplicación
    ./deploy-war.sh war-projects/feature-flags/target/feature-flags.war
    
    # Verificar despliegue
    curl http://localhost:7001/feature-flags/health
    ```

=== "Base de Datos FF4J"
    ```sql
    -- Verificar tablas FF4J
    SELECT table_name FROM user_tables WHERE table_name LIKE 'FF4J%';
    
    -- Crear tablas si no existen
    @scripts/ff4j-schema.sql
    ```

#### 5. Despliegue Canary Falla

**Síntomas:**
- Tráfico no se divide correctamente
- Servidores canary no reciben requests
- Error al cambiar porcentajes

**Diagnóstico:**
```bash
# Verificar configuración canary
./canary-control.sh status

# Verificar HAProxy stats
curl http://localhost:8404/stats | grep canary

# Verificar servidores canary
docker ps | grep canary
```

**Soluciones:**

=== "Servidores Canary Inactivos"
    ```bash
    # Iniciar servidores canary
    ./setup-canary.sh
    
    # Verificar estado
    docker-compose ps | grep canary
    ```

=== "Configuración HAProxy"
    ```bash
    # Verificar reglas de enrutamiento
    grep -A 10 "canary" haproxy/haproxy.cfg
    
    # Recargar configuración
    docker-compose restart haproxy-lb
    ```

## ❓ Preguntas Frecuentes

### 🚀 Instalación y Configuración

#### ¿Cuáles son los requisitos mínimos?

**Mínimos:**
- Docker Engine 20.10+, Docker Compose 2.0+
- 8GB RAM, 50GB disco, 4 CPU cores

**Recomendados:**
- Docker Engine 24.0+, Docker Compose 2.20+
- 16GB RAM, 100GB disco, 8 CPU cores

#### ¿Puedo usar una BD Oracle externa?

Sí, edita el archivo `.env`:

```bash
DB_HOST=your-oracle-server.com
DB_PORT=1521
DB_SID=ORCL
DB_USER=weblogic
DB_PASSWORD=your_password
```

#### ¿Cómo cambio las credenciales por defecto?

Edita `.env` antes del primer despliegue:

```bash
WEBLOGIC_ADMIN_USER=admin
WEBLOGIC_ADMIN_PASSWORD=secure_password
HAPROXY_STATS_USER=admin
HAPROXY_STATS_PASSWORD=secure_password
```

### 🔄 Despliegue y Operaciones

#### ¿Cómo despliego una aplicación WAR?

```bash
# Método 1: Script de despliegue
./deploy-war.sh path/to/application.war

# Método 2: Auto-deployment
cp application.war autodeploy/
```

#### ¿Puedo desplegar múltiples aplicaciones?

Sí, cada aplicación tendrá su propio contexto:

```bash
./deploy-war.sh app1.war  # http://localhost:8080/app1
./deploy-war.sh app2.war  # http://localhost:8080/app2
```

#### ¿Cómo hago rollback?

```bash
# Opción 1: Redesplegar versión anterior
./deploy-war.sh previous-version.war

# Opción 2: Usar backup
./scripts/utils/restore.sh backup/20240125_143000/
```

### 🎯 Canary Deployment

#### ¿Cómo configuro un despliegue canary?

```bash
# 1. Configurar servidores canary
./setup-canary.sh

# 2. Desplegar nueva versión
./deploy-war.sh new-version.war canary

# 3. Dirigir tráfico gradualmente
./canary-control.sh set 10    # 10%
./canary-control.sh set 50    # 50%

# 4. Promover o rollback
./canary-control.sh promote   # O rollback
```

#### ¿Puedo cambiar el porcentaje en tiempo real?

Sí, sin interrumpir el servicio:

```bash
./canary-control.sh set 25   # 25% a canary
./canary-control.sh set 0    # Desactivar canary
```

### 🚩 Feature Flags

#### ¿Cómo activo/desactivo una feature flag?

**Consola Web:**
1. Accede a `http://localhost:7001/ff4j-web-console`
2. Toggle ON/OFF

**API REST:**
```bash
# Activar
curl -X POST http://localhost:7001/ff4j-web-console/api/ff4j/store/features/MY_FEATURE/enable

# Desactivar
curl -X POST http://localhost:7001/ff4j-web-console/api/ff4j/store/features/MY_FEATURE/disable
```

#### ¿Cómo creo una nueva feature flag?

```java
@Component
public class MyService {
    @Autowired
    private FF4j ff4j;
    
    public void myMethod() {
        if (ff4j.check("NEW_FEATURE")) {
            // Nueva funcionalidad
        } else {
            // Código existente
        }
    }
}
```

### ⚖️ Load Balancing

#### ¿Cómo funciona el balanceador?

HAProxy distribuye tráfico usando round-robin por defecto. Puedes cambiar el algoritmo en `haproxy/haproxy.cfg`.

#### ¿Puedo agregar más servidores?

Sí, edita `docker-compose.yml` y `haproxy/haproxy.cfg`:

```yaml
# docker-compose.yml
weblogic-managed-3:
  image: weblogic:latest
  ports:
    - "7011:7001"
```

```haproxy
# haproxy.cfg
backend weblogic_main
    server weblogic-3 weblogic-managed-3:7001 check
```

### 🔍 Monitoreo

#### ¿Dónde encuentro los logs?

```bash
# Todos los servicios
docker-compose logs

# Servicio específico
docker-compose logs weblogic-admin

# En tiempo real
docker-compose logs -f --tail=100
```

#### ¿Cómo monitoreo el rendimiento?

- **HAProxy Stats**: http://localhost:8404/stats
- **WebLogic Console**: http://localhost:7001/console
- **Métricas Docker**: `docker stats`

### 🔐 Seguridad

#### ¿Cómo uso HTTPS/SSL?

Configura SSL en HAProxy:

```haproxy
frontend weblogic_frontend
    bind *:443 ssl crt /path/to/certificate.pem
    redirect scheme https if !{ ssl_fc }
```

#### ¿Cómo aseguro la base de datos?

- Usa credenciales fuertes
- Configura SSL/TLS para conexiones
- Restringe acceso de red
- Habilita auditoría

## 🛠️ Herramientas de Diagnóstico

### Comandos Útiles

```bash
# Estado general del sistema
docker-compose ps
docker stats --no-stream

# Conectividad de servicios
curl -I http://localhost:8080
curl -I http://localhost:7001/console
curl -I http://localhost:8404/stats

# Logs con filtros
docker-compose logs | grep -i error
docker-compose logs weblogic-admin | grep -i deploy

# Métricas de HAProxy
curl -s http://localhost:8404/stats | grep -E "(main|canary)"

# Verificar base de datos
telnet localhost 1521
sqlplus system/oracle@localhost:1521/XE
```

### Scripts de Monitoreo

```bash
# Monitor continuo
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    docker-compose ps --format "table {{.Name}}\t{{.Status}}"
    curl -s http://localhost:8080/health || echo "❌ App no responde"
    sleep 30
done
```

## 🔄 Backup y Recuperación

### Backup Automático

```bash
#!/bin/bash
# backup-system.sh

BACKUP_DIR="backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup configuraciones
cp -r config/ $BACKUP_DIR/
cp -r haproxy/ $BACKUP_DIR/
cp docker-compose.yml $BACKUP_DIR/
cp .env $BACKUP_DIR/

# Backup base de datos
docker exec oracle-db exp system/oracle file=/tmp/backup.dmp full=y
docker cp oracle-db:/tmp/backup.dmp $BACKUP_DIR/

echo "✅ Backup creado en: $BACKUP_DIR"
```

### Restauración

```bash
#!/bin/bash
# restore-system.sh

BACKUP_DIR=$1
if [ -z "$BACKUP_DIR" ]; then
    echo "Uso: $0 <directorio_backup>"
    exit 1
fi

# Detener servicios
docker-compose down

# Restaurar configuraciones
cp -r $BACKUP_DIR/config/ ./
cp -r $BACKUP_DIR/haproxy/ ./
cp $BACKUP_DIR/docker-compose.yml ./
cp $BACKUP_DIR/.env ./

# Reiniciar servicios
docker-compose up -d

echo "✅ Sistema restaurado desde: $BACKUP_DIR"
```

## 📞 Obtener Ayuda

### Información para Reportes

Cuando reportes un problema, incluye:

```bash
# Información del sistema
uname -a
docker --version
docker-compose --version

# Estado de contenedores
docker ps -a

# Logs relevantes
docker-compose logs --tail=100 > logs_$(date +%Y%m%d_%H%M%S).txt
```

### Canales de Soporte

- **GitHub Issues**: Para bugs y mejoras
- **Documentación**: Esta guía completa
- **Email**: support@icbs.com

### Antes de Reportar

1. ✅ Ejecuta el script de diagnóstico
2. ✅ Revisa esta guía de troubleshooting
3. ✅ Verifica logs por errores específicos
4. ✅ Intenta reproducir el problema
5. ✅ Documenta pasos exactos

## 💡 Consejos de Rendimiento

### Optimización General

```bash
# Ajustar memoria según hardware
export JAVA_OPTIONS="-Xms4g -Xmx8g"

# Usar SSD para mejor I/O
# Monitorear métricas regularmente
docker stats

# Limpiar recursos no utilizados
docker system prune -f
```

### Monitoreo Proactivo

```bash
# Configurar alertas básicas
#!/bin/bash
# alerts.sh

# Verificar memoria alta
mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" weblogic-admin | sed 's/%//')
if (( $(echo "$mem_usage > 85" | bc -l) )); then
    echo "🚨 ALERTA: Memoria alta en WebLogic: $mem_usage%"
fi

# Verificar tiempo de respuesta
response_time=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:8080/health)
if (( $(echo "$response_time > 3.0" | bc -l) )); then
    echo "🚨 ALERTA: Tiempo de respuesta alto: ${response_time}s"
fi
```

¡Esta guía consolidada debería resolver la mayoría de problemas que puedas encontrar! Si necesitas ayuda adicional, no dudes en contactar al equipo de soporte.
