package com.icbs.ff4j;

/**
 * Simulación de proveedor de FF4j para la aplicación.
 * Esta clase es una simulación y no implementa la funcionalidad real de FF4j.
 */
public class FF4jProvider {
    
    /**
     * Constructor privado para evitar instanciación.
     */
    private FF4jProvider() {
        // Constructor privado para evitar instanciación
    }
    
    /**
     * Verifica si una característica está habilitada.
     * 
     * @param featureName Nombre de la característica
     * @return true si la característica está habilitada, false en caso contrario
     */
    public static boolean isEnabled(String featureName) {
        switch (featureName) {
            case "new-ui-design":
            case "dark-mode":
                return true;
            case "advanced-dashboard":
            case "real-time-notifications":
            case "data-export":
            case "external-integration":
                return false;
            default:
                return false;
        }
    }
    
    /**
     * Obtiene el valor de una propiedad.
     * 
     * @param propertyName Nombre de la propiedad
     * @return Valor de la propiedad
     */
    public static String getProperty(String propertyName) {
        switch (propertyName) {
            case "app.theme":
                return "light";
            case "app.max-items-per-page":
                return "10";
            case "service.api-url":
                return "http://api.example.com";
            case "app.cache-time":
                return "300";
            case "app.welcome-message":
                return "Bienvenido a WebLogic Features";
            default:
                return "";
        }
    }
}
