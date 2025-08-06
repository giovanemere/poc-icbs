# Documentación del Proyecto Docker Oracle WebLogic

Bienvenido a la documentación completa del proyecto Docker Oracle WebLogic con HAProxy y feature flags.

## 🚀 Inicio Rápido

Para iniciar todos los servicios:

```bash
./manage-services.sh start
```

## 📋 Servicios Disponibles

### WebLogic Servers
- **WebLogic A**: http://localhost:7001/console
- **WebLogic B**: http://localhost:7002/console

### HAProxy Load Balancer
- **Load Balancer**: http://localhost:8083
- **HAProxy Stats**: http://localhost:8404/stats
- **HAProxy Admin**: http://localhost:8082

### Base de Datos Oracle
- **Oracle Database**: localhost:1521 (XE)
- **Oracle EM Express**: https://localhost:5500/em

### Documentación
- **Esta documentación**: http://localhost:8000

## 🛠️ Comandos Útiles

```bash
# Ver estado de los servicios
./manage-services.sh status

# Ver logs en tiempo real
./manage-services.sh logs --follow

# Detener servicios
./manage-services.sh stop

# Actualizar HAProxy
./manage-services.sh update-haproxy
```

## 📚 Más Información

- [Primeros Pasos](getting-started.md)
- [Arquitectura del Sistema](arquitectura.md)
- [Configuración de HAProxy](haproxy.md)
- [Despliegues Canary](canary-and-features.md)
