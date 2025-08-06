# Docker Configuration and Scripts

Este directorio contiene toda la configuración Docker centralizada para el proyecto WebLogic Oracle Feature Flags.

## 📁 Estructura

```
docker/
├── .env                    # Variables de entorno centralizadas
├── docker-compose.yml      # Configuración de servicios
├── Dockerfile.weblogic     # WebLogic Feature Flags image
├── Dockerfile.haproxy      # HAProxy Advanced image
├── Dockerfile.mkdocs       # MkDocs Documentation image
├── build-and-push.sh       # Build y push a Docker Hub
├── pull-from-hub.sh        # Pull desde Docker Hub
├── deploy-from-hub.sh      # Deploy usando imágenes de Docker Hub
└── README.md              # Esta documentación
```

## 🐳 Docker Hub Registry

**Registry**: `edissonz8809`  
**URL**: https://hub.docker.com/repositories/edissonz8809

### Imágenes Disponibles

| Imagen | Descripción | Tag |
|--------|-------------|-----|
| `edissonz8809/weblogic-feature-flags` | WebLogic con Feature Flags | `latest`, `version-a`, `version-b` |
| `edissonz8809/haproxy-advanced` | HAProxy con Admin UI | `latest` |
| `edissonz8809/mkdocs-server` | Servidor de documentación | `latest` |

## 🔧 Variables de Entorno

Todas las variables están centralizadas en `.env`:

### Docker Registry
```bash
DOCKER_REGISTRY=edissonz8809
DOCKER_TAG=latest
DOCKER_PLATFORM=linux/amd64
```

### Aplicaciones
```bash
WEBLOGIC_IMAGE=${DOCKER_REGISTRY}/weblogic-feature-flags:${DOCKER_TAG}
HAPROXY_IMAGE=${DOCKER_REGISTRY}/haproxy-advanced:${DOCKER_TAG}
MKDOCS_IMAGE=${DOCKER_REGISTRY}/mkdocs-server:${DOCKER_TAG}
```

### Configuración de Servicios
- WebLogic: Puertos 7001, 7002
- HAProxy: Puertos 8081-8404
- Oracle DB: Puerto 1521
- MkDocs: Puerto 8000

## 🚀 Scripts de Automatización

### 1. Build y Push a Docker Hub

```bash
# Build y push todas las imágenes
./build-and-push.sh

# Build y push imagen específica
./build-and-push.sh weblogic
./build-and-push.sh haproxy
./build-and-push.sh mkdocs
```

**Requisitos**:
- Docker login: `docker login -u edissonz8809`
- Permisos de push al registry

### 2. Pull desde Docker Hub

```bash
# Pull todas las imágenes
./pull-from-hub.sh

# Pull imagen específica
./pull-from-hub.sh weblogic
./pull-from-hub.sh haproxy
./pull-from-hub.sh mkdocs
./pull-from-hub.sh oracle
```

### 3. Deploy desde Docker Hub

```bash
# Deploy completo con pull de imágenes
./deploy-from-hub.sh

# Deploy sin pull (usar imágenes locales)
./deploy-from-hub.sh --no-pull

# Ver estado de servicios
./deploy-from-hub.sh status

# Ejecutar health checks
./deploy-from-hub.sh health

# Detener servicios
./deploy-from-hub.sh stop
```

## 📦 Uso con Docker Compose

### Desarrollo Local (Build local)
```bash
docker-compose -f docker-compose.yml up -d --build
```

### Producción (Imágenes de Docker Hub)
```bash
docker-compose -f docker-compose.yml up -d --no-build
```

### Comandos Útiles
```bash
# Ver logs
docker-compose -f docker-compose.yml logs -f [servicio]

# Reiniciar servicio específico
docker-compose -f docker-compose.yml restart [servicio]

# Escalar servicios
docker-compose -f docker-compose.yml up -d --scale weblogic-a=2

# Detener y limpiar
docker-compose -f docker-compose.yml down --volumes --remove-orphans
```

## 🏗️ Dockerfiles

### Dockerfile.weblogic
- **Base**: `vulhub/weblogic:12.2.1.3-2018`
- **Features**: Feature Flags, SQL*Plus, Monitoring
- **Puertos**: 7001, 7002
- **Volúmenes**: Logs, Monitoring, Autodeploy

