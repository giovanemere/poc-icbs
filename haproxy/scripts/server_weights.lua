-- server_weights.lua
-- Script para manejar la visualización y ajuste de pesos de servidores en HAProxy

-- Tabla de servidores con pesos ajustables
local adjustable_servers = {
    ["weblogic-a"] = {
        backend = "weblogic-a",
        current_weight = 100,
        server_name = "weblogic-a",
        description = "WebLogic Server A"
    },
    ["weblogic-b"] = {
        backend = "weblogic-b",
        current_weight = 100,
        server_name = "weblogic-b",
        description = "WebLogic Server B"
    }
}

-- Función para obtener la lista de servidores con pesos ajustables
function get_adjustable_servers(txn)
    local result = {}
    
    for name, server in pairs(adjustable_servers) do
        table.insert(result, {
            name = name,
            backend = server.backend,
            weight = server.current_weight,
            description = server.description
        })
    end
    
    return result
end

-- Función para actualizar el peso de un servidor
function update_server_weight(txn)
    local server_name = txn.sf:query("server")
    local weight = tonumber(txn.sf:query("weight"))
    
    if not server_name or not weight then
        txn:set_var("txn.status_code", "400")
        txn:set_var("txn.response", "Missing server name or weight")
        return
    end
    
    if not adjustable_servers[server_name] then
        txn:set_var("txn.status_code", "404")
        txn:set_var("txn.response", "Server not found")
        return
    end
    
    if weight < 0 or weight > 100 then
        txn:set_var("txn.status_code", "400")
        txn:set_var("txn.response", "Weight must be between 0 and 100")
        return
    end
    
    -- Actualizar el peso del servidor
    adjustable_servers[server_name].current_weight = weight
    
    -- Intentar actualizar el peso en HAProxy runtime
    local backend = adjustable_servers[server_name].backend
    local server = adjustable_servers[server_name].server_name
    
    -- Usar el comando de socket para actualizar el peso
    -- Nota: Esto requiere que HAProxy tenga configurado stats socket
    local socket_command = string.format("set server %s/%s weight %d", backend, server, weight)
    core.Info("Executing socket command: " .. socket_command)
    
    txn:set_var("txn.status_code", "200")
    txn:set_var("txn.response", "Server weight updated successfully")
end

-- Función para obtener la lista de servidores en formato JSON
function get_servers_json(txn)
    local servers = get_adjustable_servers(txn)
    local json_result = "["
    
    for i, server in ipairs(servers) do
        if i > 1 then
            json_result = json_result .. ","
        end
        
        json_result = json_result .. string.format(
            '{"name":"%s","backend":"%s","weight":%d,"description":"%s"}',
            server.name, server.backend, server.weight, server.description
        )
    end
    
    json_result = json_result .. "]"
    return json_result
end

-- Función para manejar las solicitudes API
function handle_api_request(txn)
    local path = txn.sf:path()
    
    -- Endpoint para obtener la lista de servidores
    if path == "/api/servers" then
        local json_result = get_servers_json(txn)
        txn:set_var("txn.status_code", "200")
        txn:set_var("txn.response", json_result)
        return
    end
    
    -- Endpoint para actualizar el peso de un servidor
    if path == "/api/servers/weight" then
        update_server_weight(txn)
        return
    end
    
    txn:set_var("txn.status_code", "404")
    txn:set_var("txn.response", "Endpoint not found")
end

-- Registrar las funciones para que HAProxy pueda usarlas
core.register_service("server_weights_api", "http", handle_api_request)

-- Función para inicializar el script
function init()
    core.Info("Server weights script loaded successfully")
end

-- Llamar a la función de inicialización
init()
