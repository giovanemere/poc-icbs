package com.icbs.weblogic.ff4j;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.ff4j.FF4j;
import org.ff4j.property.Property;

/**
 * Servlet para cambiar entre versión A y B.
 * Proporciona una API REST para cambiar la característica "version-b".
 */
@WebServlet("/api/version-switch")
public class VersionSwitchServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Maneja las solicitudes GET para obtener el estado actual de la versión.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Obtener la instancia de FF4j
        FF4j ff4j = FF4jProvider.getFF4j();
        
        // Configurar la respuesta
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        // Verificar si la versión B está habilitada
        boolean isVersionB = ff4j.check("version-b");
        String versionAUrl = ff4j.getProperty("app.version-a-url").getValue().toString();
        String versionBUrl = ff4j.getProperty("app.version-b-url").getValue().toString();
        
        // Construir la respuesta JSON
        try (PrintWriter out = response.getWriter()) {
            out.println("{");
            out.println("  \"version\": \"" + (isVersionB ? "B" : "A") + "\",");
            out.println("  \"versionAUrl\": \"" + versionAUrl + "\",");
            out.println("  \"versionBUrl\": \"" + versionBUrl + "\"");
            out.println("}");
        }
    }
    
    /**
     * Maneja las solicitudes POST para cambiar la versión.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Obtener la instancia de FF4j
        FF4j ff4j = FF4jProvider.getFF4j();
        
        // Obtener el parámetro de versión
        String version = request.getParameter("version");
        
        // Configurar la respuesta
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        // Cambiar la característica según la versión solicitada
        if ("A".equalsIgnoreCase(version)) {
            ff4j.disable("version-b");
        } else if ("B".equalsIgnoreCase(version)) {
            ff4j.enable("version-b");
        }
        
        // Verificar el estado actual después del cambio
        boolean isVersionB = ff4j.check("version-b");
        String versionAUrl = ff4j.getProperty("app.version-a-url").getValue().toString();
        String versionBUrl = ff4j.getProperty("app.version-b-url").getValue().toString();
        
        // Construir la respuesta JSON
        try (PrintWriter out = response.getWriter()) {
            out.println("{");
            out.println("  \"success\": true,");
            out.println("  \"version\": \"" + (isVersionB ? "B" : "A") + "\",");
            out.println("  \"versionAUrl\": \"" + versionAUrl + "\",");
            out.println("  \"versionBUrl\": \"" + versionBUrl + "\"");
            out.println("}");
        }
    }
}
