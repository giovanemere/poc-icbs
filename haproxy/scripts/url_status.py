#!/usr/bin/env python3
"""
Script para verificar el estado de las URLs y proporcionar los resultados en formato JSON.
Este script ejecuta check-urls-container.sh y formatea la salida para el dashboard de HAProxy.
"""

import os
import json
import subprocess
import re
from flask import jsonify

def run_check_urls():
    """Ejecutar el script check-urls-container.sh y procesar su salida."""
    try:
        # Ruta al script check-urls-container.sh
        script_path = "/scripts/check-urls-container.sh"
        
        # Ejecutar el script
        result = subprocess.run([script_path], 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE, 
                               text=True)
        
        # Procesar la salida
        return result.stdout
    except Exception as e:
        return f"Error al ejecutar check-urls-container.sh: {str(e)}"

def parse_url_status(output):
    """Parsear la salida del script check-urls-container.sh y convertirla a formato JSON."""
    urls = []
    summary = {"success": 0, "warnings": 0, "errors": 0}
    
    # Patrones para extraer información
    url_pattern = re.compile(r'(✅|⚠️|❌)\s+(http[s]?://[^\s]+)\s+-\s+([A-Z]+)\s+\((\d+)\)')
    summary_pattern = re.compile(r'URLs exitosas:\s+(\d+).*URLs con advertencias:\s+(\d+).*URLs con errores:\s+(\d+)', re.DOTALL)
    
    # Extraer información de URLs
    for line in output.split('\n'):
        match = url_pattern.search(line)
        if match:
            status_icon, url, status_text, status_code = match.groups()
            
            status_type = "success"
            if status_icon == "⚠️":
                status_type = "warning"
            elif status_icon == "❌":
                status_type = "error"
            
            urls.append({
                "url": url,
                "status": status_text,
                "code": status_code,
                "type": status_type
            })
    
    # Extraer resumen
    summary_match = summary_pattern.search(output)
    if summary_match:
        summary["success"] = int(summary_match.group(1))
        summary["warnings"] = int(summary_match.group(2))
        summary["errors"] = int(summary_match.group(3))
    
    return {
        "urls": urls,
        "summary": summary,
        "raw_output": output
    }

def get_url_status():
    """Obtener el estado de las URLs en formato JSON."""
    output = run_check_urls()
    return parse_url_status(output)

if __name__ == "__main__":
    # Si se ejecuta directamente, imprimir el resultado en formato JSON
    result = get_url_status()
    print(json.dumps(result, indent=2))
