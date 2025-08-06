<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>WebLogic Features - Version B</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 10px; backdrop-filter: blur(10px); }
        .version { background: #dc3545; padding: 10px 20px; border-radius: 5px; display: inline-block; margin: 10px 0; }
        .feature { background: rgba(255,255,255,0.2); padding: 15px; margin: 10px 0; border-radius: 5px; }
        .status { color: #FFB6C1; font-weight: bold; }
        .beta { color: #FFA500; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 WebLogic Feature Flags System</h1>
        <div class="version">VERSION B - BETA</div>
        
        <h2>📊 System Status</h2>
        <div class="feature">
            <h3>🔧 Server Information</h3>
            <p><strong>Server:</strong> <%= request.getServerName() %>:<%= request.getServerPort() %></p>
            <p><strong>Session ID:</strong> <%= session.getId() %></p>
            <p><strong>Timestamp:</strong> <%= new java.util.Date() %></p>
            <p><strong>Version:</strong> <span class="beta">B - BETA RELEASE</span></p>
        </div>
        
        <div class="feature">
            <h3>🎯 Feature Flags (Version B)</h3>
            <p>✅ <strong>Modern UI:</strong> <span class="status">ENABLED</span></p>
            <p>✅ <strong>Enhanced Authentication:</strong> <span class="status">ENABLED</span></p>
            <p>✅ <strong>Advanced Monitoring:</strong> <span class="status">ENABLED</span></p>
            <p>✅ <strong>Advanced Analytics:</strong> <span class="beta">BETA</span></p>
            <p>✅ <strong>Experimental Features:</strong> <span class="beta">BETA</span></p>
        </div>
        
        <div class="feature">
            <h3>🔗 Navigation</h3>
            <p><a href="/console" style="color: #FFB6C1;">WebLogic Console</a></p>
            <p><a href="/health" style="color: #FFB6C1;">Health Check</a></p>
        </div>
        
        <div class="feature">
            <h3>🏗️ Architecture Status</h3>
            <p><strong>Load Balancer:</strong> <span class="status">HAProxy Active</span></p>
            <p><strong>Database:</strong> <span class="status">Oracle Connected</span></p>
            <p><strong>Deployment:</strong> <span class="status">Automated Success</span></p>
            <p><strong>Canary Mode:</strong> <span class="beta">ACTIVE</span></p>
        </div>
    </div>
</body>
</html>
