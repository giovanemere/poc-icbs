package com.icbs.weblogic.ff4j;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.ff4j.FF4j;
import org.ff4j.core.Feature;
import org.ff4j.property.Property;

/**
 * Servlet para demostrar el uso de FF4j.
 * Muestra una página HTML con las características y propiedades de FF4j.
 */
@WebServlet("/features")
public class FeatureDemoServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    
    /**
     * Maneja las solicitudes GET.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Obtener la instancia de FF4j
        FF4j ff4j = FF4jProvider.getFF4j();
        
        // Configurar la respuesta
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        try (PrintWriter out = response.getWriter()) {
            out.println("<!DOCTYPE html>");
            out.println("<html lang=\"es\">");
            out.println("<head>");
            out.println("    <meta charset=\"UTF-8\">");
            out.println("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">");
            out.println("    <title>FF4j Feature Demo</title>");
            out.println("    <style>");
            out.println("        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }");
            out.println("        .container { max-width: 1200px; margin: 0 auto; }");
            out.println("        header { margin-bottom: 20px; }");
            out.println("        h1 { color: #333; }");
            out.println("        .feature-enabled { background-color: #e6f7ff; border: 1px solid #91d5ff; padding: 15px; margin-bottom: 15px; border-radius: 4px; }");
            out.println("        .feature-disabled { background-color: #fff1f0; border: 1px solid #ffa39e; padding: 15px; margin-bottom: 15px; border-radius: 4px; }");
            out.println("        .premium { background-color: #fffbe6; border: 1px solid #ffe58f; }");
            out.println("        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }");
            out.println("        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }");
            out.println("        th { background-color: #f2f2f2; }");
            out.println("        .dashboard { display: flex; justify-content: space-between; }");
            out.println("        .chart { flex: 1; margin: 10px; padding: 20px; background-color: #f9f9f9; border: 1px solid #ddd; text-align: center; }");
            out.println("        .export-buttons { margin-top: 10px; }");
            out.println("        button { padding: 5px 10px; margin-right: 5px; }");
            out.println("        .notification { background-color: #f6ffed; border: 1px solid #b7eb8f; padding: 10px; border-radius: 4px; }");
            out.println("        .ff4j-links { margin-top: 20px; }");
            out.println("        .ff4j-links ul { list-style-type: none; padding: 0; }");
            out.println("        .ff4j-links li { margin-bottom: 5px; }");
            out.println("        .dark-mode { background-color: #333; color: #fff; }");
            out.println("        .dark-mode h1, .dark-mode h2 { color: #fff; }");
            out.println("        .dark-mode table { border-color: #555; }");
            out.println("        .dark-mode th, .dark-mode td { border-color: #555; }");
            out.println("        .dark-mode th { background-color: #444; color: #fff; }");
            out.println("    </style>");
            out.println("</head>");
            
            // Aplicar tema oscuro si está habilitado
            if (ff4j.check("dark-mode")) {
                out.println("<body class=\"dark-mode\">");
            } else {
                out.println("<body>");
            }
            
            out.println("    <div class=\"container\">");
            out.println("        <header>");
            out.println("            <h1>FF4j Feature Demo</h1>");
            
            // Mostrar mensaje de bienvenida desde propiedades
            String welcomeMessage = ff4j.getProperty("app.welcome-message").getValue().toString();
            out.println("            <p>" + welcomeMessage + "</p>");
            out.println("        </header>");
            
            // Mostrar nuevo diseño si está habilitado
            if (ff4j.check("new-ui-design")) {
                out.println("        <div class=\"feature-enabled\">");
                out.println("            <h2>Nuevo Diseño de UI</h2>");
                out.println("            <p>Estás viendo el nuevo diseño de interfaz de usuario.</p>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Nuevo Diseño de UI</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar dashboard avanzado si está habilitado
            if (ff4j.check("advanced-dashboard")) {
                out.println("        <div class=\"feature-enabled\">");
                out.println("            <h2>Dashboard Avanzado</h2>");
                out.println("            <div class=\"dashboard\">");
                out.println("                <div class=\"chart\">Gráfico 1</div>");
                out.println("                <div class=\"chart\">Gráfico 2</div>");
                out.println("                <div class=\"chart\">Gráfico 3</div>");
                out.println("            </div>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Dashboard Avanzado</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar notificaciones en tiempo real si está habilitado
            if (ff4j.check("real-time-notifications")) {
                out.println("        <div class=\"feature-enabled\">");
                out.println("            <h2>Notificaciones en Tiempo Real</h2>");
                out.println("            <div class=\"notification\">Tienes 3 nuevas notificaciones</div>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Notificaciones en Tiempo Real</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar funcionalidades premium si está habilitado
            if (ff4j.check("premium-features")) {
                out.println("        <div class=\"feature-enabled premium\">");
                out.println("            <h2>Funcionalidades Premium</h2>");
                out.println("            <p>Tienes acceso a funcionalidades premium.</p>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Funcionalidades Premium</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar exportación de datos si está habilitado
            if (ff4j.check("data-export")) {
                out.println("        <div class=\"feature-enabled\">");
                out.println("            <h2>Exportación de Datos</h2>");
                out.println("            <p>Puedes exportar datos en diferentes formatos.</p>");
                out.println("            <div class=\"export-buttons\">");
                out.println("                <button>Exportar a CSV</button>");
                out.println("                <button>Exportar a Excel</button>");
                out.println("                <button>Exportar a PDF</button>");
                out.println("            </div>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Exportación de Datos</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar integración con sistemas externos si está habilitado
            if (ff4j.check("external-integration")) {
                out.println("        <div class=\"feature-enabled\">");
                out.println("            <h2>Integración con Sistemas Externos</h2>");
                out.println("            <p>API URL: " + ff4j.getProperty("service.api-url").getValue().toString() + "</p>");
                out.println("        </div>");
            } else {
                out.println("        <div class=\"feature-disabled\">");
                out.println("            <h2>Integración con Sistemas Externos</h2>");
                out.println("            <p>Esta característica está deshabilitada.</p>");
                out.println("        </div>");
            }
            
            // Mostrar versión A/B si está habilitado
            out.println("        <div class=\"" + (ff4j.check("version-b") ? "feature-enabled" : "feature-disabled") + "\">");
            out.println("            <h2>Control de Versión A/B</h2>");
            out.println("            <p>Versión actual: " + (ff4j.check("version-b") ? "B" : "A") + "</p>");
            out.println("            <p>URL Versión A: " + ff4j.getProperty("app.version-a-url").getValue().toString() + "</p>");
            out.println("            <p>URL Versión B: " + ff4j.getProperty("app.version-b-url").getValue().toString() + "</p>");
            out.println("        </div>");
            
            // Mostrar lista de todas las características
            out.println("        <div class=\"feature-list\">");
            out.println("            <h2>Lista de Características</h2>");
            out.println("            <table>");
            out.println("                <tr>");
            out.println("                    <th>Nombre</th>");
            out.println("                    <th>Descripción</th>");
            out.println("                    <th>Estado</th>");
            out.println("                    <th>Grupo</th>");
            out.println("                </tr>");
            
            Map<String, Feature> features = ff4j.getFeatures();
            for (Feature feature : features.values()) {
                out.println("                <tr>");
                out.println("                    <td>" + feature.getUid() + "</td>");
                out.println("                    <td>" + feature.getDescription() + "</td>");
                out.println("                    <td>" + (feature.isEnable() ? "Habilitado" : "Deshabilitado") + "</td>");
                out.println("                    <td>" + (feature.getGroup() != null ? feature.getGroup() : "-") + "</td>");
                out.println("                </tr>");
            }
            
            out.println("            </table>");
            out.println("        </div>");
            
            // Mostrar lista de propiedades
            out.println("        <div class=\"property-list\">");
            out.println("            <h2>Lista de Propiedades</h2>");
            out.println("            <table>");
            out.println("                <tr>");
            out.println("                    <th>Nombre</th>");
            out.println("                    <th>Valor</th>");
            out.println("                    <th>Descripción</th>");
            out.println("                </tr>");
            
            Map<String, Property<?>> properties = ff4j.getProperties();
            for (Property<?> property : properties.values()) {
                out.println("                <tr>");
                out.println("                    <td>" + property.getName() + "</td>");
                out.println("                    <td>" + property.getValue() + "</td>");
                out.println("                    <td>" + property.getDescription() + "</td>");
                out.println("                </tr>");
            }
            
            out.println("            </table>");
            out.println("        </div>");
            
            // Enlaces a la consola de FF4j
            out.println("        <div class=\"ff4j-links\">");
            out.println("            <h2>Enlaces a FF4j</h2>");
            out.println("            <ul>");
            out.println("                <li><a href=\"ff4j-console\" target=\"_blank\">FF4j Console</a></li>");
            out.println("                <li><a href=\"api/ff4j/store/features\" target=\"_blank\">FF4j API - Features</a></li>");
            out.println("                <li><a href=\"api/ff4j/store/properties\" target=\"_blank\">FF4j API - Properties</a></li>");
            out.println("            </ul>");
            out.println("        </div>");
            
            out.println("    </div>");
            out.println("</body>");
            out.println("</html>");
        }
    }
}
