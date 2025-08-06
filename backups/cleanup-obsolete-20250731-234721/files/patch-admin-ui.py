#!/usr/bin/env python3
"""
Script para agregar el endpoint /api/servers-status a la interfaz web de HAProxy.
"""

def create_api_endpoint():
    """Crear el código para el nuevo endpoint."""
    
    endpoint_code = '''
@app.route('/api/servers-status')
def api_servers_status():
    """Endpoint para obtener el estado actualizado de todos los servidores."""
    try:
        # Obtener estadísticas de HAProxy
        stats_response = requests.get(f"{API_BASE_URL}/stats")
        
        if stats_response.status_code == 200:
            stats = stats_response.json()
            return jsonify(stats)
        else:
            return jsonify({'error': 'No se pudieron obtener las estadísticas'}), 500
            
    except Exception as e:
        return jsonify({'error': f'Error al obtener estadísticas: {str(e)}'}), 500
'''
    
    return endpoint_code

def main():
    """Función principal."""
    print("🔧 Creando parche para admin_ui.py...")
    
    endpoint_code = create_api_endpoint()
    
    # Escribir el código del endpoint
    with open('/tmp/api_endpoint_patch.py', 'w') as f:
        f.write(endpoint_code)
    
    print("✅ Parche creado en /tmp/api_endpoint_patch.py")
    print("\nPara aplicar el parche manualmente:")
    print("1. Agregar el código del endpoint al final de admin_ui.py")
    print("2. Reiniciar el contenedor HAProxy")
    
    return True

if __name__ == "__main__":
    main()
