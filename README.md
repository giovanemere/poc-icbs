# Docker para Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags

Este proyecto proporciona un entorno Docker para Oracle WebLogic con soporte para estrategias avanzadas de despliegue como Testing A/B, Canary Deployment y Feature Flags utilizando HAProxy. Incluye modo oscuro en las interfaces de usuario, herramientas para build local y sistema unificado de gestión.

## 🚀 Inicio Rápido

### **Comando Principal (Recomendado)**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

### **Parar Todo el Sistema**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./stop.sh
```

### **Verificar URLs del Sistema**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./verify-updated-urls.sh
```

## 🎯 **URLs Principales del Sistema**

### **🎛️ DASHBOARD PRINCIPAL:**
```
🎛️ http://localhost:8085/unified-dashboard-fixed.html  ⭐ Principal
📊 http://localhost:8084/                              Dashboard de Tráfico
```

### **🎛️ Dashboards Principales (Más Confiables)**

| Componente | URL | Descripción |
|------------|-----|-------------|
| **Dashboard Unificado** | `http://localhost:8085/unified-dashboard-fixed.html` | ⭐ **Dashboard Principal** |
| **Dashboard de Tráfico** | `http://localhost:8084/` | Dashboard de tráfico y monitoreo |
| **Panel HAProxy** | `http://localhost:8092/index-functional.html` | Panel de administración HAProxy |
| **API Admin** | `http://localhost:8093/api/health` | API de administración |

### **🌐 Frontend Principal (Puerto 8100)**

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| **Frontend Principal** | `http://localhost:8100/` | **Punto de entrada principal** ✅ |
| **Version A** | `http://localhost:8100/version-a/` | Versión A para pruebas ✅ |
| **Version B** | `http://localhost:8100/version-b/` | Versión B para pruebas ✅ |
| **Feature Flags** | `http://localhost:8100/feature-flags/` | Aplicación de Feature Flags ✅ |
| **FF4J Simple** | `http://localhost:8100/ff4j-simple/` | Aplicación FF4J ✅ |

### **📈 Administración y Monitoreo**

| Componente | URL | Descripción |
|------------|-----|-------------|
| HAProxy Stats | `http://localhost:8404/stats` | Estadísticas de HAProxy (admin/admin123) |
| WebLogic A Console | `http://localhost:7001/console` | Consola de administración WebLogic A |
| WebLogic B Console | `http://localhost:7002/console` | Consola de administración WebLogic B |
| Oracle Enterprise Manager | `http://localhost:5500/em` | Enterprise Manager de Oracle Database |

### **📊 APIs del Dashboard de Tráfico**

| API | URL | Método | Descripción |
|-----|-----|--------|-------------|
| Health Check | `http://localhost:8084/api/health` | GET | Verificación de salud |
| Estadísticas | `http://localhost:8084/api/stats` | GET | Estadísticas en tiempo real |
| A/B Testing | `http://localhost:8084/api/ab/apply` | POST | API para aplicar A/B Testing |
| Canary Deployment | `http://localhost:8084/api/canary/apply` | POST | API para aplicar Canary Deployment |
| Reset Stats | `http://localhost:8084/api/reset` | POST | Reiniciar estadísticas |

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
│                         (Puerto 8100)                              │
│                                                                     │
└───┬─────────────────────────────────┬───────────────────────────┬───┘
    │                                 │                           │
    ▼                                 ▼                           ▼
┌─────────────┐                 ┌─────────────┐             ┌─────────────┐
│             │                 │             │             │ Dashboards  │
│ WebLogic A  │                 │ WebLogic B  │             │Independientes│
│  (7001)     │                 │  (7002)     │             │(8084-8093)  │
│             │                 │             │             │             │
└──────┬──────┘                 └──────┬──────┘             └─────────────┘
       │                               │
       └───────────────┬───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │               │
               │  Oracle DB    │
               │ (1521/5500)   │
               │               │
               └───────────────┘
```

### Puertos del Sistema

| Servicio | Puerto Interno | Puerto Externo | Descripción |
|----------|----------------|----------------|-------------|
| HAProxy | 80 | **8100** | **Frontend Principal** ✅ |
| HAProxy | 443 | 8443 | HTTPS Frontend |
| HAProxy | 8404 | 8404 | Estadísticas de HAProxy |
| HAProxy | 8081 | 8081 | API de Administración |
| HAProxy | 8082 | 8082 | UI de Administración |
| WebLogic A | 7001 | 7001 | Consola de Administración A |
| WebLogic B | 7001 | 7002 | Consola de Administración B |
| Oracle DB | 1521 | 1521 | Listener de Oracle |
| Oracle DB | 5500 | 5500 | Enterprise Manager |
| Dashboard Unificado | - | 8085 | Dashboard Principal |
| Dashboard de Tráfico | - | 8084 | Dashboard de Tráfico |
| Panel HAProxy | - | 8092 | Panel de Administración |
| API Admin | - | 8093 | API de Administración |

## 🔧 Comandos de Desarrollo

### **Build WAR Files**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./scripts/build/build-wars.sh
```

