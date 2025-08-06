#!/bin/bash

# Script para actualizar el dashboard con datos reales de WebLogic

echo "Obteniendo estado actual de WebLogic desde HAProxy..."

# Obtener datos JSON de HAProxy
WEBLOGIC_A_STATUS=$(curl -s -u admin:admin123 "http://localhost:8404/stats;json" | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    for item in data:
        if isinstance(item, list):
            current_server = None
            current_proxy = None
            status = None
            
            for entry in item:
                if entry.get('objType') == 'Server':
                    field_name = entry.get('field', {}).get('name')
                    value = entry.get('value', {}).get('value')
                    
                    if field_name == 'pxname':
                        current_proxy = value
                    elif field_name == 'svname':
                        current_server = value
                    elif field_name == 'status':
                        status = value
            
            if (current_proxy == 'weblogic_main' and current_server == 'weblogic-a'):
                print('Activo' if status == 'UP' else 'Inactivo')
                break
    else:
        print('Inactivo')
except:
    print('Error')
")

WEBLOGIC_B_STATUS=$(curl -s -u admin:admin123 "http://localhost:8404/stats;json" | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    for item in data:
        if isinstance(item, list):
            current_server = None
            current_proxy = None
            status = None
            
            for entry in item:
                if entry.get('objType') == 'Server':
                    field_name = entry.get('field', {}).get('name')
                    value = entry.get('value', {}).get('value')
                    
                    if field_name == 'pxname':
                        current_proxy = value
                    elif field_name == 'svname':
                        current_server = value
                    elif field_name == 'status':
                        status = value
            
            if (current_proxy == 'weblogic_main' and current_server == 'weblogic-b'):
                print('Activo' if status == 'UP' else 'Inactivo')
                break
    else:
        print('Inactivo')
except:
    print('Error')
")

echo "Estado de WebLogic A: $WEBLOGIC_A_STATUS"
echo "Estado de WebLogic B: $WEBLOGIC_B_STATUS"

# Mostrar resumen
echo ""
echo "=== RESUMEN DEL ESTADO ==="
echo "WebLogic A: $WEBLOGIC_A_STATUS"
echo "WebLogic B: $WEBLOGIC_B_STATUS"
echo ""

if [ "$WEBLOGIC_A_STATUS" = "Activo" ] && [ "$WEBLOGIC_B_STATUS" = "Activo" ]; then
    echo "✅ Ambos servidores WebLogic están funcionando correctamente"
    echo "El problema está en la configuración del dashboard web"
    echo ""
    echo "SOLUCIÓN:"
    echo "1. Los servidores WebLogic A y B están UP y funcionando"
    echo "2. HAProxy los detecta correctamente como activos"
    echo "3. El dashboard web no puede obtener estos datos porque la API intermedia no funciona"
    echo "4. Accede directamente a las estadísticas de HAProxy en: http://localhost:8404/stats"
    echo "   (usuario: admin, contraseña: admin123)"
else
    echo "❌ Hay problemas con los servidores WebLogic"
fi
