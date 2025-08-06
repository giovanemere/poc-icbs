#!/bin/bash
"""
Script para configurar autenticación segura en HAProxy
Genera credenciales aleatorias y actualiza la configuración
"""

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
HAPROXY_CONFIG="$PROJECT_ROOT/applications/haproxy-advanced/config/haproxy.cfg"
MONITORING_CONFIG="$PROJECT_ROOT/config/monitoring/url-monitoring.json"
BACKUP_DIR="$PROJECT_ROOT/backups/security"

echo -e "${BLUE}🔐 Configurando autenticación segura para HAProxy${NC}"
echo "=================================================="

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Función para generar contraseña segura
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
}

# Función para hacer backup
backup_file() {
    local file="$1"
    local backup_name="$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$BACKUP_DIR/$backup_name"
    echo -e "${GREEN}✅ Backup creado: $backup_name${NC}"
}

# Generar nuevas credenciales
echo -e "\n${YELLOW}🎲 Generando credenciales seguras...${NC}"
NEW_USERNAME="haproxy_admin"
NEW_PASSWORD=$(generate_password)

echo "Usuario: $NEW_USERNAME"
echo "Contraseña: $NEW_PASSWORD"

# Hacer backup de archivos
echo -e "\n${YELLOW}💾 Creando backups...${NC}"
backup_file "$HAPROXY_CONFIG"
backup_file "$MONITORING_CONFIG"

# Actualizar configuración de HAProxy
echo -e "\n${YELLOW}⚙️  Actualizando configuración HAProxy...${NC}"
sed -i.bak "s/stats auth admin:admin123/stats auth $NEW_USERNAME:$NEW_PASSWORD/g" "$HAPROXY_CONFIG"

if grep -q "stats auth $NEW_USERNAME:$NEW_PASSWORD" "$HAPROXY_CONFIG"; then
    echo -e "${GREEN}✅ HAProxy configurado correctamente${NC}"
else
    echo -e "${RED}❌ Error actualizando HAProxy${NC}"
    exit 1
fi

# Actualizar configuración de monitoreo
echo -e "\n${YELLOW}📊 Actualizando configuración de monitoreo...${NC}"
python3 -c "
import json
import sys

config_file = '$MONITORING_CONFIG'
try:
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Buscar y actualizar HAProxy Stats
    for url_config in config['urls']:
        if url_config['name'] == 'HAProxy Stats':
            if 'auth' in url_config:
                url_config['auth']['username'] = '$NEW_USERNAME'
                url_config['auth']['password'] = '$NEW_PASSWORD'
                break
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print('✅ Configuración de monitoreo actualizada')
except Exception as e:
    print(f'❌ Error: {e}')
    sys.exit(1)
"

# Reiniciar HAProxy
echo -e "\n${YELLOW}🔄 Reiniciando HAProxy...${NC}"
cd "$PROJECT_ROOT"
docker-compose -f config/docker-compose.yml restart haproxy

# Esperar a que HAProxy esté listo
echo -e "\n${YELLOW}⏳ Esperando a que HAProxy esté listo...${NC}"
sleep 5

# Probar nueva autenticación
echo -e "\n${YELLOW}🧪 Probando nueva autenticación...${NC}"
if curl -s -u "$NEW_USERNAME:$NEW_PASSWORD" http://localhost:8404/stats | grep -q "HAProxy Statistics"; then
    echo -e "${GREEN}✅ Autenticación funcionando correctamente${NC}"
else
    echo -e "${RED}❌ Error en la autenticación${NC}"
    exit 1
fi

# Guardar credenciales en archivo seguro
CREDS_FILE="$BACKUP_DIR/haproxy-credentials-$(date +%Y%m%d_%H%M%S).txt"
cat > "$CREDS_FILE" << EOF
HAProxy Authentication Credentials
Generated: $(date)
================================

Username: $NEW_USERNAME
Password: $NEW_PASSWORD

URLs:
- Stats: http://localhost:8404/stats
- Admin: http://localhost:8082/

IMPORTANT: Keep this file secure and delete after noting credentials!
EOF

chmod 600 "$CREDS_FILE"

echo -e "\n${GREEN}🎉 Configuración completada exitosamente!${NC}"
echo "=================================================="
echo -e "${YELLOW}📋 RESUMEN:${NC}"
echo "• Usuario: $NEW_USERNAME"
echo "• Contraseña: $NEW_PASSWORD"
echo "• Credenciales guardadas en: $CREDS_FILE"
echo "• Backups en: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}🔗 URLs de acceso:${NC}"
echo "• Stats: http://localhost:8404/stats"
echo "• Admin: http://localhost:8082/"
echo ""
echo -e "${RED}⚠️  IMPORTANTE: Anota las credenciales y elimina el archivo de credenciales${NC}"
