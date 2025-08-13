# Docker para Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags

Este proyecto proporciona un entorno Docker para Oracle WebLogic con soporte para estrategias avanzadas de despliegue como Testing A/B, Canary Deployment y Feature Flags utilizando HAProxy. Incluye modo oscuro en las interfaces de usuario y herramientas para build local.

Verifica que los contenedores estén en ejecución:
```bash

Para uso diario
./manage-services.sh start    # Iniciar todo
./manage-services.sh status   # Ver estado
./manage-services.sh stop     # Detener todo

Para desarrollo/debugging
./manage-services.sh logs --follow haproxy  # Ver logs de HAProxy
./manage-services.sh restart                # Reiniciar rápido
./manage-services.sh update-haproxy         # Solo actualizar HAProxy

```
   
## Arquitectura del Sistema

```
                                  ┌─────────────┐
                                  │             │
                                  │   Cliente   │
                                  │             │
                                  └──────┬──────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                            HAProxy                                  │
│                      (172.23.0.5:80/443)                           │
│                                                                     │
└───┬─────────────────────────────────┬───────────────────────────┬───┘
    │                                 │                           │
    ▼                                 ▼                           ▼
┌─────────────┐                 ┌─────────────┐             ┌─────────────┐
│             │                 │             │             │             │
│ WebLogic A  │                 │ WebLogic B  │             │  API de     │
│(172.23.0.4) │                 │(172.23.0.3) │             │Administración│
│             │                 │             │             │(8081/8082)  │
└──────┬──────┘                 └──────┬──────┘             └─────────────┘
       │                               │
       └───────────────┬───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │               │
               │  Oracle DB    │
               │ (172.23.0.2)  │
               │               │
               └───────────────┘
```

### Puertos Expuestos

| Servicio | Puerto Interno | Puerto Externo | Descripción |
|----------|----------------|----------------|-------------|
| HAProxy | 80 | 8080 | HTTP Frontend |
| HAProxy | 443 | 8443 | HTTPS Frontend |
| HAProxy | 8404 | 8404 | Estadísticas de HAProxy |
| HAProxy | 8081 | 8081 | API de Administración |
| HAProxy | 8082 | 8082 | UI de Administración |
| WebLogic A | 7001 | 7001 | Consola de Administración A |
| WebLogic B | 7001 | 7002 | Consola de Administración B |
| Oracle DB | 1521 | 1521 | Listener de Oracle |
| Oracle DB | 5500 | 5500 | Enterprise Manager |

## URLs y Endpoints del Sistema

### URLs de Acceso Principal

| Componente | URL | Descripción |
|------------|-----|-------------|
| HAProxy Frontend | `http://localhost:8080` | Punto de entrada principal para todas las aplicaciones |
| HAProxy Stats | `http://localhost:8404/stats` | Interfaz de estadísticas de HAProxy (admin/admin123) |
| Panel de Administración | `http://localhost:8082` | Panel web para gestionar estrategias de despliegue |
| Dashboard Profesional | `http://localhost:8080/dashboard/` | Dashboard profesional de tráfico y monitoreo |
| Dashboard Directo | `http://localhost:8001/` | Acceso directo al dashboard (desarrollo/debug) |
| API de Administración | `http://localhost:8081/api` | API REST para configurar HAProxy dinámicamente |

### Consolas de Administración

| Componente | URL | Descripción |
|------------|-----|-------------|
| WebLogic A | `http://localhost:7001/console` | Consola de administración de WebLogic A |
| WebLogic B | `http://localhost:7002/console` | Consola de administración de WebLogic B |
| Oracle DB | `http://localhost:5500/em` | Enterprise Manager de Oracle Database |

### Aplicaciones a través de HAProxy

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| FF4J | `http://localhost:8080/ff4j-simple` | Aplicación FF4J |
| Feature Flags | `http://localhost:8080/feature-flags` | Aplicación de Feature Flags |
| WebLogic Features A | `http://localhost:8080/weblogic-features-a` | Versión A de la aplicación WebLogic Features |
| WebLogic Features B | `http://localhost:8080/weblogic-features-b` | Versión B de la aplicación WebLogic Features |
| Version A | `http://localhost:8080/version-a` | Versión A para pruebas de Canary/A-B |
| Version B | `http://localhost:8080/version-b` | Versión B para pruebas de Canary/A-B |

