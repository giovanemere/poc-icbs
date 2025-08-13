-- dynamic_routing.lua
-- Script para manejar el enrutamiento dinámico en HAProxy

-- Configuración inicial
local config = {
    -- Configuración para A/B testing
    ab_testing = {
        enabled = true,
        cookie_name = "ab_test",
        version_a_weight = 50,  -- 50% para versión A
        version_b_weight = 50   -- 50% para versión B
    },
    
    -- Configuración para Canary deployment
    canary = {
        enabled = true,
        cookie_name = "canary",
        header_name = "X-Canary",
        percentage = 20  -- 20% del tráfico va a la versión canary
    }
}

-- Función para determinar si un usuario debe ir a la versión B (canary/nueva)
function should_route_to_b(txn)
    -- Si el A/B testing está deshabilitado, siempre usar versión A
    if not config.ab_testing.enabled and not config.canary.enabled then
        return false
    end
    
    -- Verificar si el usuario ya tiene una cookie de A/B testing
    local ab_cookie = txn.f:req_cookie(config.ab_testing.cookie_name)
    if ab_cookie then
        return ab_cookie == "B"
    end
    
    -- Verificar si el usuario tiene el header de canary
    local canary_header = txn.f:req_hdr(config.canary.header_name)
    if canary_header and canary_header:lower() == "true" then
        return true
    end
    
    -- Verificar si el usuario tiene una cookie de canary
    local canary_cookie = txn.f:req_cookie(config.canary.cookie_name)
    if canary_cookie and canary_cookie:lower() == "true" then
        return true
    end
    
    -- Aplicar porcentaje de canary
    if config.canary.enabled then
        local random_value = math.random(100)
        if random_value <= config.canary.percentage then
            return true
        end
    end
    
    -- Aplicar porcentaje de A/B testing
    if config.ab_testing.enabled then
        local random_value = math.random(100)
        if random_value <= config.ab_testing.version_b_weight then
            return true
        end
    end
    
    -- Por defecto, usar versión A
    return false
end

-- Función para actualizar la configuración dinámicamente
function update_config(txn)
    local path = txn.sf:path()
    
    -- Endpoint para actualizar la configuración de A/B testing
    if path == "/api/config/ab" then
        local enabled = txn.sf:query("enabled")
        local weight_a = tonumber(txn.sf:query("weight_a"))
        local weight_b = tonumber(txn.sf:query("weight_b"))
        
        if enabled then
            config.ab_testing.enabled = (enabled:lower() == "true")
        end
        
        if weight_a and weight_a >= 0 and weight_a <= 100 then
            config.ab_testing.version_a_weight = weight_a
            config.ab_testing.version_b_weight = 100 - weight_a
        end
        
        txn:set_var("txn.status_code", "200")
        txn:set_var("txn.response", "A/B testing configuration updated")
        return
    end
    
    -- Endpoint para actualizar la configuración de Canary
    if path == "/api/config/canary" then
        local enabled = txn.sf:query("enabled")
        local percentage = tonumber(txn.sf:query("percentage"))
        
        if enabled then
            config.canary.enabled = (enabled:lower() == "true")
        end
        
        if percentage and percentage >= 0 and percentage <= 100 then
            config.canary.percentage = percentage
        end
        
        txn:set_var("txn.status_code", "200")
        txn:set_var("txn.response", "Canary configuration updated")
        return
    end
    
    -- Endpoint para obtener la configuración actual
    if path == "/api/config" then
        local response = {
            ab_testing = {
                enabled = config.ab_testing.enabled,
                version_a_weight = config.ab_testing.version_a_weight,
                version_b_weight = config.ab_testing.version_b_weight
            },
            canary = {
                enabled = config.canary.enabled,
                percentage = config.canary.percentage
            }
        }
        
        txn:set_var("txn.status_code", "200")
        txn:set_var("txn.response", json.encode(response))
        return
    end
    
    txn:set_var("txn.status_code", "404")
    txn:set_var("txn.response", "Endpoint not found")
end

-- Registrar las funciones para que HAProxy pueda usarlas
core.register_action("route_to_b", {"http-req"}, should_route_to_b)
core.register_service("update_config", "http", update_config)

-- Función para inicializar el script
function init()
    math.randomseed(os.time())
    core.Info("Dynamic routing script loaded successfully")
end

-- Llamar a la función de inicialización
init()
