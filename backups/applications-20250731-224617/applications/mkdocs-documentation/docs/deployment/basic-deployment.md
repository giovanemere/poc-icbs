# Guía de Despliegue

Esta guía cubre todo lo relacionado con el despliegue de aplicaciones, desde la construcción hasta el redespliegue y automatización.

## 🏗️ Construcción de Aplicaciones

### Scripts de Build Principales

| Script | Función | Uso |
|--------|---------|-----|
| `build.sh` | Construir imagen Docker | `./build.sh` |
| `build-wars.sh` | Compilar archivos WAR | `./build-wars.sh` |
| `create-simple-wars.sh` | Crear WARs de ejemplo | `./create-simple-wars.sh` |

### Construcción Completa

```bash
# Construcción completa del proyecto
./build.sh

# Solo construir WARs
./build-wars.sh

# Crear aplicaciones de ejemplo
./create-simple-wars.sh
```

### Construcción Personalizada

```bash
# Construir WAR específico
cd war-projects/mi-aplicacion
mvn clean package

# Construir con perfil específico
mvn clean package -P production

# Construir con tests
mvn clean package -DskipTests=false
```

## 📦 Despliegue de Aplicaciones

### Despliegue Básico

```bash
# Desplegar WAR directamente
./deploy-war.sh path/to/application.war

# Auto-deployment (más simple)
cp application.war autodeploy/
```

### Despliegue con Configuración

```bash
# Desplegar con contexto específico
./deploy-war.sh myapp.war /custom-context

# Desplegar en servidor específico
./deploy-war.sh myapp.war default managed-server-1

# Desplegar con opciones avanzadas
./deploy-war.sh myapp.war /myapp managed-server-1 --force
```

### Verificación de Despliegue

```bash
# Verificar estado de aplicación
curl -I http://localhost:8080/myapp

# Verificar en WebLogic Console
# http://localhost:7001/console -> Deployments

# Verificar logs de despliegue
docker-compose logs weblogic-admin | grep -i deploy
```

## 🔄 Redespliegue y Actualización

### Redespliegue Rápido

```bash
# Redesplegar aplicación existente
./deploy-war.sh new-version.war --redeploy

# Redesplegar con limpieza de caché
./deploy-war.sh new-version.war --clean-cache
```

### Actualización de Clases

Para desarrollo rápido sin redespliegue completo:

```bash
# Actualizar clases específicas
./scripts/deploy/update-classes.sh com.mycompany.MyClass

# Actualizar recursos estáticos
./scripts/deploy/update-resources.sh webapp/css/styles.css
```

### Gestión de Versiones

```bash
# Crear backup antes de redespliegue
./scripts/utils/backup.sh

# Redesplegar con rollback automático
./deploy-war.sh new-version.war --with-rollback

# Rollback manual
./scripts/deploy/rollback.sh previous-version.war
```

## 🚀 Automatización de Despliegue

### Pipeline de CI/CD

```yaml
# Ejemplo GitHub Actions
name: Deploy to WebLogic
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build WAR
        run: |
          cd war-projects/myapp
          mvn clean package
      
      - name: Deploy to WebLogic
        run: |
          ./deploy-war.sh war-projects/myapp/target/myapp.war
      
      - name: Verify Deployment
        run: |
          curl -f http://localhost:8080/myapp/health
```

### Script de Despliegue Automático

```bash
#!/bin/bash
# auto-deploy.sh

set -e

APP_NAME="$1"
VERSION="$2"

echo "🚀 Iniciando despliegue automático de $APP_NAME v$VERSION"

# 1. Backup actual
echo "📦 Creando backup..."
./scripts/utils/backup.sh

# 2. Build
echo "🏗️ Construyendo aplicación..."
cd war-projects/$APP_NAME
mvn clean package -DskipTests

# 3. Deploy
echo "📤 Desplegando aplicación..."
cd ../..
./deploy-war.sh war-projects/$APP_NAME/target/$APP_NAME.war

# 4. Verificar
echo "✅ Verificando despliegue..."
sleep 30
curl -f http://localhost:8080/$APP_NAME/health || {
    echo "❌ Despliegue falló, ejecutando rollback..."
    ./scripts/deploy/rollback.sh
    exit 1
}

echo "✅ Despliegue completado exitosamente"
```

## 🔧 Configuración de Despliegue

### Variables de Entorno para Despliegue

```bash
# En .env
DEPLOYMENT_TIMEOUT=300
AUTO_DEPLOYMENT_ENABLED=true
HOT_DEPLOYMENT_ENABLED=true
DEPLOYMENT_BACKUP_ENABLED=true
```

### Configuración de WebLogic

