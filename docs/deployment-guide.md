# Guía de Implementación de Testing A/B y Canary Deployment

Esta guía explica cómo implementar y utilizar las estrategias de Testing A/B y Canary Deployment en el entorno de WebLogic utilizando HAProxy.

## Introducción

El entorno de WebLogic está configurado con dos instancias (A y B) que pueden ejecutar diferentes versiones de las aplicaciones. HAProxy se utiliza como balanceador de carga y para implementar estrategias de despliegue avanzadas.

### ¿Qué es el Testing A/B?

El Testing A/B es una metodología que permite comparar dos versiones de una aplicación para determinar cuál ofrece mejor rendimiento o experiencia de usuario. Los usuarios son divididos en grupos y cada grupo ve una versión diferente de la aplicación.

### ¿Qué es el Canary Deployment?

El Canary Deployment es una estrategia que consiste en liberar una nueva versión de la aplicación a un pequeño porcentaje de usuarios antes de un despliegue completo. Esto permite detectar problemas antes de que afecten a todos los usuarios.

## Arquitectura del Sistema

```
                   +----------------+
                   |                |
  Usuarios ------> |    HAProxy     | -----+
                   |                |      |
                   +----------------+      |
                           |               |
                           v               v
                   +----------------+ +----------------+
                   |                | |                |
                   |  WebLogic A    | |  WebLogic B    |
                   |  (Versión A)   | |  (Versión B)   |
                   |                | |                |
                   +----------------+ +----------------+
                           |               |
                           v               v
                   +----------------------------------+
                   |                                  |
                   |           Oracle DB              |
                   |                                  |
                   +----------------------------------+
```

## Preparación del Entorno

### 1. Construir y Desplegar el Entorno

```bash
# Clonar el repositorio (si aún no lo has hecho)
git clone <repositorio>
cd docker-for-oracle-weblogic

# Construir y desplegar los contenedores
docker-compose build
docker-compose up -d
```

### 2. Verificar que Todo Esté Funcionando

```bash
# Verificar que los contenedores estén en ejecución
docker-compose ps

# Verificar los logs de WebLogic A
docker logs weblogic-a

# Verificar los logs de WebLogic B
docker logs weblogic-b

# Verificar los logs de HAProxy
docker logs haproxy
```

## URLs y Endpoints del Sistema

### URLs de Acceso Principal

| Componente | URL | Descripción |
|------------|-----|-------------|
| HAProxy Frontend | `http://localhost:8080` | Punto de entrada principal para todas las aplicaciones |
| HAProxy Stats | `http://localhost:8404/stats` | Interfaz de estadísticas de HAProxy (admin/admin123) |
| API de Administración | `http://localhost:8081/api` | API REST para configurar HAProxy dinámicamente |

### Consolas de Administración

| Componente | URL | Descripción |
|------------|-----|-------------|
| WebLogic A | `http://localhost:7001/console` | Consola de administración de WebLogic A |
| WebLogic B | `http://localhost:7002/console` | Consola de administración de WebLogic B |
| Oracle DB | `http://localhost:5500/em` | Enterprise Manager de Oracle Database |

### Aplicaciones a través de HAProxy

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| FF4J | `http://localhost:8080/ff4j-simple` | Aplicación FF4J |
| Feature Flags | `http://localhost:8080/feature-flags` | Aplicación de Feature Flags |
| WebLogic Features A | `http://localhost:8080/weblogic-features-a` | Versión A de la aplicación WebLogic Features |
| WebLogic Features B | `http://localhost:8080/weblogic-features-b` | Versión B de la aplicación WebLogic Features |

### Acceso Directo a Nodos

| Componente | URL | Descripción |
|------------|-----|-------------|
| WebLogic A | `http://172.28.0.2:7001` | Acceso directo al nodo WebLogic A |
| WebLogic B | `http://172.28.0.3:7001` | Acceso directo al nodo WebLogic B |
| HAProxy | `http://172.28.0.4:80` | Acceso directo al nodo HAProxy |
| Oracle DB | `http://172.28.0.5:1521` | Acceso directo a Oracle Database (puerto 1521) |

## Implementación de Testing A/B

### 1. Preparar las Versiones A y B

Asegúrate de que ambas versiones de la aplicación estén desplegadas en WebLogic A y WebLogic B respectivamente.

```bash
# Desplegar la versión A en WebLogic A
cp aplicacion-versionA.war ./autodeploy/

# Desplegar la versión B en WebLogic B
cp aplicacion-versionB.war ./autodeploy/
```

### 2. Configurar el Testing A/B

Utiliza el script de control para configurar el Testing A/B:

```bash
# Ver el estado actual
./haproxy/scripts/control.sh status

# Habilitar A/B testing con 70% del tráfico a la versión A y 30% a la versión B
./haproxy/scripts/control.sh ab --enable --weight-a 70
```

### 3. Monitorear y Analizar

Monitorea el comportamiento de ambas versiones utilizando la interfaz de estadísticas de HAProxy y tus herramientas de análisis.

