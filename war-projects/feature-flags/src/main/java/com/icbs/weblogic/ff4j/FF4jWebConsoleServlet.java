package com.icbs.weblogic.ff4j;

import javax.servlet.annotation.WebServlet;

import org.ff4j.web.FF4jDispatcherServlet;

/**
 * Servlet para la consola web de FF4j.
 * Extiende FF4jDispatcherServlet para proporcionar la interfaz web de administración de FF4j.
 */
@WebServlet(urlPatterns = "/ff4j-console/*", loadOnStartup = 1)
public class FF4jWebConsoleServlet extends FF4jDispatcherServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Constructor por defecto.
     * Configura la consola web de FF4j con la instancia de FF4j del proveedor.
     */
    public FF4jWebConsoleServlet() {
        super();
        setFf4j(FF4jProvider.getFF4j());
    }
}
