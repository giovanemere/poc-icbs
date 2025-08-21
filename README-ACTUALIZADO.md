# 🎛️ Docker para Oracle WebLogic con Dashboard Unificado

Este proyecto proporciona un entorno Docker completo para Oracle WebLogic con **Dashboard Unificado** para Testing A/B, Canary Deployment y Feature Flags utilizando HAProxy. Incluye modo oscuro, herramientas de build local y gestión completa de despliegues.

## 🚀 Inicio Rápido

### **Comando Principal (Todo en Uno):**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./manage-admin-panel.sh start
```

### **URLs Principales:**
- **🎛️ Dashboard Unificado**: `http://localhost:8085/unified-dashboard-fixed.html` ⭐ **RECOMENDADO**
- **📊 Panel HAProxy**: `http://localhost:8082`
- **🔧 API de Control**: `http://localhost:8084/api`
- **📈 HAProxy Stats**: `http://localhost:8404/stats` (admin/admin123)

## 📋 Arquitectura del Sistema

```
                                  ┌─────────────┐
                                  │   Cliente   │
                                  │ (Navegador) │
                                  └──────┬──────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     🎛️ Dashboard Unificado                          │
│                    (localhost:8085) - INTERFAZ PRINCIPAL            │
│          Testing A/B + Canary Deployment + Feature Flags           │
└───┬─────────────────────────────────┬───────────────────────────┬───┘
    │                                 │                           │
    ▼                                 ▼                           ▼
┌─────────────┐                 ┌─────────────┐             ┌─────────────┐
│   HAProxy   │                 │ API Control │             │  Dashboard  │
│(172.23.0.5) │                 │(localhost:  │             │  Tráfico    │
│   :80/443   │                 │8084)        │             │(localhost:  │
└──────┬──────┘                 └─────────────┘             │8001)        │
       │                                                    └─────────────┘
       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            HAProxy                                  │
│                      (172.23.0.5:80/443)                           │
│                                                                     │
└───┬─────────────────────────────────┬───────────────────────────┬───┘
    │                                 │                           │
    ▼                                 ▼                           ▼
┌─────────────┐                 ┌─────────────┐             ┌─────────────┐
│ WebLogic A  │                 │ WebLogic B  │             │  Oracle DB  │
│(172.23.0.4) │                 │(172.23.0.3) │             │(172.23.0.2) │
│   :7001     │                 │   :7001     │             │   :1521     │
└──────┬──────┘                 └──────┬──────┘             └─────────────┘
       │                               │
       └───────────────┬───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │  Oracle DB    │
               │ (172.23.0.2)  │
               │               │
               └───────────────┘
```

## 🎛️ Dashboard Unificado - Características Principales

### **✅ Funcionalidades Completamente Implementadas:**

#### **🎯 A/B Testing:**
- ✅ **Toggle ON/OFF** para activar/desactivar
- ✅ **Slider 0-100%** para distribución de tráfico
- ✅ **Actualización en tiempo real** de URLs y gráfico
- ✅ **Colores dinámicos**: Verde (>80%), Amarillo (21-79%), Rojo (<20%)

#### **🚀 Canary Deployment:**
- ✅ **Toggle ON/OFF** para activar/desactivar
- ✅ **Slider 0-100%** para porcentaje canary
- ✅ **Actualización en tiempo real** de URLs y gráfico
- ✅ **Colores dinámicos** según distribución de tráfico

#### **🔗 URLs Activas del Sistema:**
- ✅ **Cambio de color inmediato** al mover sliders
- ✅ **Porcentajes actualizados** en tiempo real
- ✅ **Estados visuales**: Verde/Amarillo/Rojo según tráfico
- ✅ **Enlaces funcionales** a aplicaciones reales

#### **📊 Distribución de Tráfico en Tiempo Real:**
- ✅ **Gráfico de dona** con 4 segmentos
- ✅ **Actualización inmediata** sin delays
- ✅ **Labels dinámicos** con porcentajes actuales
- ✅ **Colores que cambian** según estado

#### **🚩 Feature Flags:**
- ✅ **Integración con FF4J**
- ✅ **Consola de administración**
- ✅ **API REST** para control programático

## 🛠️ Gestión del Sistema

### **Script Principal de Gestión:**
```bash
./manage-admin-panel.sh [comando]
```

### **Comandos Principales:**
```bash
# Iniciar sistema completo
./manage-admin-panel.sh start

# Ver estado de todos los servicios
./manage-admin-panel.sh status

# Detener todos los servicios
./manage-admin-panel.sh stop

# Reiniciar sistema completo
./manage-admin-panel.sh restart

# Probar funcionalidad completa
./manage-admin-panel.sh test
```

