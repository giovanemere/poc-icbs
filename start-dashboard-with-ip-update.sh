#!/bin/bash

# Script integrado mejorado que incluye actualización de IPs antes del HAProxy Deployment Manager
# Equivale a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./cleanup-environment.sh light && ./start-dashboard-integrated.sh
# Pero con actualización de IPs integrada usando ambos métodos

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Función para limpiar en caso de error
cleanup_on_error() {
    echo
    echo -e "${RED}❌ Error detectado durante el inicio${NC}"
    echo -e "${YELLOW}🧹 Iniciando limpieza automática...${NC}"
    echo
    
    # Detener y limpiar contenedores
    echo -e "${BLUE}Deteniendo contenedores existentes...${NC}"
    docker-compose -f config/docker-compose-multi-env.yml down --remove-orphans 2>/dev/null || true
    
    # Limpiar contenedores huérfanos
    echo -e "${BLUE}Limpiando contenedores huérfanos...${NC}"
    docker container prune -f 2>/dev/null || true
    
    # Limpiar redes no utilizadas
    echo -e "${BLUE}Limpiando redes no utilizadas...${NC}"
    docker network prune -f 2>/dev/null || true
    
    echo -e "${GREEN}✓ Limpieza completada${NC}"
    echo
    echo -e "${YELLOW}🔄 Reintentando inicio...${NC}"
    echo
}

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

echo -e "${BLUE}=== Iniciando Entorno Completo con HAProxy Deployment Manager e IPs Actualizadas ===${NC}"
echo

# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

echo -e "${BLUE}Directorio actual: $(pwd)${NC}"
echo

