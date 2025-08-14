# Comandos útiles de WebLogic

Este documento contiene comandos útiles para trabajar con Oracle WebLogic Server.

## Comandos WLST (WebLogic Scripting Tool)

### Conexión al servidor

```python
connect('weblogic', 'password', 't3://localhost:7001')
```

### Listar despliegues

```python
domainConfig()
cd('/AppDeployments')
ls()
```

### Desplegar una aplicación

```python
deploy('myapp', '/path/to/myapp.war', targets='AdminServer')
```

### Redesplegar una aplicación

```python
redeploy('myapp', '/path/to/myapp.war', targets='AdminServer')
```

### Desactivar una aplicación

```python
stopApplication('myapp')
```

### Activar una aplicación

```python
startApplication('myapp')
```

### Eliminar una aplicación

```python
undeploy('myapp')
```

### Guardar cambios

```python
save()
activate()
```

## Comandos de administración

### Iniciar el servidor de administración

```bash
$DOMAIN_HOME/bin/startWebLogic.sh
```

### Detener el servidor de administración

```bash
$DOMAIN_HOME/bin/stopWebLogic.sh
```

### Iniciar un servidor gestionado

```bash
$DOMAIN_HOME/bin/startManagedWebLogic.sh managed_server_name
```

### Detener un servidor gestionado

```bash
$DOMAIN_HOME/bin/stopManagedWebLogic.sh managed_server_name
```

## Comandos de diagnóstico

### Ver logs del servidor

```bash
tail -f $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.log
```

### Ver estado del servidor

```bash
$DOMAIN_HOME/bin/serverStatus.sh
```

### Ver estado de la JVM

```bash
jps -v
```

## Comandos Docker para WebLogic

### Construir imagen de WebLogic

```bash
docker build -t weblogic:12.2.1.4 .
```

### Ejecutar contenedor de WebLogic

```bash
docker run -d -p 7001:7001 -p 7002:7002 --name weblogic weblogic:12.2.1.4
```

### Ejecutar comando dentro del contenedor

```bash
docker exec -it weblogic /bin/bash
```

### Ver logs del contenedor

```bash
docker logs -f weblogic
```
