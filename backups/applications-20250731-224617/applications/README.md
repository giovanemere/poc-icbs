# Applications Directory

Este directorio contiene todas las aplicaciones del proyecto organizadas de manera modular y centralizada.

## 📁 Estructura

```
applications/
├── weblogic-feature-flags/     # Aplicación WebLogic con Feature Flags
│   ├── src/                    # Código fuente
│   ├── deploy/                 # Archivos WAR para despliegue
│   ├── config/                 # Configuraciones específicas
│   ├── container-scripts/      # Scripts de contenedor
│   └── install/               # Archivos de instalación
├── haproxy-advanced/          # Load Balancer HAProxy
│   ├── config/                # Configuraciones HAProxy
│   ├── scripts/               # Scripts de administración
│   │   ├── templates/         # Templates web
│   │   └── static/           # Archivos estáticos
├── mkdocs-documentation/      # Servidor de documentación
│   ├── docs/                  # Archivos de documentación
│   ├── mkdocs.yml            # Configuración MkDocs
│   └── requirements.txt      # Dependencias Python
└── oracle-setup/             # Configuración Oracle Database
    ├── scripts/              # Scripts de setup
    └── config/               # Configuraciones DB
```

## 🚀 Aplicaciones

### 1. WebLogic Feature Flags

**Directorio**: `weblogic-feature-flags/`  
**Imagen Docker**: `edissonz8809/weblogic-feature-flags:latest`  
**Puertos**: 7001, 7002

#### Características
- Oracle WebLogic Server 12.2.1.3
- Sistema de Feature Flags integrado
- Soporte para múltiples versiones (A/B)
- Auto-deployment de WAR files
- Monitoreo y logging integrado

#### Archivos WAR Disponibles
- `feature-flags.war` - Aplicación principal de feature flags
- `ff4j-simple.war` - Implementación FF4J simplificada
- `version-a.war` - Versión A de la aplicación
- `version-b.war` - Versión B de la aplicación
- `weblogic-features-a.war` - Features específicas versión A
- `weblogic-features-b.war` - Features específicas versión B

#### Scripts de Contenedor
- `setup-monitoring.sh` - Configuración de monitoreo
- `health-check.sh` - Health checks personalizados
- `deploy-wars.sh` - Despliegue automático de WARs

### 2. HAProxy Advanced

**Directorio**: `haproxy-advanced/`  
**Imagen Docker**: `edissonz8809/haproxy-advanced:latest`  
**Puertos**: 80, 443, 8080-8404

#### Características
- HAProxy 2.6 con configuración avanzada
- Admin UI web integrada
- Dashboard de estadísticas
- Routing dinámico con Lua
- SSL/TLS termination
- Health checks automáticos

#### Configuraciones
- `haproxy-advanced.cfg` - Configuración principal
- `haproxy-fixed.cfg` - Configuración fija
- `haproxy.cfg` - Configuración base

#### Scripts de Administración
- `admin_api.py` - API de administración
- `admin_ui.py` - Interfaz web de administración
- `start-haproxy.sh` - Script de inicio
- `dynamic_routing.lua` - Routing dinámico

### 3. MkDocs Documentation

**Directorio**: `mkdocs-documentation/`  
**Imagen Docker**: `edissonz8809/mkdocs-server:latest`  
**Puerto**: 8000

#### Características
- MkDocs con Material theme
- Auto-reload en desarrollo
- Soporte para múltiples formatos
- Integración con Git
- Búsqueda integrada

#### Configuración
- `mkdocs.yml` - Configuración principal
- `requirements.txt` - Dependencias Python
- `docs/` - Archivos de documentación

### 4. Oracle Setup

**Directorio**: `oracle-setup/`  
**Imagen Base**: `container-registry.oracle.com/database/express:latest`  
**Puerto**: 1521

#### Características
- Oracle Database Express 21c
- Scripts de inicialización
- Configuración de schemas
- Datos de demo incluidos

#### Configuraciones
- `demo_oracle.ddl` - Schema y datos de demo
- Scripts de setup y mantenimiento

## 🔧 Desarrollo

### Estructura de Desarrollo

Cada aplicación sigue una estructura estándar:

```
application-name/
├── src/                    # Código fuente
├── config/                 # Configuraciones
├── scripts/               # Scripts específicos
├── deploy/                # Artefactos de despliegue
├── tests/                 # Tests unitarios/integración
├── docs/                  # Documentación específica
└── README.md              # Documentación de la aplicación
```

