#!/usr/bin/env python3
"""
Script de prueba para verificar autenticación HAProxy Stats
"""

import requests
from requests.auth import HTTPBasicAuth
import json

def test_haproxy_auth():
    """Probar autenticación HAProxy Stats"""
    
    # Configuración
    url = "http://localhost:8404/stats"
    username = "admin"
    password = "admin123"
    
    print("🔐 Probando autenticación HAProxy Stats...")
    print(f"URL: {url}")
    print(f"Usuario: {username}")
    
    try:
        # Prueba sin autenticación
        print("\n1. Probando sin autenticación...")
        response_no_auth = requests.get(url, timeout=10)
        print(f"   Status Code: {response_no_auth.status_code}")
        
        if response_no_auth.status_code == 401:
            print("   ✅ Correcto: Se requiere autenticación")
        else:
            print("   ⚠️  Advertencia: No se requiere autenticación")
        
        # Prueba con autenticación
        print("\n2. Probando con autenticación...")
        auth = HTTPBasicAuth(username, password)
        response_auth = requests.get(url, auth=auth, timeout=10)
        print(f"   Status Code: {response_auth.status_code}")
        
        if response_auth.status_code == 200:
            print("   ✅ Éxito: Autenticación correcta")
            print(f"   Content-Type: {response_auth.headers.get('content-type', 'N/A')}")
            print(f"   Content-Length: {len(response_auth.content)} bytes")
            
            # Verificar que contiene estadísticas
            if "HAProxy Statistics" in response_auth.text or "stats" in response_auth.text:
                print("   ✅ Contenido: Página de estadísticas detectada")
            else:
                print("   ⚠️  Contenido: No parece ser página de estadísticas")
                
        else:
            print(f"   ❌ Error: Autenticación falló - {response_auth.status_code}")
            
        # Prueba con credenciales incorrectas
        print("\n3. Probando con credenciales incorrectas...")
        wrong_auth = HTTPBasicAuth("wrong", "credentials")
        response_wrong = requests.get(url, auth=wrong_auth, timeout=10)
        print(f"   Status Code: {response_wrong.status_code}")
        
        if response_wrong.status_code == 401:
            print("   ✅ Correcto: Credenciales incorrectas rechazadas")
        else:
            print("   ⚠️  Advertencia: Credenciales incorrectas aceptadas")
            
        # Resumen
        print("\n" + "="*50)
        print("📊 RESUMEN DE PRUEBAS")
        print("="*50)
        
        if response_auth.status_code == 200:
            print("✅ Autenticación HAProxy: FUNCIONANDO")
            print(f"   Usuario: {username}")
            print(f"   URL: {url}")
            print("   Estado: Listo para monitoreo")
        else:
            print("❌ Autenticación HAProxy: FALLANDO")
            print("   Revisar configuración de HAProxy")
            
    except requests.exceptions.ConnectionError:
        print("❌ Error: No se puede conectar a HAProxy")
        print("   Verificar que HAProxy esté ejecutándose")
    except Exception as e:
        print(f"❌ Error inesperado: {e}")

if __name__ == "__main__":
    test_haproxy_auth()
