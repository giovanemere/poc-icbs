# Integración del Sistema

## Componentes Integrados

El sistema POC ICBS integra múltiples componentes para proporcionar una solución completa de Core Banking:

### Oracle WebLogic
- Servidor de aplicaciones principal
- Gestión de transacciones
- Pool de conexiones a base de datos

### HAProxy
- Balanceador de carga
- Terminación SSL
- Health checks automáticos

### Base de Datos Oracle
- Almacenamiento de datos transaccionales
- Respaldos automáticos
- Replicación

## Flujo de Integración

1. **Cliente** → HAProxy (puerto 80/443)
2. **HAProxy** → WebLogic Instances (puertos 7001, 7002)
3. **WebLogic** → Oracle Database (puerto 1521)

## Configuración de Red

- Red Docker: `icbs-network`
- Subnet: `172.20.0.0/16`
- DNS interno automático

Para más detalles, consulta la [documentación de Docker Compose](DOCKER-COMPOSE-INTEGRATED.md).
