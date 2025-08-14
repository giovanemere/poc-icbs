# Guía Detallada de Scripts de Construcción

Esta guía proporciona instrucciones detalladas sobre cómo utilizar los scripts de construcción disponibles en el proyecto Docker para Oracle WebLogic.

## Índice

1. [Script Principal de Construcción (build.sh)](#script-principal-de-construcción-buildsh)
2. [Construcción de Archivos WAR (build-wars.sh)](#construcción-de-archivos-war-build-warssh)
3. [Creación de Aplicaciones WAR Simples (create-simple-wars.sh)](#creación-de-aplicaciones-war-simples-create-simple-warssh)
4. [Construcción de Feature Flags (build-feature-flags.sh)](#construcción-de-feature-flags-build-feature-flagssh)
5. [Solución de Problemas Comunes](#solución-de-problemas-comunes)

## Script Principal de Construcción (build.sh)

El script `build.sh` es el punto de entrada principal para construir todo el entorno, incluyendo las aplicaciones WAR y las imágenes Docker.

### Uso

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de construcción
./scripts/build/build.sh
```

### Requisitos Previos

Antes de ejecutar el script, asegúrate de que los siguientes archivos estén presentes en el directorio `install/`:

- `fmw_14.1.1.0.0_wls_Disk1_1of1.zip` - Instalador de Oracle WebLogic Server
- `sqlcl-25.2.2.199.0918.zip` - Oracle SQL Developer Command Line

Si estos archivos no están presentes, el script mostrará un error y se detendrá.

### Qué Hace

1. Verifica la presencia de los archivos de instalación necesarios
2. Compila todas las aplicaciones WAR llamando a `build-wars.sh`
3. Construye las imágenes Docker utilizando `docker-compose build`

### Ejemplo de Salida

```
=== Construyendo imagen Docker para Oracle WebLogic ===

Compilando aplicaciones WAR...
=== Construyendo archivos WAR ===

Construyendo Feature Flags...
...
Construyendo versiones A y B para Canary...
...
Construyendo FF4J Simple...
...

=== Construcción de WARs completada ===

Los archivos WAR se encuentran en el directorio deploy/

-rw-r--r-- 1 user user 12345 Jul 22 10:00 deploy/feature-flags.war
-rw-r--r-- 1 user user  5678 Jul 22 10:00 deploy/ff4j-simple.war
-rw-r--r-- 1 user user  2345 Jul 22 10:00 deploy/weblogic-features-a.war
-rw-r--r-- 1 user user  2345 Jul 22 10:00 deploy/weblogic-features-b.war

Construyendo imagen Docker...
...

=== Construcción completada ===

Para iniciar los contenedores, ejecute:
  docker-compose -f config/docker-compose.yml up -d
```

## Construcción de Archivos WAR (build-wars.sh)

Este script compila todas las aplicaciones WAR necesarias para el proyecto.

### Uso

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de construcción de WARs
./scripts/build/build-wars.sh
```

### Qué Hace

1. Crea el directorio `deploy/` si no existe
2. Compila la aplicación Feature Flags
3. Crea las aplicaciones para pruebas A/B y Canary (weblogic-features-a y weblogic-features-b)
4. Crea la aplicación FF4J Simple

### Aplicaciones Generadas

- `feature-flags.war` - Aplicación para gestionar feature flags
- `weblogic-features-a.war` - Versión A para pruebas A/B y Canary
- `weblogic-features-b.war` - Versión B para pruebas A/B y Canary
- `ff4j-simple.war` - Aplicación simple de FF4J

## Creación de Aplicaciones WAR Simples (create-simple-wars.sh)

Este script crea aplicaciones WAR simples con páginas HTML básicas.

### Uso

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Crear una aplicación WAR simple (reemplaza "nombre-aplicacion" con el nombre deseado)
./scripts/build/create-simple-wars.sh nombre-aplicacion

# Ejemplos:
./scripts/build/create-simple-wars.sh version-a
./scripts/build/create-simple-wars.sh version-b
./scripts/build/create-simple-wars.sh mi-aplicacion
```

### Parámetros

- `nombre-aplicacion`: Nombre de la aplicación WAR a crear (obligatorio)

### Qué Hace

1. Crea una estructura de directorios temporal
2. Genera un archivo `web.xml` básico
3. Crea páginas HTML (`index.html` e `info.html`) con estilos específicos según el nombre:
   - Si el nombre contiene "-a", se usa un tema verde (Versión A)
   - Si el nombre contiene "-b", se usa un tema azul (Versión B)
   - De lo contrario, se usa un tema naranja
4. Empaqueta todo en un archivo WAR
5. Copia el archivo WAR al directorio `deploy/`
6. También copia los archivos fuente al directorio `war-projects/nombre-aplicacion/`

### Ejemplo de Salida

```
=== Creando archivo WAR simple: version-a ===

Creando archivo WAR...

=== Creación de version-a.war completada ===

El archivo WAR se encuentra en deploy/version-a.war
```

## Construcción de Feature Flags (build-feature-flags.sh)

Este script compila específicamente la aplicación Feature Flags desde el código fuente.

### Uso

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Compilar la aplicación Feature Flags
./scripts/build/build-feature-flags.sh
```

### Qué Hace

1. Navega al directorio del proyecto Feature Flags
2. Compila el proyecto utilizando Maven
3. Copia el archivo WAR resultante al directorio `deploy/`

### Requisitos Previos

- Maven debe estar instalado en el sistema
- El código fuente de Feature Flags debe estar presente en `war-projects/feature-flags/`

## Construcción de Aplicaciones Específicas

Si deseas construir solo una aplicación específica, puedes utilizar los siguientes comandos:

### Feature Flags

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/build-feature-flags.sh
```

### Versión A

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/create-simple-wars.sh version-a
```

### Versión B

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/create-simple-wars.sh version-b
```

### WebLogic Features A

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/create-simple-wars.sh weblogic-features-a
```

### WebLogic Features B

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/create-simple-wars.sh weblogic-features-b
```

## Solución de Problemas Comunes

### Error: No se encontró el archivo de instalación

Si ves un error como:
```
Error: No se encontró el archivo install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip
```

**Solución**: Descarga el archivo desde el sitio web de Oracle y colócalo en el directorio `install/` del proyecto.

### Error: Fallo en la compilación de Maven

Si ves errores relacionados con Maven durante la compilación de Feature Flags:

**Solución**:
1. Verifica que Maven esté instalado:
   ```bash
   mvn --version
   ```
2. Verifica que el código fuente esté presente:
   ```bash
   ls -la war-projects/feature-flags/
   ```
3. Intenta compilar manualmente:
   ```bash
   cd war-projects/feature-flags/
   mvn clean package
   ```

### Error: No se puede crear el directorio deploy

**Solución**:
1. Verifica los permisos:
   ```bash
   ls -la /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/
   ```
2. Crea el directorio manualmente:
   ```bash
   mkdir -p /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/deploy
   chmod 755 /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/deploy
   ```

### Error: Fallo en la construcción de Docker

Si hay errores durante la construcción de las imágenes Docker:

**Solución**:
1. Verifica que Docker esté en ejecución:
   ```bash
   docker info
   ```
2. Verifica que docker-compose esté instalado:
   ```bash
   docker-compose --version
   ```
3. Intenta construir manualmente:
   ```bash
   cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/
   docker-compose -f config/docker-compose.yml build
   ```
