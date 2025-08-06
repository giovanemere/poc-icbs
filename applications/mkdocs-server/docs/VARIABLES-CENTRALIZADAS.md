# Sistema de Variables Centralizadas

## Descripción General

El proyecto Docker WebLogic Oracle implementa un sistema avanzado de variables de entorno centralizadas que permite:

- **Gestión multi-ambiente**: Configuraciones específicas para development, staging y production
- **Variables centralizadas**: Todas las configuraciones en archivos `.env` organizados
- **Validación automática**: Scripts para verificar la integridad de la configuración
- **Integración Docker Hub**: Configuración completa para registry edissonz8809
- **Sistema IPs dinámicas**: Variables para el sistema de actualización automática

## Estructura de Archivos

```
scripts/
├── .env                           # Configuración base (todas las variables)
├── .env.development              # Overrides para desarrollo
├── .env.staging                  # Overrides para staging
├── .env.production               # Overrides para producción
├── .env.current                  # Ambiente actualmente activo
├── .docker-hub-config            # Credenciales Docker Hub (no en git)
├── core/
│   └── load-env-enhanced.sh      # Script mejorado de carga de variables
├── validation/
│   └── validate-env-variables.sh # Validación completa de variables
└── utilities/
    ├── docker-hub-config.sh      # Gestión configuración Docker Hub
    ├── migrate-env-config.sh     # Migración desde sistema anterior
    └── env-system-status.sh      # Estado del sistema de variables
```

## Uso Básico

### Cargar Variables de Entorno

```bash
# Cargar ambiente de desarrollo (default)
source scripts/core/load-env-enhanced.sh

# Cargar ambiente específico
source scripts/core/load-env-enhanced.sh production

# Cargar con validación
source scripts/core/load-env-enhanced.sh staging --validate

# Cargar y mostrar variables
source scripts/core/load-env-enhanced.sh development --show
```

### Validar Configuración

```bash
# Validar ambiente actual
./scripts/validation/validate-env-variables.sh

# Validar ambiente específico
./scripts/validation/validate-env-variables.sh production

# Validar todos los ambientes
./scripts/validation/validate-env-variables.sh all

# Validar y exportar configuración
./scripts/validation/validate-env-variables.sh development --export
```

### Estado del Sistema

```bash
# Estado básico
./scripts/utilities/env-system-status.sh

# Estado detallado
./scripts/utilities/env-system-status.sh --detailed

# Exportar configuración
./scripts/utilities/env-system-status.sh --export
```

## Variables Principales

### WebLogic Servers

```bash
WEBLOGIC_A_EXTERNAL_PORT=7001          # Puerto WebLogic A
WEBLOGIC_B_EXTERNAL_PORT=7002          # Puerto WebLogic B
WEBLOGIC_ADMIN_PASSWORD=welcome1       # Password admin
WEBLOGIC_A_CONTAINER_NAME=weblogic-a   # Nombre contenedor A
WEBLOGIC_B_CONTAINER_NAME=weblogic-b   # Nombre contenedor B
```

### HAProxy Load Balancer

```bash
HAPROXY_HTTP_EXTERNAL_PORT=8083        # Puerto HTTP
HAPROXY_HTTPS_EXTERNAL_PORT=8444       # Puerto HTTPS
HAPROXY_STATS_EXTERNAL_PORT=8404       # Puerto estadísticas
HAPROXY_UI_EXTERNAL_PORT=8082          # Puerto interfaz admin
HAPROXY_API_EXTERNAL_PORT=8081         # Puerto API (CORREGIDO)
HAPROXY_STATS_USER=admin               # Usuario stats
HAPROXY_STATS_PASSWORD=admin123        # Password stats
```

### Oracle Database

```bash
ORACLE_EXTERNAL_PORT=1521              # Puerto principal
ORACLE_EM_EXTERNAL_PORT=5500           # Puerto Enterprise Manager
ORACLE_ADMIN_PASSWORD=welcome1         # Password admin
ORACLE_SID=XE                          # SID de la base
ORACLE_PDB=XEPDB1                      # Pluggable database
```

### Docker Hub Integration

```bash
DOCKER_REGISTRY=docker.io              # Registry
DOCKER_NAMESPACE=edissonz8809          # Namespace
DOCKER_USERNAME=edissonz8809           # Usuario
WEBLOGIC_FULL_IMAGE=edissonz8809/weblogic-feature-flags:v1.0.0
HAPROXY_FULL_IMAGE=edissonz8809/haproxy-advanced:v1.1.0
ORACLE_FULL_IMAGE=edissonz8809/oracle-setup:v1.0.0
MKDOCS_FULL_IMAGE=edissonz8809/mkdocs-server:v1.0.0
```

### Sistema IPs Dinámicas

```bash
ENABLE_DYNAMIC_IP_UPDATE=true          # Habilitar sistema
HAPROXY_IP_UPDATE_TIMEOUT=30           # Timeout actualización
HAPROXY_RELOAD_WAIT_TIME=3             # Tiempo espera reload
ENABLE_IP_UPDATE_LOGGING=true          # Logging habilitado
HAPROXY_CONFIG_BACKUP_ENABLED=true     # Backup configuración
```

## Configuración por Ambiente