### Comandos de Desarrollo

```bash
# Build aplicación específica
cd docker
./build-and-push.sh weblogic

# Deploy aplicación específica
docker-compose up -d weblogic-a

# Logs de aplicación
docker-compose logs -f weblogic-a
```

## 🚀 Despliegue

### Despliegue Local

```bash
# Desde el directorio docker
docker-compose -f docker-compose.yml up -d --build
```

### Despliegue desde Docker Hub

```bash
# Desde el directorio docker
./deploy-from-hub.sh
```

### Despliegue Individual

```bash
# WebLogic solamente
docker-compose up -d weblogic-a weblogic-b orcldb

# HAProxy solamente
docker-compose up -d haproxy

# Documentación solamente
docker-compose up -d mkdocs-server
```

## 🔍 Monitoreo y Logs

### Ubicaciones de Logs

| Aplicación | Ubicación | Volumen |
|------------|-----------|---------|
| WebLogic A | `/u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs` | `weblogic-a-logs` |
| WebLogic B | `/u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs` | `weblogic-b-logs` |
| HAProxy | `/var/log/haproxy.log` | Container logs |
| Oracle | `/opt/oracle/diag` | `db-oracle-data` |

### Comandos de Monitoreo

```bash
# Ver logs en tiempo real
docker-compose logs -f [servicio]

# Estadísticas de contenedores
docker stats

# Health checks
docker-compose ps
```

## 🔐 Configuración de Seguridad

### Variables de Entorno Sensibles

Las credenciales se manejan a través de variables de entorno:

```bash
# WebLogic
WEBLOGIC_ADMIN_PASSWORD=welcome1

# Oracle
ORACLE_PASSWORD=oracle123

# HAProxy
HAPROXY_STATS_PASSWORD=admin123
```

### Mejores Prácticas

1. **No hardcodear credenciales** en código fuente
2. **Usar Docker secrets** en producción
3. **Rotar passwords** regularmente
4. **Limitar acceso** a puertos administrativos
5. **Habilitar SSL/TLS** en producción

## 🧪 Testing

### Tests Automatizados

```bash
# Tests de integración
cd scripts/testing
./test-integration.sh

# Tests de performance
./test-performance.sh

# Validación completa
./validate-complete-system.sh
```

### Health Checks

Cada aplicación incluye health checks:

- **WebLogic**: HTTP check en `/console`
- **HAProxy**: HTTP check en `/stats`
- **Oracle**: Database connectivity check
- **MkDocs**: HTTP check en `/`

## 📦 Versionado

### Estrategia de Versionado

- **latest**: Última versión estable
- **version-a**: Versión A específica
- **version-b**: Versión B específica
- **v1.0.0**: Tags semánticos

### Gestión de Releases

```bash
# Tag nueva versión
docker tag edissonz8809/weblogic-feature-flags:latest edissonz8809/weblogic-feature-flags:v1.0.0

# Push versión específica
docker push edissonz8809/weblogic-feature-flags:v1.0.0
```

## 🔄 CI/CD Integration

### Pipeline de Build

1. **Build** - Construcción de imágenes
2. **Test** - Ejecución de tests
3. **Push** - Subida a Docker Hub
4. **Deploy** - Despliegue automático

### GitHub Actions Example

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Push
        run: |
          cd docker
          ./build-and-push.sh
      - name: Deploy
        run: |
          cd docker
          ./deploy-from-hub.sh
```

## 📚 Documentación Adicional

- [Plan de Implementación](../docs/plan-implementacion.md)
- [Seguimiento de Progreso](../docs/seguimiento-progreso.md)
- [Docker Configuration](../docker/README.md)
- [Scripts Documentation](../scripts/INDEX.md)

## 🤝 Contribución

### Agregar Nueva Aplicación

1. Crear directorio en `applications/`
2. Seguir estructura estándar
3. Crear Dockerfile en `docker/`
4. Actualizar docker-compose.yml
5. Agregar scripts de build/deploy
6. Documentar en README

### Modificar Aplicación Existente

1. Hacer cambios en directorio de aplicación
2. Actualizar versión en .env
3. Rebuild y push imagen
4. Actualizar documentación

---

**Última actualización**: 2025-08-01  
**Mantenido por**: Development Team
