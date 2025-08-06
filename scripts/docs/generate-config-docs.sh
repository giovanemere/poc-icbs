#!/bin/bash
# Script para generar documentación de configuración

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"

echo "🔧 Generando documentación de configuración..."

# Crear documentación de configuración
cat > "$DOCS_DIR/configuration.md" << 'EOCONFIG'
# Configuración del Sistema

## Variables de Entorno

El sistema utiliza un archivo `.env` para centralizar toda la configuración.

### WebLogic Servers
```bash
WEBLOGIC_A_PORT=7001
WEBLOGIC_B_PORT=7002
WEBLOGIC_ADMIN_PASSWORD=welcome1
```

### HAProxy Configuration
```bash
HAPROXY_HTTP_PORT=8083
HAPROXY_HTTPS_PORT=8444
HAPROXY_STATS_PORT=8404
HAPROXY_UI_PORT=8082
```

### Oracle Database
```bash
ORACLE_EXTERNAL_PORT=1521
ORACLE_EM_EXTERNAL_PORT=5500
ORACLE_ADMIN_PASSWORD=welcome1
```

### Documentation
```bash
MKDOCS_EXTERNAL_PORT=8000
```

## Archivos de Configuración

### docker-compose.yml
Ubicado en `config/docker-compose.yml`, define todos los servicios Docker.

### haproxy.cfg
Ubicado en `haproxy/config/haproxy.cfg`, configuración del load balancer.

### mkdocs.yml
Configuración de la documentación con MkDocs Material.

## Scripts de Gestión

### Comando Principal
```bash
./manage-services.sh [comando]
```

Comandos disponibles:
- `start` - Iniciar servicios
- `stop` - Detener servicios
- `status` - Ver estado
- `logs` - Ver logs
- `config` - Mostrar configuración

EOCONFIG

echo "✅ Documentación de configuración generada"
