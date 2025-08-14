package com.icbs.weblogic.ff4j;

import javax.servlet.annotation.WebServlet;

import org.ff4j.web.FF4jDispatcherServlet;

/**
 * Servlet para la API REST de FF4j.
 * Proporciona endpoints REST para interactuar con FF4j desde aplicaciones cliente.
 */
@WebServlet(urlPatterns = "/api/ff4j/*", loadOnStartup = 2)
public class FF4jApiServlet extends FF4jDispatcherServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Constructor por defecto.
     * Configura la API REST de FF4j con la instancia de FF4j del proveedor.
     */
    public FF4jApiServlet() {
        super();
        setFf4j(FF4jProvider.getFF4j());
    }
}
