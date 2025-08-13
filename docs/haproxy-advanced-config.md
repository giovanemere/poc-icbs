# HAProxy Advanced Configuration (haproxy-advanced.cfg)

Este documento describe la configuración avanzada de HAProxy implementada en `haproxy-advanced.cfg`, que incluye todas las mejoras y funcionalidades del sistema.

## 📋 Tabla de Contenidos

1. [Configuración Global](#configuración-global)
2. [Frontend HTTP Principal](#frontend-http-principal)
3. [Dashboard Integrado](#dashboard-integrado)
4. [Testing A/B y Canary](#testing-ab-y-canary)
5. [Backends de Aplicaciones](#backends-de-aplicaciones)
6. [Monitoreo y Estadísticas](#monitoreo-y-estadísticas)
7. [API de Administración](#api-de-administración)
8. [Configuración de Seguridad](#configuración-de-seguridad)

## 🌐 Configuración Global

```haproxy
global
    log stdout format raw local0
    maxconn 4096
    tune.ssl.default-dh-param 2048
    stats socket /var/run/haproxy.sock mode 666 level admin
    lua-load /scripts/dynamic_routing.lua
```

### Características:
- **📊 Logging**: Salida directa a stdout para Docker
- **🔧 Conexiones**: Máximo 4096 conexiones concurrentes
- **🔒 SSL/TLS**: Parámetros DH de 2048 bits para seguridad
- **⚙️ Runtime API**: Socket para configuración dinámica
- **🚀 Lua Scripts**: Carga de scripts para routing avanzado

## 🌍 Frontend HTTP Principal

### Configuración Base:
```haproxy
frontend http-in
    bind *:80
    mode http
```

### ACLs (Access Control Lists):
```haproxy
# Identificación de rutas de aplicaciones
acl path_ff4j path_beg /ff4j-simple
acl path_feature_flags path_beg /feature-flags
acl path_version_a path_beg /version-a
acl path_version_b path_beg /version-b
acl path_weblogic_features_a path_beg /weblogic-features-a
acl path_weblogic_features_b path_beg /weblogic-features-b

# ACLs para A/B Testing y Canary
acl canary_percent rand(100) lt 20  # 20% tráfico a versión B
acl canary_user hdr(X-Canary) -i true
acl canary_cookie cookie(canary) -i true
acl ab_test_cookie cookie(ab_test) -i B
```

## 📊 Dashboard Integrado

### Configuración:
```haproxy
# Dashboard servido como archivo estático
acl path_dashboard path_beg /dashboard
http-request return status 200 content-type text/html file /dashboard/simple-dashboard.html if path_dashboard
```

### Características:
- **⚡ Alto rendimiento**: Servido directamente por HAProxy
- **📱 Responsive**: Diseño adaptable
- **🔄 Auto-refresh**: Actualización automática cada 30s
- **🔗 Enlaces rápidos**: Acceso directo a todos los servicios

### URL de Acceso:
- **Dashboard**: http://localhost:8080/dashboard/

## 🧪 Testing A/B y Canary Deployment

### Reglas de Enrutamiento:
```haproxy
# Reglas para rutas genéricas (no específicas)
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags !path_dashboard canary_user
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags !path_dashboard canary_cookie
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags !path_dashboard ab_test_cookie
use_backend version-b-backend if !path_version_a !path_version_b !path_weblogic_features_a !path_weblogic_features_b !path_ff4j !path_feature_flags !path_dashboard canary_percent
```

### Gestión de Cookies:
```haproxy
# Establecimiento automático de cookies A/B
http-response set-header Set-Cookie "ab_test=A; path=/; max-age=3600; HttpOnly" if !ab_test_cookie { rand(100) lt 50 }
http-response set-header Set-Cookie "ab_test=B; path=/; max-age=3600; HttpOnly" if !ab_test_cookie { rand(100) ge 50 }
```

### Métodos de Activación:

| Método | Descripción | Ejemplo |
|--------|-------------|---------|
| **Cookie** | `canary=true` | `curl -b "canary=true" http://localhost:8080/` |
| **Header** | `X-Canary: true` | `curl -H "X-Canary: true" http://localhost:8080/` |
| **A/B Cookie** | `ab_test=B` | `curl -b "ab_test=B" http://localhost:8080/` |
| **Porcentaje** | Distribución aleatoria | Automático (20% por defecto) |

## 🏗️ Backends de Aplicaciones

### WebLogic Backends:
```haproxy
# WebLogic A
backend weblogic-a
    balance roundrobin
    option httpchk GET /console
    http-check expect status 302
    default-server inter 3s fall 3 rise 2
    cookie JSESSIONID prefix nocache
    server weblogic-a weblogic-a:7001 check weight 100 cookie A

# WebLogic B
backend weblogic-b
    balance roundrobin
    option httpchk GET /console
    http-check expect status 302
    default-server inter 3s fall 3 rise 2
    cookie JSESSIONID prefix nocache
    server weblogic-b weblogic-b:7001 check weight 100 cookie B
```

### Backends de Aplicaciones:
```haproxy
# FF4J Simple
backend ff4j-backend
    balance roundrobin
    option httpchk GET /ff4j-simple/
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server weblogic-a-ff4j weblogic-a:7001 check weight 100
    server weblogic-b-ff4j weblogic-b:7001 check backup weight 50

# Feature Flags
backend feature-flags-backend
    balance roundrobin
    option httpchk GET /feature-flags/
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server weblogic-a-feature weblogic-a:7001 check weight 100
    server weblogic-b-feature weblogic-b:7001 check backup weight 50
```

### Backends A/B Testing:
```haproxy
# Version A
backend version-a-backend
    balance roundrobin
    option httpchk GET /version-a/
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    cookie SERVERID insert indirect nocache
    http-request set-header X-Backend-Version "A"
    http-response set-header X-Served-By "Version-A"
    server weblogic-a-version weblogic-a:7001 check cookie A weight 100

# Version B
backend version-b-backend
    balance roundrobin
    option httpchk GET /version-b/
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    cookie SERVERID insert indirect nocache
    http-request set-header X-Backend-Version "B"
    http-response set-header X-Served-By "Version-B"
    server weblogic-b-version weblogic-b:7001 check cookie B weight 100
```

## 📊 Monitoreo y Estadísticas

### HAProxy Stats:
```haproxy
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 5s
    stats show-legends
    stats show-node
    stats auth admin:admin123
    stats admin if TRUE
    stats hide-version
    stats realm "HAProxy Statistics - WebLogic A/B Testing"
    stats show-desc "Sistema de Load Balancing con A/B Testing y Canary Deployment"
```

### Características:
- **🔄 Refresh automático**: Cada 5 segundos
- **🔐 Autenticación**: admin/admin123
- **⚙️ Administración**: Habilitar/deshabilitar servidores
- **📊 Métricas detalladas**: Conexiones, requests, errores
- **🏷️ Información personalizada**: Descripción del sistema

### URL de Acceso:
- **Stats**: http://localhost:8404/stats

## 🔧 API de Administración

### Frontend API:
```haproxy
frontend management-api
    bind *:8081
    mode http
    
    # Seguridad - solo redes internas
    acl authorized_management src 127.0.0.1 172.0.0.0/8 10.0.0.0/8
    http-request deny unless authorized_management
    
    # Headers de seguridad
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-Frame-Options DENY
    http-response set-header X-XSS-Protection "1; mode=block"
    
    use_backend management-backend
```

### Frontend UI Admin:
```haproxy
frontend admin-ui
    bind *:8082
    mode http
    
    # Seguridad - solo redes internas
    acl authorized_ui src 127.0.0.1 172.0.0.0/8 10.0.0.0/8
    http-request deny unless authorized_ui
    
    # Headers de seguridad
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-Frame-Options SAMEORIGIN
    http-response set-header X-XSS-Protection "1; mode=block"
    
    use_backend admin-ui-backend
```

### URLs de Acceso:
- **API**: http://localhost:8081/api
- **Admin UI**: http://localhost:8082

## 🔒 Configuración de Seguridad

### Restricciones de Acceso:
```haproxy
# Solo redes internas pueden acceder a la administración
acl authorized_management src 127.0.0.1 172.0.0.0/8 10.0.0.0/8
acl authorized_ui src 127.0.0.1 172.0.0.0/8 10.0.0.0/8
```

### Headers de Seguridad:
```haproxy
# Prevención de ataques
http-response set-header X-Content-Type-Options nosniff
http-response set-header X-Frame-Options DENY
http-response set-header X-XSS-Protection "1; mode=block"
```

### Cookies Seguras:
```haproxy
# Cookies con HttpOnly flag
http-response set-header Set-Cookie "ab_test=A; path=/; max-age=3600; HttpOnly"
```

## 🚀 Funcionalidades Avanzadas

### Headers de Tracking:
```haproxy
# Headers para debugging y analytics
http-request set-header X-Request-ID %[uuid()]
http-request set-header X-Current-Weight str(100)
http-response set-header X-Backend-Server %[res.hdr(Server)]
http-response set-header X-Response-Time %Tr
```

### Health Checks Avanzados:
```haproxy
# Configuración de health checks
option httpchk GET /version-a/
http-check expect status 200
default-server inter 3s fall 3 rise 2
```

### Parámetros de Health Check:
- **inter 3s**: Verificación cada 3 segundos
- **fall 3**: 3 fallos consecutivos para marcar como DOWN
- **rise 2**: 2 éxitos consecutivos para marcar como UP

## 📈 Configuraciones Opcionales

### Logging Avanzado:
```haproxy
# Descomentar para habilitar logging a syslog
# log 127.0.0.1:514 local0 info
```

### Compresión:
```haproxy
# Descomentar para habilitar compresión
# compression algo gzip
# compression type text/html text/plain text/css text/javascript application/javascript application/json
```

### Rate Limiting:
```haproxy
# Descomentar para habilitar rate limiting
# stick-table type ip size 100k expire 30s store http_req_rate(10s)
# http-request track-sc0 src
# http-request deny if { sc_http_req_rate(0) gt 20 }
```

## 🔧 Comandos de Gestión

### Usar la Configuración Avanzada:
```bash
# Copiar la configuración avanzada como principal
cp haproxy/config/haproxy-advanced.cfg haproxy/config/haproxy.cfg

# Reiniciar HAProxy con la nueva configuración
./start-with-images.sh restart
```

### Validar Configuración:
```bash
# Validar sintaxis de la configuración
docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
```

### Recargar Configuración:
```bash
# Recargar sin interrumpir el servicio
docker exec haproxy kill -USR2 1
```

## 📊 Métricas y Monitoreo

### URLs de Monitoreo:
- **Dashboard**: http://localhost:8080/dashboard/
- **HAProxy Stats**: http://localhost:8404/stats
- **Admin UI**: http://localhost:8082
- **API Health**: http://localhost:8081/api/health

### Métricas Clave:
- **Conexiones activas**: Número de conexiones concurrentes
- **Requests por segundo**: Throughput del sistema
- **Tiempo de respuesta**: Latencia promedio
- **Estado de backends**: UP/DOWN de cada servidor
- **Distribución de tráfico**: Porcentajes A/B y Canary

## 🎯 Casos de Uso

### 1. Despliegue Canary Gradual:
```bash
# Fase 1: 5% del tráfico
# Modificar canary_percent rand(100) lt 5

# Fase 2: 20% del tráfico
# Modificar canary_percent rand(100) lt 20

# Fase 3: 50% del tráfico
# Modificar canary_percent rand(100) lt 50

# Fase 4: 100% del tráfico
# Cambiar default_backend a version-b-backend
```

### 2. A/B Testing por Usuarios:
```bash
# Usuarios específicos siempre ven versión B
curl -H "X-Canary: true" http://localhost:8080/

# Usuarios con cookie específica
curl -b "canary=true" http://localhost:8080/
```

### 3. Rollback Rápido:
```bash
# En caso de problemas, deshabilitar servidor problemático
echo "disable server version-b-backend/weblogic-b-version" | socat stdio /var/run/haproxy.sock
```

---

**🎉 La configuración avanzada de HAProxy proporciona un sistema completo de load balancing con A/B testing, Canary deployment, dashboard integrado y monitoreo avanzado, listo para entornos de producción.**