### Acceso Directo a Nodos

| Componente | URL | Descripción |
|------------|-----|-------------|
| WebLogic A | `http://172.23.0.4:7001` | Acceso directo al nodo WebLogic A |
| WebLogic B | `http://172.23.0.3:7001` | Acceso directo al nodo WebLogic B |
| HAProxy | `http://172.23.0.5:80` | Acceso directo al nodo HAProxy |
| Oracle DB | `http://172.23.0.2:1521` | Acceso directo a Oracle Database (puerto 1521) |

## Inicio Rápido

### 1. Construir y Desplegar el Entorno

```bash
# Clonar el repositorio (si aún no lo has hecho)
git clone <repositorio>
cd docker-for-oracle-weblogic

# Construir y desplegar los contenedores
./start-all.sh
```

### 2. Verificar que Todo Esté Funcionando

```bash
# Verificar que los contenedores estén en ejecución
docker-compose -f config/docker-compose.yml ps

# Verificar los logs de HAProxy
docker logs haproxy

# Verificar que todas las URLs estén funcionando
./scripts/check-urls.sh
```

### 3. Construir y Desplegar Aplicaciones WAR

#### Construcción de Aplicaciones

Para construir todas las aplicaciones WAR:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Construir todos los archivos WAR
./scripts/build/build-wars.sh

# Alternativa: Usar el nuevo script de build local
./scripts/build/build-local.sh --all
```

Para construir aplicaciones específicas:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Construir versión A
./scripts/build/create-simple-wars.sh version-a

# Construir versión B
./scripts/build/create-simple-wars.sh version-b

# Construir Feature Flags (compilación completa desde código fuente)
./scripts/build/build-feature-flags.sh

# Alternativa: Usar el nuevo script de build local para un proyecto específico
./scripts/build/build-local.sh feature-flags
```

#### Despliegue de Aplicaciones

Para desplegar todas las aplicaciones WAR:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Desplegar todas las aplicaciones
./scripts/deploy/deploy-war.sh --all

# Desplegar todas las aplicaciones con limpieza de caché
./scripts/deploy/deploy-war.sh --clean-all
```

Para desplegar aplicaciones específicas:

```bash
# Navegar al directorio raíz del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Desplegar versión A
./scripts/deploy/deploy-war.sh deploy/version-a.war

# Desplegar versión B
./scripts/deploy/deploy-war.sh deploy/version-b.war

# Desplegar Feature Flags
./scripts/deploy/deploy-war.sh deploy/feature-flags.war

# Desplegar con limpieza de caché
./scripts/deploy/deploy-war.sh --clean deploy/feature-flags.war
```

Para limpiar todas las cachés sin desplegar:

```bash
# Limpiar todas las cachés (HAProxy, WebLogic, navegadores)
./scripts/deploy/clear-all-caches.sh
```

Para más detalles sobre los scripts de construcción y despliegue, consulta la [Guía Detallada de Scripts de Construcción](docs/build-scripts.md).

## Características Adicionales

### Dashboard Profesional

El sistema incluye un dashboard profesional dedicado para monitorear el tráfico y el estado de los servicios en tiempo real.

#### Características del Dashboard:

1. **Monitoreo en Tiempo Real**:
   - Estado de todos los servicios (WebLogic A/B, HAProxy, Oracle DB)
   - Métricas de rendimiento y tiempo de respuesta
   - Estadísticas de tráfico actual y pico

2. **Visualización de Estrategias de Despliegue**:
   - Estado actual del A/B Testing con porcentajes de tráfico
   - Información del Canary Deployment
   - Distribución de requests entre versiones

3. **API REST Integrada**:
   - `/api/health` - Health check del dashboard
   - `/api/stats` - Estadísticas en tiempo real en formato JSON

#### Acceso al Dashboard:

- **Vía HAProxy (Recomendado)**: `http://localhost:8080/dashboard/`
- **Acceso Directo**: `http://localhost:8001/`

#### Probar el Dashboard:

```bash
# Ejecutar script de prueba completo
./scripts/test-dashboard.sh

# Verificar solo la conectividad básica
curl -s http://localhost:8080/dashboard/api/health | jq .
```

### Modo Oscuro

El sistema ahora incluye soporte para modo oscuro en las interfaces de usuario:

