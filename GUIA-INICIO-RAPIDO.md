# Guía de Inicio Rápido - Docker WebLogic Oracle

## 🚀 Inicio Rápido con Imágenes Docker Hub (Recomendado)

### ✅ Todas las imágenes principales están disponibles públicamente en Docker Hub

## 📋 Prerrequisitos

### Requisitos del Sistema
- **Docker**: 20.10+ instalado y funcionando
- **Docker Compose**: 3.8+ instalado
- **RAM**: Mínimo 4GB, recomendado 8GB
- **Espacio en Disco**: Mínimo 8GB libres
- **Puertos Libres**: 80, 1521, 5500, 7001, 7002, 8000, 8081, 8404

### Verificar Prerrequisitos
```bash
# Verificar Docker
docker --version
docker info

# Verificar Docker Compose
docker-compose --version

# Verificar puertos libres
netstat -tulpn | grep -E ':(80|1521|5500|7001|7002|8000|8081|8404)'

# Verificar espacio en disco
df -h
```

## 🎯 Opción 1: Inicio Súper Rápido (5 minutos)

### Paso 1: Descargar Docker Compose Template
```bash
# Crear directorio del proyecto
mkdir docker-weblogic-oracle
cd docker-weblogic-oracle

# Descargar template Docker Compose
curl -o docker-compose.yml https://raw.githubusercontent.com/tu-repo/docker-compose.dockerhub.yml
```

### Paso 2: Configurar Variables (Opcional)
```bash
# Crear archivo de variables básicas
cat > .env << EOF
# Configuración básica
ORACLE_PWD=Oracle123
WEBLOGIC_ADMIN_PASSWORD=welcome1
HAPROXY_STATS_USER=admin
HAPROXY_STATS_PASSWORD=admin123
EOF
```

### Paso 3: Iniciar Stack Completo
```bash
# Pull de todas las imágenes (primera vez)
docker pull edissonz8809/mkdocs-server:v1.1.0
docker pull edissonz8809/haproxy-advanced:v1.1.0
docker pull edissonz8809/weblogic-feature-flags:v1.1.0
docker pull container-registry.oracle.com/database/express:21.3.0-xe

# Iniciar todos los servicios
docker-compose up -d

# Verificar estado
docker-compose ps
```

### Paso 4: Verificar Servicios (2-3 minutos de espera)
```bash
# Verificar logs de inicio
docker-compose logs -f

# Verificar health checks
docker-compose ps
```

## 🎯 Opción 2: Proyecto Completo (10 minutos)

### Paso 1: Clonar Repositorio Completo
```bash
# Clonar proyecto completo
git clone <repository-url>
cd docker-for-oracle-weblogic

# Verificar estructura
ls -la
```

### Paso 2: Configurar Variables de Registry
```bash
# Cargar configuración Docker Hub
source .env.registry

# Verificar variables
echo "Registry: $DOCKER_REGISTRY"
echo "MkDocs Image: $MKDOCS_IMAGE:$MKDOCS_VERSION"
echo "HAProxy Image: $HAPROXY_IMAGE:$HAPROXY_VERSION"
echo "WebLogic Image: $WEBLOGIC_IMAGE:$WEBLOGIC_VERSION"
```

### Paso 3: Usar Script de Gestión Automática
```bash
# Iniciar con script automático (recomendado)
./manage-services.sh start

# O usar Docker Compose con imágenes Docker Hub
docker-compose -f docker-compose.dockerhub.yml up -d
```

### Paso 4: Monitoreo y Logs
```bash
# Ver estado de servicios
./manage-services.sh status

# Ver logs en tiempo real
docker-compose logs -f

# Verificar health checks
docker-compose ps
```

## 🔗 URLs de Acceso

### Servicios Principales
Una vez que todos los servicios estén corriendo (2-3 minutos), puedes acceder a:

| Servicio | URL | Credenciales | Estado |
|----------|-----|--------------|--------|
| **HAProxy Load Balancer** | http://localhost | - | ✅ Balanceador principal |
| **HAProxy Admin UI** | http://localhost:8404 | admin / admin123 | ✅ Interface administrativa |
| **HAProxy Stats** | http://localhost:8081 | - | ✅ Estadísticas en tiempo real |
| **WebLogic A Console** | http://localhost:7001/console | weblogic / welcome1 | ✅ Servidor A |
| **WebLogic B Console** | http://localhost:7002/console | weblogic / welcome1 | ✅ Servidor B |
| **MkDocs Documentation** | http://localhost:8000 | - | ✅ Documentación completa |
| **Oracle Enterprise Manager** | http://localhost:5500/em | system / Oracle123 | ✅ Gestión BD |