```bash
# Acceder a las estadísticas de HAProxy
open http://localhost:8404/stats
```

### 4. Ajustar la Distribución

Basándote en los datos recolectados, ajusta la distribución del tráfico:

```bash
# Aumentar el tráfico a la versión A
./haproxy/scripts/control.sh ab --enable --weight-a 80

# O aumentar el tráfico a la versión B
./haproxy/scripts/control.sh ab --enable --weight-a 20
```

### 5. Finalizar el Test

Una vez que hayas determinado qué versión es mejor, finaliza el test:

```bash
# Si la versión A es mejor
./haproxy/scripts/control.sh ab --enable --weight-a 100

# Si la versión B es mejor
./haproxy/scripts/control.sh ab --enable --weight-a 0

# Desactivar el A/B testing
./haproxy/scripts/control.sh ab --disable
```

## Implementación de Canary Deployment

### 1. Preparar la Nueva Versión

Despliega la nueva versión de la aplicación en WebLogic B:

```bash
# Desplegar la nueva versión en WebLogic B
cp nueva-version.war ./autodeploy/
```

### 2. Iniciar el Canary Deployment

Comienza con un pequeño porcentaje de tráfico dirigido a la nueva versión:

```bash
# Habilitar Canary deployment con 5% del tráfico a la nueva versión
./haproxy/scripts/control.sh canary --enable --percentage 5
```

### 3. Monitorear el Comportamiento

Monitorea cuidadosamente el comportamiento de la nueva versión:

```bash
# Acceder a las estadísticas de HAProxy
open http://localhost:8404/stats
```

### 4. Incrementar Gradualmente

Si la nueva versión funciona correctamente, aumenta gradualmente el porcentaje de tráfico:

```bash
# Aumentar al 20%
./haproxy/scripts/control.sh canary --enable --percentage 20

# Aumentar al 50%
./haproxy/scripts/control.sh canary --enable --percentage 50

# Aumentar al 100%
./haproxy/scripts/control.sh canary --enable --percentage 100
```

### 5. Completar el Despliegue

Una vez que el 100% del tráfico está en la nueva versión y todo funciona correctamente:

```bash
# Desactivar el Canary deployment
./haproxy/scripts/control.sh canary --disable
```

## Casos de Uso Avanzados

### Combinación de A/B Testing y Canary Deployment

Puedes combinar ambas estrategias para un enfoque más sofisticado:

1. Utiliza Canary Deployment para introducir gradualmente una nueva versión
2. Una vez que la nueva versión esté estable, utiliza A/B Testing para comparar diferentes variantes

```bash
# Primero, implementa Canary Deployment
./haproxy/scripts/control.sh canary --enable --percentage 20

# Después de verificar la estabilidad, cambia a A/B Testing
./haproxy/scripts/control.sh canary --disable
./haproxy/scripts/control.sh ab --enable --weight-a 50
```

### Despliegue Segmentado

Puedes dirigir el tráfico basado en criterios específicos como ubicación geográfica, tipo de dispositivo, o características del usuario:

1. Modifica la configuración de HAProxy para incluir ACLs adicionales
2. Utiliza headers o cookies para identificar segmentos de usuarios
3. Configura reglas de enrutamiento específicas para cada segmento

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

## Solución de Problemas

### HAProxy no Enruta Correctamente

Verifica la configuración de HAProxy:

```bash
# Ver la configuración actual
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg

# Reiniciar HAProxy
docker-compose restart haproxy
```

### Las Aplicaciones no Están Disponibles

Verifica que WebLogic esté funcionando correctamente:

```bash
# Verificar los logs de WebLogic A
docker logs weblogic-a

# Verificar los logs de WebLogic B
docker logs weblogic-b

# Verificar que las aplicaciones estén desplegadas
docker exec weblogic-a ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/
docker exec weblogic-b ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/
```

### La API de Administración no Responde

Verifica que la API esté en ejecución:

```bash
# Verificar los procesos en ejecución en HAProxy
docker exec haproxy ps aux | grep admin_api.py

# Reiniciar HAProxy
docker-compose restart haproxy
```

## Recursos Adicionales

- [Documentación de HAProxy](http://www.haproxy.org/#docs)
- [Documentación de WebLogic](https://docs.oracle.com/middleware/12213/wls/index.html)
- [Más información sobre Testing A/B](https://www.optimizely.com/optimization-glossary/ab-testing/)
- [Más información sobre Canary Deployment](https://martinfowler.com/bliki/CanaryRelease.html)

## Conclusión

La implementación de estrategias de Testing A/B y Canary Deployment te permite:

- Reducir riesgos al introducir nuevas funcionalidades
- Tomar decisiones basadas en datos sobre diferentes implementaciones
- Mejorar la experiencia del usuario mediante pruebas controladas
- Detectar y corregir problemas antes de que afecten a todos los usuarios

Siguiendo esta guía, podrás implementar estas estrategias de forma efectiva en tu entorno de WebLogic.
