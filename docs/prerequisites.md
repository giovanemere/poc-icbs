# Prerequisitos del Proyecto Docker Oracle WebLogic

## Requisitos del Sistema

### Hardware
- **RAM**: Mínimo 8GB disponible (recomendado 16GB)
- **Disco**: Mínimo 20GB de espacio libre
- **CPU**: Procesador multi-core (recomendado 4+ cores)

### Software
- **Docker**: Versión 19.03 o superior
- **Docker Compose**: Versión 1.27 o superior
- **Sistema Operativo**: Linux (Ubuntu/CentOS/RHEL), macOS, o Windows con WSL2

## Archivos Requeridos

### 1. Oracle WebLogic Server
**Archivo**: `fmw_14.1.1.0.0_wls_Disk1_1of1.zip`
- **Descripción**: Oracle Fusion Middleware WebLogic Server 14.1.1.0.0
- **Tamaño**: ~1GB
- **Ubicación**: `docker/weblogic/installers/`
- **Fuente**: Oracle Technology Network (OTN)
- **Licencia**: Requiere aceptar términos de licencia de Oracle

### 2. Oracle SQL Command Line (SQLcl)
**Archivo**: `sqlcl-25.2.2.199.0918.zip`
- **Descripción**: Oracle SQL Command Line Interface
- **Tamaño**: ~50MB
- **Ubicación**: `oracle/installers/`
- **Fuente**: Oracle Technology Network (OTN)
- **Uso**: Herramienta para ejecutar scripts SQL y administrar la base de datos

### 3. Scripts de Base de Datos Demo
**Archivo**: `demo_oracle.ddl`
- **Descripción**: Scripts DDL para crear esquemas y datos de demostración
- **Ubicación**: `oracle/scripts/setup/`
- **Uso**: Inicialización de la base de datos con datos de prueba

### 4. Archivo de Configuración de Variables de Entorno
**Archivo**: `.env`
- **Descripción**: Variables de entorno para configurar todos los servicios
- **Ubicación**: Directorio raíz del proyecto (`./`)
- **Contenido**: Configuraciones de Oracle, WebLogic, HAProxy, puertos, credenciales, etc.
- **Generación**: Se crea automáticamente con el script de prerequisitos

## Estructura de Directorios Requerida

```
docker-for-oracle-weblogic/
├── .env                                    # Variables de entorno
├── docker/
│   └── weblogic/
│       └── installers/
│           └── fmw_14.1.1.0.0_wls_Disk1_1of1.zip
├── oracle/
│   ├── installers/
│   │   └── sqlcl-25.2.2.199.0918.zip
│   └── scripts/
│       └── setup/
│           └── demo_oracle.ddl
└── ...
```

## Instrucciones de Instalación

### Paso 1: Crear Estructura de Directorios

```bash
# Desde el directorio raíz del proyecto
mkdir -p docker/weblogic/installers
mkdir -p oracle/installers
mkdir -p oracle/scripts/setup
```

### Paso 2: Mover Archivos a sus Ubicaciones

```bash
# Mover desde /home/giovanemere/periferia/icbs/install
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Mover WebLogic Server
mv /home/giovanemere/periferia/icbs/install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip docker/weblogic/installers/

# Mover SQLcl
mv /home/giovanemere/periferia/icbs/install/sqlcl-25.2.2.199.0918.zip oracle/installers/

# Mover scripts de demo
mv /home/giovanemere/periferia/icbs/install/demo_oracle.ddl oracle/scripts/setup/
```

### Paso 3: Verificar Archivos

```bash
# Verificar que los archivos estén en las ubicaciones correctas
ls -la docker/weblogic/installers/
ls -la oracle/installers/
ls -la oracle/scripts/setup/
```

## Verificación de Prerequisitos

### Script de Verificación

Crear un script para verificar que todos los prerequisitos estén cumplidos:

```bash
#!/bin/bash
# scripts/check-prerequisites.sh

echo "=== Verificación de Prerequisitos ==="

# Verificar Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "✓ Docker encontrado: $DOCKER_VERSION"
else
    echo "✗ Docker no encontrado"
    exit 1
fi

# Verificar Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "✓ Docker Compose encontrado: $COMPOSE_VERSION"
else
    echo "✗ Docker Compose no encontrado"
    exit 1
fi

# Verificar archivos requeridos
echo ""
echo "=== Verificación de Archivos ==="

if [ -f "docker/weblogic/installers/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" ]; then
    echo "✓ WebLogic Server installer encontrado"
else
    echo "✗ WebLogic Server installer no encontrado en docker/weblogic/installers/"
fi

if [ -f "oracle/installers/sqlcl-25.2.2.199.0918.zip" ]; then
    echo "✓ SQLcl installer encontrado"
else
    echo "✗ SQLcl installer no encontrado en oracle/installers/"
fi

if [ -f "oracle/scripts/setup/demo_oracle.ddl" ]; then
    echo "✓ Scripts de demo encontrados"
else
    echo "✗ Scripts de demo no encontrados en oracle/scripts/setup/"
fi

# Verificar recursos del sistema
echo ""
echo "=== Verificación de Recursos ==="

# RAM disponible
AVAILABLE_RAM=$(free -g | awk 'NR==2{printf "%.1f", $7}')
echo "RAM disponible: ${AVAILABLE_RAM}GB"

# Espacio en disco
AVAILABLE_DISK=$(df -h . | awk 'NR==2{print $4}')
echo "Espacio en disco disponible: $AVAILABLE_DISK"

echo ""
echo "=== Verificación Completada ==="
```

## Descarga de Archivos

### Oracle WebLogic Server
1. Visita [Oracle Technology Network](https://www.oracle.com/middleware/technologies/weblogic-server-downloads.html)
2. Acepta los términos de licencia
3. Descarga `fmw_14.1.1.0.0_wls_Disk1_1of1.zip`

### Oracle SQLcl
1. Visita [Oracle SQLcl Downloads](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/)
2. Descarga la versión más reciente (25.2.2.199.0918 o superior)

### Scripts de Demo
Los scripts de demo pueden ser:
- Proporcionados por el equipo de desarrollo
- Generados automáticamente durante la instalación
- Descargados desde el repositorio del proyecto

## Notas Importantes

1. **Licencias**: Asegúrate de tener las licencias apropiadas para Oracle WebLogic Server y Oracle Database
2. **Conectividad**: Algunos pasos pueden requerir acceso a internet para descargar dependencias adicionales
3. **Permisos**: Asegúrate de tener permisos de escritura en los directorios del proyecto
4. **Firewall**: Los puertos especificados en el README principal deben estar disponibles

## Solución de Problemas

### Error: Archivo no encontrado durante build
- Verifica que los archivos estén en las ubicaciones correctas
- Verifica los permisos de lectura de los archivos

### Error: Espacio insuficiente en disco
- Libera espacio en disco
- Considera usar un disco externo o aumentar el espacio disponible

### Error: RAM insuficiente
- Cierra aplicaciones innecesarias
- Considera aumentar la RAM del sistema o usar swap