### Conexiones de Base de Datos
```bash
# Conexión Oracle Database
Host: localhost
Port: 1521
SID: XE
PDB: XEPDB1
System User: system / Oracle123
WebLogic User: weblogic_dev / WebLogic123
```

## ⏱️ Tiempos de Inicio Esperados

### Primera Ejecución (con pull de imágenes)
- **Pull de imágenes**: 3-5 minutos (dependiendo de conexión)
- **Inicio Oracle Database**: 2-3 minutos
- **Inicio WebLogic Servers**: 2-3 minutos
- **Inicio HAProxy**: 30 segundos
- **Inicio MkDocs**: 10 segundos
- **Total**: 8-12 minutos

### Ejecuciones Posteriores (imágenes en cache)
- **Inicio Oracle Database**: 1-2 minutos
- **Inicio WebLogic Servers**: 1-2 minutos
- **Inicio HAProxy**: 15 segundos
- **Inicio MkDocs**: 5 segundos
- **Total**: 3-5 minutos

## 🧪 Verificación y Testing

### Paso 1: Verificar Health Checks
```bash
# Verificar que todos los servicios estén healthy
docker-compose ps

# Debería mostrar:
# mkdocs-server        Up (healthy)
# haproxy-advanced     Up (healthy)
# weblogic-features-a  Up (healthy)
# weblogic-features-b  Up (healthy)
# oracle-express-db    Up (healthy)
```

### Paso 2: Test de Conectividad
```bash
# Test HAProxy Load Balancer
curl -I http://localhost

# Test HAProxy Stats
curl -I http://localhost:8081

# Test MkDocs
curl -I http://localhost:8000

# Test WebLogic A
curl -I http://localhost:7001/console

# Test WebLogic B
curl -I http://localhost:7002/console
```

### Paso 3: Test de Base de Datos
```bash
# Test conexión Oracle (requiere sqlplus)
docker exec oracle-express-db sqlplus system/Oracle123@localhost:1521/XE <<< "SELECT 1 FROM DUAL;"

# O verificar logs de Oracle
docker logs oracle-express-db | tail -20
```

### Paso 4: Test de Feature Flags
```bash
# Verificar Feature Flags en WebLogic A
curl http://localhost:7001/weblogic-features/api/flags

# Verificar Feature Flags en WebLogic B
curl http://localhost:7002/weblogic-features/api/flags
```

## 🎯 Casos de Uso y Testing

### 1. Test de Load Balancing
```bash
# Hacer múltiples requests al load balancer
for i in {1..10}; do
  curl -s http://localhost | grep -o "WebLogic [AB]"
done

# Debería mostrar distribución entre WebLogic A y B
```

### 2. Test de A/B Testing
```bash
# Acceder a versión A específica
curl -H "X-Feature-Version: A" http://localhost

# Acceder a versión B específica
curl -H "X-Feature-Version: B" http://localhost
```

### 3. Test de Canary Deployment
```bash
# Simular canary deployment (90% A, 10% B)
for i in {1..100}; do
  curl -s http://localhost | grep -o "Version [AB]"
done | sort | uniq -c
```

### 4. Test de Failover
```bash
# Parar WebLogic A
docker-compose stop weblogic-a

# Verificar que el tráfico va solo a B
curl http://localhost

# Reiniciar WebLogic A
docker-compose start weblogic-a
```

## 📊 Monitoreo y Observabilidad

### HAProxy Stats Dashboard
- **URL**: http://localhost:8404
- **Características**:
  - Estado de backends en tiempo real
  - Métricas de requests y responses
  - Health check status
  - Configuración dinámica

### HAProxy Admin Interface
- **URL**: http://localhost:8081
- **Funcionalidades**:
  - Habilitar/deshabilitar backends
  - Cambiar pesos de load balancing
  - Ver estadísticas detalladas
  - Configuración en tiempo real

### Logs Centralizados
```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de servicio específico
docker-compose logs -f haproxy
docker-compose logs -f weblogic-a
docker-compose logs -f oracle

# Ver logs con timestamps
docker-compose logs -f -t
```

### Métricas de Sistema
```bash
# Ver uso de recursos
docker stats

# Ver uso de volúmenes
docker system df

# Ver información de red
docker network ls
docker network inspect docker-for-oracle-weblogic_weblogic-network
```

