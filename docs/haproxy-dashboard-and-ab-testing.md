# HAProxy Avanzado: Dashboard, Testing A/B y Canary Deployment

Este documento describe la configuración avanzada de HAProxy implementada en el sistema, incluyendo el dashboard integrado, testing A/B, Canary deployment y todas las mejoras realizadas.

## 📊 1. Dashboard Integrado de HAProxy

Se ha implementado un dashboard completo integrado directamente en HAProxy que proporciona monitoreo en tiempo real y enlaces rápidos a todos los servicios del sistema.

### 🌐 URLs del Dashboard:

| Componente | URL | Descripción |
|------------|-----|-------------|
| **Dashboard Principal** | http://localhost:8080/dashboard/ | Dashboard integrado con estado de servicios |
| **HAProxy Stats** | http://localhost:8404/stats | Estadísticas detalladas (admin/admin123) |
| **Admin UI** | http://localhost:8082 | Interfaz de administración avanzada |
| **API de Administración** | http://localhost:8081/api | API REST para configuración dinámica |

### ✨ Características del Dashboard:

- **📊 Estado de servicios en tiempo real**: Monitoreo visual de todos los componentes
- **🔗 Enlaces rápidos**: Acceso directo a todas las interfaces del sistema
- **🔄 Auto-refresh**: Actualización automática cada 30 segundos
- **📱 Diseño responsive**: Optimizado para desktop y móviles
- **⚡ Servido por HAProxy**: Sin dependencias externas, máximo rendimiento
- **🎨 Interfaz moderna**: Diseño limpio y profesional

### 🛠️ Implementación Técnica:

```haproxy
# Configuración en haproxy.cfg
frontend http-in
    # Dashboard servido como archivo estático
    acl path_dashboard path_beg /dashboard
    http-request return status 200 content-type text/html file /dashboard/simple-dashboard.html if path_dashboard
```

## 🔄 2. Testing A/B Avanzado

El sistema implementa un testing A/B robusto y configurable que permite comparar diferentes versiones de aplicaciones.

### 🎯 Configuración A/B Testing:

```haproxy
# ACLs para A/B Testing
acl ab_test_cookie cookie(ab_test) -i B
acl canary_percent rand(100) lt 20  # 20% del tráfico va a versión B

# Reglas de enrutamiento A/B
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags ab_test_cookie
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags canary_percent

# Establecimiento automático de cookies
http-response set-header Set-Cookie "ab_test=A; path=/; max-age=3600" if !ab_test_cookie { rand(100) lt 50 }
http-response set-header Set-Cookie "ab_test=B; path=/; max-age=3600" if !ab_test_cookie { rand(100) ge 50 }
```

### 📋 Características A/B Testing:

- **🍪 Gestión de cookies**: Mantiene consistencia de experiencia por usuario
- **⚖️ Distribución configurable**: Porcentajes ajustables dinámicamente
- **🎲 Distribución aleatoria**: Algoritmo robusto para distribución equitativa
- **📊 Sticky sessions**: Los usuarios mantienen su versión asignada
- **🔄 Tiempo de expiración**: Cookies con TTL de 1 hora configurable

## 🚀 3. Canary Deployment

Implementación completa de Canary deployment para despliegues graduales y seguros.

### 🎯 Configuración Canary:

```haproxy
# ACLs para Canary Deployment
acl canary_user hdr(X-Canary) -i true
acl canary_cookie cookie(canary) -i true
acl canary_percent rand(100) lt 20  # 20% del tráfico

# Reglas de enrutamiento Canary
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags canary_user
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags canary_cookie
```

### 📋 Métodos de Activación Canary:

1. **🍪 Cookie**: `canary=true`
2. **📡 Header HTTP**: `X-Canary: true`
3. **📊 Porcentaje**: Configuración dinámica de porcentaje de tráfico
4. **👥 Usuarios específicos**: Basado en identificadores de usuario

### 📈 Plan de Despliegue Canary Recomendado:

```bash
# Fase 1: 5% del tráfico (validación inicial)
curl -X POST http://localhost:8081/api/canary/percentage/5

# Fase 2: 20% del tráfico (validación extendida)
curl -X POST http://localhost:8081/api/canary/percentage/20

# Fase 3: 50% del tráfico (validación masiva)
curl -X POST http://localhost:8081/api/canary/percentage/50

# Fase 4: 100% del tráfico (despliegue completo)
curl -X POST http://localhost:8081/api/canary/percentage/100
```

## 🏗️ 4. Arquitectura de Backends

El sistema utiliza backends especializados para cada tipo de aplicación y estrategia de despliegue.

### 🎯 Backends Configurados:

| Backend | Propósito | Health Check | Balanceador |
|---------|-----------|--------------|-------------|
| `weblogic-a` | Consola WebLogic A | `/console` (302) | Round Robin |
| `weblogic-b` | Consola WebLogic B | `/console` (302) | Round Robin |
| `version-a-backend` | Aplicación versión A | `/version-a/` (200) | Round Robin |
| `version-b-backend` | Aplicación versión B | `/version-b/` (200) | Round Robin |
| `ff4j-backend` | FF4J Simple | `/ff4j-simple/` (200) | Round Robin |
| `feature-flags-backend` | Feature Flags | `/feature-flags/` (200) | Round Robin |
| `weblogic-features-a` | Features versión A | `/weblogic-features-a/` (200) | Round Robin |
| `weblogic-features-b` | Features versión B | `/weblogic-features-b/` (200) | Round Robin |

### 🔍 Health Checks Avanzados:

