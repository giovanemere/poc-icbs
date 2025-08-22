# 🔗 URLs del Sistema

Esta página contiene todas las URLs del sistema WebLogic organizadas por categoría y función.

## 🎯 URLs Principales

### 🎛️ Dashboard Principal
```
🎛️ http://localhost:8085/unified-dashboard-fixed.html  ⭐ Principal
📊 http://localhost:8084/                              Dashboard de Tráfico
```

!!! success "URLs Más Confiables"
    Los dashboards independientes (8084, 8085, 8092, 8093) son más confiables que las URLs que dependen de HAProxy.

## 📊 Dashboards y Paneles

### 🎛️ Dashboards Principales

| Componente | URL | Puerto | Descripción |
|------------|-----|--------|-------------|
| **Dashboard Unificado** | `http://localhost:8085/unified-dashboard-fixed.html` | 8085 | ⭐ **Dashboard Principal** |
| **Dashboard de Tráfico** | `http://localhost:8084/` | 8084 | Dashboard de tráfico y monitoreo |
| **Panel HAProxy** | `http://localhost:8092/index-functional.html` | 8092 | Panel de administración HAProxy |
| **Panel HAProxy Principal** | `http://localhost:8092/` | 8092 | Página principal del panel HAProxy |
| **API Admin** | `http://localhost:8093/api/health` | 8093 | API de administración |

### 📈 Administración y Monitoreo

| Componente | URL | Puerto | Credenciales |
|------------|-----|--------|--------------|
| **HAProxy Stats** | `http://localhost:8404/stats` | 8404 | admin/admin123 |
| **WebLogic A Console** | `http://localhost:7001/console` | 7001 | weblogic/welcome1 |
| **WebLogic B Console** | `http://localhost:7002/console` | 7002 | weblogic/welcome1 |
| **Oracle Enterprise Manager** | `http://localhost:5500/em` | 5500 | - |

## 🌐 Frontend y Aplicaciones

### 🌐 Frontend Principal (Puerto 8100)

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| **Frontend Principal** | `http://localhost:8100/` | **Punto de entrada principal** ✅ |
| **Version A** | `http://localhost:8100/version-a/` | Versión A para pruebas ✅ |
| **Version B** | `http://localhost:8100/version-b/` | Versión B para pruebas ✅ |
| **Feature Flags** | `http://localhost:8100/feature-flags/` | Aplicación de Feature Flags ✅ |
| **FF4J Simple** | `http://localhost:8100/ff4j-simple/` | Aplicación FF4J ✅ |

!!! warning "Dependencia de HAProxy"
    Las URLs del puerto 8100 dependen de que HAProxy esté funcionando correctamente.

## 🔌 APIs del Sistema

### 📊 APIs del Dashboard de Tráfico (Puerto 8084)

| API | URL | Método | Descripción |
|-----|-----|--------|-------------|
| **Health Check** | `http://localhost:8084/api/health` | GET | Verificación de salud |
| **Estadísticas** | `http://localhost:8084/api/stats` | GET | Estadísticas en tiempo real |
| **A/B Testing** | `http://localhost:8084/api/ab/apply` | POST | API para aplicar A/B Testing |
| **Canary Deployment** | `http://localhost:8084/api/canary/apply` | POST | API para aplicar Canary Deployment |
| **Reset Stats** | `http://localhost:8084/api/reset` | POST | Reiniciar estadísticas |

#### Ejemplos de Uso de APIs POST

=== "A/B Testing"
    ```bash
    curl -X POST -H "Content-Type: application/json" \
      -d '{"percentage_a": 70, "percentage_b": 30}' \
      http://localhost:8084/api/ab/apply
    ```

=== "Canary Deployment"
    ```bash
    curl -X POST -H "Content-Type: application/json" \
      -d '{"canary_percentage": 20}' \
      http://localhost:8084/api/canary/apply
    ```

=== "Reset Stats"
    ```bash
    curl -X POST http://localhost:8084/api/reset
    ```

### 📡 APIs de Administración (Puerto 8093)

| API | URL | Método | Descripción |
|-----|-----|--------|-------------|
| **Health Check** | `http://localhost:8093/api/health` | GET | Verificación de salud |
| **Status** | `http://localhost:8093/api/status` | GET | Estado del sistema |
| **Panel Principal** | `http://localhost:8093/` | GET | Panel de administración |

## 🗺️ Mapa de Puertos

### Puertos Principales