# Verificar que el archivo docker-compose existe
if [ ! -f "config/docker-compose-multi-env.yml" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo config/docker-compose-multi-env.yml${NC}"
    exit 1
fi

# Verificar que el script start-multi-env.sh existe
if [ ! -f "start-multi-env.sh" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo start-multi-env.sh${NC}"
    exit 1
fi

# Primer intento de inicio
echo -e "${BLUE}=== Paso 1: Iniciando servicios base ===${NC}"
echo

if ./start-multi-env.sh full; then
    echo
    echo -e "${GREEN}=== ✅ Servicios Base Iniciados Exitosamente ===${NC}"
    
    # Paso 2: Actualizar IPs de HAProxy (CRÍTICO)
    echo
    echo -e "${BLUE}=== Paso 2: Actualizando IPs de HAProxy ===${NC}"
    echo -e "${YELLOW}⚠️  Este paso es crítico para el funcionamiento del HAProxy Deployment Manager${NC}"
    echo
    
    # Método 1: Script automático (recomendado)
    echo -e "${BLUE}Método 1: Script automático (recomendado)${NC}"
    if [ -f "scripts/auto-update-haproxy.sh" ] && ./scripts/auto-update-haproxy.sh; then
        show_status 0 "IPs actualizadas con script automático"
        ip_update_success=true
    else
        show_status 1 "Error con script automático"
        ip_update_success=false
        
        # Método 2: Script Python (más avanzado)
        echo -e "${BLUE}Método 2: Script Python avanzado (fallback)${NC}"
        if [ -f "scripts/haproxy-ip-updater.py" ] && python3 scripts/haproxy-ip-updater.py; then
            show_status 0 "IPs actualizadas con script Python"
            ip_update_success=true
        else
            show_status 1 "Error con script Python"
            
            # Método 3: Script integrado
            echo -e "${BLUE}Método 3: Script integrado (último recurso)${NC}"
            if [ -f "update-haproxy-ips.sh" ] && ./update-haproxy-ips.sh; then
                show_status 0 "IPs actualizadas con script integrado"
                ip_update_success=true
            else
                show_status 1 "Error con todos los métodos de actualización de IPs"
                ip_update_success=false
            fi
        fi
    fi
    
    if [ "$ip_update_success" = true ]; then
        echo -e "${GREEN}✅ Actualización de IPs completada exitosamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Continuando sin actualización de IPs - El HAProxy Manager podría no funcionar correctamente${NC}"
    fi
    
    # Paso 3: Inicializar HAProxy Deployment Manager
    echo
    echo -e "${BLUE}=== Paso 3: Inicializando HAProxy Deployment Manager ===${NC}"
    
    # Esperar que HAProxy esté completamente listo
    sleep 5
    
    # Verificar que HAProxy esté ejecutándose
    if docker ps | grep -q "haproxy"; then
        show_status 0 "HAProxy está ejecutándose"
        
        # Verificar configuración de IPs
        echo -e "${BLUE}Verificando configuración de IPs en HAProxy...${NC}"
        if docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
            show_status 0 "Configuración de IPs verificada"
            echo -e "${BLUE}IPs configuradas:${NC}"
            docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg | sed 's/^/  /'
        else
            show_status 1 "Configuración de IPs no encontrada en HAProxy"
        fi
        
        # Arreglar certificados SSL en el contenedor
        echo -e "${BLUE}Configurando certificados SSL...${NC}"
        docker exec haproxy update-ca-certificates >/dev/null 2>&1 || true
        
        # Iniciar servicios de administración del HAProxy Manager
        echo -e "${BLUE}Iniciando servicios de administración...${NC}"
        docker exec -d haproxy python3 /scripts/admin_ui.py 2>/dev/null || true
        
        # Esperar que los servicios estén listos
        sleep 8
        
        # Verificar API de administración
        if curl -s --max-time 5 http://localhost:8081/api/config >/dev/null 2>&1; then
            show_status 0 "API de administración accesible (puerto 8081)"
        else
            show_status 1 "API de administración no accesible"
        fi
        
        # Verificar UI de administración
        if curl -s --max-time 5 http://localhost:8082 >/dev/null 2>&1; then
            show_status 0 "UI de administración accesible (puerto 8082)"
        else
            show_status 1 "UI de administración no accesible"
        fi
        
    else
        show_status 1 "HAProxy no está ejecutándose"
    fi
    
    echo
    echo -e "${GREEN}=== ✅ Comando Integrado Completado Exitosamente ===${NC}"
    echo -e "${YELLOW}🎉 Todos los servicios están ejecutándose, incluyendo el HAProxy Deployment Manager!${NC}"
    
else
    # Si falla, hacer limpieza y reintentar
    cleanup_on_error
    
    # Segundo intento después de la limpieza
    echo -e "${BLUE}Segundo intento: ./start-multi-env.sh full${NC}"
    echo
    
    if ./start-multi-env.sh full; then
        echo
        echo -e "${GREEN}=== ✅ Servicios Base Iniciados (Segundo Intento) ===${NC}"
        
        # Repetir proceso de actualización de IPs y HAProxy Manager
        echo
        echo -e "${BLUE}=== Actualizando IPs de HAProxy (Segundo Intento) ===${NC}"
        
        # Usar script integrado directamente
        if [ -f "update-haproxy-ips.sh" ] && ./update-haproxy-ips.sh; then
            show_status 0 "IPs actualizadas correctamente"
        else
            show_status 1 "Error al actualizar IPs"
        fi
        
        # Inicializar HAProxy Deployment Manager
        echo
        echo -e "${BLUE}=== Inicializando HAProxy Deployment Manager (Segundo Intento) ===${NC}"
        
        sleep 5
        
        if docker ps | grep -q "haproxy"; then
            show_status 0 "HAProxy está ejecutándose"
            
            # Configurar SSL y servicios
            docker exec haproxy update-ca-certificates >/dev/null 2>&1 || true
            docker exec -d haproxy python3 /scripts/admin_ui.py 2>/dev/null || true
            sleep 8
            
            # Verificar servicios
            if curl -s --max-time 5 http://localhost:8081/api/config >/dev/null 2>&1; then
                show_status 0 "API de administración accesible (puerto 8081)"
            else
                show_status 1 "API de administración no accesible"
            fi
            
            if curl -s --max-time 5 http://localhost:8082 >/dev/null 2>&1; then
                show_status 0 "UI de administración accesible (puerto 8082)"
            else
                show_status 1 "UI de administración no accesible"
            fi
        fi
        
        echo
        echo -e "${GREEN}=== ✅ Comando Integrado Completado Exitosamente (Segundo Intento) ===${NC}"
        echo -e "${YELLOW}🎉 Todos los servicios están ejecutándose, incluyendo el HAProxy Deployment Manager!${NC}"
    else
        echo
        echo -e "${RED}=== ❌ Error: No se pudo iniciar el entorno después de la limpieza ===${NC}"
        exit 1
    fi
fi

echo
echo -e "${BLUE}=== 🌐 URLs de Acceso ===${NC}"
echo -e "🌐 HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"
echo -e "🎛️  HAProxy Deployment Manager: ${YELLOW}http://localhost:8082${NC}"
echo -e "📊 Dashboard Profesional:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
echo -e "🔧 Dashboard Directo:          ${YELLOW}http://localhost:8001/${NC}"
echo -e "📈 HAProxy Stats:              ${YELLOW}http://localhost:8404/stats${NC}"
echo -e "🔧 API de Administración:      ${YELLOW}http://localhost:8081/api${NC}"
echo -e "🅰️  WebLogic A:                 ${YELLOW}http://localhost:7001/console${NC}"
echo -e "🅱️  WebLogic B:                 ${YELLOW}http://localhost:7002/console${NC}"
echo -e "🚩 WebLogic Feature Flags:     ${YELLOW}http://localhost:7003/console${NC}"
echo -e "🗄️  Oracle Database:            ${YELLOW}localhost:1521${NC}"
echo -e "🗄️  Oracle Enterprise Manager:  ${YELLOW}http://localhost:5500/em${NC}"

echo
echo -e "${BLUE}=== 🛠️  Comandos Útiles ===${NC}"
echo -e "  Ver estado:                 ${YELLOW}./start-multi-env.sh status${NC}"
echo -e "  Ver logs del dashboard:     ${YELLOW}./start-multi-env.sh logs dashboard${NC}"
echo -e "  Ver logs de HAProxy:        ${YELLOW}./start-multi-env.sh logs haproxy${NC}"
echo -e "  Probar dashboard:           ${YELLOW}./scripts/test-dashboard.sh${NC}"
echo -e "  Probar HAProxy Manager:     ${YELLOW}./start-haproxy-manager.sh${NC}"
echo -e "  Actualizar IPs manualmente: ${YELLOW}./update-haproxy-ips.sh${NC}"
echo -e "  Reiniciar HAProxy:          ${YELLOW}./start-multi-env.sh restart haproxy${NC}"
echo -e "  Detener todo:               ${YELLOW}./start-multi-env.sh stop${NC}"

echo
echo -e "${GREEN}=== ✅ Verificación Final ===${NC}"

# Verificación rápida de servicios críticos
sleep 5

echo -e "${BLUE}Verificando servicios críticos...${NC}"

# Verificar HAProxy
if curl -s --max-time 5 http://localhost:8080 >/dev/null 2>&1; then
    show_status 0 "HAProxy Frontend accesible"
else
    show_status 1 "HAProxy Frontend no accesible"
fi

# Verificar HAProxy Deployment Manager
if curl -s --max-time 5 http://localhost:8082 >/dev/null 2>&1; then
    show_status 0 "HAProxy Deployment Manager accesible"
else
    show_status 1 "HAProxy Deployment Manager no accesible"
fi

# Verificar Dashboard directo
if curl -s --max-time 5 http://localhost:8001/api/health >/dev/null 2>&1; then
    show_status 0 "Dashboard directo accesible"
else
    show_status 1 "Dashboard directo no accesible"
fi

# Verificar Dashboard vía HAProxy
if curl -s --max-time 5 http://localhost:8080/dashboard/api/health >/dev/null 2>&1; then
    show_status 0 "Dashboard vía HAProxy accesible"
else
    show_status 1 "Dashboard vía HAProxy no accesible"
fi

echo
echo -e "${GREEN}🎉 ¡Entorno completo con HAProxy Deployment Manager e IPs actualizadas listo!${NC}"
echo -e "${BLUE}Accede al HAProxy Deployment Manager: ${YELLOW}http://localhost:8082${NC}"
echo -e "${YELLOW}💡 Para una verificación completa, ejecuta: ${BLUE}./scripts/test-dashboard.sh${NC}"
