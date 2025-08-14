#!/bin/bash
#
# Script para validar el archivo .env
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Validando archivo .env ===${NC}"
echo ""

if [ ! -f ".env" ]; then
    echo -e "${RED}Error: No se encontró el archivo .env${NC}"
    exit 1
fi

# Contadores
VALID_VARS=0
INVALID_VARS=0
WARNINGS=0

echo -e "${YELLOW}Validando variables...${NC}"

# Leer el archivo línea por línea
while IFS= read -r line; do
    # Saltar líneas vacías y comentarios
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ -z $line ]] && continue
    
    # Verificar si la línea contiene una asignación de variable
    if [[ $line =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Verificar si la clave es válida
        if [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            ((VALID_VARS++))
            
            # Verificaciones específicas
            case $key in
                *PASSWORD*)
                    if [[ ${#value} -lt 8 ]]; then
                        echo -e "${YELLOW}Advertencia: $key parece tener una contraseña corta${NC}"
                        ((WARNINGS++))
                    fi
                    ;;
                *MEMORY_ARGS*)
                    if [[ $value != \"*\" ]]; then
                        echo -e "${YELLOW}Advertencia: $key debería estar entre comillas dobles${NC}"
                        ((WARNINGS++))
                    fi
                    ;;
                BUILD_DATE)
                    if [[ $value == *'$('* ]]; then
                        echo -e "${YELLOW}Advertencia: $key contiene comando que puede causar problemas${NC}"
                        ((WARNINGS++))
                    fi
                    ;;
            esac
        else
            echo -e "${RED}Error: Clave inválida: $key${NC}"
            ((INVALID_VARS++))
        fi
    else
        # Línea que no es una asignación válida
        if [[ ! $line =~ ^[[:space:]]*$ ]]; then
            echo -e "${RED}Error: Línea con formato inválido: $line${NC}"
            ((INVALID_VARS++))
        fi
    fi
done < .env

echo ""
echo -e "${BLUE}=== Resumen de validación ===${NC}"
echo -e "Variables válidas: ${GREEN}$VALID_VARS${NC}"
echo -e "Variables inválidas: ${RED}$INVALID_VARS${NC}"
echo -e "Advertencias: ${YELLOW}$WARNINGS${NC}"

if [ $INVALID_VARS -eq 0 ]; then
    echo -e "${GREEN}✓ El archivo .env es válido${NC}"
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ Hay algunas advertencias que deberías revisar${NC}"
    fi
    
    exit 0
else
    echo -e "${RED}✗ El archivo .env tiene errores que deben corregirse${NC}"
    exit 1
fi