1. **Panel de Administración HAProxy**: 
   - Accede a `http://localhost:8082`
   - Haz clic en el botón de modo oscuro en la esquina superior derecha

2. **Aplicación Feature Flags**:
   - Accede a `http://localhost:8080/feature-flags/`
   - Haz clic en el botón de modo oscuro en la esquina superior derecha

El modo oscuro se guarda en localStorage y se mantiene entre sesiones.

### Limpieza de Caché

El sistema incluye scripts mejorados para limpiar la caché en diferentes niveles:

1. **Limpieza completa**:
   ```bash
   ./scripts/deploy/clear-all-caches.sh
   ```

2. **Limpieza de HAProxy**:
   ```bash
   ./scripts/deploy/clear-haproxy-cache.sh
   ```

3. **Limpieza de WebLogic**:
   ```bash
   ./scripts/deploy/clear-weblogic-cache.sh
   ```

4. **Limpieza de navegadores**:
   ```bash
   ./scripts/deploy/clear-browser-cache.sh
   ```
   Este script genera una herramienta HTML que puedes abrir para limpiar la caché del navegador.

5. **Despliegue con limpieza**:
   ```bash
   ./scripts/deploy/deploy-war.sh --clean deploy/feature-flags.war
   ```

### 1. Testing A/B

El Testing A/B permite comparar dos versiones de una aplicación para determinar cuál ofrece mejor rendimiento o experiencia de usuario.

#### Configuración desde la línea de comandos:

```bash
# Ver el estado actual
./haproxy/scripts/control.sh status

# Habilitar A/B testing con 70% del tráfico a la versión A y 30% a la versión B
./haproxy/scripts/control.sh ab --enable --weight-a 70

# Alternativa usando los scripts de canary
./scripts/canary/manage-traffic.sh ab 30  # Envía 30% del tráfico a la versión B
```

#### Configuración desde la interfaz web:

1. Accede al panel de administración: `http://localhost:8082`
2. Navega a la sección "A/B Testing"
3. Ajusta el porcentaje de tráfico entre las versiones A y B
4. Haz clic en "Aplicar Cambios"

#### Verificación:

1. Abre varias ventanas de navegación privada y accede a `http://localhost:8080/version-a/` o `http://localhost:8080/weblogic-features-a/`
2. Observa cómo algunas solicitudes son dirigidas a la versión A y otras a la versión B según el porcentaje configurado
3. Verifica las estadísticas en `http://localhost:8404/stats`

### 2. Canary Deployment

El Canary Deployment permite liberar una nueva versión a un pequeño porcentaje de usuarios antes de un despliegue completo.

#### Configuración desde la línea de comandos:

```bash
# Ver el estado actual
./haproxy/scripts/control.sh status

# Habilitar Canary deployment con 5% del tráfico a la nueva versión
./haproxy/scripts/control.sh canary --enable --percentage 5

# Aumentar gradualmente el porcentaje
./haproxy/scripts/control.sh canary --enable --percentage 20

# Alternativa usando los scripts de canary
./scripts/canary/manage-traffic.sh canary 20  # Envía 20% del tráfico a la versión B
```

#### Configuración desde la interfaz web:

1. Accede al panel de administración: `http://localhost:8082`
2. Navega a la sección "Canary Deployment"
3. Ajusta el porcentaje de tráfico para la versión canary
4. Haz clic en "Aplicar Cambios"

#### Plan de despliegue gradual recomendado:

1. Inicia con 5% de tráfico a la versión canary
2. Monitorea durante 30 minutos
3. Si no hay problemas, aumenta al 20%
4. Monitorea durante 1 hora
5. Si no hay problemas, aumenta al 50%
6. Monitorea durante 2 horas
7. Si no hay problemas, completa la migración al 100%

#### Simulación de tráfico para pruebas:

```bash
# Simular 100 solicitudes con un intervalo de 0.5 segundos
./scripts/canary/simulate-traffic.sh 100 0.5
```

### 3. Feature Flags

Los Feature Flags permiten activar o desactivar funcionalidades específicas sin necesidad de redesplegar la aplicación.

#### Acceso a la consola de Feature Flags:

1. Accede a la consola de administración: `http://localhost:8080/feature-flags/`
2. Inicia sesión si es necesario
3. Explora las características disponibles