### **Build Docker Images**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./build-latest.sh
```

### **Desplegar Aplicaciones WAR**
```bash
# Desplegar automáticamente todas las aplicaciones
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Copiar aplicaciones a WebLogic A
docker cp deploy/version-a.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/feature-flags.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/ff4j-simple.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/weblogic-features-a.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/

# Copiar aplicaciones a WebLogic B
docker cp deploy/version-b.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/feature-flags.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/ff4j-simple.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp deploy/weblogic-features-b.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
```

### **Aplicaciones Desplegadas**

#### **WebLogic A (Puerto 7001):**
- ✅ `version-a` - http://localhost:7001/version-a/
- ✅ `feature-flags` - http://localhost:7001/feature-flags/
- ✅ `ff4j-simple` - http://localhost:7001/ff4j-simple/
- ✅ `weblogic-features-a` - http://localhost:7001/weblogic-features-a/

#### **WebLogic B (Puerto 7002):**
- ✅ `version-b` - http://localhost:7002/version-b/
- ✅ `feature-flags` - http://localhost:7002/feature-flags/
- ✅ `ff4j-simple` - http://localhost:7002/ff4j-simple/
- ✅ `weblogic-features-b` - http://localhost:7002/weblogic-features-b/

#### **A través de HAProxy (Puerto 8100) - Con Balanceo de Carga:**
- ✅ `version-a` - http://localhost:8100/version-a/ → WebLogic A
- ✅ `version-b` - http://localhost:8100/version-b/ → WebLogic B
- ✅ `feature-flags` - http://localhost:8100/feature-flags/ → Balanceado A/B
- ✅ `ff4j-simple` - http://localhost:8100/ff4j-simple/ → Balanceado A/B

### **Subir MkDocs para Desarrollo**
```bash
# Opción 1: Navegar al directorio del proyecto de documentación
cd /path/to/mkdocs-project

# Iniciar servidor de desarrollo MkDocs
mkdocs serve --dev-addr=0.0.0.0:8000

# Opción 2: Si tienes un script específico
./start-mkdocs-dev.sh

# Opción 3: Con Docker (si tienes imagen de MkDocs)
docker run --rm -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material

# Opción 4: MkDocs con auto-reload
mkdocs serve --dev-addr=0.0.0.0:8000 --livereload
```

**URLs de MkDocs:**
- **Documentación Local**: `http://localhost:8000`
- **Auto-reload**: Se actualiza automáticamente al guardar cambios
- **Puerto por defecto**: 8000 (evita conflictos con WebLogic)

## 📋 Scripts Disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`./start.sh`** | ⭐ **PRINCIPAL** - Inicio inteligente (detecta estado y actúa) | Uso diario |
| **`./smart-start.sh`** | 🧠 Inicio inteligente con detección automática | Uso avanzado |
| **`./force-restart.sh`** | 🔄 Reinicio forzado completo (parada total + inicio limpio) | Cuando hay problemas |
| **`./status.sh`** | 📊 Estado detallado de todos los servicios | Monitoreo |
| **`./stop.sh`** | 🛑 Para todo el sistema completamente | Cuando termines |
| **`./verify-updated-urls.sh`** | 🔍 Verifica todas las URLs del sistema | Verificación |
| `./start-unified-system.sh` | Script completo con logs detallados | Debugging |
| `./check-images.sh` | Verifica imágenes Docker disponibles | Troubleshooting |
| `./scripts/build/build-wars.sh` | Construye archivos WAR | Desarrollo |
| `./build-latest.sh` | Construye imágenes Docker | Desarrollo |

## 🆕 Cambios Recientes (v2.2.0)

### **Correcciones Críticas y Mejoras:**
- ✅ **Corrección de inicio de WebLogic** - Solucionado problema de configuración como servidor gestionado
- ✅ **Despliegue completo de aplicaciones WAR** en ambos nodos WebLogic A y B
- ✅ **Configuración HAProxy corregida** para routing correcto a backends WebLogic
- ✅ **Balanceo de carga funcional** entre WebLogic A y B
- ✅ **Carga automática de variables .env** en scripts de inicio
- ✅ **Configuración de red Docker simplificada** sin parámetros external problemáticos