```haproxy
# Ejemplo de configuración de health check
backend version-a-backend
    balance roundrobin
    option httpchk GET /version-a/
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    cookie SERVERID insert indirect nocache
    server weblogic-a-version weblogic-a:7001 check cookie A
```

## 📊 5. Monitoreo y Estadísticas

### 🎯 HAProxy Stats (Puerto 8404):

- **📊 Métricas en tiempo real**: Conexiones, requests, errores
- **🔍 Estado de backends**: UP/DOWN, health checks
- **📈 Gráficos de rendimiento**: Throughput, latencia
- **⚙️ Configuración dinámica**: Habilitar/deshabilitar servidores

### 🎯 Dashboard Integrado (Puerto 8080/dashboard):

- **🌐 Vista unificada**: Estado de todos los servicios
- **🔗 Enlaces directos**: Acceso rápido a interfaces
- **📱 Responsive**: Funciona en todos los dispositivos
- **🔄 Auto-actualización**: Datos siempre actualizados

## 🧪 6. Pruebas y Validación

### 🔬 Pruebas de A/B Testing:

```bash
# Probar distribución A/B
for i in {1..100}; do
    curl -s -I http://localhost:8080/ | grep "Set-Cookie: ab_test"
done | sort | uniq -c

# Probar con cookie específica
curl -b "ab_test=A" http://localhost:8080/
curl -b "ab_test=B" http://localhost:8080/
```

### 🚀 Pruebas de Canary Deployment:

```bash
# Probar con header Canary
curl -H "X-Canary: true" http://localhost:8080/

# Probar con cookie Canary
curl -b "canary=true" http://localhost:8080/

# Simular tráfico para validar porcentajes
./scripts/canary/simulate-traffic.sh 1000 0.1
```

### 📊 Validación de Distribución:

```bash
# Script para validar distribución de tráfico
#!/bin/bash
echo "Validando distribución de tráfico..."
for i in {1..1000}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
    echo $RESPONSE
done | sort | uniq -c
```

## ⚙️ 7. Configuración y Administración

### 🛠️ Archivos de Configuración:

| Archivo | Propósito | Ubicación |
|---------|-----------|-----------|
| `haproxy.cfg` | Configuración principal | `/haproxy/config/` |
| `simple-dashboard.html` | Dashboard integrado | `/haproxy/dashboard/` |
| `dynamic_routing.lua` | Scripts Lua avanzados | `/haproxy/scripts/` |
| `admin_api.py` | API de administración | `/haproxy/scripts/` |
| `admin_ui.py` | Interfaz web admin | `/haproxy/scripts/` |

### 🔧 Scripts de Gestión:

```bash
# Iniciar con imágenes construidas (recomendado)
./start-with-images.sh start

# Ver estado de servicios
./start-with-images.sh status

# Ver logs específicos
./start-with-images.sh logs haproxy

# Gestión de tráfico Canary
./scripts/canary/manage-traffic.sh canary 20

# Gestión de A/B Testing
./scripts/canary/manage-traffic.sh ab 30
```

### 📡 API REST para Configuración Dinámica:

```bash
# Cambiar porcentaje Canary
curl -X POST http://localhost:8081/api/canary/percentage/25

# Habilitar/deshabilitar A/B Testing
curl -X POST http://localhost:8081/api/ab/enable
curl -X POST http://localhost:8081/api/ab/disable

# Obtener estadísticas
curl http://localhost:8081/api/stats
```

## 🔒 8. Seguridad y Mejores Prácticas

### 🛡️ Configuración de Seguridad:

- **🔐 Autenticación**: Stats protegidos con usuario/contraseña
- **🌐 Restricción de acceso**: API limitada a redes internas
- **🍪 Cookies seguras**: HTTPOnly y Secure flags cuando corresponde
- **📊 Logs detallados**: Registro completo de actividad

### 📋 Mejores Prácticas:

1. **🔄 Monitoreo continuo**: Verificar health checks regularmente
2. **📊 Análisis de métricas**: Revisar estadísticas de rendimiento
3. **🧪 Pruebas graduales**: Incrementar tráfico Canary progresivamente
4. **🔙 Plan de rollback**: Tener procedimientos de reversión listos
5. **📝 Documentación**: Mantener logs de cambios y configuraciones

## 🚀 9. Próximos Pasos y Mejoras

### 🎯 Mejoras Planificadas:

- **📊 Métricas avanzadas**: Integración con Prometheus/Grafana
- **🤖 Automatización**: Scripts de despliegue automático
- **🔔 Alertas**: Notificaciones automáticas de fallos
- **📈 Analytics**: Análisis detallado de comportamiento de usuarios
- **🔒 Seguridad avanzada**: Integración con sistemas de autenticación

### 🛠️ Configuraciones Adicionales:

```bash
# Habilitar logging avanzado
echo "log 127.0.0.1:514 local0" >> /etc/haproxy/haproxy.cfg

# Configurar SSL/TLS
echo "bind *:443 ssl crt /etc/ssl/certs/haproxy.pem" >> /etc/haproxy/haproxy.cfg

# Habilitar compresión
echo "compression algo gzip" >> /etc/haproxy/haproxy.cfg
```

---

## 📚 Referencias y Enlaces Útiles

- **HAProxy Documentation**: https://docs.haproxy.org/
- **A/B Testing Best Practices**: https://blog.haproxy.com/ab-testing/
- **Canary Deployment Strategies**: https://martinfowler.com/bliki/CanaryRelease.html
- **Load Balancing Algorithms**: https://docs.haproxy.org/2.8/configuration.html#balance

---

**🎉 El sistema HAProxy avanzado está completamente configurado y listo para producción con todas las funcionalidades de testing A/B, Canary deployment y monitoreo integrado.**
