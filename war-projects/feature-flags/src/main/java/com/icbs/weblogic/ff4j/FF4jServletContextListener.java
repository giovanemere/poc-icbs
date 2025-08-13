package com.icbs.weblogic.ff4j;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import org.ff4j.FF4j;

/**
 * Listener para inicializar FF4j al iniciar la aplicación.
 * Se encarga de crear y configurar la instancia de FF4j y guardarla en el contexto de la aplicación.
 */
@WebListener
public class FF4jServletContextListener implements ServletContextListener {

    /**
     * Se ejecuta cuando se inicializa el contexto de la aplicación.
     */
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try {
            // Inicializar FF4j
            FF4j ff4j = FF4jProvider.getFF4j();
            
            // Guardar la instancia de FF4j en el contexto de la aplicación
            sce.getServletContext().setAttribute("FF4J", ff4j);
            
            System.out.println("FF4j ha sido inicializado correctamente");
            System.out.println("Número de características cargadas: " + ff4j.getFeatures().size());
            System.out.println("Número de propiedades cargadas: " + ff4j.getProperties().size());
        } catch (Exception e) {
            System.err.println("Error al inicializar FF4j: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Se ejecuta cuando se destruye el contexto de la aplicación.
     */
    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // Limpiar recursos si es necesario
        sce.getServletContext().removeAttribute("FF4J");
        System.out.println("FF4j ha sido destruido correctamente");
    }
}
