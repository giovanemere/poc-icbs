# WebLogic Feature Flags - Docker Image

## Descripción
Imagen Docker de WebLogic Server 12.2.1.3 con sistema integrado de Feature Flags para deployments canary y A/B testing.

## Características
- WebLogic Server 12.2.1.3
- Sistema de Feature Flags integrado
- Health checks automáticos
- Soporte para deployments canary
- Configuración A/B testing
- Auto-deployment habilitado

## Uso
```bash
docker run -d -p 7001:7001 -p 7002:7002 \
  --name weblogic-features \
  edissonz8809/weblogic-feature-flags:v1.1.0
```

## Puertos
- 7001: WebLogic Admin Server
- 7002: WebLogic Managed Server
- 9002: Debug port

## Variables de Entorno
- FEATURE_FLAGS_ENABLED=true
- ADMIN_PASSWORD=welcome1
- LOG_LEVEL=INFO

## Health Check
La imagen incluye health checks automáticos que verifican el estado del servidor WebLogic.

## Versión
v1.1.0 - 2025-07-31