```properties
# config/weblogic/deployment.properties
weblogic.deployment.timeout=300
weblogic.deployment.stage.mode=nostage
weblogic.deployment.upload.enabled=true
weblogic.deployment.plan.enabled=false
```

### Configuración de Maven

```xml
<!-- pom.xml -->
<plugin>
    <groupId>com.oracle.weblogic</groupId>
    <artifactId>weblogic-maven-plugin</artifactId>
    <version>12.2.1-4-0</version>
    <configuration>
        <adminurl>t3://localhost:7001</adminurl>
        <user>weblogic</user>
        <password>welcome1</password>
        <targets>managed-server-1,managed-server-2</targets>
        <upload>true</upload>
        <action>deploy</action>
    </configuration>
</plugin>
```

## 📊 Monitoreo de Despliegues

### Logs de Despliegue

```bash
# Ver logs en tiempo real
docker-compose logs -f weblogic-admin | grep -i deploy

# Logs específicos de aplicación
docker-compose logs weblogic-managed-1 | grep myapp

# Logs de HAProxy para verificar tráfico
docker-compose logs haproxy-lb | grep myapp
```

### Métricas de Despliegue

```bash
# Tiempo de despliegue
time ./deploy-war.sh myapp.war

# Estado de aplicaciones
curl http://localhost:7001/management/weblogic/latest/domainRuntime/deployments

# Métricas de HAProxy
curl http://localhost:8404/stats | grep myapp
```

## 🎯 Estrategias de Despliegue

### Blue-Green Deployment

```bash
# 1. Desplegar en ambiente "green"
./deploy-war.sh myapp-v2.war green-cluster

# 2. Verificar en green
curl http://green-cluster:8080/myapp/health

# 3. Cambiar tráfico a green
./scripts/deploy/switch-traffic.sh green

# 4. Verificar tráfico
curl http://localhost:8080/myapp
```

### Rolling Deployment

```bash
# 1. Desplegar en servidor 1
./deploy-war.sh myapp.war managed-server-1

# 2. Verificar servidor 1
curl http://managed-server-1:7003/myapp/health

# 3. Desplegar en servidor 2
./deploy-war.sh myapp.war managed-server-2

# 4. Verificar balanceador
curl http://localhost:8080/myapp
```

## 🔍 Troubleshooting de Despliegue

### Problemas Comunes

**Error: "Application already exists"**
```bash
# Solución: Forzar redespliegue
./deploy-war.sh myapp.war --force

# O desinstalar primero
./scripts/deploy/undeploy.sh myapp
./deploy-war.sh myapp.war
```

**Error: "Deployment timeout"**
```bash
# Solución: Aumentar timeout
export DEPLOYMENT_TIMEOUT=600
./deploy-war.sh myapp.war

# O verificar recursos
docker stats
free -h
```

**Error: "Target server not available"**
```bash
# Verificar servidores
docker-compose ps

# Reiniciar servidor específico
docker-compose restart weblogic-managed-1

# Verificar conectividad
telnet weblogic-managed-1 7003
```

### Logs de Debug

```bash
# Habilitar debug de despliegue
export DEBUG_DEPLOYMENT=true
./deploy-war.sh myapp.war

# Ver logs detallados
docker-compose logs weblogic-admin --tail=100

# Verificar en WebLogic Console
# http://localhost:7001/console -> Monitoring -> Log Files
```

## 📋 Checklist de Despliegue

### Pre-Despliegue
- [ ] Backup de aplicación actual
- [ ] Verificar recursos del sistema
- [ ] Confirmar versión de aplicación
- [ ] Verificar configuración de BD
- [ ] Revisar logs por errores

### Durante Despliegue
- [ ] Monitorear logs en tiempo real
- [ ] Verificar uso de memoria/CPU
- [ ] Confirmar que no hay errores
- [ ] Verificar conectividad de BD

### Post-Despliegue
- [ ] Verificar aplicación responde
- [ ] Probar funcionalidades críticas
- [ ] Verificar logs por warnings
- [ ] Confirmar métricas normales
- [ ] Documentar cambios

## 🚀 Mejores Prácticas

### Desarrollo
- Usa `autodeploy/` para iteración rápida
- Habilita hot-deployment en desarrollo
- Mantén logs de debug activados
- Usa perfiles Maven para diferentes entornos

### Testing
- Siempre prueba en ambiente similar a producción
- Usa datos de prueba realistas
- Automatiza tests de smoke después del despliegue
- Verifica rollback antes de ir a producción

### Producción
- Siempre haz backup antes de desplegar
- Usa despliegues graduales (canary/blue-green)
- Monitorea métricas durante y después del despliegue
- Ten plan de rollback preparado
- Documenta todos los cambios