### Development
- Debug habilitado
- SSL deshabilitado
- Logging verbose
- Recursos limitados
- Todas las features habilitadas para testing

### Staging
- Configuración intermedia
- SSL habilitado
- Testing completo
- Recursos moderados
- Validación pre-producción

### Production
- Máxima seguridad
- SSL obligatorio
- Logging optimizado
- Recursos completos
- Features estables únicamente

## Gestión Docker Hub

### Configurar Credenciales

```bash
# Configuración interactiva
./scripts/utilities/docker-hub-config.sh setup

# Con parámetros
./scripts/utilities/docker-hub-config.sh setup --username edissonz8809 --namespace edissonz8809
```

### Login/Logout

```bash
# Login
./scripts/utilities/docker-hub-config.sh login

# Logout
./scripts/utilities/docker-hub-config.sh logout

# Estado
./scripts/utilities/docker-hub-config.sh status
```

### Validar Configuración

```bash
# Test completo
./scripts/utilities/docker-hub-config.sh validate

# Test conectividad
./scripts/utilities/docker-hub-config.sh test

# Listar repositorios
./scripts/utilities/docker-hub-config.sh list-repos
```

## Migración desde Sistema Anterior

Si tienes configuraciones del sistema anterior, puedes migrar:

```bash
# Crear backup y migrar
./scripts/utilities/migrate-env-config.sh --backup --migrate

# Solo validar migración
./scripts/utilities/migrate-env-config.sh --validate

# Rollback si hay problemas
./scripts/utilities/migrate-env-config.sh --rollback
```

## Integración con Scripts Existentes

Los scripts existentes se actualizan automáticamente para usar el nuevo sistema:

```bash
# manage-services.sh usa automáticamente las nuevas variables
./scripts/services/manage-services.sh start

# auto-update-haproxy.sh usa las variables de IPs dinámicas
./scripts/maintenance/auto-update-haproxy.sh
```

## Validaciones Automáticas

El sistema incluye validaciones para:

- ✅ **Variables críticas**: Verificación de variables obligatorias
- ✅ **Puertos únicos**: No hay conflictos de puertos
- ✅ **Rangos válidos**: Puertos en rangos permitidos
- ✅ **Formato imágenes**: Sintaxis correcta de imágenes Docker
- ✅ **Conectividad**: Acceso a Docker Hub
- ✅ **Scripts disponibles**: Archivos necesarios presentes

## URLs de Acceso

Con la configuración por defecto:

| Servicio | URL | Puerto |
|----------|-----|--------|
| Load Balancer | http://localhost:8083 | 8083 |
| HAProxy Stats | http://localhost:8404/stats | 8404 |
| HAProxy Admin | http://localhost:8082 | 8082 |
| HAProxy API | http://localhost:8081 | 8081 |
| WebLogic A | http://localhost:7001/console | 7001 |
| WebLogic B | http://localhost:7002/console | 7002 |
| Oracle EM | http://localhost:5500/em | 5500 |
| Documentation | http://localhost:8000 | 8000 |

## Troubleshooting

### Error: Variables no definidas

```bash
# Verificar carga de variables
source scripts/core/load-env-enhanced.sh development --validate

# Validar configuración completa
./scripts/validation/validate-env-variables.sh development
```

### Error: Puertos en uso

```bash
# Verificar puertos ocupados
netstat -tlnp | grep -E ":(7001|7002|8081|8082|8083|8404|1521|5500|8000)"

# Cambiar puertos en archivo .env correspondiente
```

### Error: Docker Hub no accesible

```bash
# Verificar configuración
./scripts/utilities/docker-hub-config.sh status

# Test conectividad
./scripts/utilities/docker-hub-config.sh test

# Reconfigurar si es necesario
./scripts/utilities/docker-hub-config.sh setup
```

### Error: Scripts no encontrados

```bash
# Verificar estado del sistema
./scripts/utilities/env-system-status.sh --detailed

# Migrar configuración si es necesario
./scripts/utilities/migrate-env-config.sh --backup --migrate
```

## Mejores Prácticas

1. **Siempre usar source**: `source scripts/core/load-env-enhanced.sh`
2. **Validar después de cambios**: `./scripts/validation/validate-env-variables.sh`
3. **Backup antes de migrar**: `--backup` en scripts de migración
4. **Usar ambientes específicos**: No mezclar configuraciones
5. **Mantener .gitignore**: Excluir archivos con credenciales
6. **Documentar cambios**: Actualizar este archivo con modificaciones

## Estado Actual del Proyecto

- ✅ **Variables centralizadas**: 100% implementado
- ✅ **Multi-ambiente**: Funcional (dev/staging/prod)
- ✅ **Docker Hub**: Configurado (requiere login)
- ✅ **IPs dinámicas**: Variables integradas
- ✅ **Validación**: Sistema completo
- ✅ **Migración**: Scripts disponibles
- ✅ **Documentación**: Completa

## Próximos Pasos

1. Completar login Docker Hub
2. Reestructurar directorio applications/
3. Implementar CI/CD pipeline
4. Configurar monitoreo avanzado
5. Optimizar configuraciones de producción

---

**Nota**: Este sistema es parte de la **Fase 3** del proyecto (Docker Hub Integration) y está **75% completo** según el seguimiento de progreso.
