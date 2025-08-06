#!/bin/bash

# Script para organizar y mejorar la estructura del proyecto

set -e

echo "🚀 Organizando estructura del proyecto..."

# Crear directorios necesarios
echo "📁 Creando estructura de directorios..."

# Directorios para documentación
mkdir -p docs/assets/images
mkdir -p docs/assets/diagrams
mkdir -p docs/assets/screenshots

# Directorios para scripts organizados
mkdir -p scripts/build
mkdir -p scripts/deploy
mkdir -p scripts/canary
mkdir -p scripts/monitoring
mkdir -p scripts/utils

# Directorios para configuraciones
mkdir -p config/weblogic
mkdir -p config/haproxy
mkdir -p config/database
mkdir -p config/ff4j

# Directorios para logs organizados
mkdir -p logs/weblogic
mkdir -p logs/haproxy
mkdir -p logs/application

# Directorios para backups
mkdir -p backup/configs
mkdir -p backup/database
mkdir -p backup/applications

echo "📋 Creando archivos README para cada directorio..."

# README para scripts
cat > scripts/README.md << 'EOF'
# Scripts del Proyecto

Esta carpeta contiene todos los scripts organizados por categoría.

## Estructura

- `build/` - Scripts de construcción y compilación
- `deploy/` - Scripts de despliegue
- `canary/` - Scripts para despliegues canary
- `monitoring/` - Scripts de monitoreo y métricas
- `utils/` - Utilidades y herramientas auxiliares

## Uso

Todos los scripts deben ejecutarse desde la raíz del proyecto.

```bash
# Ejemplo
./scripts/build/build-all.sh
./scripts/deploy/deploy-war.sh myapp.war
```
EOF

# README para config
cat > config/README.md << 'EOF'
# Configuraciones del Proyecto

Esta carpeta contiene todas las configuraciones organizadas por componente.

## Estructura

- `weblogic/` - Configuraciones de WebLogic Server
- `haproxy/` - Configuraciones del load balancer
- `database/` - Scripts y configuraciones de base de datos
- `ff4j/` - Configuraciones de Feature Flags

## Archivos de Configuración

- `.properties` - Archivos de propiedades Java
- `.cfg` - Archivos de configuración HAProxy
- `.sql` - Scripts de base de datos
- `.xml` - Archivos de configuración XML
EOF

# README para logs
cat > logs/README.md << 'EOF'
# Logs del Sistema

Esta carpeta contiene todos los logs organizados por componente.

## Estructura

- `weblogic/` - Logs de WebLogic Server
- `haproxy/` - Logs del load balancer
- `application/` - Logs de aplicaciones

## Rotación de Logs

Los logs se rotan automáticamente para evitar que crezcan demasiado.

## Monitoreo

Usa `tail -f` para monitorear logs en tiempo real:

```bash
tail -f logs/weblogic/server.log
tail -f logs/haproxy/access.log
```
EOF

echo "🖼️ Creando imágenes de ejemplo..."

# Crear un logo simple usando texto ASCII
cat > docs/assets/images/weblogic-logo.txt << 'EOF'
 _    _      _     _                 _      