#### Creación de un nuevo Feature Flag:

1. En la consola de Feature Flags, haz clic en "Create Feature"
2. Completa los campos:
   - **ID**: Identificador único (ej: `new-payment-flow`)
   - **Name**: Nombre descriptivo (ej: "New Payment Flow")
   - **Description**: Descripción detallada
   - **Group**: Grupo al que pertenece (opcional)
   - **Permissions**: Permisos necesarios (opcional)
3. Haz clic en "Create"

#### Activación/Desactivación de Features:

1. En la lista de características, encuentra la que deseas modificar
2. Utiliza el interruptor para activar o desactivar la característica
3. Para una activación más granular, configura:
   - **Estrategia**: Porcentaje, usuarios específicos, etc.
   - **Filtros**: Condiciones para la activación

#### Uso de la API REST para Feature Flags:

```bash
# Activar una característica
curl -X POST -H "Content-Type: application/json" \
  http://localhost:8080/feature-flags/api/ff4j/store/features/feature-name/enable

# Desactivar una característica
curl -X POST -H "Content-Type: application/json" \
  http://localhost:8080/feature-flags/api/ff4j/store/features/feature-name/disable

# Verificar el estado de una característica
curl -X GET -H "Content-Type: application/json" \
  http://localhost:8080/feature-flags/api/ff4j/store/features/feature-name
```

## Estrategia de Implementación Integrada

Para aprovechar al máximo estas estrategias, se recomienda el siguiente enfoque integrado:

1. **Desarrollo de nuevas características:**
   - Implementa nuevas características detrás de feature flags
   - Esto permite desplegar código inactivo que puede activarse posteriormente

2. **Pruebas iniciales:**
   - Activa los feature flags solo para usuarios internos o beta testers
   - Recopila feedback y realiza ajustes

3. **Despliegue Canary:**
   - Despliega la nueva versión con los feature flags configurados
   - Utiliza el despliegue canary para dirigir un pequeño porcentaje de tráfico a la nueva versión
   - Monitorea el rendimiento y los errores

4. **Testing A/B:**
   - Para características específicas, utiliza testing A/B para comparar diferentes implementaciones
   - Utiliza feature flags para controlar qué usuarios ven qué variante

5. **Despliegue completo:**
   - Una vez validada la estabilidad, aumenta gradualmente el tráfico a la nueva versión
   - Activa los feature flags para todos los usuarios

6. **Monitoreo continuo:**
   - Mantén la capacidad de desactivar características problemáticas mediante feature flags
   - Utiliza las estadísticas de HAProxy para monitorear el rendimiento de cada versión

## Solución de Problemas Comunes

### Aplicaciones no disponibles (Error 503)

Si recibes errores 503 al acceder a las aplicaciones:

1. Verifica que los contenedores estén en ejecución:
   ```bash
   docker-compose -f config/docker-compose.yml ps
   
   Subir sercios
   docker-compose -f config/docker-compose.yml up -d
   
   Bajar Servicios
   docker-compose -f config/docker-compose.yml down
   ```

2. Verifica que las aplicaciones WAR estén desplegadas:
   ```bash
   ./scripts/check-urls.sh
   ```

3. Si las aplicaciones no están desplegadas, construye y despliega los archivos WAR:
   ```bash
   ./scripts/build/create-simple-wars.sh version-a
   ./scripts/build/create-simple-wars.sh version-b
   ./scripts/deploy/deploy-war.sh deploy/version-a.war
   ./scripts/deploy/deploy-war.sh deploy/version-b.war
   ```

4. Si necesitas forzar un redespliegue limpio:
   ```bash
   ./scripts/deploy/clean-redeploy.sh version-a
   ```

Para más detalles sobre cómo borrar la caché, forzar redespliegues y gestionar usuarios, consulta la [Guía de Redespliegue y Gestión de Caché](docs/redeployment-guide.md).

### Problemas con HAProxy

Si HAProxy no está funcionando correctamente:

1. Verifica los logs:
   ```bash
   docker logs haproxy
   ```

2. Reinicia el contenedor:
   ```bash
   docker restart haproxy
   ```

3. Si persisten los problemas, recrea el contenedor:
   ```bash
   docker stop haproxy
   docker rm haproxy
   docker-compose -f config/docker-compose.yml up -d haproxy
   ```

