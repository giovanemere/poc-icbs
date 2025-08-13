# Despliegue Canary en WebLogic

Este documento describe cómo implementar un despliegue canary en Oracle WebLogic Server.

## ¿Qué es un despliegue Canary?

El despliegue canary es una técnica para reducir el riesgo de introducir una nueva versión de software en producción. Consiste en desplegar la nueva versión para un pequeño subconjunto de usuarios antes de hacerlo para todos. Si se detectan problemas durante el despliegue canary, se puede revertir rápidamente con un impacto mínimo.

## Arquitectura de despliegue Canary en WebLogic

![Arquitectura Canary](../images/canary-architecture.png)

### Componentes principales:

1. **Versión A (estable)**: La versión actual de la aplicación
2. **Versión B (nueva)**: La nueva versión de la aplicación
3. **Balanceador de carga**: Distribuye el tráfico entre las versiones A y B
4. **Mecanismo de enrutamiento**: Determina qué usuarios van a qué versión

## Implementación en WebLogic

### 1. Desplegar ambas versiones

Primero, desplegar ambas versiones de la aplicación con nombres diferentes:

```python
# WLST script
connect('weblogic', 'password', 't3://localhost:7001')

# Desplegar versión A
deploy('app-version-a', '/path/to/app-version-a.war', targets='AdminServer')

# Desplegar versión B
deploy('app-version-b', '/path/to/app-version-b.war', targets='AdminServer')
```

### 2. Configurar el proxy HTTP

Crear un archivo `httpd.conf` para Apache HTTP Server:

```apache
<VirtualHost *:80>
    ServerName myapp.example.com
    
    # Configuración del proxy
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Configuración del balanceo
    <Proxy balancer://mycluster>
        # Versión A (90% del tráfico)
        BalancerMember http://weblogic:7001/app-version-a route=version_a
        
        # Versión B (10% del tráfico)
        BalancerMember http://weblogic:7001/app-version-b route=version_b
        
        # Configuración de pesos
        ProxySet lbmethod=bytraffic
        ProxySet stickysession=JSESSIONID
    </Proxy>
    
    # Regla de proxy
    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```

### 3. Implementar script de control Canary

Crear un script para ajustar los porcentajes de tráfico:

```bash
#!/bin/bash

# Uso: ./canary-control.sh [porcentaje-version-b]
# Ejemplo: ./canary-control.sh 20 (20% del tráfico a la versión B)

if [ -z "$1" ]; then
    echo "Uso: $0 [porcentaje-version-b]"
    exit 1
fi

PERCENT_B=$1
PERCENT_A=$((100 - PERCENT_B))

# Actualizar configuración de Apache
sed -i "s/BalancerMember http:\/\/weblogic:7001\/app-version-a route=version_a.*/BalancerMember http:\/\/weblogic:7001\/app-version-a route=version_a loadfactor=$PERCENT_A/g" /etc/httpd/conf.d/httpd.conf
sed -i "s/BalancerMember http:\/\/weblogic:7001\/app-version-b route=version_b.*/BalancerMember http:\/\/weblogic:7001\/app-version-b route=version_b loadfactor=$PERCENT_B/g" /etc/httpd/conf.d/httpd.conf

# Reiniciar Apache
systemctl restart httpd

echo "Configuración actualizada: Versión A: $PERCENT_A%, Versión B: $PERCENT_B%"
```

### 4. Implementar script de prueba Canary

Crear un script para probar la distribución del tráfico:

```bash
#!/bin/bash

# Uso: ./test-canary.sh [número-de-peticiones]
# Ejemplo: ./test-canary.sh 100

if [ -z "$1" ]; then
    echo "Uso: $0 [número-de-peticiones]"
    exit 1
fi

NUM_REQUESTS=$1
VERSION_A_COUNT=0
VERSION_B_COUNT=0

echo "Realizando $NUM_REQUESTS peticiones..."

for i in $(seq 1 $NUM_REQUESTS); do
    RESPONSE=$(curl -s http://myapp.example.com/version)
    
    if [[ "$RESPONSE" == *"version-a"* ]]; then
        VERSION_A_COUNT=$((VERSION_A_COUNT + 1))
    elif [[ "$RESPONSE" == *"version-b"* ]]; then
        VERSION_B_COUNT=$((VERSION_B_COUNT + 1))
    fi
    
    echo -n "."
    
    # Esperar un poco entre peticiones
    sleep 0.1
done

echo ""
echo "Resultados:"
echo "Versión A: $VERSION_A_COUNT peticiones ($(echo "scale=2; $VERSION_A_COUNT*100/$NUM_REQUESTS" | bc)%)"
echo "Versión B: $VERSION_B_COUNT peticiones ($(echo "scale=2; $VERSION_B_COUNT*100/$NUM_REQUESTS" | bc)%)"
```

## Implementación con WebLogic Proxy Plugin

Si se utiliza el plugin de WebLogic para Apache o NGINX, se puede configurar el despliegue canary de la siguiente manera:

### Para Apache:

```apache
<IfModule mod_weblogic.c>
    WebLogicCluster weblogic1:7001,weblogic2:7001
    
    # Configuración de canary
    SetHandler weblogic-handler
    WebLogicHost weblogic1
    WebLogicPort 7001
    PathTrim /
    
    # Reglas de enrutamiento
    RewriteEngine On
    RewriteCond %{REMOTE_ADDR} 10\.0\.0\.[0-9]+$
    RewriteRule ^/(.*)$ /app-version-b/$1 [PT]
    
    # Regla por defecto (versión A)
    RewriteRule ^/(.*)$ /app-version-a/$1 [PT]
</IfModule>
```

### Para NGINX:

```nginx
upstream version_a {
    server weblogic1:7001;
}

upstream version_b {
    server weblogic2:7001;
}

split_clients "${remote_addr}${http_user_agent}" $appversion {
    10%     version_b;
    *       version_a;
}

server {
    listen 80;
    server_name myapp.example.com;
    
    location / {
        proxy_pass http://$appversion;
    }
}
```

## Monitoreo del despliegue Canary

Es importante monitorear ambas versiones durante el despliegue canary:

1. **Métricas de rendimiento**: Tiempo de respuesta, throughput, uso de recursos
2. **Tasas de error**: Errores HTTP, excepciones, logs de error
3. **Experiencia de usuario**: Feedback de usuarios, tasas de conversión
4. **Métricas de negocio**: Ingresos, transacciones completadas

## Estrategia de rollback

En caso de problemas con la versión B:

1. Establecer el porcentaje de tráfico a la versión B en 0%
2. Verificar que todo el tráfico va a la versión A
3. Desactivar la versión B
4. Analizar los problemas y preparar una nueva versión

## Recursos adicionales

- [Canary Releases (Martin Fowler)](https://martinfowler.com/bliki/CanaryRelease.html)
- [Documentación de WebLogic Server](https://docs.oracle.com/middleware/12213/wls/index.html)
- [Documentación de Apache HTTP Server](https://httpd.apache.org/docs/)
- [Documentación de NGINX](https://nginx.org/en/docs/)
