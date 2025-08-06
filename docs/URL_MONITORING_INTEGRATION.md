# Integración del Sistema de Monitoreo de URLs

## Resumen

Este documento describe la integración del nuevo sistema de monitoreo de URLs con el dashboard HAProxy existente, solucionando el problema "Error al cargar datos: NOT FOUND".

## Arquitectura de la Solución

### Componentes

1. **Servicio Principal de Monitoreo** (Puerto 8090)
   - Monitoreo continuo de URLs cada 30s
   - Actualización automática de IPs de contenedores
   - API REST completa
   - Logs detallados

2. **Servicio de Integración HAProxy** (Puerto 8085)
   - Compatibilidad con dashboard existente
   - Traducción de formatos de datos
   - Fallback en caso de errores

3. **Configuración Centralizada**
   - Variables de entorno en `.env`
   - Archivo JSON de configuración
   - Mapeo automático de puertos

## Endpoints Principales

### Sistema de Monitoreo
- `GET /api/status` - Estado del servicio
- `GET /api/url-status` - Estado de todas las URLs
- `POST /api/url-status/refresh` - Forzar actualización
- `POST /api/containers/update-ips` - Actualizar IPs de contenedores
- `POST /api/config/reload` - Recargar configuración

### Integración HAProxy
- `GET /api/url-status` - Endpoint compatible con dashboard
- `GET /api/status` - Estado de la integración

## Uso

### Inicio Rápido
```bash
# Iniciar sistema completo
./scripts/monitoring/setup-complete-monitoring.sh

# O usar el script integrado
./start-monitoring-integrated.sh
```

### Verificación
```bash
# Probar sistema
./scripts/monitoring/test-monitoring-system.sh

# Ver estado
curl http://localhost:8090/api/url-status | jq
```

### Detener
```bash
./scripts/monitoring/stop-monitoring.sh
```

## Configuración

### Variables de Entorno (.env)
```bash
URL_STATUS_SERVICE_PORT=8090
HAPROXY_INTEGRATION_PORT=8085
URL_CHECK_INTERVAL=30
URL_CHECK_TIMEOUT=5
URL_CHECK_RETRIES=3
```

### URLs Monitoreadas
- HAProxy Load Balancer: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT}/
- HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT}/stats
- HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT}/
- WebLogic Server A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT}/console
- WebLogic Server B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT}/console
- MkDocs Documentation: http://localhost:${MKDOCS_EXTERNAL_PORT}/

## Características

### ✅ Solucionado
- Error "NOT FOUND" por cambios de IP
- Monitoreo manual vs automático
- Configuración dispersa en múltiples archivos
- Falta de logs detallados
- Sin actualización automática de IPs

### ✅ Implementado
- Monitoreo automático continuo
- Actualización automática de IPs cuando hay errores críticos
- API REST completa
- Logs detallados con rotación
- Configuración centralizada
- Compatible con dashboard existente
- Demonio de monitoreo
- Sistema de reintentos
- Detección de contenedores Docker
- Backup automático de configuraciones

## Troubleshooting

### Problema: Servicio no inicia
```bash
# Verificar puertos
netstat -tuln | grep -E "(8090|8085)"

# Ver logs
tail -f logs/monitoring/url-monitoring-$(date +%Y%m%d).log
```

### Problema: URLs siguen fallando
```bash
# Forzar actualización de IPs
curl -X POST http://localhost:8090/api/containers/update-ips

# Verificar contenedores
docker ps
```

### Problema: Dashboard no muestra datos
```bash
# Verificar integración
curl http://localhost:8085/api/url-status

# Verificar logs de integración
tail -f logs/monitoring/haproxy-integration-$(date +%Y%m%d).log
```

## Archivos Importantes

- `scripts/monitoring/url-status-service.py` - Servicio principal
- `scripts/monitoring/haproxy-url-integration.py` - Integración HAProxy
- `config/monitoring/url-monitoring.json` - Configuración
- `logs/monitoring/` - Directorio de logs
- `.env` - Variables de entorno

## Mantenimiento

### Logs
Los logs se rotan automáticamente cuando superan 10MB.

### Configuración
Para agregar nuevas URLs, editar el archivo `.env` y reiniciar:
```bash
./scripts/monitoring/stop-monitoring.sh
./scripts/monitoring/setup-complete-monitoring.sh
```

### Backup
Las configuraciones se respaldan automáticamente antes de cambios.
