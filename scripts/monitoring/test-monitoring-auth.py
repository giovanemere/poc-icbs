#!/usr/bin/env python3
"""
Script de prueba para verificar monitoreo con autenticación
"""

import json
import requests
from requests.auth import HTTPBasicAuth

def test_monitoring_with_auth():
    """Probar monitoreo con autenticación"""
    
    # Cargar configuración
    config_path = "/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/config/monitoring/url-monitoring.json"
    
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
    except Exception as e:
        print(f"❌ Error cargando configuración: {e}")
        return
    
    print("🔍 Probando URLs con autenticación...")
    print("="*50)
    
    for url_config in config['urls']:
        name = url_config['name']
        url = url_config['url']
        
        print(f"\n📍 {name}")
        print(f"   URL: {url}")
        
        # Configurar autenticación si está presente
        auth = None
        if 'auth' in url_config:
            auth_config = url_config['auth']
            if auth_config.get('type') == 'basic':
                auth = HTTPBasicAuth(
                    auth_config.get('username', ''),
                    auth_config.get('password', '')
                )
                print(f"   🔐 Autenticación: {auth_config.get('username')}")
        
        try:
            response = requests.get(url, auth=auth, timeout=10, verify=False)
            status_code = response.status_code
            
            expected_codes = url_config.get('expected_codes', [200])
            
            if status_code in expected_codes:
                print(f"   ✅ Status: {status_code} (Esperado)")
            else:
                print(f"   ⚠️  Status: {status_code} (Esperado: {expected_codes})")
                
            print(f"   📊 Tamaño: {len(response.content)} bytes")
            
        except requests.exceptions.ConnectionError:
            print(f"   ❌ Error: No se puede conectar")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print("\n" + "="*50)
    print("✅ Prueba de monitoreo completada")

if __name__ == "__main__":
    test_monitoring_with_auth()
