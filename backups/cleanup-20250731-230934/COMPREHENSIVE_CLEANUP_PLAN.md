# 🧹 PLAN INTEGRAL DE LIMPIEZA Y REORGANIZACIÓN

**Fecha:** $(date)
**Objetivo:** Limpiar completamente la raíz y reorganizar archivos dispersos
**Problema:** Archivos .py, .txt, .sh y otros desorganizados en raíz

## 🔍 ANÁLISIS DE ARCHIVOS ENCONTRADOS

### Archivos Identificados en Raíz:
- `fix_dashboard.py` - Script Python para dashboard HAProxy
- `browser-cache-instructions.txt` - Instrucciones para usuarios
- `docker-compose.yml.backup` - Backup de configuración Docker
- `requirements.txt` - Dependencias Python (esencial)
- `.env.example` - Ejemplo de variables (esencial)

## 📋 ESTRATEGIA DE REORGANIZACIÓN

### 🎯 FASE 1: CLASIFICACIÓN DE ARCHIVOS

#### ✅ Archivos ESENCIALES (mantener en raíz):
- `requirements.txt` - Necesario para instalación Python
- `.env.example` - Template de configuración
- `docker-compose.yml` - Configuración principal
- `Dockerfile*` - Configuraciones de contenedores
- `mkdocs.yml` - Configuración de documentación
- `README.md` - Documentación principal
- `LICENSE` - Licencia del proyecto

#### 📁 Archivos a REORGANIZAR:

1. **Scripts Python** → `scripts/python/`
   - `fix_dashboard.py` → `scripts/python/fix_dashboard.py`

2. **Documentación de Usuario** → `docs/user-guides/`
   - `browser-cache-instructions.txt` → `docs/user-guides/browser-cache-guide.md`

3. **Backups y Temporales** → `backup/`
   - `docker-compose.yml.backup` → `backup/docker-compose/`

4. **Archivos de Configuración** → `config/`
   - Archivos de configuración específicos

### 🎯 FASE 2: ACTUALIZACIÓN DE SERVICIOS

#### Servicios que usan estos archivos:
1. **HAProxy Dashboard** - usa `fix_dashboard.py`
2. **Documentación MkDocs** - puede referenciar instrucciones
3. **Docker Compose** - puede usar backups

#### Actualizaciones necesarias:
1. **Actualizar referencias** en scripts que usan estos archivos
2. **Crear enlaces simbólicos** si es necesario para compatibilidad
3. **Actualizar documentación** con nuevas ubicaciones
4. **Modificar scripts de servicios** para usar nuevas rutas

### 🎯 FASE 3: ESTRUCTURA OBJETIVO

```
Raíz del proyecto (LIMPIA):
├── 📄 README.md                    # Documentación principal
├── 📄 LICENSE                      # Licencia
├── 📄 .env.example                 # Template de configuración
├── 📄 .gitignore                   # Control de versiones
├── 📄 docker-compose.yml           # Configuración Docker principal
├── 📄 Dockerfile*                  # Configuraciones de contenedores
├── 📄 mkdocs.yml                   # Configuración MkDocs
├── 📄 requirements.txt             # Dependencias Python
├── 🔗 [enlaces simbólicos .sh]     # Scripts principales accesibles
├── 📁 scripts/                     # Scripts organizados
│   ├── 📁 python/                  # Scripts Python
│   │   ├── 📄 fix_dashboard.py
│   │   └── 📄 [otros scripts .py]
│   └── 📁 [otras categorías]
├── 📁 docs/                        # Documentación
│   ├── 📁 user-guides/             # Guías de usuario
│   │   ├── 📄 browser-cache-guide.md
│   │   └── 📄 [otras guías]
│   └── 📁 [otras secciones]
├── 📁 config/                      # Configuraciones
├── 📁 backup/                      # Backups y temporales
│   └── 📁 docker-compose/
└── 📁 [otras carpetas organizadas]
```

## 🛠️ PLAN DE EJECUCIÓN

### Paso 1: Crear Estructura de Carpetas
```bash
mkdir -p scripts/python
mkdir -p docs/user-guides
mkdir -p backup/docker-compose
mkdir -p config
```

### Paso 2: Mover Archivos
```bash
# Scripts Python
mv fix_dashboard.py scripts/python/

# Documentación de usuario
mv browser-cache-instructions.txt docs/user-guides/browser-cache-guide.md

# Backups
mv docker-compose.yml.backup backup/docker-compose/
```

### Paso 3: Actualizar Referencias
- Buscar y actualizar scripts que referencien estos archivos
- Crear enlaces simbólicos si es necesario para compatibilidad
- Actualizar documentación

### Paso 4: Actualizar Servicios
- Modificar scripts de servicios para usar nuevas rutas
- Actualizar configuraciones Docker si es necesario
- Probar que todos los servicios funcionen correctamente

## 🔧 SERVICIOS A ACTUALIZAR

### 1. HAProxy Dashboard Service
- **Archivo afectado**: `fix_dashboard.py`
- **Nueva ubicación**: `scripts/python/fix_dashboard.py`
- **Acción**: Actualizar referencias en scripts de servicios

### 2. Documentación MkDocs
- **Archivo afectado**: `browser-cache-instructions.txt`
- **Nueva ubicación**: `docs/user-guides/browser-cache-guide.md`
- **Acción**: Convertir a Markdown y actualizar navegación

### 3. Docker Compose Services
- **Archivo afectado**: `docker-compose.yml.backup`
- **Nueva ubicación**: `backup/docker-compose/`
- **Acción**: Mantener como backup, no afecta servicios activos

## 📊 BENEFICIOS ESPERADOS

### ✅ Raíz Limpia
- Solo archivos esenciales para el funcionamiento
- Estructura profesional y mantenible
- Fácil navegación y comprensión

### ✅ Organización Lógica
- Scripts Python en carpeta dedicada
- Documentación de usuario organizada
- Backups en ubicación apropiada

### ✅ Servicios Actualizados
- Referencias correctas a archivos movidos
- Funcionalidad mantenida
- Mejor mantenibilidad

### ✅ Mantenibilidad
- Estructura clara para futuros desarrollos
- Fácil localización de archivos
- Separación lógica de responsabilidades

## 🚀 COMANDOS DE EJECUCIÓN

### Ejecutar limpieza completa:
```bash
./scripts/maintenance/comprehensive-cleanup.sh
```

### Validar después de limpieza:
```bash
./scripts/validation/validate-services-after-cleanup.sh
```

### Probar servicios:
```bash
./manage-services.sh start
./scripts/validation/test-all-services.sh
```

## ⚠️ CONSIDERACIONES IMPORTANTES

### Backup de Seguridad
- Crear backup completo antes de mover archivos
- Mantener posibilidad de rollback
- Documentar todos los cambios

### Testing Completo
- Probar todos los servicios después de cambios
- Validar que HAProxy dashboard funcione
- Verificar que documentación sea accesible

### Compatibilidad
- Mantener enlaces simbólicos si es necesario
- Actualizar scripts gradualmente
- Verificar que no se rompa funcionalidad existente

---

## 🎯 PRÓXIMO PASO

**Crear y ejecutar script de limpieza integral:**
```bash
./create-comprehensive-cleanup.sh
```

Este plan garantiza una limpieza completa manteniendo toda la funcionalidad.
