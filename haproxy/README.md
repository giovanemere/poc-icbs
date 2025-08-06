# HAProxy para Testing A/B y Canary Deployment

Este directorio contiene la configuración de HAProxy para implementar estrategias de Testing A/B y Canary Deployment en el entorno de WebLogic.

## Características

- **Testing A/B**: Permite dirigir el tráfico a diferentes versiones de la aplicación basado en porcentajes configurables.
- **Canary Deployment**: Permite liberar una nueva versión a un pequeño porcentaje de usuarios antes de un despliegue completo.
- **API de Administración**: Permite configurar dinámicamente las estrategias de despliegue sin reiniciar HAProxy.
- **Interfaz de Estadísticas**: Proporciona una interfaz web para monitorear el tráfico y el estado de los backends.
- **Sticky Sessions**: Garantiza que los usuarios sean dirigidos consistentemente a la misma versión de la aplicación.

## Estructura de Directorios

```
haproxy/
├── config/
│   ├── haproxy.cfg           # Configuración básica de HAProxy
│   ├── haproxy-advanced.cfg  # Configuración avanzada con A/B testing y Canary
│   └── certs/                # Certificados SSL
├── scripts/
│   ├── dynamic_routing.lua   # Script Lua para enrutamiento dinámico
│   ├── admin_api.py          # API de administración para configuración dinámica
│   ├── start-haproxy.sh      # Script de inicio para HAProxy
│   └── control.sh            # Script para controlar las configuraciones desde la línea de comandos
├── Dockerfile                # Dockerfile para construir la imagen de HAProxy
└── README.md                 # Este archivo
```

## Configuración

### Testing A/B

El testing A/B permite dirigir el tráfico a diferentes versiones de la aplicación basado en porcentajes configurables. Por ejemplo, puedes enviar el 70% del tráfico a la versión A y el 30% a la versión B.

La configuración de A/B testing se puede realizar de varias formas:

1. **Basado en cookies**: Los usuarios con la cookie `ab_test=B` son dirigidos a la versión B.
2. **Basado en porcentajes**: Un porcentaje configurable del tráfico es dirigido a la versión B.
3. **Basado en headers**: Los usuarios con el header `X-AB-Test: B` son dirigidos a la versión B.

### Canary Deployment

El Canary Deployment permite liberar una nueva versión a un pequeño porcentaje de usuarios antes de un despliegue completo. Esto permite detectar problemas antes de afectar a todos los usuarios.

La configuración de Canary Deployment se puede realizar de varias formas:

1. **Basado en cookies**: Los usuarios con la cookie `canary=true` son dirigidos a la versión canary.
2. **Basado en porcentajes**: Un porcentaje configurable del tráfico es dirigido a la versión canary.
3. **Basado en headers**: Los usuarios con el header `X-Canary: true` son dirigidos a la versión canary.

## Instalación y Configuración Inicial

Para implementar esta solución, sigue estos pasos:

1. **Reconstruir y reiniciar los contenedores**:
   ```bash
   cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
   docker-compose down
   docker-compose build
   docker-compose up -d
   ```

2. **Verificar que HAProxy esté funcionando correctamente**:
   ```bash
   docker logs haproxy
   ```

3. **Acceder a la interfaz de estadísticas** para verificar que todos los backends estén disponibles:
   - URL: `http://localhost:8404/stats`
   - Usuario: `admin`
   - Contraseña: `admin123`

## URLs y Endpoints

### URLs de Acceso

- **HAProxy Frontend**: `http://localhost:8080` - Punto de entrada principal para todas las aplicaciones
- **WebLogic Consola A**: `http://localhost:7001/console` - Consola de administración de WebLogic A
- **WebLogic Consola B**: `http://localhost:7002/console` - Consola de administración de WebLogic B
- **Aplicación FF4J**: `http://localhost:8080/ff4j-simple` - Aplicación FF4J a través de HAProxy
- **Feature Flags**: `http://localhost:8080/feature-flags` - Aplicación de Feature Flags a través de HAProxy
- **WebLogic Features A**: `http://localhost:8080/weblogic-features-a` - Versión A de la aplicación WebLogic Features
- **WebLogic Features B**: `http://localhost:8080/weblogic-features-b` - Versión B de la aplicación WebLogic Features

### Acceso Directo a Nodos

