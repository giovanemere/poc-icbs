# Referencia de Scripts

## Scripts por Funcionalidad

### 🔧 Core (Fundamentales)
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `setup.sh` | Configuración inicial del proyecto | `scripts/core/` |
| `run.sh` | Script principal de ejecución | `scripts/core/` |
| `load-env.sh` | Carga variables de entorno | `scripts/core/` |

### 🚀 Servicios
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `manage-services.sh` | Gestión completa de servicios | `scripts/services/` |
| `start-all.sh` | Iniciar todos los servicios | `scripts/services/` |
| `stop-all-services.sh` | Detener todos los servicios | `scripts/services/` |

### 📦 Despliegue
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `deploy-complete.sh` | Despliegue completo | `scripts/deployment/` |
| `deploy-war.sh` | Desplegar WAR específico | `scripts/deployment/` |
| `clear-all-caches.sh` | Limpiar todas las cachés | `scripts/deployment/` |

### 🎯 Canary
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `setup-canary.sh` | Configurar canary deployment | `scripts/canary/` |
| `canary-control.sh` | Controlar tráfico canary | `scripts/canary/` |
| `test-canary.sh` | Probar canary deployment | `scripts/canary/` |

### 🔧 Mantenimiento
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `cleanup-all.sh` | Limpieza completa del sistema | `scripts/maintenance/` |
| `diagnose-and-fix.sh` | Diagnóstico y reparación | `scripts/maintenance/` |
| `organize-scripts.sh` | Organizar estructura de scripts | `scripts/maintenance/` |

### ✅ Validación
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `run-all-tests.sh` | Ejecutar todos los tests | `scripts/validation/` |
| `validate-complete-system.sh` | Validación completa | `scripts/validation/` |
| `check-urls.sh` | Verificar URLs del sistema | `scripts/validation/` |

### 📚 Documentación
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `build-docs.sh` | Construir documentación | `scripts/docs/` |
| `setup-docs.sh` | Configurar entorno de docs | `scripts/docs/` |
| `setup-haproxy-mkdocs.sh` | Configurar HAProxy para docs | `scripts/docs/` |

## Variables de Entorno Importantes

```bash
# WebLogic
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome1
WEBLOGIC_PORT_A=7001
WEBLOGIC_PORT_B=7002

# HAProxy
HAPROXY_PORT=8080
HAPROXY_STATS_PORT=8404

# Paths
PROJECT_ROOT=/path/to/project
SCRIPTS_DIR=$PROJECT_ROOT/scripts
```

## Comandos de Uso Frecuente

```bash
# Validación rápida
./scripts/quick-validate.sh

# Configuración inicial
./setup.sh

# Iniciar servicios
./start-all.sh

# Desplegar aplicación
./deploy-war.sh

# Configurar canary
./setup-canary.sh

# Ejecutar tests completos
./scripts/validation/run-all-tests.sh

# Limpieza completa
./scripts/maintenance/cleanup-all.sh
```

## Troubleshooting

### Problemas Comunes

1. **Scripts sin permisos**: `./scripts/quick-validate.sh`
2. **Enlaces rotos**: `./scripts/maintenance/fix-references.sh`
3. **Servicios no responden**: `./scripts/maintenance/diagnose-and-fix.sh`
4. **Errores de sintaxis**: Revisar logs y ejecutar `bash -n script.sh`

### Logs

- WebLogic: `logs/weblogic/`
- HAProxy: `logs/haproxy/`
- Scripts: `logs/scripts/`