| |  | |    | |   | |               (_)     
| |  | | ___| |__ | |     ___   __ _ _  ___ 
| |/\| |/ _ \ '_ \| |    / _ \ / _` | |/ __|
\  /\  /  __/ |_) | |___| (_) | (_| | | (__ 
 \/  \/ \___|_.__/|______\___/ \__, |_|\___|
                                __/ |       
                               |___/        
EOF

# Crear archivo de configuración para imágenes
cat > docs/assets/images/README.md << 'EOF'
# Imágenes y Assets

Esta carpeta contiene todas las imágenes y recursos visuales de la documentación.

## Estructura

- `logos/` - Logos y branding
- `diagrams/` - Diagramas exportados
- `screenshots/` - Capturas de pantalla
- `icons/` - Iconos y elementos gráficos

## Formatos Recomendados

- **PNG**: Para capturas de pantalla y imágenes con transparencia
- **JPG**: Para fotografías y imágenes complejas
- **SVG**: Para logos, iconos y diagramas vectoriales

## Optimización

Todas las imágenes deben estar optimizadas para web:

- Tamaño máximo: 1920x1080
- Calidad: 80-90% para JPG
- Compresión: PNG-8 cuando sea posible
EOF

echo "📊 Creando archivos de configuración mejorados..."

# Archivo de configuración principal
cat > config/project.properties << 'EOF'
# Configuración Principal del Proyecto
# ====================================

# Información del Proyecto
project.name=Docker Oracle WebLogic
project.version=1.0.0
project.description=Proyecto Docker para Oracle WebLogic con Canary Deployment

# Configuración de Entorno
environment=development
debug.enabled=true
logging.level=INFO

# Configuración de Red
network.name=weblogic_network
network.subnet=172.20.0.0/16

# Puertos Base
ports.weblogic.admin=7001
ports.weblogic.managed.start=7003
ports.haproxy.main=8080
ports.haproxy.stats=8404
ports.database=1521

# Configuración de Recursos
resources.memory.weblogic=2g
resources.memory.database=1g
resources.cpu.limit=2
EOF

# Configuración de desarrollo
cat > config/development.properties << 'EOF'
# Configuración de Desarrollo
# ===========================

# Hot Deployment
hot.deployment.enabled=true
auto.deployment.enabled=true
deployment.timeout=300

# Debug
debug.port=5005
debug.suspend=false
jvm.debug.enabled=true

# Logging
logging.level=DEBUG
logging.console.enabled=true
logging.file.enabled=true

# Feature Flags
ff4j.console.enabled=true
ff4j.audit.enabled=true
ff4j.monitoring.enabled=true
EOF

echo "🔧 Creando scripts de utilidades..."

# Script de limpieza
cat > scripts/utils/cleanup.sh << 'EOF'
#!/bin/bash

# Script de limpieza del proyecto

echo "🧹 Limpiando proyecto..."

# Limpiar contenedores
echo "Deteniendo contenedores..."
docker-compose down

# Limpiar imágenes no utilizadas
echo "Limpiando imágenes Docker..."
docker image prune -f

# Limpiar logs antiguos
echo "Limpiando logs antiguos..."
find logs/ -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Limpiar archivos temporales
echo "Limpiando archivos temporales..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.bak" -delete 2>/dev/null || true

# Limpiar target de Maven
echo "Limpiando builds de Maven..."
find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Limpieza completada"
EOF

# Script de verificación de salud
cat > scripts/utils/health-check.sh << 'EOF'
#!/bin/bash

# Script de verificación de salud del sistema

echo "🏥 Verificando salud del sistema..."

# Verificar Docker
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker no está instalado o no funciona"
    exit 1
fi

# Verificar Docker Compose
if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ Docker Compose no está instalado"
    exit 1
fi

# Verificar servicios
echo "📊 Estado de servicios:"
docker-compose ps

# Verificar conectividad
echo "🌐 Verificando conectividad:"
services=("localhost:8080" "localhost:7001" "localhost:8404")
for service in "${services[@]}"; do
    if timeout 5 bash -c "</dev/tcp/${service/:/ }" 2>/dev/null; then
        echo "✅ $service - OK"
    else
        echo "❌ $service - FAIL"
    fi
done

# Verificar uso de recursos
echo "💾 Uso de recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo "✅ Verificación completada"
EOF

# Hacer scripts ejecutables
chmod +x scripts/utils/*.sh

echo "📝 Creando documentación de estructura..."

# Actualizar README principal con nueva estructura
cat > STRUCTURE.md << 'EOF'
# Estructura del Proyecto

```
docker-for-oracle-weblogic/
├── 📁 backup/                     # Backups del sistema
│   ├── configs/                   # Backups de configuraciones
│   ├── database/                  # Backups de base de datos
│   └── applications/              # Backups de aplicaciones
├── 📁 config/                     # Configuraciones organizadas
│   ├── weblogic/                  # Configuraciones WebLogic
│   ├── haproxy/                   # Configuraciones HAProxy
│   ├── database/                  # Scripts de base de datos
│   ├── ff4j/                      # Configuraciones Feature Flags
│   ├── project.properties         # Configuración principal
│   └── development.properties     # Configuración de desarrollo
├── 📁 docs/                       # Documentación MkDocs
│   ├── assets/                    # Recursos de documentación
│   │   ├── images/               # Imágenes y logos
│   │   ├── diagrams/             # Diagramas
│   │   └── screenshots/          # Capturas de pantalla
│   ├── index.md                   # Página principal
│   ├── installation.md            # Guía de instalación
│   ├── arquitectura.md            # Arquitectura del sistema
│   └── ...                        # Otras páginas
├── 📁 logs/                       # Logs organizados
│   ├── weblogic/                  # Logs de WebLogic
│   ├── haproxy/                   # Logs de HAProxy
│   └── application/               # Logs de aplicaciones
├── 📁 scripts/                    # Scripts organizados
│   ├── build/                     # Scripts de construcción
│   ├── deploy/                    # Scripts de despliegue
│   ├── canary/                    # Scripts de canary
│   ├── monitoring/                # Scripts de monitoreo
│   └── utils/                     # Utilidades
├── 📁 war-projects/               # Proyectos de aplicaciones
├── 📁 haproxy/                    # Configuración HAProxy
├── 📁 oracle/                     # Configuración Oracle
├── 📄 docker-compose.yml          # Definición de servicios
├── 📄 mkdocs.yml                  # Configuración documentación
├── 📄 build-docs.sh               # Script para documentación
├── 📄 organize-project.sh         # Este script
└── 📄 README.md                   # Documentación principal
```

## Convenciones

### Nomenclatura de Archivos
- Scripts: `kebab-case.sh`
- Configuraciones: `snake_case.properties`
- Documentación: `kebab-case.md`

### Estructura de Scripts
- Todos los scripts deben tener header con descripción
- Usar `set -e` para fallar rápido
- Incluir mensajes informativos con emojis

### Documentación
- Usar Markdown estándar
- Incluir ejemplos de código
- Agregar diagramas Mermaid cuando sea útil
EOF

echo "🎨 Configurando Git hooks..."

# Crear directorio de hooks si no existe
mkdir -p .git/hooks

# Hook pre-commit para verificar documentación
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook para verificar documentación

echo "🔍 Verificando documentación antes del commit..."

# Verificar que MkDocs puede construir
if [ -f "mkdocs.yml" ]; then
    if ! ./build-docs.sh build > /dev/null 2>&1; then
        echo "❌ Error al construir documentación"
        echo "   Ejecuta: ./build-docs.sh build"
        exit 1
    fi
fi

echo "✅ Documentación verificada"
EOF

chmod +x .git/hooks/pre-commit 2>/dev/null || true

echo "✅ Organización del proyecto completada!"
echo ""
echo "📋 Resumen de cambios:"
echo "   ✅ Estructura de directorios creada"
echo "   ✅ Archivos README agregados"
echo "   ✅ Scripts de utilidades creados"
echo "   ✅ Configuraciones organizadas"
echo "   ✅ Documentación de estructura creada"
echo "   ✅ Git hooks configurados"
echo ""
echo "🚀 Próximos pasos:"
echo "   1. Revisar la nueva estructura en STRUCTURE.md"
echo "   2. Ejecutar: ./build-docs.sh serve"
echo "   3. Personalizar configuraciones en config/"
echo "   4. Agregar imágenes a docs/assets/images/"
echo ""
echo "📖 Documentación disponible en: http://localhost:8000"
EOF
