# POC ICBS - Sistema Core Banking Integrado

Sistema Core Banking Integrado basado en Oracle WebLogic con soporte para estrategias avanzadas de despliegue como Testing A/B, Canary Deployment y Feature Flags utilizando HAProxy.

## Características Principales

- **Oracle WebLogic** como servidor de aplicaciones
- **Testing A/B** para comparar diferentes versiones
- **Canary Deployment** para despliegues graduales
- **Feature Flags** para control de funcionalidades
- **HAProxy** como balanceador de carga
- **Modo oscuro** en interfaces de usuario
- **Herramientas de build local**

## Arquitectura del Sistema

El sistema está diseñado con una arquitectura de microservicios que permite:

- Balanceo de carga inteligente
- Despliegues sin tiempo de inactividad
- Monitoreo en tiempo real
- Escalabilidad horizontal

## Comandos Principales

### Uso Diario
```bash
./manage-services.sh start    # Iniciar todo
./manage-services.sh status   # Ver estado
./manage-services.sh stop     # Detener todo
```

### Desarrollo/Debugging
```bash
./manage-services.sh logs --follow haproxy  # Ver logs de HAProxy
./manage-services.sh restart                # Reiniciar rápido
./manage-services.sh update-haproxy         # Solo actualizar HAProxy
```

## Documentación Adicional

- [Arquitectura](arquitectura.md) - Detalles de la arquitectura del sistema
- [Guía de Despliegue](deployment-guide.md) - Instrucciones de despliegue
- [Configuración HAProxy](haproxy-guide.md) - Configuración del balanceador
- [Feature Flags](feature-flags-deployment.md) - Gestión de feature flags

## Enlaces

- [Repositorio GitHub](https://github.com/giovanemere/poc-icbs)
- [Issues](https://github.com/giovanemere/poc-icbs/issues)
