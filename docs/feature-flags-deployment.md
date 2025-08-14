# Guía de Despliegue y Ejecución de Feature Flags

Esta guía proporciona instrucciones detalladas sobre cómo compilar, desplegar y ejecutar la aplicación Feature Flags en diferentes entornos.

## Índice

1. [Compilación y Despliegue en WebLogic](#compilación-y-despliegue-en-weblogic)
   - [Despliegue Básico](#despliegue-básico)
   - [Despliegue con Script Específico](#despliegue-con-script-específico)
   - [Redespliegue Limpio](#redespliegue-limpio)
   - [Script Interactivo de Compilación y Despliegue](#script-interactivo-de-compilación-y-despliegue)
2. [Ejecución Local para Desarrollo](#ejecución-local-para-desarrollo)
   - [Configuración de Jetty](#configuración-de-jetty)
   - [Ejecución con Script](#ejecución-con-script)
3. [Actualización de Clases sin Redespliegue](#actualización-de-clases-sin-redespliegue)
4. [Solución de Problemas Comunes](#solución-de-problemas-comunes)

## Compilación y Despliegue en WebLogic

### Despliegue Básico

El método más directo para compilar y desplegar la aplicación Feature Flags:

```bash
# Navegar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags

# Compilar el proyecto con Maven
mvn clean package

# Copiar el archivo WAR generado al directorio de despliegue
cp target/feature-flags.war ../../deploy/

# Desplegar en WebLogic
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/deploy/deploy-war.sh deploy/feature-flags.war
```

### Despliegue con Script Específico

Utiliza el script específico para Feature Flags que automatiza el proceso:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de despliegue de feature-flags
./scripts/deploy/deploy-feature-flags.sh
```

### Redespliegue Limpio

Si necesitas asegurarte de que no haya problemas de caché, puedes usar el script de redespliegue limpio:

```bash
# Navegar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags

# Compilar el proyecto con Maven
mvn clean package

# Copiar el archivo WAR generado al directorio de despliegue
cp target/feature-flags.war ../../deploy/

# Navegar al directorio raíz y hacer un redespliegue limpio
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/deploy/clean-redeploy.sh feature-flags
```

### Script Interactivo de Compilación y Despliegue

Este script combina la compilación y te da la opción de hacer un redespliegue limpio o normal:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script interactivo
./scripts/deploy/build-deploy-feature-flags.sh
```

El script te preguntará si deseas hacer un redespliegue limpio o un despliegue normal.

## Ejecución Local para Desarrollo

### Configuración de Jetty

El proyecto está configurado para ejecutarse localmente con Jetty. La configuración se encuentra en el archivo `pom.xml`:

```xml
<plugin>
    <groupId>org.eclipse.jetty</groupId>
    <artifactId>jetty-maven-plugin</artifactId>
    <version>9.4.44.v20210927</version>
    <configuration>
        <scanIntervalSeconds>2</scanIntervalSeconds>
        <webApp>
            <contextPath>/feature-flags</contextPath>
        </webApp>
        <httpConnector>
            <port>9090</port>
        </httpConnector>
    </configuration>
</plugin>
```

### Ejecución con Script

Para ejecutar la aplicación localmente con Jetty:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de ejecución local
./scripts/deploy/run-local-feature-flags.sh
```

La aplicación estará disponible en: http://localhost:9090/feature-flags/

## Actualización de Clases sin Redespliegue

Si estás haciendo cambios frecuentes en el código y no quieres redesplegar toda la aplicación cada vez, puedes usar el script de actualización de clases:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar el script de actualización de clases
./scripts/deploy/update-feature-flags-classes.sh
```

Este script:
1. Compila solo las clases Java
2. Actualiza las clases en los servidores WebLogic sin redespliegue completo
3. Fuerza una recarga de las clases en la próxima solicitud

## Solución de Problemas Comunes

### Problema: La aplicación no se actualiza después del despliegue

**Síntomas**: La aplicación sigue mostrando el comportamiento anterior después del despliegue.

**Soluciones**:

1. **Limpiar la caché del navegador**:
   - Presiona Ctrl+F5 o Cmd+Shift+R para forzar una recarga completa
   - O utiliza el modo incógnito/privado del navegador

2. **Forzar un redespliegue limpio**:
   ```bash
   ./scripts/deploy/clean-redeploy.sh feature-flags
   ```

### Problema: Error al compilar el proyecto

**Síntomas**: Maven muestra errores durante la compilación.

**Soluciones**:

1. **Verificar dependencias**:
   ```bash
   cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags
   mvn dependency:tree
   ```

2. **Limpiar el repositorio local de Maven**:
   ```bash
   mvn dependency:purge-local-repository
   ```

3. **Verificar la versión de Java**:
   ```bash
   java -version
   ```
   Asegúrate de que estás usando Java 8 o superior.

### Problema: La aplicación local no se inicia

**Síntomas**: Jetty muestra errores al iniciar la aplicación localmente.

**Soluciones**:

1. **Verificar que el puerto no esté en uso**:
   ```bash
   netstat -tuln | grep 9090
   ```
   Si el puerto está en uso, cambia el puerto en el archivo `pom.xml`.

2. **Verificar permisos**:
   ```bash
   ls -la /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags
   ```
   Asegúrate de que tienes permisos de lectura y escritura en el directorio del proyecto.

### Problema: Las clases actualizadas no se cargan

**Síntomas**: Los cambios en el código no se reflejan después de usar el script de actualización de clases.

**Soluciones**:

1. **Verificar que las clases se compilaron correctamente**:
   ```bash
   ls -la /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags/target/classes
   ```

2. **Forzar una recarga manual**:
   ```bash
   # Encontrar el directorio de despliegue
   docker exec -it weblogic-a find /u01/oracle/user_projects/domains/base_domain -name "feature-flags" -type d | grep -v "tmp" | grep -v "cache"
   
   # Tocar el archivo weblogic.xml
   docker exec -it weblogic-a touch /ruta/encontrada/WEB-INF/weblogic.xml
   ```

3. **Reiniciar la aplicación desde la consola de WebLogic**:
   - Accede a la consola de administración: http://localhost:7001/console
   - Navega a "Despliegues"
   - Selecciona "feature-flags"
   - Haz clic en "Detener" y luego en "Iniciar"