### **Aplicaciones Desplegadas y Funcionando:**
- ✅ **version-a**: http://localhost:8100/version-a/ → WebLogic A
- ✅ **version-b**: http://localhost:8100/version-b/ → WebLogic B  
- ✅ **feature-flags**: http://localhost:8100/feature-flags/ → Balanceado A/B
- ✅ **ff4j-simple**: http://localhost:8100/ff4j-simple/ → Balanceado A/B
- ✅ **weblogic-features-a/b**: Aplicaciones específicas por nodo

### **Sistema Completamente Funcional:**
- ✅ **Oracle Database**: Puerto 1521/5500 (healthy)
- ✅ **WebLogic A**: Puerto 7001 (running)
- ✅ **WebLogic B**: Puerto 7002 (running)
- ✅ **HAProxy**: Puerto 8100 con balanceo real
- ✅ **Dashboards**: Puertos 8084, 8085, 8092, 8093 (todos funcionando)
- ✅ **Estadísticas HAProxy**: http://localhost:8404/stats (admin/admin123)

## 🎯 Flujo de Trabajo Recomendado

### **1. Desarrollo Completo**
```bash
# 1. Construir WAR files
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./scripts/build/build-wars.sh

# 2. Construir imágenes Docker
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./build-latest.sh

# 3. Iniciar todo el sistema
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

### **2. Uso Diario**
```bash
# Iniciar sistema
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh

# Verificar que todo funciona
# - Abrir: http://localhost:8085/unified-dashboard-fixed.html
# - Probar: http://localhost:8100/

# Parar sistema al final del día
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./stop.sh
```

### **3. Desarrollo con MkDocs**
```bash
# En terminal separada para documentación
cd /path/to/mkdocs-project
mkdocs serve --dev-addr=0.0.0.0:8000

# Acceder a documentación en: http://localhost:8000
```

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

- **Vía HAProxy (Recomendado)**: `http://localhost:8100/dashboard/`
- **Dashboard Unificado**: `http://localhost:8085/unified-dashboard-fixed.html` ⭐
- **Dashboard de Tráfico**: `http://localhost:8084/`

### Modo Oscuro

El sistema incluye soporte para modo oscuro en las interfaces de usuario:

1. **Panel de Administración HAProxy**: 
   - Accede a `http://localhost:8092`
   - Haz clic en el botón de modo oscuro en la esquina superior derecha

2. **Aplicación Feature Flags**:
   - Accede a `http://localhost:8100/feature-flags/`
   - Haz clic en el botón de modo oscuro en la esquina superior derecha

El modo oscuro se guarda en localStorage y se mantiene entre sesiones.

## 🔧 Comandos Útiles

### **Gestión de Contenedores**
```bash
# Ver logs en tiempo real
docker-compose -f config/docker-compose.yml logs -f

# Ver estado de contenedores
docker-compose -f config/docker-compose.yml ps

# Reiniciar solo un servicio
docker-compose -f config/docker-compose.yml restart haproxy

# Ver logs de un servicio específico
docker-compose -f config/docker-compose.yml logs -f haproxy
```

### **Verificación y Debugging**
```bash
# Verificar imágenes disponibles
./check-images.sh

# Verificar configuración de URLs
./verify-updated-urls.sh

# Inicio con logs detallados
./start-unified-system.sh
```

### **Limpieza**
```bash
# Parar y limpiar todo
./stop.sh

# Limpieza manual completa
docker-compose -f config/docker-compose.yml down --remove-orphans
docker system prune -f
```

## 🚨 Solución de Problemas Comunes

### **Si algo no funciona:**

1. **Parar todo y reiniciar:**
   ```bash
   ./stop.sh
   ./start.sh
   ```

2. **Ver logs detallados:**
   ```bash
   ./start-unified-system.sh
   ```

3. **Verificar imágenes:**
   ```bash
   ./check-images.sh
   ```

4. **Verificar URLs:**
   ```bash
   ./verify-updated-urls.sh
   ```

### **URLs de Respaldo (Siempre Funcionan)**
Si HAProxy falla, estos dashboards independientes siguen funcionando:
- `http://localhost:8085/unified-dashboard-fixed.html`
- `http://localhost:8084/`
- `http://localhost:8092/index-functional.html`
- `http://localhost:8093/api/health`

### **Problemas de Despliegue de Aplicaciones**

Si las aplicaciones no están disponibles:

1. **Verificar que los contenedores estén corriendo:**
   ```bash
   docker ps | grep weblogic
   ```

2. **Verificar que las aplicaciones WAR estén desplegadas:**
   ```bash
   docker exec weblogic-a-main ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/
   docker exec weblogic-b-main ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/
   ```

