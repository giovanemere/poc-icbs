package com.icbs.weblogic;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;
import java.util.concurrent.atomic.AtomicInteger;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/metrics")
public class MetricsServlet extends HttpServlet {
    
    private static final long serialVersionUID = 1L;
    private static final AtomicInteger visitCount = new AtomicInteger(0);
    private static final long startTime = System.currentTimeMillis();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Incrementar contador de visitas
        int currentCount = visitCount.incrementAndGet();
        
        // Obtener información de la versión
        String version = getServletContext().getInitParameter("version");
        String build = getServletContext().getInitParameter("build");
        
        // Calcular tiempo de actividad
        long uptime = System.currentTimeMillis() - startTime;
        long uptimeSeconds = uptime / 1000;
        long uptimeMinutes = uptimeSeconds / 60;
        long uptimeHours = uptimeMinutes / 60;
        long uptimeDays = uptimeHours / 24;
        
        // Configurar respuesta
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        try (PrintWriter out = response.getWriter()) {
            out.println("<!DOCTYPE html>");
            out.println("<html lang=\"es\">");
            out.println("<head>");
            out.println("    <meta charset=\"UTF-8\">");
            out.println("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">");
            out.println("    <title>Métricas - WebLogic Features Versión " + version + "</title>");
            out.println("    <style>");
            out.println("        body {");
            out.println("            font-family: Arial, sans-serif;");
            out.println("            margin: 0;");
            out.println("            padding: 20px;");
            if ("A".equals(version)) {
                out.println("            background-color: #f5f5f5;");
            } else {
                out.println("            background-color: #e3f2fd;");
            }
            out.println("            color: #333;");
            out.println("        }");
            out.println("        .container {");
            out.println("            max-width: 800px;");
            out.println("            margin: 0 auto;");
            out.println("            background-color: white;");
            out.println("            padding: 20px;");
            out.println("            border-radius: 5px;");
            out.println("            box-shadow: 0 2px 5px rgba(0,0,0,0.1);");
            out.println("        }");
            out.println("        header {");
            if ("A".equals(version)) {
                out.println("            background-color: #4CAF50;");
            } else {
                out.println("            background-color: #2196F3;");
            }
            out.println("            color: white;");
            out.println("            padding: 20px;");
            out.println("            text-align: center;");
            out.println("            border-radius: 5px 5px 0 0;");
            out.println("            margin-bottom: 20px;");
            out.println("        }");
            out.println("        h1, h2 {");
            out.println("            margin-top: 0;");
            out.println("        }");
            out.println("        .metric {");
            out.println("            margin-bottom: 15px;");
            out.println("            padding: 15px;");
            if ("A".equals(version)) {
                out.println("            border-left: 4px solid #4CAF50;");
            } else {
                out.println("            border-left: 4px solid #2196F3;");
            }
            out.println("            background-color: #f9f9f9;");
            out.println("        }");
            out.println("        .metric-value {");
            out.println("            font-size: 24px;");
            out.println("            font-weight: bold;");
            if ("A".equals(version)) {
                out.println("            color: #4CAF50;");
            } else {
                out.println("            color: #2196F3;");
            }
            out.println("        }");
            out.println("        .button {");
            out.println("            display: inline-block;");
            out.println("            padding: 10px 20px;");
            out.println("            margin: 10px 0;");
            out.println("            border: none;");
            out.println("            border-radius: 4px;");
            out.println("            cursor: pointer;");
            out.println("            font-size: 16px;");
            out.println("            font-weight: bold;");
            out.println("            text-decoration: none;");
            out.println("            color: white;");
            if ("A".equals(version)) {
                out.println("            background-color: #4CAF50;");
            } else {
                out.println("            background-color: #2196F3;");
            }
            out.println("        }");
            out.println("    </style>");
            out.println("</head>");
            out.println("<body>");
            out.println("    <div class=\"container\">");
            out.println("        <header>");
            out.println("            <h1>Métricas de WebLogic Features</h1>");
            out.println("            <p>Versión " + version + " (Build " + build + ")</p>");
            out.println("        </header>");
            
            out.println("        <div class=\"metric\">");
            out.println("            <h2>Contador de Visitas</h2>");
            out.println("            <p class=\"metric-value\">" + currentCount + "</p>");
            out.println("            <p>Número total de visitas a esta versión desde el inicio.</p>");
            out.println("        </div>");
            
            out.println("        <div class=\"metric\">");
            out.println("            <h2>Tiempo de Actividad</h2>");
            out.println("            <p class=\"metric-value\">" + uptimeDays + "d " + (uptimeHours % 24) + "h " + 
                    (uptimeMinutes % 60) + "m " + (uptimeSeconds % 60) + "s</p>");
            out.println("            <p>Tiempo transcurrido desde el inicio de la aplicación.</p>");
            out.println("        </div>");
            
            out.println("        <div class=\"metric\">");
            out.println("            <h2>Información del Servidor</h2>");
            out.println("            <p>Servidor: " + request.getServerName() + ":" + request.getServerPort() + "</p>");
            out.println("            <p>Fecha y hora actual: " + new Date() + "</p>");
            out.println("            <p>Memoria libre: " + Runtime.getRuntime().freeMemory() / (1024 * 1024) + " MB</p>");
            out.println("            <p>Memoria total: " + Runtime.getRuntime().totalMemory() / (1024 * 1024) + " MB</p>");
            out.println("        </div>");
            
            out.println("        <div style=\"text-align: center;\">");
            out.println("            <a href=\"../index.html\" class=\"button\">Volver a la Página Principal</a>");
            out.println("        </div>");
            
            out.println("    </div>");
            out.println("</body>");
            out.println("</html>");
        }
    }
}
