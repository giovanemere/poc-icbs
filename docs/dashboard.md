# Dashboard y Monitoreo

## HAProxy Stats Dashboard

El sistema incluye un dashboard de estadísticas de HAProxy accesible en:

- **URL**: http://localhost:8404/stats
- **Usuario**: admin
- **Contraseña**: admin123

### Métricas Disponibles

- **Requests por segundo**
- **Tiempo de respuesta promedio**
- **Estado de health checks**
- **Distribución de tráfico**
- **Errores y timeouts**

## Monitoreo de Aplicaciones

### WebLogic Console
- **URL**: http://localhost:7001/console
- **Usuario**: weblogic
- **Contraseña**: welcome1

### Logs Centralizados

```bash
# Ver logs de todos los servicios
./manage-services.sh logs

# Ver logs específicos
./manage-services.sh logs haproxy
./manage-services.sh logs weblogic1
./manage-services.sh logs oracle
```

## Alertas y Notificaciones

El sistema puede configurarse para enviar alertas cuando:

- Un servicio se vuelve no disponible
- El tiempo de respuesta excede umbrales
- Se detectan errores críticos
- La carga del sistema es alta

Para configurar alertas, consulta la [guía de configuración avanzada](haproxy-advanced-config.md).
