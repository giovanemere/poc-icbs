package com.icbs.ff4j;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.HashMap;
import java.util.Map;

/**
 * Servlet que simula la API de FF4j.
 */
@WebServlet("/api/ff4j/*")
public class FF4jServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Maneja las solicitudes GET a la API de FF4j.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        if (pathInfo == null || pathInfo.equals("/")) {
            // Devolver todas las características
            out.println(getAllFeatures());
        } else if (pathInfo.startsWith("/check/")) {
            // Verificar si una característica está habilitada
            String featureName = pathInfo.substring(7);
            out.println("{\"name\":\"" + featureName + "\",\"enabled\":" + 
                    FF4jProvider.isEnabled(featureName) + "}");
        } else if (pathInfo.equals("/properties")) {
            // Devolver todas las propiedades
            out.println(getAllProperties());
        } else {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.println("{\"error\":\"Recurso no encontrado\"}");
        }
    }
    
    /**
     * Devuelve todas las características en formato JSON.
     */
    private String getAllFeatures() {
        Map<String, Boolean> features = new HashMap<>();
        features.put("new-ui-design", true);
        features.put("advanced-dashboard", false);
        features.put("real-time-notifications", false);
        features.put("dark-mode", true);
        features.put("data-export", false);
        features.put("external-integration", false);
        
        StringBuilder json = new StringBuilder();
        json.append("{\"features\":{");
        
        boolean first = true;
        for (Map.Entry<String, Boolean> entry : features.entrySet()) {
            if (!first) {
                json.append(",");
            }
            json.append("\"").append(entry.getKey()).append("\":{");
            json.append("\"name\":\"").append(entry.getKey()).append("\",");
            json.append("\"enabled\":").append(entry.getValue());
            json.append("}");
            first = false;
        }
        
        json.append("}}");
        return json.toString();
    }
    
    /**
     * Devuelve todas las propiedades en formato JSON.
     */
    private String getAllProperties() {
        Map<String, String> properties = new HashMap<>();
        properties.put("app.theme", "light");
        properties.put("app.max-items-per-page", "10");
        properties.put("service.api-url", "http://api.example.com");
        properties.put("app.cache-time", "300");
        properties.put("app.welcome-message", "Bienvenido a WebLogic Features");
        
        StringBuilder json = new StringBuilder();
        json.append("{\"properties\":{");
        
        boolean first = true;
        for (Map.Entry<String, String> entry : properties.entrySet()) {
            if (!first) {
                json.append(",");
            }
            json.append("\"").append(entry.getKey()).append("\":{");
            json.append("\"name\":\"").append(entry.getKey()).append("\",");
            json.append("\"value\":\"").append(entry.getValue()).append("\"");
            json.append("}");
            first = false;
        }
        
        json.append("}}");
        return json.toString();
    }
}