- **WebLogic A**: `http://172.28.0.2:7001` - Acceso directo al nodo WebLogic A
- **WebLogic B**: `http://172.28.0.3:7001` - Acceso directo al nodo WebLogic B

### Interfaz de Estadísticas

La interfaz de estadísticas está disponible en `http://localhost:8404/stats`. Las credenciales por defecto son:

- Usuario: `admin`
- Contraseña: `admin123`

Esta interfaz te permite monitorear en tiempo real:
- El estado de los backends y servidores
- El número de conexiones y solicitudes
- Los tiempos de respuesta
- Los errores y rechazos

### API de Administración

La API de administración está disponible en `http://localhost:8081/api`. Puedes usar esta API para configurar dinámicamente las estrategias de despliegue.

#### Endpoints disponibles:

- `GET `: Obtiene la configuración actual.
- `POST /api/config/ab`: Configura el A/B testing.
- `POST /api/config/canary`: Configura el Canary deployment.
- `POST /api/server/weight`: Configura el peso de un servidor.
- `GET /api/stats`: Obtiene estadísticas de HAProxy.
- `GET /api/backends`: Obtiene información de los backends.
- `GET /api/servers/{backend}`: Obtiene información de los servidores de un backend.

### Script de Control

El script `control.sh` permite controlar las configuraciones desde la línea de comandos.

```bash
# Ver el estado actual
./scripts/control.sh status

# Configurar A/B testing
./scripts/control.sh ab --enable --weight-a 70

# Configurar Canary deployment
./scripts/control.sh canary --enable --percentage 20

# Configurar el peso de un servidor
./scripts/control.sh weight weblogic-features-a weblogic-a-features 100
```

## Guía Paso a Paso para Implementar Estrategias de Despliegue

### Implementar un Canary Deployment

El Canary Deployment es ideal para reducir riesgos al introducir nuevas funcionalidades o cambios significativos.

1. **Preparación**: Asegúrate de que la versión B (canary) esté desplegada y funcionando correctamente:
   ```bash
   curl http://localhost:7002/weblogic-features/
   ```

2. **Iniciar con un porcentaje bajo**: Comienza dirigiendo solo el 5-10% del tráfico a la versión canary:
   ```bash
   ./haproxy/scripts/control.sh canary --enable --percentage 5
   ```

3. **Monitoreo**: Observa el comportamiento de la versión canary en la interfaz de estadísticas durante al menos 30 minutos.
   - Verifica errores, tiempos de respuesta y tasas de rechazo
   - Compara métricas con la versión estable

4. **Incremento gradual**: Si todo funciona correctamente, aumenta gradualmente el porcentaje:
   ```bash
   ./haproxy/scripts/control.sh canary --enable --percentage 20
   # Espera y monitorea
   ./haproxy/scripts/control.sh canary --enable --percentage 50
   # Espera y monitorea
   ./haproxy/scripts/control.sh canary --enable --percentage 100
   ```

5. **Completar el despliegue**: Una vez que el 100% del tráfico está en la versión canary y todo funciona correctamente, puedes:
   - Desactivar el modo canary: `./haproxy/scripts/control.sh canary --disable`
   - Actualizar la versión A para que coincida con la B
   - Reequilibrar el tráfico entre ambas versiones

### Implementar un Testing A/B

El Testing A/B es ideal para comparar diferentes implementaciones o características y tomar decisiones basadas en datos.

1. **Preparación**: Asegúrate de que ambas versiones (A y B) estén desplegadas con las variantes que deseas probar.

2. **Configurar distribución inicial**: Comienza con una distribución equilibrada:
   ```bash
   ./haproxy/scripts/control.sh ab --enable --weight-a 50
   ```

3. **Recolección de datos**: Deja que el test corra durante un período significativo (días o semanas, dependiendo del tráfico).
   - Recolecta métricas de ambas versiones
   - Analiza tasas de conversión, tiempos de respuesta, y experiencia del usuario

4. **Ajuste de distribución**: Si es necesario, ajusta la distribución basándote en los datos iniciales:
   ```bash
   ./haproxy/scripts/control.sh ab --enable --weight-a 70
   ```

5. **Decisión final**: Basándote en los datos recolectados, decide qué versión implementar completamente:
   ```bash
   # Si la versión A es mejor:
   ./haproxy/scripts/control.sh ab --enable --weight-a 100
   
   # Si la versión B es mejor:
   ./haproxy/scripts/control.sh ab --enable --weight-a 0
   ```