### Panel de Administración no accesible

Si no puedes acceder al panel de administración en `http://localhost:8082`:

1. Verifica que el puerto esté expuesto en el docker-compose.yml:
   ```bash
   grep -A 5 "ports:" config/docker-compose.yml
   ```

2. Si el puerto 8082 no está expuesto, añádelo y reinicia el contenedor:
   ```bash
   # Editar config/docker-compose.yml para añadir "- 8082:8082"
   docker-compose -f config/docker-compose.yml up -d haproxy
   ```

## Estructura del Proyecto

```
docker-for-oracle-weblogic/
├── autodeploy/                # Directorio para despliegue automático de aplicaciones
├── config/                    # Configuraciones generales
│   └── docker-compose.yml     # Archivo principal de Docker Compose
├── container-scripts/         # Scripts para los contenedores
├── deploy/                    # Directorio para despliegue manual de aplicaciones
├── docs/                      # Documentación detallada
├── docker/                    # Archivos Docker
│   └── Dockerfile             # Dockerfile para WebLogic
├── haproxy/                   # Configuración de HAProxy
│   ├── config/                # Archivos de configuración de HAProxy
│   ├── scripts/               # Scripts para HAProxy
│   └── Dockerfile             # Dockerfile para HAProxy
├── oracle/                    # Configuración de Oracle Database
├── scripts/                   # Scripts de utilidad
│   ├── build/                 # Scripts para construir aplicaciones
│   ├── canary/                # Scripts para gestionar despliegue canary
│   ├── deploy/                # Scripts para desplegar aplicaciones
│   ├── check-urls.sh          # Script para verificar URLs
│   └── check-direct-urls.sh   # Script para verificar URLs directamente
├── start-all.sh               # Script para iniciar todos los servicios
└── README.md                  # Este archivo
```

## Prerequisitos y Requisitos

### Requisitos del Sistema
- Docker 19.03 o superior
- Docker Compose 1.27 o superior
- Al menos 8GB de RAM disponible (recomendado 16GB)
- Al menos 20GB de espacio en disco

### Archivos Requeridos

Antes de iniciar el proyecto, necesitas descargar y colocar los siguientes archivos en sus ubicaciones correspondientes:

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `fmw_14.1.1.0.0_wls_Disk1_1of1.zip` | `docker/weblogic/installers/` | Oracle WebLogic Server 14.1.1.0.0 |
| `sqlcl-25.2.2.199.0918.zip` | `oracle/installers/` | Oracle SQL Command Line Interface |
| `demo_oracle.ddl` | `oracle/scripts/setup/` | Scripts DDL para datos de demostración |
| `.env` | Directorio raíz (`./`) | Variables de entorno del proyecto |

### Verificación de Prerequisitos

Para verificar que todos los prerequisitos estén cumplidos, ejecuta:

```bash
# Verificar prerequisitos del sistema
./scripts/check-prerequisites.sh
```

Este script verificará:
- Instalación de Docker y Docker Compose
- Presencia de archivos requeridos
- Recursos del sistema (RAM y disco)
- Disponibilidad de puertos
- Estructura de directorios

### Configuración Inicial

Si es la primera vez que usas el proyecto:

```bash
# 1. Crear estructura de directorios (si no existe)
mkdir -p docker/weblogic/installers oracle/installers oracle/scripts/setup

# 2. Mover archivos a sus ubicaciones (ajusta las rutas según tu caso)
# mv /ruta/a/fmw_14.1.1.0.0_wls_Disk1_1of1.zip docker/weblogic/installers/
# mv /ruta/a/sqlcl-25.2.2.199.0918.zip oracle/installers/
# mv /ruta/a/demo_oracle.ddl oracle/scripts/setup/

# 3. Verificar prerequisitos
./scripts/check-prerequisites.sh

# 4. Si todo está correcto, iniciar el proyecto
./start-all.sh
```

Para información detallada sobre prerequisitos, consulta [docs/prerequisites.md](docs/prerequisites.md).

## Licencias

- Oracle WebLogic Server: Requiere aceptar los términos de licencia de Oracle
- Oracle Database: Requiere aceptar los términos de licencia de Oracle
- HAProxy: Licencia GPL v2
- Scripts y configuraciones personalizadas: MIT License