### **Comandos Específicos del Dashboard:**
```bash
# Iniciar Dashboard Unificado (versión corregida)
./manage-admin-panel.sh unified fixed

# Iniciar versión original
./manage-admin-panel.sh unified original

# Iniciar versión simple de prueba
./manage-admin-panel.sh unified simple

# Probar todas las versiones
./manage-admin-panel.sh unified test

# Ver estado del dashboard
./manage-admin-panel.sh unified status
```

### **Comandos de Construcción:**
```bash
# Construir imágenes Docker
./manage-admin-panel.sh build images

# Construir archivos WAR
./manage-admin-panel.sh build wars

# Construir todo (imágenes + WARs)
./manage-admin-panel.sh build all
```

## 🔨 Proceso de Build y Despliegue

### **1. Construcción de Imágenes Docker:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./build-latest.sh
```

**O usando el script de gestión:**
```bash
./manage-admin-panel.sh build images
```

### **2. Construcción de Archivos WAR:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./scripts/build/build-wars.sh
```

**O usando el script de gestión:**
```bash
./manage-admin-panel.sh build wars
```

### **3. Despliegue de Aplicaciones:**
```bash
# Desplegar todas las aplicaciones
./scripts/deploy/deploy-war.sh --all

# Desplegar aplicación específica
./scripts/deploy/deploy-war.sh deploy/version-a.war

# Desplegar con limpieza de caché
./scripts/deploy/deploy-war.sh --clean-all
```

**O usando el script de gestión:**
```bash
./manage-admin-panel.sh deploy
```

### **4. Proceso Completo (Build + Deploy):**
```bash
# Todo en una secuencia
./manage-admin-panel.sh build all
./manage-admin-panel.sh deploy
./manage-admin-panel.sh start
```

## 🌐 Puertos y URLs del Sistema

### **Puertos Expuestos:**

| Servicio | Puerto Interno | Puerto Externo | Descripción |
|----------|----------------|----------------|-------------|
| **Dashboard Unificado** | 8085 | 8085 | **Interfaz Principal** |
| HAProxy Frontend | 80 | 8080 | HTTP Frontend |
| HAProxy HTTPS | 443 | 8443 | HTTPS Frontend |
| HAProxy Stats | 8404 | 8404 | Estadísticas HAProxy |
| Panel HAProxy | 8082 | 8082 | UI de Administración |
| API de Control | 8084 | 8084 | API REST |
| Dashboard Tráfico | 8001 | 8001 | Dashboard Secundario |
| WebLogic A | 7001 | 7001 | Consola Admin A |
| WebLogic B | 7001 | 7002 | Consola Admin B |
| Oracle DB | 1521 | 1521 | Listener Oracle |
| Oracle EM | 5500 | 5500 | Enterprise Manager |

### **URLs Principales:**

| Componente | URL | Descripción |
|------------|-----|-------------|
| **🎛️ Dashboard Unificado** | `http://localhost:8085/unified-dashboard-fixed.html` | **INTERFAZ PRINCIPAL** ⭐ |
| Dashboard Original | `http://localhost:8085/unified-dashboard.html` | Versión original |
| Dashboard Simple | `http://localhost:8085/test-simple-functionality.html` | Versión de prueba |
| Panel HAProxy | `http://localhost:8082` | Panel web HAProxy |
| API de Control | `http://localhost:8084/api` | API REST |
| HAProxy Stats | `http://localhost:8404/stats` | Estadísticas (admin/admin123) |
| HAProxy Frontend | `http://localhost:8080` | Punto de entrada apps |

### **Aplicaciones a través de HAProxy:**

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| Version A | `http://localhost:8080/version-a` | Versión A para A/B Testing |
| Version B | `http://localhost:8080/version-b` | Versión B para A/B Testing |
| Feature Flags | `http://localhost:8080/feature-flags` | Consola FF4J |
| WebLogic Features A | `http://localhost:8080/weblogic-features-a` | Features WebLogic A |
| WebLogic Features B | `http://localhost:8080/weblogic-features-b` | Features WebLogic B |

### **Consolas de Administración:**

| Componente | URL | Credenciales |
|------------|-----|--------------|
| WebLogic A | `http://localhost:7001/console` | weblogic/welcome1 |
| WebLogic B | `http://localhost:7002/console` | weblogic/welcome1 |
| Oracle DB | `http://localhost:5500/em` | sys/oracle |
| HAProxy Stats | `http://localhost:8404/stats` | admin/admin123 |

## 🧪 Uso del Dashboard Unificado

### **1. Acceso:**
```bash
# Iniciar dashboard
./manage-admin-panel.sh unified fixed

# Abrir en navegador
http://localhost:8085/unified-dashboard-fixed.html
```

### **2. Testing A/B:**
1. **Activar toggle** "A/B Testing"
2. **Mover slider** para ajustar distribución (0-100%)
3. **Observar cambios inmediatos**:
   - URLs cambian color según porcentaje
   - Gráfico se actualiza en tiempo real
   - Métricas se actualizan

