# 📚 Documentación MkDocs - Guía Completa

Esta guía te explica cómo trabajar con la documentación consolidada del proyecto usando MkDocs.

## 🚀 Configuración Inicial (Solo Una Vez)

### 1. Ejecutar Setup Automático

```bash
./setup-docs.sh
```

Este script configura automáticamente:
- ✅ Entorno virtual Python
- ✅ Instalación de MkDocs y plugins
- ✅ Verificación de dependencias
- ✅ Estructura de directorios
- ✅ Archivos de configuración
- ✅ Scripts de utilidad

### 2. Verificar Instalación

```bash
./build-docs.sh validate
```

## 📖 Estructura de Documentación Consolidada

### 🗂️ Archivos Principales (7 archivos)

```
docs/
├── 🏠 index.md                    # Página principal
├── 🚀 getting-started.md          # Instalación + Configuración
├── 🏗️ arquitectura.md             # Diseño del sistema
├── 📦 deployment.md               # Despliegue completo
├── 🎯 canary-and-features.md      # Canary + Feature Flags
├── ⚖️ haproxy.md                  # Load Balancer
└── 🆘 support.md                  # Troubleshooting + FAQ
```

### 📁 Archivos de Respaldo

Los archivos originales están en `docs/_old_files/` por si necesitas consultar algo específico.

## 🛠️ Comandos de Trabajo

### Desarrollo Diario

```bash
# Servir documentación con auto-reload
./build-docs.sh serve
# Disponible en: http://localhost:8000

# Construir sitio estático
./build-docs.sh build

# Validar antes de commit
./build-docs.sh validate
```

### Comandos Adicionales

```bash
# Ver estadísticas
./build-docs.sh stats

# Limpiar archivos generados
./build-docs.sh clean

# Ver ayuda completa
./build-docs.sh help
```

### Activar Entorno Manualmente

```bash
# Activar entorno de documentación
./activate-docs-env.sh

# O manualmente:
source mkdocs-env/bin/activate
mkdocs serve
```

## 📝 Flujo de Trabajo Típico

### 1. Primera Vez
```bash
# Solo una vez por proyecto
./setup-docs.sh
```

### 2. Desarrollo
```bash
# Servir con auto-reload
./build-docs.sh serve

# Editar archivos en docs/
# Los cambios se ven automáticamente en http://localhost:8000
```

### 3. Antes de Commit
```bash
# Validar documentación
./build-docs.sh validate

# Ver estadísticas
./build-docs.sh stats
```

### 4. Producción
```bash
# Construir sitio final
./build-docs.sh build

# El sitio estático queda en site/
```

## 🎯 Beneficios de la Consolidación

### ✅ Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Archivos** | 14 archivos dispersos | 7 archivos consolidados |
| **Navegación** | Compleja, muchos saltos | Simple, contenido relacionado junto |
| **Mantenimiento** | Difícil, información fragmentada | Fácil, información cohesiva |
| **Búsqueda** | Resultados dispersos | Resultados más relevantes |
| **UX** | Confusa para nuevos usuarios | Clara y progresiva |

### 📊 Métricas de Mejora

- **50% menos archivos** (14 → 7)
- **27% menos líneas** pero sin pérdida de información
- **Navegación simplificada** con emojis y estructura clara
- **Mejor experiencia de usuario** con flujo lógico

## 🔧 Configuración Avanzada

### Archivos de Configuración

```
├── mkdocs.yml              # Configuración principal
├── mkdocs-dev.yml          # Configuración de desarrollo
├── requirements.txt        # Dependencias Python
├── .gitignore             # Archivos a ignorar
└── mkdocs-env/            # Entorno virtual
```

### Personalización

#### Cambiar Puerto de Desarrollo

```bash
# Editar build-docs.sh
SERVE_PORT=8080
```

#### Agregar Plugins

```bash
# Activar entorno
source mkdocs-env/bin/activate

# Instalar plugin
pip install mkdocs-new-plugin

# Agregar a mkdocs.yml
plugins:
  - new-plugin
```

#### Personalizar Tema

```yaml
# En mkdocs.yml
theme:
  name: material
  palette:
    primary: blue
    accent: blue
```

## 🐛 Solución de Problemas

### Error: "Entorno virtual no encontrado"

```bash
# Solución: Ejecutar setup inicial
./setup-docs.sh
```

### Error: "MkDocs no está instalado"

```bash
# Verificar entorno virtual
source mkdocs-env/bin/activate
pip list | grep mkdocs

# Si no está, reinstalar
./setup-docs.sh
```

### Error: "Puerto en uso"

```bash
# Cambiar puerto en build-docs.sh
SERVE_PORT=8001

# O matar proceso existente
lsof -ti:8000 | xargs kill -9
```

### Problemas de Permisos

```bash
# Dar permisos a scripts
chmod +x *.sh

# Verificar permisos de directorios
ls -la docs/
```

## 📚 Recursos Adicionales

### Documentación Oficial

- [MkDocs](https://www.mkdocs.org/)
- [Material Theme](https://squidfunk.github.io/mkdocs-material/)
- [Mermaid Plugin](https://github.com/fralau/mkdocs-mermaid2-plugin)

### Sintaxis Markdown

```markdown
# Título 1
## Título 2

**Negrita** y *cursiva*

- Lista item 1
- Lista item 2

```bash
# Bloque de código
comando --help
```

!!! tip "Consejo"
    Usa admonitions para destacar información importante

!!! warning "Advertencia"
    Información crítica que el usuario debe saber

!!! info "Información"
    Detalles adicionales útiles
```

### Diagramas Mermaid

```mermaid
graph LR
    A[Usuario] --> B[HAProxy]
    B --> C[WebLogic]
    C --> D[Base de Datos]
```

## 🎉 ¡Listo para Trabajar!

Con esta configuración tienes:

- ✅ **Documentación consolidada** y bien organizada
- ✅ **Entorno de desarrollo** completo y automatizado
- ✅ **Scripts de utilidad** para todas las tareas comunes
- ✅ **Flujo de trabajo** optimizado y eficiente
- ✅ **Configuración robusta** con manejo de errores

### Comandos Esenciales para Recordar

```bash
# Primera vez (solo una vez)
./setup-docs.sh

# Desarrollo diario
./build-docs.sh serve

# Antes de commit
./build-docs.sh validate

# Producción
./build-docs.sh build
```

¡Ahora puedes enfocarte en crear contenido excelente sin preocuparte por la configuración técnica! 🚀
