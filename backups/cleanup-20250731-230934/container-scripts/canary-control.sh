#!/bin/bash
#
# Script para controlar el despliegue Canary de weblogic-features
#

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  deploy              - Despliega la aplicación weblogic-features con soporte para Canary"
    echo "  version-a           - Cambia a 100% tráfico a la versión A"
    echo "  version-b           - Cambia a 100% tráfico a la versión B"
    echo "  split [A] [B]       - Divide el tráfico entre versiones A y B (porcentajes)"
    echo "  status              - Muestra el estado actual del despliegue Canary"
    echo ""
    echo "Ejemplos:"
    echo "  $0 deploy"
    echo "  $0 version-a"
    echo "  $0 version-b"
    echo "  $0 split 80 20      - 80% versión A, 20% versión B"
    echo "  $0 status"
}

# Verificar que se proporcionó un comando
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

# Obtener el comando
COMMAND=$1

# Ejecutar el comando correspondiente
case $COMMAND in
    deploy)
        echo "Desplegando aplicación weblogic-features con soporte para Canary..."
        java weblogic.WLST /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/container-scripts/deploy-weblogic-features.py
        ;;
    version-a)
        echo "Cambiando a 100% tráfico a la versión A..."
        java weblogic.WLST /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/container-scripts/switch-canary-version.py 100 0
        ;;
    version-b)
        echo "Cambiando a 100% tráfico a la versión B..."
        java weblogic.WLST /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/container-scripts/switch-canary-version.py 0 100
        ;;
    split)
        # Verificar que se proporcionaron los porcentajes
        if [ $# -ne 3 ]; then
            echo "Error: Se requieren dos porcentajes para el comando split"
            show_help
            exit 1
        fi
        
        # Verificar que los porcentajes suman 100
        if [ $(($2 + $3)) -ne 100 ]; then
            echo "Error: Los porcentajes deben sumar 100"
            exit 1
        fi
        
        echo "Dividiendo tráfico: $2% versión A, $3% versión B..."
        java weblogic.WLST /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/container-scripts/switch-canary-version.py $2 $3
        ;;
    status)
        echo "Consultando estado del despliegue Canary..."
        # Aquí se podría implementar un script adicional para consultar el estado
        echo "Funcionalidad no implementada aún"
        ;;
    *)
        echo "Comando desconocido: $COMMAND"
        show_help
        exit 1
        ;;
esac

exit 0
