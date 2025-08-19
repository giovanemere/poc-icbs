# Configuración del Sistema

## Requisitos del Sistema

### Hardware Mínimo
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disco**: 50 GB disponibles
- **Red**: Conexión estable a internet

### Software Requerido
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- Bash shell

## Variables de Entorno

El sistema utiliza múltiples archivos de configuración:

### `.env` (Principal)
```bash
# Oracle Database
ORACLE_SID=ORCLCDB
ORACLE_PDB=ORCLPDB1
ORACLE_PWD=Oracle123

# WebLogic
ADMIN_PASSWORD=welcome1
DOMAIN_NAME=base_domain

# HAProxy
HAPROXY_STATS_USER=admin
HAPROXY_STATS_PASS=admin123
```

### `.env.integrated` (Integración)
Configuraciones específicas para el entorno integrado con múltiples servicios.

### `.env.registry` (Registry)
Configuraciones para el registry de imágenes Docker.

## Puertos del Sistema

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| HAProxy | 80 | HTTP principal |
| HAProxy | 443 | HTTPS |
| HAProxy Stats | 8404 | Dashboard de estadísticas |
| WebLogic 1 | 7001 | Instancia principal |
| WebLogic 2 | 7002 | Instancia secundaria |
| Oracle DB | 1521 | Base de datos |
| Oracle EM | 5500 | Enterprise Manager |

## Gestión de Servicios

### Scripts Principales

- `manage-services.sh` - Gestión general de servicios
- `manage-integrated.sh` - Gestión del entorno integrado
- `start-dashboard-integrated.sh` - Inicio con dashboard
- `cleanup-environment.sh` - Limpieza del entorno

### Comandos de Mantenimiento

```bash
# Backup de la base de datos
./manage-integrated-backup.sh create

# Actualización de IPs de HAProxy
./update-haproxy-ips.sh

# Reinicio completo del entorno
./manage-services.sh restart-all
```

Para más detalles sobre la configuración, consulta los [prerequisitos](prerequisites.md).