## 🔧 Troubleshooting

### Problemas Comunes

#### 1. Servicios no inician
```bash
# Verificar logs de error
docker-compose logs

# Verificar puertos ocupados
netstat -tulpn | grep -E ':(80|1521|7001|7002|8000|8081|8404)'

# Liberar puertos si es necesario
docker-compose down
sudo lsof -ti:8080 | xargs kill -9  # Ejemplo para puerto 8080
```

#### 2. Oracle Database no inicia
```bash
# Verificar logs de Oracle
docker logs oracle-express-db

# Verificar espacio en disco
df -h

# Reiniciar Oracle si es necesario
docker-compose restart oracle
```

#### 3. WebLogic no se conecta a Oracle
```bash
# Verificar conectividad de red
docker exec weblogic-features-a ping oracle

# Verificar variables de entorno
docker exec weblogic-features-a env | grep ORACLE

# Verificar logs de WebLogic
docker logs weblogic-features-a
```

#### 4. HAProxy backends DOWN
```bash
# Verificar estado en HAProxy Stats
curl http://localhost:8081

# Verificar health checks
docker exec haproxy-advanced curl -I http://weblogic-a:7001/console
docker exec haproxy-advanced curl -I http://weblogic-b:7001/console

# Reiniciar HAProxy si es necesario
docker-compose restart haproxy
```

### Comandos de Diagnóstico
```bash
# Estado completo del sistema
docker-compose ps
docker stats --no-stream
docker system df

# Información de red
docker network inspect docker-for-oracle-weblogic_weblogic-network

# Verificar volúmenes
docker volume ls
docker volume inspect docker-for-oracle-weblogic_oracle_data

# Logs de sistema
journalctl -u docker.service --since "1 hour ago"
```

## 🛑 Parar y Limpiar

### Parar Servicios
```bash
# Parar todos los servicios
docker-compose down

# Parar y remover volúmenes (CUIDADO: elimina datos)
docker-compose down -v

# Parar con script de gestión
./manage-services.sh stop
```

### Limpieza Completa
```bash
# Remover containers, networks, y volúmenes
docker-compose down -v --remove-orphans

# Limpiar imágenes no utilizadas
docker image prune -a

# Limpiar sistema completo (CUIDADO)
docker system prune -a --volumes
```

## 📚 Documentación Adicional

### Enlaces Útiles
- **Docker Hub Images**: https://hub.docker.com/u/edissonz8809
- **Documentación Completa**: http://localhost:8000 (cuando MkDocs esté corriendo)
- **Plan de Implementación**: `docs/plan-implementacion.md`
- **Seguimiento de Progreso**: `docs/seguimiento-progreso.md`

### Archivos de Configuración
- `.env.registry` - Variables Docker Hub
- `docker-compose.dockerhub.yml` - Template con imágenes públicas
- `docker-compose.yml` - Template local
- `mkdocs.yml` - Configuración documentación

## 🎯 Próximos Pasos

### Después del Inicio Exitoso
1. **Explorar Documentación**: http://localhost:8000
2. **Configurar Feature Flags**: Acceder a WebLogic Consoles
3. **Monitorear Sistema**: Usar HAProxy Stats
4. **Personalizar Configuración**: Modificar variables de entorno

### Desarrollo Avanzado
1. **CI/CD Pipeline**: Implementar automatización
2. **Monitoring**: Agregar Prometheus + Grafana
3. **Security**: Implementar SSL/TLS
4. **Scaling**: Configurar múltiples instancias

---

## ✅ Checklist de Verificación

### Antes de Empezar
- [ ] Docker instalado y funcionando
- [ ] Docker Compose disponible
- [ ] Puertos libres verificados
- [ ] Espacio en disco suficiente
- [ ] RAM suficiente (4GB+)

### Después del Inicio
- [ ] Todos los servicios UP y healthy
- [ ] URLs principales accesibles
- [ ] HAProxy Stats funcionando
- [ ] WebLogic Consoles accesibles
- [ ] Oracle Database conectando
- [ ] MkDocs documentación cargando

### Testing Básico
- [ ] Load balancing funcionando
- [ ] Feature Flags respondiendo
- [ ] Health checks pasando
- [ ] Logs sin errores críticos
- [ ] Conectividad entre servicios

**¡Listo para usar! 🚀**

---

**Guía actualizada**: 2025-08-01 09:00 UTC  
**Versión**: v1.1.0  
**Estado**: ✅ Todas las imágenes Docker Hub disponibles públicamente
