package com.icbs.weblogic.ff4j;

import org.ff4j.FF4j;
import org.ff4j.audit.repository.InMemoryEventRepository;
import org.ff4j.cache.InMemoryCacheManager;
import org.ff4j.conf.XmlConfig;
import org.ff4j.core.Feature;
import org.ff4j.property.PropertyString;
import org.ff4j.property.PropertyInt;
import org.ff4j.strategy.el.ExpressionFlipStrategy;
import org.ff4j.web.ApiConfig;

/**
 * Proveedor de FF4J para la aplicación.
 * Implementa el patrón Singleton para asegurar una única instancia de FF4j.
 */
public class FF4jProvider {
    
    private static FF4j ff4j;
    
    /**
     * Constructor privado para evitar instanciación directa.
     */
    private FF4jProvider() {
        // Constructor privado para implementar el patrón Singleton
    }
    
    /**
     * Obtener la instancia de FF4j.
     * 
     * @return instancia de FF4j
     */
    public static synchronized FF4j getFF4j() {
        if (ff4j == null) {
            initializeFF4j();
        }
        return ff4j;
    }
    
    /**
     * Inicializa la instancia de FF4j con configuraciones y características.
     */
    private static void initializeFF4j() {
        // Crear una nueva instancia de FF4j
        ff4j = new FF4j();
        
        try {
            // Intentar cargar configuración desde XML si existe
            ff4j = new FF4j(new XmlConfig("ff4j-features.xml"));
        } catch (Exception e) {
            // Si no existe el archivo XML o hay error, crear configuración programáticamente
            System.out.println("No se encontró archivo de configuración XML. Creando configuración programáticamente.");
            ff4j = new FF4j();
            
            // Habilitar auditoría
            ff4j.audit(true);
            
            // Configurar repositorio de eventos en memoria
            ff4j.setEventRepository(new InMemoryEventRepository());
            
            // Configurar caché
            ff4j.cache(new InMemoryCacheManager());
            
            // Crear características (features)
            createFeatures();
            
            // Crear propiedades
            createProperties();
        }
        
        // Configurar comportamiento de autorización
        ff4j.setAuthManager(null); // Sin autorización para este ejemplo
        ff4j.setAutocreate(false); // No crear características automáticamente
    }
    
    /**
     * Crear características (features) para la aplicación.
     */
    private static void createFeatures() {
        // Feature 1: Nuevo diseño de interfaz de usuario
        ff4j.createFeature(new Feature("new-ui-design", true, "Nuevo diseño de interfaz de usuario"));
        
        // Feature 2: Dashboard avanzado
        ff4j.createFeature(new Feature("advanced-dashboard", false, "Dashboard con gráficos avanzados"));
        
        // Feature 3: Notificaciones en tiempo real
        ff4j.createFeature(new Feature("real-time-notifications", false, "Notificaciones en tiempo real"));
        
        // Feature 4: Modo oscuro
        ff4j.createFeature(new Feature("dark-mode", true, "Modo oscuro para la interfaz"));
        
        // Feature 5: Exportación de datos
        Feature exportFeature = new Feature("data-export", false, "Exportación de datos a diferentes formatos");
        exportFeature.setGroup("admin");
        ff4j.createFeature(exportFeature);
        
        // Feature 6: Integración con sistemas externos
        Feature integrationFeature = new Feature("external-integration", false, "Integración con sistemas externos");
        integrationFeature.setGroup("admin");
        ff4j.createFeature(integrationFeature);
        
        // Feature 7: Funcionalidades premium (con estrategia de activación)
        Feature premiumFeature = new Feature("premium-features", false, "Funcionalidades premium");
        ExpressionFlipStrategy strategy = new ExpressionFlipStrategy("PremiumUserStrategy", "user.isPremium()");
        premiumFeature.setFlippingStrategy(strategy);
        ff4j.createFeature(premiumFeature);
        
        // Feature 8: Control de versión A/B
        ff4j.createFeature(new Feature("version-b", false, "Activar versión B (desactivado = versión A)"));
    }
    
    /**
     * Crear propiedades para la aplicación.
     */
    private static void createProperties() {
        // Propiedad 1: Tema de la aplicación
        ff4j.createProperty(new PropertyString("app.theme", "light", "Tema de la aplicación"));
        
        // Propiedad 2: Número máximo de elementos por página
        ff4j.createProperty(new PropertyInt("app.max-items-per-page", 10, "Número máximo de elementos por página"));
        
        // Propiedad 3: URL del servicio de API
        ff4j.createProperty(new PropertyString("service.api-url", "http://api.example.com", "URL del servicio de API"));
        
        // Propiedad 4: Tiempo de caché en segundos
        ff4j.createProperty(new PropertyInt("app.cache-time", 300, "Tiempo de caché en segundos"));
        
        // Propiedad 5: Mensaje de bienvenida
        ff4j.createProperty(new PropertyString("app.welcome-message", "Bienvenido a WebLogic Features", "Mensaje de bienvenida"));
        
        // Propiedad 6: URL de la versión A
        ff4j.createProperty(new PropertyString("app.version-a-url", "http://localhost:8080/version-a/", "URL de la versión A"));
        
        // Propiedad 7: URL de la versión B
        ff4j.createProperty(new PropertyString("app.version-b-url", "http://localhost:8080/version-b/", "URL de la versión B"));
    }
    
    /**
     * Obtener la configuración de la API para FF4j.
     * 
     * @return configuración de la API
     */
    public static ApiConfig getApiConfig() {
        return new ApiConfig(getFF4j());
    }
}
