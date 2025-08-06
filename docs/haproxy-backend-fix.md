# Corrección de Backends HAProxy - WebLogic

## Problema Identificado
**Fecha**: 2025-08-01  
**Estado**: ✅ RESUELTO

### Síntomas
- Los servicios `weblogic-features-a` y `weblogic-features-b` aparecían como DOWN en HAProxy
- Los backends `weblogic-a` y `weblogic-b` funcionaban correctamente
- Otros backends como `ff4j-backend` y `feature-flags-backend` estaban UP

### Causa Raíz
Los backends `weblogic-features-a` y `weblogic-features-b` estaban configurados con health checks hacia el endpoint `/weblogic-features/` que no existe en los servidores WebLogic, devolviendo código 404.

```bash
# Health check original (INCORRECTO)
option httpchk GET /weblogic-features/
# Resultado: 404 Not Found → Backend DOWN
```

### Solución Aplicada
Se cambió el health check de los backends `weblogic-features-*` para usar el endpoint `/console` que existe y devuelve código 302:

```bash
# Health check corregido
option httpchk GET /console
http-check expect status 200,302
```

### Comandos Ejecutados
```bash
# 1. Diagnóstico del problema
curl -s -u admin:admin123 "http://localhost:8404/stats;csv" | grep weblogic-features

# 2. Verificación de endpoints
curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/weblogic-features/  # 404
curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/console            # 302

# 3. Corrección de configuración
docker exec haproxy sed -i 's|option httpchk GET /weblogic-features/|option httpchk GET /console|g' /usr/local/etc/haproxy/haproxy.cfg

# 4. Reinicio de HAProxy
docker-compose -f config/docker-compose.yml restart haproxy
```

### Estado Final
✅ **Todos los backends WebLogic están UP**:
- `weblogic-a`: UP
- `weblogic-b`: UP  
- `weblogic-features-a`: UP
- `weblogic-features-b`: UP
- `ff4j-backend`: UP
- `feature-flags-backend`: UP

### URLs de Verificación
- HAProxy Stats: http://localhost:8404/stats (admin/admin123)
- Load Balancer: http://localhost:8083/
- WebLogic A: http://localhost:7001/console
- WebLogic B: http://localhost:7002/console

### Lecciones Aprendidas
1. Los health checks deben apuntar a endpoints que existan realmente
2. Es importante verificar los códigos de respuesta esperados (200, 302, etc.)
3. Los backends de A/B testing deben usar el mismo health check que los backends principales
4. Siempre hacer backup de configuraciones antes de modificar

### Próximos Pasos
- [ ] Implementar monitoreo automático de backends
- [ ] Crear scripts de validación de health checks
- [ ] Documentar todos los endpoints disponibles en WebLogic