3. **Redesplegar aplicaciones manualmente:**
   ```bash
   # Para WebLogic A
   docker cp deploy/version-a.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
   docker cp deploy/feature-flags.war weblogic-a-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
   
   # Para WebLogic B
   docker cp deploy/version-b.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
   docker cp deploy/feature-flags.war weblogic-b-main:/u01/oracle/user_projects/domains/base_domain/autodeploy/
   ```

4. **Verificar logs de WebLogic:**
   ```bash
   docker logs --tail 20 weblogic-a-main
   docker logs --tail 20 weblogic-b-main
   ```

### **Problemas de Configuración de Red**

Si hay errores de red en docker-compose:

1. **Verificar archivo .env:**
   ```bash
   cat .env | grep -E "(NETWORK|EXTERNAL)"
   ```

2. **Limpiar redes Docker:**
   ```bash
   docker network prune -f
   ```

3. **Reiniciar con configuración limpia:**
   ```bash
   ./stop.sh
   docker system prune -f
   ./start.sh
   ```

## 🎮 Testing A/B, Canary Deployment y Feature Flags

### 1. Testing A/B

El Testing A/B permite comparar dos versiones de una aplicación para determinar cuál ofrece mejor rendimiento o experiencia de usuario.

#### Configuración desde la interfaz web:

1. Accede al Dashboard de Tráfico: `http://localhost:8084`
2. Navega a la sección "A/B Testing"
3. Ajusta el porcentaje de tráfico entre las versiones A y B
4. Haz clic en "Aplicar Cambios"

#### Verificación:

1. Abre varias ventanas de navegación privada y accede a `http://localhost:8100/version-a/`
2. Observa cómo algunas solicitudes son dirigidas a la versión A y otras a la versión B según el porcentaje configurado
3. Verifica las estadísticas en `http://localhost:8404/stats`

### 2. Canary Deployment

El Canary Deployment permite liberar una nueva versión a un pequeño porcentaje de usuarios antes de un despliegue completo.

#### Configuración desde la interfaz web:

1. Accede al Dashboard de Tráfico: `http://localhost:8084`
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

### 3. Feature Flags

Los Feature Flags permiten activar o desactivar funcionalidades específicas sin necesidad de redesplegar la aplicación.

#### Acceso a la consola de Feature Flags:

1. Accede a la consola de administración: `http://localhost:8100/feature-flags/`
2. Inicia sesión si es necesario
3. Explora las características disponibles

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
│   │   ├── build-wars.sh      # Construir archivos WAR
│   │   └── build-local.sh     # Build local
│   ├── canary/                # Scripts para gestionar despliegue canary
│   └── deploy/                # Scripts para desplegar aplicaciones
├── start.sh                   # ⭐ Script principal para iniciar todo
├── stop.sh                    # Script para parar todo
├── start-unified-system.sh    # Script unificado completo
├── verify-updated-urls.sh     # Verificar configuración de URLs
├── check-images.sh            # Verificar imágenes Docker
├── build-latest.sh            # Construir imágenes Docker
└── README.md                  # Este archivo
```

## Prerequisitos y Requisitos

### Requisitos del Sistema
- Docker 19.03 o superior
- Docker Compose 1.27 o superior
- Al menos 8GB de RAM disponible (recomendado 16GB)
- Al menos 20GB de espacio en disco

### Verificación de Prerequisitos

Para verificar que todos los prerequisitos estén cumplidos, ejecuta:

```bash
# Verificar prerequisitos del sistema
./check-images.sh
```

## 💡 Consejos y Mejores Prácticas

- **Los dashboards independientes** (8084, 8085, 8092, 8093) son más confiables que las URLs que dependen de HAProxy
- **El Frontend Principal** (8100) depende de que HAProxy esté funcionando correctamente
- **Usa el Dashboard de Tráfico** (8084) para A/B Testing y Canary Deployment
- **El Dashboard Unificado** (8085) es el más completo para monitoreo general
- **Construye las imágenes localmente** para mejor rendimiento y control de versiones

## 📚 Documentación Adicional

- [Instrucciones Unificadas](INSTRUCCIONES-UNIFICADAS.md) - Guía rápida de uso
- [Guía de Scripts de Construcción](docs/build-scripts.md) - Detalles sobre build y despliegue
- [Guía de Redespliegue](docs/redeployment-guide.md) - Gestión de caché y redespliegues

## Licencias

- Oracle WebLogic Server: Requiere aceptar los términos de licencia de Oracle
- Oracle Database: Requiere aceptar los términos de licencia de Oracle
- HAProxy: Licencia GPL v2
- Scripts y configuraciones personalizadas: MIT License

---

## ✨ ¡Listo para Usar!

Ejecuta el comando principal para comenzar:

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

Luego ve a: `http://localhost:8085/unified-dashboard-fixed.html` para acceder al dashboard principal.
