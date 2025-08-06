# Guía de Uso de Scripts

Esta guía explica cómo usar los scripts más importantes del proyecto.

## Scripts Principales

### Configuración Inicial
```bash
# Configurar el proyecto por primera vez
./setup.sh

# Cargar variables de entorno
source scripts/core/load-env.sh
```

### Gestión de Servicios
```bash
# Iniciar todos los servicios
./start-all.sh

# Gestionar servicios individualmente
./manage-services.sh

# Detener todos los servicios
./stop-all-services.sh
```

### Despliegue
```bash
# Despliegue completo
./scripts/deployment/deploy-complete.sh

# Desplegar WAR específico
./deploy-war.sh <nombre-war>

# Limpiar cachés
./scripts/deployment/clear-all-caches.sh
```

### Canary Deployment
```bash
# Configurar canary
./setup-canary.sh

# Controlar tráfico
./canary-control.sh 50  # 50% de tráfico

# Probar canary
./test-canary.sh
```

### Validación y Testing
```bash
# Ejecutar todos los tests
./scripts/validation/run-all-tests.sh

# Validación rápida
./scripts/quick-validate.sh

# Verificar URLs
./scripts/validation/check-urls.sh
```

### Mantenimiento
```bash
# Limpieza completa
./scripts/maintenance/cleanup-all.sh

# Diagnóstico del sistema
./scripts/maintenance/diagnose-and-fix.sh

# Organizar proyecto
./scripts/maintenance/organize-scripts.sh
```

## Variables de Entorno

Los scripts utilizan las siguientes variables principales:

- `WEBLOGIC_ADMIN_USER`: Usuario administrador de WebLogic
- `WEBLOGIC_ADMIN_PASSWORD`: Contraseña del administrador
- `HAPROXY_PORT`: Puerto de HAProxy
- `WEBLOGIC_PORT_A`: Puerto del servidor WebLogic A
- `WEBLOGIC_PORT_B`: Puerto del servidor WebLogic B

## Troubleshooting

### Problemas Comunes

1. **Scripts sin permisos**: Ejecutar `./scripts/quick-validate.sh`
2. **Enlaces rotos**: Ejecutar `./scripts/maintenance/fix-references.sh`
3. **Servicios no responden**: Ejecutar `./scripts/maintenance/diagnose-and-fix.sh`

### Logs

Los logs se encuentran en:
- `logs/weblogic/`: Logs de WebLogic
- `logs/haproxy/`: Logs de HAProxy
- `logs/scripts/`: Logs de scripts