6. **Finalizar el test**: Una vez tomada la decisión, desactiva el A/B testing:
   ```bash
   ./haproxy/scripts/control.sh ab --disable
   ```

## Mejores Prácticas

### Para Testing A/B

1. **Define métricas claras**: Antes de iniciar el test, define qué métricas determinarán el éxito.
2. **Duración adecuada**: Ejecuta el test durante tiempo suficiente para obtener datos estadísticamente significativos.
3. **Consistencia de usuario**: Utiliza cookies para asegurar que los usuarios siempre vean la misma versión.
4. **Cambios incrementales**: Prueba cambios pequeños y específicos para poder atribuir claramente los resultados.
5. **Documentación**: Registra los cambios, configuraciones y resultados de cada test.

### Para Canary Deployment

1. **Monitoreo constante**: Implementa alertas para detectar problemas rápidamente.
2. **Rollback rápido**: Prepara un plan para revertir cambios inmediatamente si se detectan problemas.
3. **Incrementos graduales**: Aumenta el porcentaje de tráfico gradualmente (5%, 10%, 25%, 50%, 100%).
4. **Segmentación de usuarios**: Considera dirigir el tráfico canary a segmentos específicos de usuarios.
5. **Pruebas automatizadas**: Ejecuta pruebas automatizadas contra la versión canary antes de aumentar el porcentaje.

## Configuración Avanzada

Para configuraciones más avanzadas, puedes editar los siguientes archivos:

- `config/haproxy-advanced.cfg`: Configuración principal de HAProxy.
- `scripts/dynamic_routing.lua`: Script Lua para enrutamiento dinámico.
- `scripts/admin_api.py`: API de administración para configuración dinámica.

### Personalización de Reglas de Enrutamiento

Para añadir reglas de enrutamiento personalizadas, edita el archivo `config/haproxy-advanced.cfg` y añade ACLs adicionales:

```
# Ejemplo: Enrutamiento basado en agente de usuario
acl is_mobile hdr(User-Agent) -m reg "(?i)(android|iphone|ipod|windows\s+phone)"
use_backend mobile-version if is_mobile path_weblogic_features
```

### Integración con Sistemas de Monitoreo

Puedes integrar esta solución con sistemas de monitoreo como Prometheus y Grafana:

1. Habilita el endpoint de métricas en HAProxy
2. Configura Prometheus para recolectar métricas de HAProxy
3. Crea dashboards en Grafana para visualizar el rendimiento de las diferentes versiones

## Solución de Problemas

### HAProxy no inicia

Verifica los logs de HAProxy:

```bash
docker logs haproxy
```

Problemas comunes:
- Errores de sintaxis en la configuración
- Puertos ya en uso
- Problemas de permisos en los archivos de configuración

### No se puede conectar a la API de administración

Verifica que HAProxy esté en ejecución y que la API esté disponible:

```bash
curl http://localhost:8081/api/config
```

Si la API no responde:
- Verifica que el contenedor esté en ejecución: `docker ps | grep haproxy`
- Verifica los logs del contenedor: `docker logs haproxy`
- Reinicia el contenedor: `docker-compose restart haproxy`

### Los cambios de configuración no surten efecto

Verifica que la API de administración esté funcionando correctamente:

```bash
curl http://localhost:8081/api/config
```

Si la API responde pero los cambios no surten efecto:
- Verifica que estés usando los parámetros correctos
- Verifica los logs de HAProxy para ver si hay errores
- Intenta reiniciar HAProxy: `docker-compose restart haproxy`

### Problemas de rendimiento

Si experimentas problemas de rendimiento:
- Verifica la carga en los servidores backend
- Ajusta los timeouts en la configuración de HAProxy
- Considera aumentar los recursos asignados a HAProxy

## Conclusión

Esta solución te proporciona una forma flexible y potente de implementar estrategias de Testing A/B y Canary Deployment en tu entorno de WebLogic. Siguiendo las recomendaciones y mejores prácticas descritas en este documento, podrás:

- Reducir riesgos al introducir nuevas funcionalidades
- Tomar decisiones basadas en datos sobre diferentes implementaciones
- Mejorar la experiencia del usuario mediante pruebas controladas
- Detectar y corregir problemas antes de que afecten a todos los usuarios

Recuerda monitorear constantemente el rendimiento y estar preparado para revertir cambios si es necesario.
