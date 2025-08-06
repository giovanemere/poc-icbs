#!/bin/bash
"""
Script para verificar el estado actual de la autenticación HAProxy
"""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Estado de Autenticación HAProxy${NC}"
echo "=================================="

# Verificar configuración actual
HAPROXY_CONFIG="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/applications/haproxy-advanced/config/haproxy.cfg"

if [ -f "$HAPROXY_CONFIG" ]; then
    echo -e "\n${YELLOW}📋 Configuración actual:${NC}"
    
    # Extraer credenciales de la configuración
    AUTH_LINE=$(grep "stats auth" "$HAPROXY_CONFIG" | head -1)
    if [ -n "$AUTH_LINE" ]; then
        CREDENTIALS=$(echo "$AUTH_LINE" | sed 's/.*stats auth //')
        USERNAME=$(echo "$CREDENTIALS" | cut -d: -f1)
        PASSWORD=$(echo "$CREDENTIALS" | cut -d: -f2)
        
        echo "• Usuario: $USERNAME"
        echo "• Contraseña: $PASSWORD"
        echo "• Línea completa: $AUTH_LINE"
    else
        echo -e "${RED}❌ No se encontró configuración de autenticación${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Archivo de configuración no encontrado${NC}"
    exit 1
fi

# Probar autenticación
echo -e "\n${YELLOW}🧪 Probando autenticación:${NC}"

# Sin autenticación
echo -n "• Sin credenciales: "
STATUS_NO_AUTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8404/stats)
if [ "$STATUS_NO_AUTH" = "401" ]; then
    echo -e "${GREEN}401 ✅ (Correcto - requiere auth)${NC}"
else
    echo -e "${RED}$STATUS_NO_AUTH ❌ (Debería ser 401)${NC}"
fi

# Con autenticación
echo -n "• Con credenciales: "
STATUS_WITH_AUTH=$(curl -s -o /dev/null -w "%{http_code}" -u "$USERNAME:$PASSWORD" http://localhost:8404/stats)
if [ "$STATUS_WITH_AUTH" = "200" ]; then
    echo -e "${GREEN}200 ✅ (Correcto - acceso autorizado)${NC}"
else
    echo -e "${RED}$STATUS_WITH_AUTH ❌ (Debería ser 200)${NC}"
fi

# Verificar contenido
echo -n "• Contenido válido: "
CONTENT=$(curl -s -u "$USERNAME:$PASSWORD" http://localhost:8404/stats | head -5)
if echo "$CONTENT" | grep -q "HAProxy Statistics\|Statistics Report"; then
    echo -e "${GREEN}✅ Página de estadísticas detectada${NC}"
else
    echo -e "${RED}❌ Contenido no válido${NC}"
fi

# Verificar configuración de monitoreo
echo -e "\n${YELLOW}📊 Configuración de monitoreo:${NC}"
MONITORING_CONFIG="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/config/monitoring/url-monitoring.json"

if [ -f "$MONITORING_CONFIG" ]; then
    MONITORING_USER=$(python3 -c "
import json
try:
    with open('$MONITORING_CONFIG', 'r') as f:
        config = json.load(f)
    for url in config['urls']:
        if url['name'] == 'HAProxy Stats' and 'auth' in url:
            print(url['auth']['username'])
            break
except:
    pass
")
    
    if [ -n "$MONITORING_USER" ]; then
        if [ "$MONITORING_USER" = "$USERNAME" ]; then
            echo -e "• Usuario en monitoreo: ${GREEN}$MONITORING_USER ✅ (Coincide)${NC}"
        else
            echo -e "• Usuario en monitoreo: ${RED}$MONITORING_USER ❌ (No coincide con HAProxy)${NC}"
        fi
    else
        echo -e "${RED}❌ No se encontró configuración de auth en monitoreo${NC}"
    fi
else
    echo -e "${RED}❌ Archivo de configuración de monitoreo no encontrado${NC}"
fi

# Resumen
echo -e "\n${BLUE}📋 RESUMEN${NC}"
echo "=========="

if [ "$STATUS_NO_AUTH" = "401" ] && [ "$STATUS_WITH_AUTH" = "200" ]; then
    echo -e "${GREEN}✅ Autenticación HAProxy: FUNCIONANDO CORRECTAMENTE${NC}"
    echo "• Acceso protegido: ✅"
    echo "• Credenciales válidas: ✅"
    echo "• Usuario actual: $USERNAME"
    echo "• URL Stats: http://localhost:8404/stats"
else
    echo -e "${RED}❌ Autenticación HAProxy: PROBLEMAS DETECTADOS${NC}"
    echo "• Revisar configuración de HAProxy"
    echo "• Verificar que el servicio esté ejecutándose"
fi