| Puerto | Servicio | Tipo | Estado |
|--------|----------|------|--------|
| **8085** | Dashboard Unificado | Dashboard | ✅ Independiente |
| **8084** | Dashboard de Tráfico | Dashboard + API | ✅ Independiente |
| **8092** | Panel HAProxy | Panel | ✅ Independiente |
| **8093** | API Admin | API | ✅ Independiente |
| **8100** | Frontend Principal | Frontend | ⚠️ Depende de HAProxy |
| **8404** | HAProxy Stats | Estadísticas | ⚠️ Depende de HAProxy |

### Puertos de Aplicaciones

| Puerto | Servicio | Descripción |
|--------|----------|-------------|
| **7001** | WebLogic A | Consola de administración A |
| **7002** | WebLogic B | Consola de administración B |
| **1521** | Oracle DB | Listener de Oracle Database |
| **5500** | Oracle EM | Enterprise Manager |

## 🔍 Verificación de URLs

### Comando de Verificación
```bash
./verify-updated-urls.sh
```

Este script verifica automáticamente todas las URLs del sistema y muestra su estado.

### Verificación Manual

=== "Dashboards Principales"
    ```bash
    # Dashboard Unificado
    curl -s -o /dev/null -w "Status: %{http_code}" \
      http://localhost:8085/unified-dashboard-fixed.html
    
    # Dashboard de Tráfico
    curl -s -o /dev/null -w "Status: %{http_code}" \
      http://localhost:8084/
    
    # Panel HAProxy
    curl -s -o /dev/null -w "Status: %{http_code}" \
      http://localhost:8092/
    ```

=== "APIs"
    ```bash
    # API de Tráfico
    curl -s http://localhost:8084/api/health
    
    # API de Admin
    curl -s http://localhost:8093/api/health
    
    # Estadísticas
    curl -s http://localhost:8084/api/stats
    ```

=== "Frontend"
    ```bash
    # Frontend Principal
    curl -s -o /dev/null -w "Status: %{http_code}" \
      http://localhost:8100/
    
    # Aplicaciones
    curl -s -o /dev/null -w "Status: %{http_code}" \
      http://localhost:8100/version-a/
    ```

## 🚨 URLs de Respaldo

### Si HAProxy Falla

Estos dashboards independientes siguen funcionando:

- ✅ `http://localhost:8085/unified-dashboard-fixed.html`
- ✅ `http://localhost:8084/`
- ✅ `http://localhost:8092/index-functional.html`
- ✅ `http://localhost:8093/api/health`

### Si un Dashboard Falla

Alternativas disponibles:

| Dashboard Principal | Alternativas |
|-------------------|-------------|
| 8085 (Unificado) | 8084 (Tráfico), 8092 (HAProxy) |
| 8084 (Tráfico) | 8085 (Unificado), 8404 (Stats) |
| 8092 (HAProxy) | 8085 (Unificado), 8404 (Stats) |

## 📱 Acceso Móvil

Todas las URLs son accesibles desde dispositivos móviles. Los dashboards tienen diseño responsive.

### URLs Optimizadas para Móvil

- 📱 Dashboard Unificado: Completamente responsive
- 📱 Dashboard de Tráfico: Optimizado para móvil
- 📱 Panel HAProxy: Diseño adaptativo

## 🔗 Enlaces Rápidos

### Para Desarrollo
- 🎛️ [Dashboard Principal](http://localhost:8085/unified-dashboard-fixed.html)
- 📊 [Dashboard de Tráfico](http://localhost:8084/)
- 🌐 [Frontend Principal](http://localhost:8100/)

### Para Administración
- 📈 [HAProxy Stats](http://localhost:8404/stats)
- 🔧 [WebLogic A](http://localhost:7001/console)
- 🔧 [WebLogic B](http://localhost:7002/console)

### Para APIs
- 🔌 [API Health](http://localhost:8084/api/health)
- 📊 [API Stats](http://localhost:8084/api/stats)
- 📡 [Admin API](http://localhost:8093/api/health)

## 💡 Consejos de Uso

!!! tip "Recomendaciones"
    
    - **Guarda como favoritos** las URLs principales
    - **Usa los dashboards independientes** para mayor confiabilidad
    - **Verifica regularmente** el estado con `./verify-updated-urls.sh`
    - **Ten a mano las URLs de respaldo** por si HAProxy falla

!!! info "Acceso Rápido"
    
    **URLs más importantes para el día a día:**
    
    1. 🎛️ `http://localhost:8085/unified-dashboard-fixed.html` - Dashboard Principal
    2. 📊 `http://localhost:8084/` - Dashboard de Tráfico  
    3. 🌐 `http://localhost:8100/` - Frontend Principal

## ✨ URLs Listas para Usar

Todas las URLs han sido verificadas y están funcionando correctamente. El sistema está listo para uso en producción! 🎉
