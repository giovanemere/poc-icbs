# Índice de Scripts - Organizado

Este documento proporciona una descripción de todos los scripts disponibles en el proyecto, organizados por categorías.

## 📁 Estructura de Directorios

```
scripts/
├── core/           # Scripts fundamentales del sistema
├── services/       # Gestión de servicios y contenedores
├── deployment/     # Scripts de despliegue
├── canary/         # Gestión de despliegues canary
├── maintenance/    # Mantenimiento y limpieza
├── validation/     # Validación y testing
├── utilities/      # Utilidades generales
├── docs/          # Gestión de documentación
├── monitoring/    # Monitoreo y métricas
└── build/         # Scripts de construcción
```

## 🔧 Scripts Core

### scripts/core/
- `load-env.sh` - Carga variables de entorno desde .env
- `docker-compose-wrapper.sh` - Wrapper para docker-compose con variables de entorno
- `setup.sh` - Script de configuración inicial del proyecto
- `run.sh` - Script principal para ejecutar el proyecto

## 🚀 Scripts de Servicios

### scripts/services/
- `manage-services.sh` - Gestión completa de servicios Docker
- `start-all.sh` - Iniciar todos los servicios
- `stop-all-services.sh` - Detener todos los servicios
- `start-with-auto-update.sh` - Iniciar con actualización automática
- `find-free-port.sh` - Encontrar puerto libre dinámicamente
- `start-haproxy-dynamic.sh` - Iniciar HAProxy con puerto dinámico
- `minikube-port-forwards.sh` - Gestión de port-forwards de Minikube

## 📦 Scripts de Despliegue

### scripts/deployment/
- `deploy-complete.sh` - Despliegue completo del sistema
- `deploy-war.sh` - Desplegar archivos WAR específicos
- `clear-all-caches.sh` - Limpiar todas las cachés
- `clear-weblogic-cache.sh` - Limpiar caché de WebLogic
- `clear-haproxy-cache.sh` - Limpiar caché de HAProxy

## 🎯 Scripts Canary

### scripts/canary/
- `setup-canary.sh` - Configurar despliegue canary
- `canary-control.sh` - Controlar porcentaje de tráfico canary
- `test-canary.sh` - Probar despliegue canary
- `manage-traffic.sh` - Gestionar tráfico entre versiones
- `simulate-traffic.sh` - Simular tráfico para pruebas

## 🔧 Scripts de Mantenimiento

### scripts/maintenance/
- `organize-scripts.sh` - Organizar estructura de scripts
- `cleanup-all.sh` - Limpieza completa del entorno
- `diagnose-and-fix.sh` - Diagnóstico y reparación del sistema
- `update-system-config.sh` - Actualizar configuración del sistema
- `auto-update-haproxy.sh` - Actualización automática de HAProxy
- `organize-project.sh` - Organizar estructura del proyecto
- `fix-references.sh` - Corregir referencias rotas
- `update_dashboard.sh` - Actualizar dashboard

## ✅ Scripts de Validación

### scripts/validation/
- `validate-complete-system.sh` - Validación completa del sistema
- `test-integration.sh` - Tests de integración
- `test-performance.sh` - Tests de rendimiento
- `check-urls.sh` - Verificar URLs del sistema
- `run-all-tests.sh` - Ejecutar todos los tests

## 🛠️ Scripts de Utilidades

### scripts/utilities/
- `debug-haproxy.sh` - Debug de HAProxy
- `verify-icbs-ports.sh` - Verificar puertos ICBS
- `haproxy-ip-updater.py` - Actualizar IPs de HAProxy

## 📚 Scripts de Documentación

### scripts/docs/
- `build-docs.sh` - Construir documentación
- `setup-docs.sh` - Configurar entorno de documentación
- `setup-haproxy-mkdocs.sh` - Configurar HAProxy para MkDocs
- `apply-haproxy-mkdocs.sh` - Aplicar configuración HAProxy-MkDocs
- `manage-docs-haproxy.sh` - Gestionar documentación con HAProxy
- `generate-docs.sh` - Generar documentación automáticamente
- `update-scripts-index.sh` - Actualizar índice de scripts

## 🏗️ Scripts de Build

### scripts/build/
- `build.sh` - Build principal del proyecto
- `build-local.sh` - Build local de proyectos WAR
- `build-wars.sh` - Construir archivos WAR
- `create-simple-wars.sh` - Crear archivos WAR simples

## 📊 Scripts de Monitoreo

### scripts/monitoring/
- Scripts de monitoreo y métricas (en desarrollo)

## 👥 Scripts de Usuarios

### scripts/users/
- `create-users.sh` - Crear usuarios en WebLogic
- `assign-roles.sh` - Asignar roles a usuarios

## 🔗 Enlaces Simbólicos en Raíz

Los siguientes scripts tienen enlaces simbólicos en la raíz del proyecto para facilitar el acceso:

- `build.sh` → `scripts/build/build.sh`
- `setup.sh` → `scripts/core/setup.sh`
- `run.sh` → `scripts/core/run.sh`
- `manage-services.sh` → `scripts/services/manage-services.sh`
- `start-all.sh` → `scripts/services/start-all.sh`
- `deploy-war.sh` → `scripts/deployment/deploy-war.sh`
- `setup-canary.sh` → `scripts/canary/setup-canary.sh`
- `canary-control.sh` → `scripts/canary/canary-control.sh`
- `test-canary.sh` → `scripts/canary/test-canary.sh`

## 🚀 Uso Rápido

### Comandos más comunes:
```bash
# Configuración inicial
./setup.sh

# Iniciar todos los servicios
./start-all.sh

# Desplegar aplicación
./deploy-war.sh

# Configurar canary
./setup-canary.sh

# Ejecutar tests
./scripts/validation/run-all-tests.sh

# Limpiar sistema
./scripts/maintenance/cleanup-all.sh
```

## 📝 Notas

- Todos los scripts tienen permisos de ejecución
- Los scripts cargan automáticamente las variables de entorno desde `.env`
- Se recomienda ejecutar `./scripts/validation/run-all-tests.sh` después de cambios importantes
- Para debugging, usar `./scripts/utilities/debug-haproxy.sh`

