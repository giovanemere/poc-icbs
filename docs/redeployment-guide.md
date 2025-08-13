# Guía de Redespliegue y Gestión de Caché en WebLogic

Esta guía proporciona instrucciones detalladas sobre cómo borrar la caché de aplicaciones WAR, forzar el redespliegue en WebLogic y gestionar usuarios de forma automática.

## Índice

1. [Borrado de Caché y Redespliegue](#borrado-de-caché-y-redespliegue)
   - [Borrar Caché de Aplicaciones](#borrar-caché-de-aplicaciones)
   - [Forzar Redespliegue](#forzar-redespliegue)
   - [Redespliegue con Actualización de Clases](#redespliegue-con-actualización-de-clases)
2. [Scripts de Despliegue Automático](#scripts-de-despliegue-automático)
   - [Script de Limpieza y Redespliegue](#script-de-limpieza-y-redespliegue)
   - [Script de Despliegue con Actualización de Clases](#script-de-despliegue-con-actualización-de-clases)
3. [Gestión de Usuarios](#gestión-de-usuarios)
   - [Creación Automática de Usuarios](#creación-automática-de-usuarios)
   - [Asignación de Roles](#asignación-de-roles)
4. [Solución de Problemas Comunes](#solución-de-problemas-comunes)

## Borrado de Caché y Redespliegue

### Borrar Caché de Aplicaciones

WebLogic almacena en caché las aplicaciones desplegadas para mejorar el rendimiento. Para forzar una recarga completa, es necesario borrar esta caché.

#### Método 1: Borrado Manual desde la Consola de Administración

1. Accede a la consola de administración de WebLogic:
   - WebLogic A: `http://localhost:7001/console`
   - WebLogic B: `http://localhost:7002/console`

2. Navega a "Despliegues" en el panel izquierdo

3. Selecciona la aplicación que deseas actualizar

4. Haz clic en "Actualizar" y selecciona "Actualizar completamente esta aplicación"

#### Método 2: Borrado Mediante Script WLST

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de borrado de caché para una aplicación específica
./scripts/deploy/clear-cache.sh feature-flags
```

El script `clear-cache.sh` ejecuta comandos WLST para borrar la caché:

```python
# Contenido de clear-cache.sh (fragmento WLST)
connect('weblogic', 'welcome1', 't3://localhost:7001')
appName = sys.argv[1]
stopApplication(appName, timeout=60000)
startApplication(appName)
disconnect()
exit()
```

### Forzar Redespliegue

Para forzar un redespliegue completo de una aplicación, puedes utilizar los siguientes métodos:

#### Método 1: Redespliegue desde la Consola de Administración

1. Accede a la consola de administración de WebLogic
2. Navega a "Despliegues"
3. Selecciona la aplicación
4. Haz clic en "Redesplegar"

#### Método 2: Redespliegue Mediante Script

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Forzar redespliegue de una aplicación específica
./scripts/deploy/force-redeploy.sh deploy/feature-flags.war
```

El script `force-redeploy.sh` realiza las siguientes acciones:

1. Detiene la aplicación si está en ejecución
2. Elimina la aplicación del servidor
3. Despliega la aplicación nuevamente
4. Inicia la aplicación

### Redespliegue con Actualización de Clases

WebLogic permite actualizar las clases de una aplicación sin necesidad de un redespliegue completo, lo que es útil para cambios menores.

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Actualizar clases de una aplicación específica
./scripts/deploy/update-classes.sh feature-flags
```

## Scripts de Despliegue Automático

### Script de Limpieza y Redespliegue

A continuación se presenta un script completo para limpiar la caché y forzar el redespliegue de una aplicación:

```bash
#!/bin/bash
# Nombre del archivo: clean-redeploy.sh

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nombre-aplicacion>"
    echo "Ejemplo: $0 feature-flags"
    exit 1
fi

APP_NAME=$1
WAR_FILE="deploy/${APP_NAME}.war"

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que el archivo WAR existe
if [ ! -f "$WAR_FILE" ]; then
    echo -e "${RED}Error: El archivo $WAR_FILE no existe${NC}"
    exit 1
fi

echo -e "${YELLOW}Iniciando proceso de limpieza y redespliegue para $APP_NAME...${NC}"

# 1. Detener la aplicación en WebLogic A
echo -e "${YELLOW}Deteniendo $APP_NAME en WebLogic A...${NC}"
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    stopApplication('$APP_NAME', timeout=60000)
    print 'Aplicación detenida correctamente'
except:
    print 'La aplicación no estaba en ejecución o no existe'
disconnect()
exit()
"

# 2. Eliminar la aplicación de WebLogic A
echo -e "${YELLOW}Eliminando $APP_NAME de WebLogic A...${NC}"
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    undeploy('$APP_NAME')
    print 'Aplicación eliminada correctamente'
except:
    print 'La aplicación no existía'
disconnect()
exit()
"

# 3. Limpiar directorios de caché en WebLogic A
echo -e "${YELLOW}Limpiando directorios de caché en WebLogic A...${NC}"
docker exec -it weblogic-a rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$APP_NAME
docker exec -it weblogic-a rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/$APP_NAME

# 4. Desplegar la aplicación en WebLogic A
echo -e "${YELLOW}Desplegando $APP_NAME en WebLogic A...${NC}"
docker cp $WAR_FILE weblogic-a:/u01/oracle/user_projects/domains/base_domain/autodeploy/

# 5. Repetir el proceso para WebLogic B
echo -e "${YELLOW}Deteniendo $APP_NAME en WebLogic B...${NC}"
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    stopApplication('$APP_NAME', timeout=60000)
    print 'Aplicación detenida correctamente'
except:
    print 'La aplicación no estaba en ejecución o no existe'
disconnect()
exit()
"

echo -e "${YELLOW}Eliminando $APP_NAME de WebLogic B...${NC}"
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    undeploy('$APP_NAME')
    print 'Aplicación eliminada correctamente'
except:
    print 'La aplicación no existía'
disconnect()
exit()
"

echo -e "${YELLOW}Limpiando directorios de caché en WebLogic B...${NC}"
docker exec -it weblogic-b rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$APP_NAME
docker exec -it weblogic-b rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/$APP_NAME

echo -e "${YELLOW}Desplegando $APP_NAME en WebLogic B...${NC}"
docker cp $WAR_FILE weblogic-b:/u01/oracle/user_projects/domains/base_domain/autodeploy/

echo -e "${GREEN}Proceso de limpieza y redespliegue completado para $APP_NAME${NC}"
echo -e "${YELLOW}Espere unos momentos mientras WebLogic procesa el despliegue...${NC}"

# Esperar a que se complete el despliegue
sleep 10

echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "Acceda a la aplicación en: ${YELLOW}http://localhost:8080/$APP_NAME/${NC}"
```

Para utilizar este script:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Crear el script
cat > scripts/deploy/clean-redeploy.sh << 'EOF'
# Contenido del script aquí
EOF

# Dar permisos de ejecución
chmod +x scripts/deploy/clean-redeploy.sh

# Ejecutar el script
./scripts/deploy/clean-redeploy.sh feature-flags
```

### Script de Despliegue con Actualización de Clases

Este script permite actualizar solo las clases Java de una aplicación sin necesidad de un redespliegue completo:

```bash
#!/bin/bash
# Nombre del archivo: update-classes.sh

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nombre-aplicacion>"
    echo "Ejemplo: $0 feature-flags"
    exit 1
fi

APP_NAME=$1
CLASS_DIR="war-projects/${APP_NAME}/WEB-INF/classes"

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que el directorio de clases existe
if [ ! -d "$CLASS_DIR" ]; then
    echo -e "${RED}Error: El directorio $CLASS_DIR no existe${NC}"
    exit 1
fi

echo -e "${YELLOW}Iniciando actualización de clases para $APP_NAME...${NC}"

# 1. Encontrar el directorio de despliegue en WebLogic A
DEPLOY_DIR_A=$(docker exec -it weblogic-a find /u01/oracle/user_projects/domains/base_domain -name "$APP_NAME" -type d | grep -v "tmp" | grep -v "cache" | head -1)

if [ -z "$DEPLOY_DIR_A" ]; then
    echo -e "${RED}Error: No se encontró el directorio de despliegue para $APP_NAME en WebLogic A${NC}"
    exit 1
fi

echo -e "${YELLOW}Directorio de despliegue en WebLogic A: $DEPLOY_DIR_A${NC}"

# 2. Copiar las clases actualizadas a WebLogic A
echo -e "${YELLOW}Copiando clases actualizadas a WebLogic A...${NC}"
docker cp $CLASS_DIR/. weblogic-a:$DEPLOY_DIR_A/WEB-INF/classes/

# 3. Encontrar el directorio de despliegue en WebLogic B
DEPLOY_DIR_B=$(docker exec -it weblogic-b find /u01/oracle/user_projects/domains/base_domain -name "$APP_NAME" -type d | grep -v "tmp" | grep -v "cache" | head -1)

if [ -z "$DEPLOY_DIR_B" ]; then
    echo -e "${RED}Error: No se encontró el directorio de despliegue para $APP_NAME en WebLogic B${NC}"
    exit 1
fi

echo -e "${YELLOW}Directorio de despliegue en WebLogic B: $DEPLOY_DIR_B${NC}"

# 4. Copiar las clases actualizadas a WebLogic B
echo -e "${YELLOW}Copiando clases actualizadas a WebLogic B...${NC}"
docker cp $CLASS_DIR/. weblogic-b:$DEPLOY_DIR_B/WEB-INF/classes/

# 5. Tocar el archivo weblogic.xml para forzar una recarga
echo -e "${YELLOW}Forzando recarga de clases...${NC}"
docker exec -it weblogic-a touch $DEPLOY_DIR_A/WEB-INF/weblogic.xml
docker exec -it weblogic-b touch $DEPLOY_DIR_B/WEB-INF/weblogic.xml

echo -e "${GREEN}Actualización de clases completada para $APP_NAME${NC}"
echo -e "${YELLOW}Las clases se recargarán en la próxima solicitud a la aplicación${NC}"
```

Para utilizar este script:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Crear el script
cat > scripts/deploy/update-classes.sh << 'EOF'
# Contenido del script aquí
EOF

# Dar permisos de ejecución
chmod +x scripts/deploy/update-classes.sh

# Ejecutar el script
./scripts/deploy/update-classes.sh feature-flags
```

## Gestión de Usuarios

### Creación Automática de Usuarios

Para crear usuarios automáticamente en WebLogic, puedes utilizar el siguiente script:

```bash
#!/bin/bash
# Nombre del archivo: create-users.sh

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nombre-usuario> <contraseña> [descripción]"
    echo "Ejemplo: $0 testuser password123 \"Usuario de prueba\""
    exit 1
fi

USERNAME=$1
PASSWORD=$2
DESCRIPTION=${3:-"Usuario creado automáticamente"}

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Creando usuario $USERNAME en WebLogic A...${NC}"

# Crear usuario en WebLogic A
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if cmo.userExists('$USERNAME'):
        print 'El usuario $USERNAME ya existe, actualizando...'
        cmo.removeUser('$USERNAME')
    cmo.createUser('$USERNAME', '$PASSWORD', '$DESCRIPTION')
    print 'Usuario $USERNAME creado correctamente'
except Exception, e:
    print 'Error al crear usuario: ', e
disconnect()
exit()
"

echo -e "${YELLOW}Creando usuario $USERNAME en WebLogic B...${NC}"

# Crear usuario en WebLogic B
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if cmo.userExists('$USERNAME'):
        print 'El usuario $USERNAME ya existe, actualizando...'
        cmo.removeUser('$USERNAME')
    cmo.createUser('$USERNAME', '$PASSWORD', '$DESCRIPTION')
    print 'Usuario $USERNAME creado correctamente'
except Exception, e:
    print 'Error al crear usuario: ', e
disconnect()
exit()
"

echo -e "${GREEN}Usuario $USERNAME creado en ambos servidores WebLogic${NC}"
```

Para utilizar este script:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Crear el script
cat > scripts/users/create-users.sh << 'EOF'
# Contenido del script aquí
EOF

# Dar permisos de ejecución
chmod +x scripts/users/create-users.sh

# Ejecutar el script
./scripts/users/create-users.sh testuser password123 "Usuario de prueba"
```

### Asignación de Roles

Para asignar roles a los usuarios creados:

```bash
#!/bin/bash
# Nombre del archivo: assign-roles.sh

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nombre-usuario> <rol>"
    echo "Ejemplo: $0 testuser Administrators"
    exit 1
fi

USERNAME=$1
ROLE=$2

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Asignando rol $ROLE al usuario $USERNAME en WebLogic A...${NC}"

# Asignar rol en WebLogic A
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if not cmo.userExists('$USERNAME'):
        print 'Error: El usuario $USERNAME no existe'
    else:
        cmo.addMemberToGroup('$ROLE', '$USERNAME')
        print 'Rol $ROLE asignado correctamente al usuario $USERNAME'
except Exception, e:
    print 'Error al asignar rol: ', e
disconnect()
exit()
"

echo -e "${YELLOW}Asignando rol $ROLE al usuario $USERNAME en WebLogic B...${NC}"

# Asignar rol en WebLogic B
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if not cmo.userExists('$USERNAME'):
        print 'Error: El usuario $USERNAME no existe'
    else:
        cmo.addMemberToGroup('$ROLE', '$USERNAME')
        print 'Rol $ROLE asignado correctamente al usuario $USERNAME'
except Exception, e:
    print 'Error al asignar rol: ', e
disconnect()
exit()
"

echo -e "${GREEN}Rol $ROLE asignado al usuario $USERNAME en ambos servidores WebLogic${NC}"
```

Para utilizar este script:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Crear el script
cat > scripts/users/assign-roles.sh << 'EOF'
# Contenido del script aquí
EOF

# Dar permisos de ejecución
chmod +x scripts/users/assign-roles.sh

# Ejecutar el script
./scripts/users/assign-roles.sh testuser Administrators
```

## Solución de Problemas Comunes

### Problema: La aplicación no se actualiza después del redespliegue

**Síntomas**: La aplicación sigue mostrando el comportamiento anterior después del redespliegue.

**Soluciones**:

1. **Limpiar la caché del navegador**:
   - Presiona Ctrl+F5 o Cmd+Shift+R para forzar una recarga completa
   - O utiliza el modo incógnito/privado del navegador

2. **Verificar que el despliegue se completó**:
   ```bash
   # Verificar logs de WebLogic A
   docker logs weblogic-a | grep -i "deploy" | grep -i "feature-flags"
   
   # Verificar logs de WebLogic B
   docker logs weblogic-b | grep -i "deploy" | grep -i "feature-flags"
   ```

3. **Forzar un redespliegue completo**:
   ```bash
   ./scripts/deploy/clean-redeploy.sh feature-flags
   ```

### Problema: Error "ClassNotFoundException" después de actualizar clases

**Síntomas**: La aplicación muestra errores de clase no encontrada después de actualizar las clases.

**Soluciones**:

1. **Verificar la estructura de directorios**:
   - Asegúrate de que las clases estén en el directorio correcto que refleje la estructura de paquetes

2. **Realizar un redespliegue completo**:
   ```bash
   ./scripts/deploy/clean-redeploy.sh feature-flags
   ```

3. **Verificar permisos de archivos**:
   ```bash
   # Verificar permisos en WebLogic A
   docker exec -it weblogic-a ls -la /ruta/al/directorio/de/clases
   
   # Corregir permisos si es necesario
   docker exec -it weblogic-a chmod -R 755 /ruta/al/directorio/de/clases
   ```

### Problema: Error al crear usuarios o asignar roles

**Síntomas**: Los scripts de gestión de usuarios muestran errores.

**Soluciones**:

1. **Verificar la conexión a WebLogic**:
   ```bash
   # Probar conexión a WebLogic A
   docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
   connect('weblogic', 'welcome1', 't3://localhost:7001')
   print 'Conexión exitosa'
   disconnect()
   exit()
   "
   ```

2. **Verificar que el dominio esté en ejecución**:
   ```bash
   docker exec -it weblogic-a ps -ef | grep java
   ```

3. **Reiniciar el servidor si es necesario**:
   ```bash
   docker restart weblogic-a
   docker restart weblogic-b
   ```