### **3. Canary Deployment:**
1. **Activar toggle** "Canary Deployment"
2. **Mover slider** para ajustar porcentaje canary (0-100%)
3. **Observar cambios inmediatos**:
   - WebLogic A/B cambian distribución
   - Gráfico refleja nueva distribución
   - URLs muestran estado actual

### **4. Estados Visuales:**
- **🟢 Verde**: Tráfico alto (>80%)
- **🟡 Amarillo**: Tráfico medio (21-79%)
- **🔴 Rojo**: Tráfico bajo (<20%)

### **5. Debugging:**
```javascript
// En la consola del navegador (F12)
testAll()                    // Prueba completa
updateTrafficPercentages()   // Solo URLs
updateChartWithCurrentData() // Solo gráfico
```

## 🐳 Configuración Docker y DNS Dinámicos

### **Posibles Problemas de Configuración:**

#### **1. Problemas de DNS:**
```bash
# Verificar resolución DNS
docker exec haproxy nslookup weblogic-a
docker exec haproxy nslookup weblogic-b

# Si falla, reiniciar red Docker
docker network ls
docker network inspect docker-for-oracle-weblogic_weblogic-network
```

#### **2. Problemas de Red:**
```bash
# Recrear red si es necesario
docker-compose -f config/docker-compose.yml down
docker network prune
docker-compose -f config/docker-compose.yml up -d
```

#### **3. Problemas de Puertos:**
```bash
# Verificar puertos ocupados
netstat -tuln | grep -E "(8080|8082|8084|8085|7001|7002)"

# Liberar puertos si es necesario
fuser -k 8085/tcp
fuser -k 8084/tcp
```

#### **4. Configuración de HAProxy:**
```bash
# Verificar configuración HAProxy
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg

# Recargar configuración
docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
```

### **Actualización de Puertos:**

#### **Para cambiar puertos del sistema:**

1. **Editar docker-compose.yml:**
```yaml
services:
  haproxy:
    ports:
      - "8080:80"      # Frontend HTTP
      - "8443:443"     # Frontend HTTPS  
      - "8404:8404"    # Stats
      - "8082:8082"    # Panel Admin
      - "8084:8084"    # API Control
```

2. **Actualizar scripts:**
```bash
# Editar manage-admin-panel.sh
# Cambiar URLs en las funciones de verificación
```

3. **Actualizar Dashboard:**
```javascript
// En unified-dashboard-fixed.html
// Actualizar API_URLS
const API_URLS = {
    stats: 'http://localhost:NUEVO_PUERTO/api/stats',
    // ...
};
```

4. **Reiniciar servicios:**
```bash
./manage-admin-panel.sh stop
docker-compose -f config/docker-compose.yml down
docker-compose -f config/docker-compose.yml up -d
./manage-admin-panel.sh start
```

## 📁 Listado de Archivos de la Solución

### **Archivos Principales del Dashboard:**
```
📁 /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/
├── 🎛️ unified-dashboard-fixed.html          # Dashboard principal (RECOMENDADO)
├── 🎛️ unified-dashboard.html                # Dashboard original
├── 🧪 test-simple-functionality.html        # Versión de prueba
├── 🔧 manage-admin-panel.sh                 # Script principal de gestión
├── 📋 README-ACTUALIZADO.md                 # Esta documentación
└── 📋 CORRECCION-LOGICA-100-PORCIENTO.md   # Documentación de correcciones
```

### **Scripts de Construcción:**
```
📁 scripts/
├── 📁 build/
│   ├── 🔨 build-wars.sh                    # Construir archivos WAR
│   ├── 🔨 build-local.sh                   # Build local
│   ├── 🔨 create-simple-wars.sh            # WARs simples
│   └── 🔨 build-feature-flags.sh           # Build Feature Flags
├── 📁 deploy/
│   ├── 🚀 deploy-war.sh                    # Desplegar WARs
│   ├── 🧹 clear-all-caches.sh              # Limpiar cachés
│   └── 🧹 clean-redeploy.sh                # Redespliegue limpio
└── 📁 canary/
    ├── 📊 manage-traffic.sh                 # Gestión de tráfico
    └── 🔄 simulate-traffic.sh               # Simulación de tráfico
```

### **Configuración Docker:**
```
📁 config/
├── 🐳 docker-compose.yml                   # Configuración principal
└── 📁 haproxy/
    ├── ⚖️ haproxy.cfg                       # Configuración HAProxy
    └── 📁 scripts/
        └── 🔧 control.sh                   # Control HAProxy
```

