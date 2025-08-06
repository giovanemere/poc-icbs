#!/bin/bash
#
# Script para limpiar la caché de WebLogic
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Limpiando caché de WebLogic ===${NC}"

# Verificar si los contenedores están en ejecución
weblogic_a_running=false
weblogic_b_running=false

if docker ps | grep -q weblogic-a; then
    weblogic_a_running=true
else
    echo -e "${RED}Error: El contenedor weblogic-a no está en ejecución${NC}"
    echo "Por favor, inicie el contenedor con:"
    echo -e "${YELLOW}  docker-compose -f config/docker-compose.yml up -d${NC}"
fi

if docker ps | grep -q weblogic-b; then
    weblogic_b_running=true
else
    echo -e "${YELLOW}Aviso: El contenedor weblogic-b no está en ejecución${NC}"
fi

# Función para limpiar caché en un contenedor WebLogic
clean_weblogic_container() {
    local container=$1
    local app_name=$2
    
    echo -e "${YELLOW}Limpiando caché en $container...${NC}"
    
    # Limpiar archivos temporales
    echo -e "${YELLOW}  Limpiando archivos temporales...${NC}"
    docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/*" || {
        echo -e "${RED}  Error al limpiar archivos temporales en $container${NC}"
    }
    
    # Limpiar archivos de caché
    echo -e "${YELLOW}  Limpiando archivos de caché...${NC}"
    docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/*" || {
        echo -e "${RED}  Error al limpiar archivos de caché en $container${NC}"
    }
    
    # Limpiar archivos de trabajo (stage)
    echo -e "${YELLOW}  Limpiando archivos de trabajo...${NC}"
    docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/stage/*" || {
        echo -e "${RED}  Error al limpiar archivos de trabajo en $container${NC}"
    }
    
    # Si se especificó una aplicación, limpiar archivos específicos
    if [ -n "$app_name" ]; then
        echo -e "${YELLOW}  Limpiando archivos específicos para $app_name...${NC}"
        docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$app_name*" || true
        docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/stage/$app_name*" || true
        docker exec $container bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/$app_name*" || true
    fi
    
    # Limpiar archivos de logs específicos
    echo -e "${YELLOW}  Limpiando archivos de logs específicos...${NC}"
    docker exec $container bash -c "rm -f /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs/access.log*" || true
    docker exec $container bash -c "find /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs -name '*.log*' -size +10M -delete" || true
    
    echo -e "${GREEN}  Caché limpiada en $container${NC}"
}

# Limpiar caché en weblogic-a si está en ejecución
if [ "$weblogic_a_running" = true ]; then
    clean_weblogic_container "weblogic-a" "$1"
fi

# Limpiar caché en weblogic-b si está en ejecución
if [ "$weblogic_b_running" = true ]; then
    clean_weblogic_container "weblogic-b" "$1"
fi

# Verificar si se necesita reiniciar los servidores
read -p "¿Desea reiniciar los servidores WebLogic? (s/n): " restart_servers

if [[ $restart_servers =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Reiniciando servidores WebLogic...${NC}"
    
    if [ "$weblogic_a_running" = true ]; then
        echo -e "${YELLOW}Reiniciando weblogic-a...${NC}"
        docker restart weblogic-a
    fi
    
    if [ "$weblogic_b_running" = true ]; then
        echo -e "${YELLOW}Reiniciando weblogic-b...${NC}"
        docker restart weblogic-b
    fi
    
    echo -e "${YELLOW}Esperando a que los servidores se inicien...${NC}"
    sleep 30
    
    # Verificar estado de los servidores
    if [ "$weblogic_a_running" = true ]; then
        echo -e "${YELLOW}Verificando estado de weblogic-a...${NC}"
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/console | grep -q "302"; then
            echo -e "${GREEN}  weblogic-a está en funcionamiento${NC}"
        else
            echo -e "${RED}  weblogic-a puede no estar completamente iniciado${NC}"
        fi
    fi
    
    if [ "$weblogic_b_running" = true ]; then
        echo -e "${YELLOW}Verificando estado de weblogic-b...${NC}"
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:7002/console | grep -q "302"; then
            echo -e "${GREEN}  weblogic-b está en funcionamiento${NC}"
        else
            echo -e "${RED}  weblogic-b puede no estar completamente iniciado${NC}"
        fi
    fi
else
    echo -e "${YELLOW}No se reiniciarán los servidores WebLogic${NC}"
fi

echo -e "${GREEN}=== Limpieza de caché de WebLogic completada ===${NC}"
echo ""
