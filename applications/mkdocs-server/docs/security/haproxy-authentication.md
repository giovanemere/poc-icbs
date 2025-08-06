# Autenticación HAProxy - Configuración y Gestión

## 📋 Resumen

La autenticación para HAProxy Stats está configurada y funcionando correctamente, proporcionando acceso seguro a las estadísticas y panel de administración.

## 🔐 Configuración Actual

### Credenciales por Defecto
- **Usuario**: `admin`
- **Contraseña**: `admin123`
- **URL Stats**: http://localhost:8404/stats
- **URL Admin**: http://localhost:8082/

### Configuración en HAProxy
```haproxy
# Stats interface
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    stats show-desc "WebLogic + MkDocs Load Balancer"
    stats auth admin:admin123
```

## 🛠️ Scripts de Gestión

### 1. Verificar Estado de Autenticación
```bash
./scripts/monitoring/check-haproxy-auth-status.sh
```

**Funciones:**
- ✅ Verifica configuración actual
- ✅ Prueba autenticación sin credenciales (debe devolver 401)
- ✅ Prueba autenticación con credenciales (debe devolver 200)
- ✅ Valida contenido de la página de estadísticas
- ✅ Compara configuración con sistema de monitoreo

### 2. Configurar Credenciales Seguras
```bash
./scripts/security/setup-haproxy-auth.sh
```

**Funciones:**
- 🎲 Genera credenciales aleatorias seguras
- 💾 Crea backups de configuraciones
- ⚙️ Actualiza configuración de HAProxy
- 📊 Actualiza configuración de monitoreo
- 🔄 Reinicia servicios automáticamente
- 🧪 Prueba nueva autenticación

### 3. Probar Autenticación
```bash
python3 scripts/monitoring/test-haproxy-auth.py
```

## 📊 Integración con Monitoreo

### Configuración JSON
```json
{
  "name": "HAProxy Stats",
  "url": "http://localhost:8404/stats",
  "type": "monitoring",
  "critical": false,
  "expected_codes": [200],
  "description": "HAProxy statistics with basic authentication",
  "auth": {
    "type": "basic",
    "username": "admin",
    "password": "admin123"
  }
}
```

### Servicio de Monitoreo
El servicio de monitoreo (`url-status-service.py`) incluye soporte para autenticación HTTP básica:

```python
# Configurar autenticación si está presente
auth = None
if 'auth' in url_config:
    auth_config = url_config['auth']
    if auth_config.get('type') == 'basic':
        from requests.auth import HTTPBasicAuth
        auth = HTTPBasicAuth(
            auth_config.get('username', ''),
            auth_config.get('password', '')
        )

response = requests.get(url, auth=auth, ...)
```

## 🔒 Seguridad

### Mejores Prácticas Implementadas
- ✅ **Autenticación requerida**: Sin credenciales devuelve 401
- ✅ **Credenciales validadas**: Solo credenciales correctas permiten acceso
- ✅ **Integración con monitoreo**: Sistema automatizado usa autenticación
- ✅ **Scripts de gestión**: Herramientas para cambiar credenciales

### Recomendaciones de Seguridad
- 🔄 **Cambiar credenciales por defecto** usando `setup-haproxy-auth.sh`
- 🔐 **Usar contraseñas fuertes** (el script genera automáticamente)
- 💾 **Hacer backups** antes de cambios (automático en scripts)
- 📝 **Documentar cambios** y guardar credenciales de forma segura

## 🧪 Pruebas y Validación

### Comandos de Prueba Manual
```bash
# Sin autenticación (debe devolver 401)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8404/stats

# Con autenticación (debe devolver 200)
curl -s -o /dev/null -w "%{http_code}" -u admin:admin123 http://localhost:8404/stats

# Verificar contenido
curl -s -u admin:admin123 http://localhost:8404/stats | head -10
```

### Resultados Esperados
- **Sin auth**: `401 Unauthorized`
- **Con auth correcta**: `200 OK` + contenido HTML
- **Con auth incorrecta**: `401 Unauthorized`

## 📈 Estado Actual

### ✅ Completado
- [x] Configuración básica de autenticación
- [x] Integración con sistema de monitoreo
- [x] Scripts de verificación y gestión
- [x] Documentación completa
- [x] Pruebas automatizadas

### 🔄 Próximos Pasos
- [ ] Implementar rotación automática de credenciales
- [ ] Agregar autenticación por certificados SSL
- [ ] Integrar con sistema de logs de seguridad
- [ ] Configurar alertas por intentos de acceso fallidos

## 🚨 Troubleshooting

### Problema: Autenticación no funciona
```bash
# Verificar configuración
./scripts/monitoring/check-haproxy-auth-status.sh

# Revisar logs de HAProxy
docker logs haproxy

# Reiniciar HAProxy
docker-compose -f config/docker-compose.yml restart haproxy
```

### Problema: Monitoreo no puede acceder
```bash
# Verificar configuración de monitoreo
python3 scripts/monitoring/test-monitoring-auth.py

# Actualizar configuración si es necesario
# Editar: config/monitoring/url-monitoring.json
```

## 📞 Soporte

Para problemas relacionados con autenticación HAProxy:
1. Ejecutar script de diagnóstico: `check-haproxy-auth-status.sh`
2. Revisar logs de HAProxy: `docker logs haproxy`
3. Verificar configuración: `applications/haproxy-advanced/config/haproxy.cfg`
4. Probar manualmente con curl

---

**Última actualización**: 2025-08-01  
**Estado**: ✅ Funcionando correctamente  
**Versión**: 1.0
