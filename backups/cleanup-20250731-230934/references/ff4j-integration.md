# Integración de FF4J en WebLogic

Este documento describe cómo integrar FF4J (Feature Flipping For Java) en una aplicación desplegada en Oracle WebLogic Server.

## Dependencias Maven

Añadir las siguientes dependencias al archivo `pom.xml`:

```xml
<!-- FF4J Core -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-core</artifactId>
    <version>1.8.11</version>
</dependency>

<!-- FF4J Web Console -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-web</artifactId>
    <version>1.8.11</version>
</dependency>

<!-- FF4J Spring Support (opcional) -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-spring-boot-starter</artifactId>
    <version>1.8.11</version>
</dependency>

<!-- FF4J Store (elegir uno) -->
<!-- En memoria -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-store-inmemory</artifactId>
    <version>1.8.11</version>
</dependency>

<!-- JDBC -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-store-jdbc</artifactId>
    <version>1.8.11</version>
</dependency>

<!-- Redis -->
<dependency>
    <groupId>org.ff4j</groupId>
    <artifactId>ff4j-store-redis</artifactId>
    <version>1.8.11</version>
</dependency>
```

## Configuración del web.xml

Añadir el siguiente fragmento al archivo `web.xml`:

```xml
<!-- FF4J Servlet -->
<servlet>
    <servlet-name>ff4j-console</servlet-name>
    <servlet-class>org.ff4j.web.FF4jDispatcherServlet</servlet-class>
    <init-param>
        <param-name>ff4jProvider</param-name>
        <param-value>com.example.FF4jProvider</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>

<servlet-mapping>
    <servlet-name>ff4j-console</servlet-name>
    <url-pattern>/ff4j-console/*</url-pattern>
</servlet-mapping>

<!-- FF4J REST API (opcional) -->
<servlet>
    <servlet-name>ff4j-rest-api</servlet-name>
    <servlet-class>org.ff4j.web.api.FF4jServlet</servlet-class>
    <init-param>
        <param-name>ff4jProvider</param-name>
        <param-value>com.example.FF4jProvider</param-value>
    </init-param>
    <load-on-startup>2</load-on-startup>
</servlet>

<servlet-mapping>
    <servlet-name>ff4j-rest-api</servlet-name>
    <url-pattern>/api/ff4j/*</url-pattern>
</servlet-mapping>
```

## Clase proveedora de FF4J

Crear la clase `FF4jProvider.java`:

```java
package com.example;

import org.ff4j.FF4j;
import org.ff4j.core.Feature;
import org.ff4j.property.PropertyString;
import org.ff4j.store.InMemoryFeatureStore;

public class FF4jProvider {
    private static FF4j ff4j;
    
    public static synchronized FF4j getFF4j() {
        if (ff4j == null) {
            ff4j = new FF4j();
            
            // Configurar almacenamiento
            ff4j.setFeatureStore(new InMemoryFeatureStore());
            
            // Crear características
            ff4j.createFeature(new Feature("feature1", true));
            ff4j.createFeature(new Feature("feature2", false));
            
            // Crear propiedades
            ff4j.createProperty(new PropertyString("property1", "value1"));
        }
        return ff4j;
    }
}
```

## Uso de FF4J en el código

```java
import org.ff4j.FF4j;

public class MyService {
    private FF4j ff4j = FF4jProvider.getFF4j();
    
    public void doSomething() {
        if (ff4j.check("feature1")) {
            // Código para feature1 habilitada
        } else {
            // Código alternativo
        }
        
        // Obtener valor de una propiedad
        String value = ff4j.getProperty("property1", String.class);
    }
}
```

## Configuración de seguridad (opcional)

Para proteger la consola FF4J, añadir al `web.xml`:

```xml
<security-constraint>
    <web-resource-collection>
        <web-resource-name>FF4J Console</web-resource-name>
        <url-pattern>/ff4j-console/*</url-pattern>
    </web-resource-collection>
    <auth-constraint>
        <role-name>admin</role-name>
    </auth-constraint>
</security-constraint>

<login-config>
    <auth-method>BASIC</auth-method>
    <realm-name>FF4J Admin</realm-name>
</login-config>

<security-role>
    <role-name>admin</role-name>
</security-role>
```

## Integración con WebLogic

### DataSource JNDI

Para usar un DataSource de WebLogic con FF4J:

```java
import org.ff4j.FF4j;
import org.ff4j.store.JdbcFeatureStore;
import javax.naming.InitialContext;
import javax.sql.DataSource;

public class FF4jProvider {
    private static FF4j ff4j;
    
    public static synchronized FF4j getFF4j() {
        if (ff4j == null) {
            try {
                InitialContext ctx = new InitialContext();
                DataSource ds = (DataSource) ctx.lookup("jdbc/MyDataSource");
                
                ff4j = new FF4j();
                ff4j.setFeatureStore(new JdbcFeatureStore(ds));
                
                // Inicializar tablas si no existen
                ((JdbcFeatureStore) ff4j.getFeatureStore()).createSchema();
            } catch (Exception e) {
                throw new RuntimeException("Error initializing FF4J", e);
            }
        }
        return ff4j;
    }
}
```

## Recursos adicionales

- [Documentación oficial de FF4J](https://ff4j.github.io/)
- [Ejemplos de FF4J](https://github.com/ff4j/ff4j-samples)
- [FF4J con Spring Boot](https://github.com/ff4j/ff4j-spring-boot-starter-parent)
