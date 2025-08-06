<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Versión</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: #ff980010;
        }
        h1 {
            color: #ff9800;
        }
        .version {
            display: inline-block;
            padding: 5px 10px;
            background-color: #ff9800;
            color: white;
            border-radius: 4px;
            font-weight: bold;
        }
        .info {
            margin-top: 20px;
            background-color: #f9f9f9;
            padding: 10px;
            border-radius: 4px;
        }
        .back {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 15px;
            background-color: #ff9800;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .back:hover {
            background-color: #e68a00;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Información de Versión</h1>
        
        <p>Aplicación: <strong>feature-flags</strong></p>
        <p>Versión: <span class="version"></span></p>
        
        <div class="info">
            <p><strong>Servidor:</strong> <%= application.getServerInfo() %></p>
            <p><strong>Servlet API:</strong> <%= application.getMajorVersion() %>.<%= application.getMinorVersion() %></p>
            <p><strong>JSP API:</strong> <%= JspFactory.getDefaultFactory().getEngineInfo().getSpecificationVersion() %></p>
            <p><strong>Java:</strong> <%= System.getProperty("java.version") %></p>
            <p><strong>Sistema Operativo:</strong> <%= System.getProperty("os.name") %> <%= System.getProperty("os.version") %></p>
            <p><strong>Fecha y hora:</strong> <%= new java.util.Date() %></p>
        </div>
        
        <a href="index.html" class="back">Volver</a>
    </div>
</body>
</html>
