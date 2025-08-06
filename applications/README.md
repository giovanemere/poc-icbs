# Applications Directory

Este directorio contiene todas las aplicaciones containerizadas del proyecto Docker WebLogic Oracle.

## 📁 Estructura Organizada

```
applications/
├── weblogic-feature-flags/    # Servidor WebLogic con Feature Flags
├── mkdocs-server/            # Servidor de documentación MkDocs
├── haproxy-advanced/         # Load balancer HAProxy avanzado
├── oracle-express-db/        # Base de datos Oracle Express
└── README.md                 # Este archivo
```

## 🎯 Estado de Aplicaciones

| Aplicación | Estado | Docker Hub | Tamaño |
|------------|--------|------------|--------|
| **WebLogic Feature Flags** | ✅ Completado | `edissonz8809/weblogic-feature-flags:v1.1.0` | 1.22GB |
| **MkDocs Server** | ✅ Completado | `edissonz8809/mkdocs-server:v1.1.0` | 310MB |
| **HAProxy Advanced** | ✅ Completado | `edissonz8809/haproxy-advanced:v1.1.0` | 87.9MB |
| **Oracle Express DB** | 🔄 Opcional | `edissonz8809/oracle-express-db:v1.1.0` | TBD |

## 🚀 Uso Rápido

### Opción 1: Docker Hub (Recomendado)
```bash
# Pull todas las imágenes
docker pull edissonz8809/mkdocs-server:v1.1.0
docker pull edissonz8809/haproxy-advanced:v1.1.0
docker pull edissonz8809/weblogic-feature-flags:v1.1.0

# Usar template Docker Hub
docker-compose -f docker-compose.dockerhub.yml up -d
```

### Opción 2: Build Local
```bash
# Build todas las aplicaciones
./scripts/docker-hub/build-all.sh

# Iniciar servicios
./manage-services.sh start
```

## 🔧 Desarrollo

Cada aplicación tiene su propia estructura:
- `Dockerfile` - Configuración del container
- `README.md` - Documentación específica
- `scripts/` - Scripts de build y deploy
- `config/` - Archivos de configuración
- `tests/` - Tests unitarios

## 📚 Documentación

- **Documentación completa**: http://localhost:8000
- **HAProxy Admin**: http://localhost:8404
- **WebLogic Console**: http://localhost:7001/console

---

**Última actualización**: 2025-08-01  
**Fase**: 3 - Docker Hub Integration (75% → 100%)
