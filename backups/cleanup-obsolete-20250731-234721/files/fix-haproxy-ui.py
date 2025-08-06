#!/usr/bin/env python3
"""
Script para corregir la interfaz web de HAProxy y centralizar la actualización de tablas.
Este script actualiza los templates para mostrar correctamente el estado de los servidores.
"""

import os
import json

def fix_index_template():
    """Corregir el template index.html para mostrar correctamente los estados."""
    
    template_content = '''{% extends "layout.html" %}

{% block title %}Dashboard{% endblock %}

{% block content %}
<div class="row mb-4">
    <div class="col-md-6 col-lg-3 mb-4">
        <div class="card card-dashboard h-100 border-left-primary shadow">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">
                            Testing A/B
                        </div>
                        <div class="h5 mb-0 font-weight-bold text-gray-800">
                            {% if config.ab_testing and config.ab_testing.enabled %}
                                <span class="badge bg-success">Activo</span>
                                <div class="mt-2">
                                    <div class="progress">
                                        <div class="progress-bar bg-primary" role="progressbar" style="width: {{ config.ab_testing.weight_a }}%"
                                            aria-valuenow="{{ config.ab_testing.weight_a }}" aria-valuemin="0" aria-valuemax="100">
                                            A: {{ config.ab_testing.weight_a }}%
                                        </div>
                                        <div class="progress-bar bg-secondary" role="progressbar" style="width: {{ 100 - config.ab_testing.weight_a }}%"
                                            aria-valuenow="{{ 100 - config.ab_testing.weight_a }}" aria-valuemin="0" aria-valuemax="100">
                                            B: {{ 100 - config.ab_testing.weight_a }}%
                                        </div>
                                    </div>
                                </div>
                            {% else %}
                                <span class="badge bg-secondary">Inactivo</span>
                            {% endif %}
                        </div>
                    </div>
                    <div class="col-auto">
                        <i class="bi bi-diagram-3 fa-2x text-gray-300" style="font-size: 2rem;"></i>
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <a href="{{ url_for('ab_testing') }}" class="btn btn-sm btn-primary">Configurar</a>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-lg-3 mb-4">
        <div class="card card-dashboard h-100 border-left-success shadow">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="text-xs font-weight-bold text-success text-uppercase mb-1">
                            Canary Deployment
                        </div>
                        <div class="h5 mb-0 font-weight-bold text-gray-800">
                            {% if config.canary and config.canary.enabled %}
                                <span class="badge bg-success">Activo</span>
                                <div class="mt-2">
                                    <div class="progress">
                                        <div class="progress-bar bg-warning" role="progressbar" style="width: {{ config.canary.percentage }}%"
                                            aria-valuenow="{{ config.canary.percentage }}" aria-valuemin="0" aria-valuemax="100">
                                            Canary: {{ config.canary.percentage }}%
                                        </div>
                                        <div class="progress-bar bg-info" role="progressbar" style="width: {{ 100 - config.canary.percentage }}%"
                                            aria-valuenow="{{ 100 - config.canary.percentage }}" aria-valuemin="0" aria-valuemax="100">
                                            Estable: {{ 100 - config.canary.percentage }}%
                                        </div>
                                    </div>
                                </div>
                            {% else %}
                                <span class="badge bg-secondary">Inactivo</span>
                            {% endif %}
                        </div>
                    </div>
                    <div class="col-auto">
                        <i class="bi bi-send fa-2x text-gray-300" style="font-size: 2rem;"></i>
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <a href="{{ url_for('canary') }}" class="btn btn-sm btn-success">Configurar</a>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-lg-3 mb-4">
        <div class="card card-dashboard h-100 border-left-info shadow">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="text-xs font-weight-bold text-info text-uppercase mb-1">
                            WebLogic A
                        </div>
                        <div class="h5 mb-0 font-weight-bold text-gray-800">
                            {% if stats and 'weblogic-a' in stats and 'weblogic-a' in stats['weblogic-a'] and stats['weblogic-a']['weblogic-a']['status'] == 'UP' %}
                                <span class="badge bg-success">Activo</span>
                            {% else %}
                                <span class="badge bg-danger">Inactivo</span>
                            {% endif %}
                            <div class="small mt-2">
                                <div>Conexiones: {{ stats['weblogic-a']['weblogic-a']['active'] if stats and 'weblogic-a' in stats and 'weblogic-a' in stats['weblogic-a'] else 'N/A' }}</div>
                                <div>Peso: {{ stats['weblogic-a']['weblogic-a']['weight'] if stats and 'weblogic-a' in stats and 'weblogic-a' in stats['weblogic-a'] else 'N/A' }}</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-auto">
                        <i class="bi bi-server fa-2x text-gray-300" style="font-size: 2rem;"></i>
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <a href="http://localhost:7001/console" target="_blank" class="btn btn-sm btn-info">Consola</a>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-lg-3 mb-4">
        <div class="card card-dashboard h-100 border-left-warning shadow">
            <div class="card-body">
                <div class="row no-gutters align-items-center">
                    <div class="col mr-2">
                        <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">
                            WebLogic B
                        </div>
                        <div class="h5 mb-0 font-weight-bold text-gray-800">
                            {% if stats and 'weblogic-b' in stats and 'weblogic-b' in stats['weblogic-b'] and stats['weblogic-b']['weblogic-b']['status'] == 'UP' %}
                                <span class="badge bg-success">Activo</span>
                            {% else %}
                                <span class="badge bg-danger">Inactivo</span>
                            {% endif %}
                            <div class="small mt-2">
                                <div>Conexiones: {{ stats['weblogic-b']['weblogic-b']['active'] if stats and 'weblogic-b' in stats and 'weblogic-b' in stats['weblogic-b'] else 'N/A' }}</div>
                                <div>Peso: {{ stats['weblogic-b']['weblogic-b']['weight'] if stats and 'weblogic-b' in stats and 'weblogic-b' in stats['weblogic-b'] else 'N/A' }}</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-auto">
                        <i class="bi bi-server fa-2x text-gray-300" style="font-size: 2rem;"></i>
                    </div>
                </div>
            </div>
            <div class="card-footer">
                <a href="http://localhost:7002/console" target="_blank" class="btn btn-sm btn-warning">Consola</a>
            </div>
        </div>
    </div>
</div>

<!-- Tabla de Servidores Actuales -->
<div class="row">
    <div class="col-lg-8">
        <div class="card shadow mb-4">
            <div class="card-header py-3 d-flex flex-row align-items-center justify-content-between">
                <h6 class="m-0 font-weight-bold text-primary">Estado de Servidores</h6>
                <button class="btn btn-sm btn-primary" onclick="refreshServerTable()">
                    <i class="bi bi-arrow-clockwise"></i> Actualizar
                </button>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-bordered table-sm" id="servers-table">
                        <thead>
                            <tr>
                                <th>Backend</th>
                                <th>Servidor</th>
                                <th>Estado</th>
                                <th>Peso</th>
                                <th>Conexiones</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody id="servers-table-body">
                            {% for backend_name, servers in stats.items() %}
                                {% for server_name, server_data in servers.items() %}
                                    {% if server_name != 'BACKEND' %}
                                    <tr>
                                        <td>{{ backend_name }}</td>
                                        <td>{{ server_name }}</td>
                                        <td>
                                            {% if server_data['status'] == 'UP' %}
                                                <span class="status-indicator status-up"></span>
                                                <span class="badge bg-success">UP</span>
                                            {% else %}
                                                <span class="status-indicator status-down"></span>
                                                <span class="badge bg-danger">DOWN</span>
                                            {% endif %}
                                        </td>
                                        <td>{{ server_data['weight'] }}</td>
                                        <td>{{ server_data['active'] }}</td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-primary" onclick="editServerWeight('{{ backend_name }}', '{{ server_name }}', {{ server_data['weight'] }})">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                        </td>
                                    </tr>
                                    {% endif %}
                                {% endfor %}
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-lg-4">
        <div class="card shadow mb-4">
            <div class="card-header py-3">
                <h6 class="m-0 font-weight-bold text-primary">Enlaces Rápidos</h6>
            </div>
            <div class="card-body">
                <div class="list-group">
                    <a href="{{ url_for('ab_testing') }}" class="list-group-item list-group-item-action">
                        <i class="bi bi-diagram-3"></i> Configurar A/B Testing
                    </a>
                    <a href="{{ url_for('canary') }}" class="list-group-item list-group-item-action">
                        <i class="bi bi-send"></i> Configurar Canary Deployment
                    </a>
                    <a href="{{ url_for('server_weight') }}" class="list-group-item list-group-item-action">
                        <i class="bi bi-sliders"></i> Configurar Pesos de Servidores
                    </a>
                    <a href="{{ url_for('url_status') }}" class="list-group-item list-group-item-action">
                        <i class="bi bi-activity"></i> Estado de URLs
                    </a>
                    <a href="http://localhost:8404/stats" target="_blank" class="list-group-item list-group-item-action">
                        <i class="bi bi-bar-chart"></i> HAProxy Stats Nativo
                    </a>
                </div>
            </div>
        </div>
        
        <div class="card shadow mb-4">
            <div class="card-header py-3">
                <h6 class="m-0 font-weight-bold text-primary">Información del Sistema</h6>
            </div>
            <div class="card-body">
                <div class="small">
                    <div><strong>Última actualización:</strong> <span id="last-update">{{ moment().format('YYYY-MM-DD HH:mm:ss') }}</span></div>
                    <div><strong>Total de backends:</strong> {{ stats|length if stats else 0 }}</div>
                    <div><strong>Servidores activos:</strong> <span id="active-servers">0</span></div>
                    <div><strong>Servidores inactivos:</strong> <span id="inactive-servers">0</span></div>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}

{% block scripts %}
<script>
// Función para actualizar la tabla de servidores
function refreshServerTable() {
    fetch('/api/servers-status')
        .then(response => response.json())
        .then(data => {
            updateServerTable(data);
            document.getElementById('last-update').textContent = new Date().toLocaleString();
        })
        .catch(error => {
            console.error('Error al actualizar la tabla:', error);
        });
}

// Función para actualizar la tabla con nuevos datos
function updateServerTable(stats) {
    const tbody = document.getElementById('servers-table-body');
    tbody.innerHTML = '';
    
    let activeCount = 0;
    let inactiveCount = 0;
    
    for (const [backendName, servers] of Object.entries(stats)) {
        for (const [serverName, serverData] of Object.entries(servers)) {
            if (serverName !== 'BACKEND') {
                const row = document.createElement('tr');
                const isUp = serverData.status === 'UP';
                
                if (isUp) activeCount++;
                else inactiveCount++;
                
                row.innerHTML = `
                    <td>${backendName}</td>
                    <td>${serverName}</td>
                    <td>
                        <span class="status-indicator ${isUp ? 'status-up' : 'status-down'}"></span>
                        <span class="badge ${isUp ? 'bg-success' : 'bg-danger'}">${serverData.status}</span>
                    </td>
                    <td>${serverData.weight}</td>
                    <td>${serverData.active}</td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary" onclick="editServerWeight('${backendName}', '${serverName}', ${serverData.weight})">
                            <i class="bi bi-pencil"></i>
                        </button>
                    </td>
                `;
                tbody.appendChild(row);
            }
        }
    }
    
    // Actualizar contadores
    document.getElementById('active-servers').textContent = activeCount;
    document.getElementById('inactive-servers').textContent = inactiveCount;
}

// Función para editar el peso de un servidor
function editServerWeight(backend, server, currentWeight) {
    const newWeight = prompt(`Nuevo peso para ${server} en ${backend}:`, currentWeight);
    if (newWeight !== null && !isNaN(newWeight)) {
        const weight = parseInt(newWeight);
        if (weight >= 0 && weight <= 256) {
            updateServerWeight(backend, server, weight);
        } else {
            alert('El peso debe estar entre 0 y 256');
        }
    }
}

// Función para actualizar el peso de un servidor
function updateServerWeight(backend, server, weight) {
    fetch('/api/servers/weight', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            backend: backend,
            server: server,
            weight: weight
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            alert('Peso actualizado correctamente');
            refreshServerTable();
        } else {
            alert('Error al actualizar el peso: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error al actualizar el peso del servidor');
    });
}

// Actualizar automáticamente cada 30 segundos
setInterval(refreshServerTable, 30000);

// Actualizar contadores al cargar la página
document.addEventListener('DOMContentLoaded', function() {
    let activeCount = 0;
    let inactiveCount = 0;
    
    document.querySelectorAll('#servers-table-body tr').forEach(row => {
        const statusBadge = row.querySelector('.badge');
        if (statusBadge && statusBadge.textContent === 'UP') {
            activeCount++;
        } else {
            inactiveCount++;
        }
    });
    
    document.getElementById('active-servers').textContent = activeCount;
    document.getElementById('inactive-servers').textContent = inactiveCount;
});
</script>
{% endblock %}
'''
    
    return template_content

def main():
    """Función principal para aplicar las correcciones."""
    print("🔧 Corrigiendo interfaz web de HAProxy...")
    
    # Crear el contenido del template corregido
    template_content = fix_index_template()
    
    # Escribir el archivo
    with open('/tmp/index_fixed.html', 'w') as f:
        f.write(template_content)
    
    print("✅ Template corregido creado en /tmp/index_fixed.html")
    print("\nPara aplicar los cambios:")
    print("1. docker cp /tmp/index_fixed.html haproxy:/etc/haproxy/templates/index.html")
    print("2. docker restart haproxy")
    
    return True

if __name__ == "__main__":
    main()
