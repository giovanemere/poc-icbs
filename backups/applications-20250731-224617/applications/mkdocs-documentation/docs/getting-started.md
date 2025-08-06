# Primeros Pasos

Esta guía te llevará desde la instalación hasta tener el proyecto funcionando completamente.

## 📋 Requisitos del Sistema

| Componente | Versión Mínima | Recomendada |
|------------|----------------|-------------|
| Docker Engine | 20.10+ | 24.0+ |
| Docker Compose | 2.0+ | 2.20+ |
| RAM | 8GB | 16GB |
| Espacio en Disco | 50GB | 100GB |
| CPU | 4 cores | 8 cores |

## 🚀 Instalación Rápida

### 1. Clonar y Configurar

```bash
# Clonar repositorio
git clone https://github.com/your-org/docker-for-oracle-weblogic.git
cd docker-for-oracle-weblogic

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus configuraciones
```

### 2. Configuración Básica

Edita el archivo `.env`:

```bash
# Base de Datos
DB_HOST=localhost
DB_PORT=1521
DB_SID=XE
DB_USER=weblogic
DB_PASSWORD=your_password

# WebLogic
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome1

# HAProxy
HAPROXY_STATS_USER=admin
HAPROXY_STATS_PASSWORD=admin
```

### 3. Iniciar Servicios

```bash
# Dar permisos a scripts
chmod +x *.sh

# Ejecutar setup inicial
./setup.sh

# Iniciar todos los servicios
./start-all.sh
```

### 4. Verificar Instalación

```bash
# Verificar contenedores
docker ps

# Probar servicios
curl -I http://localhost:8080        # Aplicación
curl -I http://localhost:7001/console # WebLogic Console
curl -I http://localhost:8404/stats   # HAProxy Stats
```

## 📁 Estructura del Proyecto

```
docker-for-oracle-weblogic/
├── 📁 config/                    # Configuraciones
│   ├── weblogic/                 # Config WebLogic
│   ├── haproxy/                  # Config HAProxy
│   └── database/                 # Scripts DB
├── 📁 docs/                      # Documentación
├── 📁 scripts/                   # Scripts organizados
│   ├── build/                    # Scripts de build
│   ├── deploy/                   # Scripts de deploy
│   └── utils/                    # Utilidades
├── 📁 war-projects/              # Proyectos WAR
├── 📁 logs/                      # Logs del sistema
├── 📄 docker-compose.yml         # Servicios Docker
├── 📄 .env                       # Variables de entorno
└── 📄 README.md                  # Documentación principal
```

## 🔧 Configuración Avanzada

### Base de Datos Externa

Si tienes una BD Oracle externa:

```bash
# En .env
DB_HOST=your-oracle-server.com
DB_PORT=1521
DB_SID=ORCL
DB_USER=weblogic
DB_PASSWORD=secure_password
```

### Configuración de Memoria

Para ajustar memoria según tu sistema:

```bash
# En .env
WEBLOGIC_MEMORY=4g              # Para sistemas con más RAM
DATABASE_MEMORY=2g              # Ajustar según necesidad
JAVA_OPTS=-Xms2g -Xmx4g        # Opciones JVM
```

### Configuración de Red

Para personalizar la red Docker:

```bash
# En .env
NETWORK_NAME=mi_red_weblogic
NETWORK_SUBNET=172.25.0.0/16
```

## 🧪 Verificación Completa

### Script de Verificación

```bash
#!/bin/bash
# health-check.sh

echo "🏥 Verificando sistema completo..."

# Verificar Docker
docker --version || { echo "❌ Docker no disponible"; exit 1; }

# Verificar servicios
services=("weblogic-admin:7001" "haproxy-lb:8080" "oracle-db:1521")
for service in "${services[@]}"; do
    container=${service%:*}
    port=${service#*:}
    if docker ps | grep -q $container; then
        echo "✅ $container - Ejecutándose"
    else
        echo "❌ $container - No encontrado"
    fi
done

# Verificar conectividad
endpoints=("localhost:8080" "localhost:7001" "localhost:8404")
for endpoint in "${endpoints[@]}"; do
    if timeout 5 bash -c "</dev/tcp/${endpoint/:/ }" 2>/dev/null; then
        echo "✅ $endpoint - Accesible"
    else
        echo "❌ $endpoint - No accesible"
    fi
done

echo "✅ Verificación completada"
```

### URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Aplicación Principal** | http://localhost:8080 | - |
| **WebLogic Console** | http://localhost:7001/console | weblogic/welcome1 |
| **HAProxy Stats** | http://localhost:8404/stats | admin/admin |
| **FF4J Console** | http://localhost:7001/ff4j-web-console | - |

## 🔄 Comandos Esenciales

### Gestión de Servicios

```bash
# Iniciar todos los servicios
./start-all.sh

# Detener todos los servicios
./stop-all-services.sh

# Reiniciar servicios específicos
docker-compose restart weblogic-admin
docker-compose restart haproxy-lb

# Ver logs
docker-compose logs -f
docker-compose logs weblogic-admin
```

### Despliegue de Aplicaciones

```bash
# Desplegar WAR
./deploy-war.sh myapp.war

# Auto-deployment (copiar a carpeta)
cp myapp.war autodeploy/

# Verificar despliegue
curl http://localhost:8080/myapp/health
```

### Gestión de Datos

```bash
# Backup de configuración
./scripts/utils/backup.sh

# Limpiar sistema
./scripts/utils/cleanup.sh

# Verificar salud
./scripts/utils/health-check.sh
```

## 🐛 Solución Rápida de Problemas

### WebLogic no inicia

```bash
# Verificar memoria
free -h
docker stats

# Verificar logs
docker-compose logs weblogic-admin

# Solución: Aumentar memoria
export JAVA_OPTIONS="-Xms2g -Xmx4g"
docker-compose restart weblogic-admin
```

### HAProxy no balancea

```bash
# Verificar configuración
docker-compose logs haproxy-lb

# Verificar backends
curl http://localhost:8404/stats

# Solución: Reiniciar servicios
docker-compose restart weblogic-managed-1 weblogic-managed-2
docker-compose restart haproxy-lb
```

### Base de datos no conecta

```bash
# Verificar conectividad
telnet localhost 1521

# Verificar contenedor
docker ps | grep oracle

# Solución: Reiniciar BD
docker-compose restart oracle-db
```

## 📚 Próximos Pasos

Una vez que tengas el sistema funcionando:

1. **[Arquitectura](arquitectura.md)** - Entender el diseño del sistema
2. **[Despliegue](deployment.md)** - Guías detalladas de despliegue
3. **[Canary y Features](canary-and-features.md)** - Despliegues avanzados
4. **[HAProxy](haproxy.md)** - Configuración del load balancer
5. **[Soporte](support.md)** - Troubleshooting y FAQ

## 💡 Consejos Importantes

!!! tip "Desarrollo"
    - Usa `autodeploy/` para desarrollo rápido
    - Habilita `DEBUG_ENABLED=true` en `.env`
    - Monta volúmenes para hot-reload

!!! warning "Producción"
    - Cambia todas las contraseñas por defecto
    - Configura SSL/TLS
    - Habilita backups automáticos
    - Monitorea recursos del sistema

!!! info "Rendimiento"
    - Ajusta memoria según tu hardware
    - Usa SSD para mejor I/O
    - Monitorea métricas en HAProxy Stats
