#!/usr/bin/env python3
"""
Script para actualizar automáticamente las IPs de los servidores WebLogic en HAProxy
"""

import docker
import time
import re
import os
import sys
from datetime import datetime

class HAProxyUpdater:
    def __init__(self):
        self.client = docker.from_env()
        self.config_path = "/usr/local/etc/haproxy/haproxy.cfg"
        self.backup_path = f"/usr/local/etc/haproxy/haproxy.cfg.bak.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
    def get_container_ip(self, container_name):
        """Obtiene la IP de un contenedor por su nombre"""
        try:
            container = self.client.containers.get(container_name)
            networks = container.attrs['NetworkSettings']['Networks']
            for network_name, network_info in networks.items():
                if network_info['IPAddress']:
                    return network_info['IPAddress']
            return None
        except docker.errors.NotFound:
            print(f"Contenedor {container_name} no encontrado")
            return None
        except Exception as e:
            print(f"Error obteniendo IP de {container_name}: {e}")
            return None
    
    def wait_for_containers(self, container_names, max_attempts=30):
        """Espera a que los contenedores estén disponibles y tengan IP"""
        print("Esperando a que los contenedores estén listos...")
        
        for attempt in range(1, max_attempts + 1):
            all_ready = True
            container_ips = {}
            
            for container_name in container_names:
                ip = self.get_container_ip(container_name)
                if ip:
                    container_ips[container_name] = ip
                    print(f"  {container_name}: {ip}")
                else:
                    all_ready = False
                    print(f"  {container_name}: No disponible")
            
            if all_ready:
                print("Todos los contenedores están listos")
                return container_ips
            
            print(f"Intento {attempt}/{max_attempts} - Esperando...")
            time.sleep(2)
        
        print(f"Timeout: Los contenedores no están listos después de {max_attempts} intentos")
        return None
    
    def update_haproxy_config(self, container_ips):
        """Actualiza la configuración de HAProxy con las nuevas IPs"""
        if not os.path.exists(self.config_path):
            print(f"Error: Archivo de configuración no encontrado: {self.config_path}")
            return False
        
        try:
            # Leer la configuración actual
            with open(self.config_path, 'r') as f:
                config_content = f.read()
            
            # Hacer backup
            with open(self.backup_path, 'w') as f:
                f.write(config_content)
            print(f"Backup creado: {self.backup_path}")
            
            # Actualizar las IPs en la configuración
            updated_content = config_content
            
            for container_name, ip in container_ips.items():
                # Patrón para encontrar la línea del servidor
                pattern = rf'(\s*server\s+{container_name}\s+)[0-9.]+(:7001.*)'
                replacement = rf'\g<1>{ip}\g<2>'
                
                updated_content = re.sub(pattern, replacement, updated_content)
                print(f"Actualizada IP de {container_name} a {ip}")
            
            # Escribir la configuración actualizada
            with open(self.config_path, 'w') as f:
                f.write(updated_content)
            
            print("Configuración de HAProxy actualizada")
            return True
            
        except Exception as e:
            print(f"Error actualizando configuración: {e}")
            return False
    
    def reload_haproxy(self):
        """Recarga la configuración de HAProxy"""
        try:
            haproxy_container = self.client.containers.get('haproxy')
            
            # Obtener el PID actual de HAProxy
            try:
                result = haproxy_container.exec_run('cat /var/run/haproxy.pid')
                if result.exit_code == 0:
                    old_pid = result.output.decode().strip()
                else:
                    old_pid = ""
            except:
                old_pid = ""
            
            # Recargar HAProxy con graceful restart
            reload_cmd = f'haproxy -f {self.config_path} -p /var/run/haproxy.pid'
            if old_pid:
                reload_cmd += f' -sf {old_pid}'
            
            result = haproxy_container.exec_run(reload_cmd)
            
            if result.exit_code == 0:
                print("HAProxy recargado exitosamente")
                return True
            else:
                print(f"Error recargando HAProxy: {result.output.decode()}")
                return False
                
        except docker.errors.NotFound:
            print("Contenedor HAProxy no encontrado")
            return False
        except Exception as e:
            print(f"Error recargando HAProxy: {e}")
            return False
    
    def run(self):
        """Ejecuta el proceso completo de actualización"""
        print("=== Iniciando actualización automática de HAProxy ===")
        
        # Contenedores a monitorear
        containers = ['weblogic-a', 'weblogic-b']
        
        # Esperar a que los contenedores estén listos
        container_ips = self.wait_for_containers(containers)
        
        if not container_ips:
            print("Error: No se pudieron obtener las IPs de los contenedores")
            return False
        
        # Actualizar la configuración
        if not self.update_haproxy_config(container_ips):
            print("Error: No se pudo actualizar la configuración")
            return False
        
        # Recargar HAProxy
        if not self.reload_haproxy():
            print("Error: No se pudo recargar HAProxy")
            return False
        
        print("=== Actualización completada exitosamente ===")
        return True

def main():
    updater = HAProxyUpdater()
    
    # Ejecutar en modo continuo si se pasa el argumento --daemon
    if len(sys.argv) > 1 and sys.argv[1] == '--daemon':
        print("Ejecutando en modo daemon...")
        while True:
            try:
                updater.run()
                print("Esperando 60 segundos antes de la próxima verificación...")
                time.sleep(60)
            except KeyboardInterrupt:
                print("Deteniendo daemon...")
                break
            except Exception as e:
                print(f"Error en daemon: {e}")
                time.sleep(10)
    else:
        # Ejecutar una sola vez
        success = updater.run()
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