### **Archivos de Build:**
```
📁 /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/
├── 🔨 build-latest.sh                      # Build imágenes Docker
├── 🚀 start-all.sh                         # Inicio completo
└── 📁 docker/
    ├── 🐳 Dockerfile                       # WebLogic Dockerfile
    └── 📁 weblogic/
        └── 📁 installers/                  # Instaladores Oracle
```

### **Archivos de Despliegue:**
```
📁 deploy/                                   # Directorio de WARs
├── 📦 version-a.war                        # Aplicación A
├── 📦 version-b.war                        # Aplicación B
├── 📦 feature-flags.war                    # Feature Flags
└── 📦 weblogic-features-*.war              # Features WebLogic
```

### **Logs y PID Files:**
```
📁 /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/
├── 📄 unified-dashboard.log                # Log dashboard
├── 📄 haproxy-api.pid                      # PID API
├── 📄 unified-dashboard.pid                # PID dashboard
└── 📄 traffic-dashboard.pid                # PID dashboard tráfico
```

## 🔧 Solución de Problemas Comunes

### **1. Dashboard no carga:**
```bash
# Verificar y reiniciar
./manage-admin-panel.sh unified stop
./manage-admin-panel.sh unified fixed
```

### **2. URLs aparecen offline:**
```bash
# Usar versión corregida
./manage-admin-panel.sh unified fixed

# Verificar en consola del navegador
testAll()
```

### **3. Gráfico no se actualiza:**
```bash
# Verificar Chart.js en consola
typeof Chart

# Forzar actualización
updateChartWithCurrentData()
```

### **4. APIs no responden:**
```bash
# Verificar APIs
curl http://localhost:8084/api/health
curl http://localhost:8084/api/stats

# Reiniciar si es necesario
./manage-admin-panel.sh restart
```

### **5. Aplicaciones no disponibles (503):**
```bash
# Verificar contenedores
docker-compose -f config/docker-compose.yml ps

# Construir y desplegar WARs
./manage-admin-panel.sh build wars
./manage-admin-panel.sh deploy
```

## 🎯 Estrategias de Despliegue Integradas

### **1. Desarrollo de Nuevas Características:**
- Implementar detrás de feature flags
- Desplegar código inactivo
- Activar gradualmente

### **2. Pruebas Iniciales:**
- Feature flags para usuarios internos
- Recopilar feedback
- Realizar ajustes

### **3. Despliegue Canary:**
- Desplegar nueva versión
- Dirigir pequeño porcentaje de tráfico
- Monitorear rendimiento

### **4. Testing A/B:**
- Comparar implementaciones
- Usar feature flags para control
- Analizar métricas

### **5. Despliegue Completo:**
- Aumentar gradualmente tráfico
- Activar feature flags
- Monitoreo continuo

## 📊 Monitoreo y Métricas

### **URLs de Monitoreo:**
- **Dashboard Principal**: `http://localhost:8085/unified-dashboard-fixed.html`
- **HAProxy Stats**: `http://localhost:8404/stats`
- **API Métricas**: `http://localhost:8084/api/stats`

### **Métricas Disponibles:**
- Distribución de tráfico en tiempo real
- Estado de servicios
- Requests por aplicación
- Porcentajes de A/B Testing y Canary

## 🎉 Resultado Final

### ✅ **SISTEMA COMPLETAMENTE FUNCIONAL**

- 🎛️ **Dashboard Unificado**: Interfaz principal completamente funcional
- 🔗 **URLs Activas**: Cambian color en tiempo real
- 📊 **Gráfico de Tráfico**: Se actualiza inmediatamente
- 🎯 **A/B Testing**: Completamente implementado
- 🚀 **Canary Deployment**: Completamente implementado
- 🚩 **Feature Flags**: Integrado con FF4J
- 🔧 **Gestión Completa**: Scripts de build, deploy y gestión

---

**🎛️ Dashboard Unificado - WebLogic Deployment Manager**

**URL Principal**: `http://localhost:8085/unified-dashboard-fixed.html` ✅ **COMPLETAMENTE FUNCIONAL**

**Gestión**: `./manage-admin-panel.sh start` ✅ **SISTEMA COMPLETO**

**Estado**: ✅ **PRODUCCIÓN READY - TODAS LAS FUNCIONALIDADES IMPLEMENTADAS**

**Fecha**: 21 de Agosto de 2025  
**Versión**: ✅ DASHBOARD UNIFICADO COMPLETO Y FUNCIONAL  
**Resultado**: ✅ SISTEMA DE DESPLIEGUE ENTERPRISE COMPLETAMENTE OPERATIVO

### 🚀 **Para Empezar Inmediatamente:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./manage-admin-panel.sh start
# Abrir: http://localhost:8085/unified-dashboard-fixed.html
```

**¡Sistema completo de gestión de despliegues WebLogic con Dashboard Unificado completamente funcional!** 🎛️✨📊
