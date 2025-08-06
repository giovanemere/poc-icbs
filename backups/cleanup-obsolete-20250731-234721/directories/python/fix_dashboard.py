#!/usr/bin/env python3
"""
Script para corregir el dashboard de HAProxy obteniendo datos directamente de HAProxy.
"""

import requests
import json
import re

def get_weblogic_status():
    """Obtener el estado de WebLogic A y B desde HAProxy."""
    try:
        # Obtener datos JSON de HAProxy
        response = requests.get('http://localhost:8404/stats;json', 
                              auth=('admin', 'admin123'))
        
        if response.status_code != 200:
            return {'weblogic-a': 'Inactivo', 'weblogic-b': 'Inactivo'}
        
        data = response.json()
        
        weblogic_status = {}
        
        # Buscar información de weblogic-a y weblogic-b
        for item in data:
            if isinstance(item, list):
                for server_data in item:
                    if (server_data.get('objType') == 'Server' and 
                        server_data.get('field', {}).get('name') == 'pxname' and
                        server_data.get('value', {}).get('value') == 'weblogic_main'):
                        
                        # Encontrar el servidor correspondiente
                        server_name = None
                        status = None
                        connections = 0
                        response_time = 0
                        
                        # Buscar el nombre del servidor en el mismo grupo
                        for server_info in item:
                            if (server_info.get('objType') == 'Server' and
                                server_info.get('field', {}).get('name') == 'svname'):
                                server_name = server_info.get('value', {}).get('value')
                            elif (server_info.get('objType') == 'Server' and
                                  server_info.get('field', {}).get('name') == 'status'):
                                status = server_info.get('value', {}).get('value')
                            elif (server_info.get('objType') == 'Server' and
                                  server_info.get('field', {}).get('name') == 'scur'):
                                connections = server_info.get('value', {}).get('value', 0)
                            elif (server_info.get('objType') == 'Server' and
                                  server_info.get('field', {}).get('name') == 'rtime'):
                                response_time = server_info.get('value', {}).get('value', 0)
                        
                        if server_name in ['weblogic-a', 'weblogic-b']:
                            weblogic_status[server_name] = {
                                'status': 'Activo' if status == 'UP' else 'Inactivo',
                                'connections': connections,
                                'response_time': response_time
                            }
        
        return weblogic_status
        
    except Exception as e:
        print(f"Error al obtener estado de WebLogic: {e}")
        return {'weblogic-a': 'Error', 'weblogic-b': 'Error'}

def update_dashboard_template():
    """Actualizar el template del dashboard con datos reales."""
    try:
        status = get_weblogic_status()
        print("Estado de WebLogic:")
        for server, info in status.items():
            print(f"  {server}: {info}")
        
        return status
        
    except Exception as e:
        print(f"Error al actualizar dashboard: {e}")
        return None

if __name__ == "__main__":
    update_dashboard_template()