### Dockerfile.haproxy
- **Base**: `haproxy:2.6`
- **Features**: Admin UI, Stats, Dynamic Routing, Lua scripts
- **Puertos**: 80, 443, 8080-8404
- **Extras**: Python Flask, Lua socket

### Dockerfile.mkdocs
- **Base**: `python:3.11-slim`
- **Features**: MkDocs, Git, Auto-reload
- **Puerto**: 8000
- **Volúmenes**: Documentación

## 🔐 Seguridad

### Secrets Management
- Passwords en variables de entorno
- Docker secrets para producción
- No hardcodear credenciales

### Registry Authentication
```bash
# Login a Docker Hub
docker login -u edissonz8809

# Verificar login
docker info | grep Username
```

### Image Scanning
```bash
# Escanear vulnerabilidades
docker scout cves edissonz8809/weblogic-feature-flags:latest
```

## 🌐 Networking

### Red Personalizada
- **Nombre**: `weblogic-network`
- **Driver**: `bridge`
- **Subnet**: `172.18.0.0/16`

### Puertos Expuestos
| Servicio | Puerto Interno | Puerto Externo | Descripción |
|----------|----------------|----------------|-------------|
| WebLogic A | 7001 | 7001 | Admin Console |
| WebLogic B | 7001 | 7002 | Admin Console |
| HAProxy Admin | 8082 | 8082 | Admin UI |
| HAProxy Stats | 8404 | 8404 | Statistics |
| HAProxy LB | 80 | 8083 | Load Balancer |
| Oracle DB | 1521 | 1521 | Database |
| Oracle EM | 5500 | 5500 | Enterprise Manager |
| MkDocs | 8000 | 8000 | Documentation |

## 💾 Volúmenes

### Volúmenes Persistentes
- `db-oracle-data`: Datos de Oracle
- `weblogic-a-logs`: Logs WebLogic A
- `weblogic-b-logs`: Logs WebLogic B
- `weblogic-a-monitoring`: Monitoring WebLogic A
- `weblogic-b-monitoring`: Monitoring WebLogic B

### Bind Mounts
- `../autodeploy`: Auto-deployment directory
- `../docs`: Documentación MkDocs

## 🔍 Troubleshooting

### Problemas Comunes

#### 1. Error de autenticación Docker Hub
```bash
# Solución
docker logout
docker login -u edissonz8809
```

#### 2. Conflictos de puertos
```bash
# Verificar puertos en uso
netstat -tulpn | grep :7001

# Cambiar puertos en .env
WEBLOGIC_EXTERNAL_PORT_A=7003
```

#### 3. Imágenes no encontradas
```bash
# Pull manual
docker pull edissonz8809/weblogic-feature-flags:latest

# Verificar imágenes disponibles
docker images | grep edissonz8809
```

#### 4. Servicios no healthy
```bash
# Ver logs detallados
docker-compose logs -f [servicio]

# Verificar health checks
docker inspect [container] | grep Health -A 10
```

### Logs y Debugging

```bash
# Logs de build
docker-compose -f docker-compose.yml logs --no-color > build.log

# Debug de red
docker network inspect weblogic-network

# Inspeccionar contenedor
docker exec -it weblogic-a bash
```

## 📊 Monitoreo

### Health Checks
- Todos los servicios tienen health checks configurados
- Intervalo: 30s, Timeout: 10s, Retries: 3

### Métricas
- HAProxy Stats: http://localhost:8404/stats
- Oracle EM: http://localhost:5500/em
- Container stats: `docker stats`

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
- name: Build and Push
  run: |
    cd docker
    ./build-and-push.sh
```

### Deployment Pipeline
```yaml
- name: Deploy from Hub
  run: |
    cd docker
    ./deploy-from-hub.sh --no-pull
```

## 📚 Referencias

- [Docker Hub Repository](https://hub.docker.com/repositories/edissonz8809)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [WebLogic Docker Images](https://github.com/oracle/docker-images/tree/main/OracleWebLogic)
- [HAProxy Documentation](http://www.haproxy.org/)

---

**Última actualización**: 2025-08-01  
**Mantenido por**: DevOps Team
