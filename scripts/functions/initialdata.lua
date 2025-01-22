local _core = require("core")
local _logger = require("logging")
local _storage = require("storage")
-- Obtener el valor inicial de "numberPlugin" desde el almacenamiento
local numberPlugin = _storage.get_number("numberPlugin") or 0
local varInicialModo = _storage.get_string("ModoId")
_logger.info("Valor de varInicialModo: "..tostring(varInicialModo))

local function ValorModo(claveBase)
    local valItem = tostring(claveBase .. numberPlugin)
    if not _storage.exists(valItem) then
        local defaultMode = "Auto"
        _logger.info("No se encontró el valor de '" .. claveBase)
        return defaultMode
    else
        local defaultMode = tostring(_storage.get_string(valItem))
        _logger.info("Se encuentra el valor de: " .. valItem .. ": " .. defaultMode)
        return defaultMode
    end
end

-- Lista de configuraciones para iterar|
local settings = {
    "Modo",
    "Type",
    "Counting",
    "dueTimestamp",
    "remaining",
    "TimerDuration",
    "statusText",
    "accionTexto",
    "accion",
    "timerAccion",
    "ScanCycle",
    "TimerID",
    "TimerIdTick",
    "Remaining_ant",
    "previousTimer",
}

-- Inicialización de configuraciones en el almacenamiento
for _, setting in ipairs(settings) do
    local key = setting .. numberPlugin
    _logger.info("Configurando Variable clave: " .. key)

    if setting == "dueTimestamp" or setting == "accion" or setting == "TimerDuration" or setting == "Remaining_ant" or setting == "previousTimer" then
        _storage.set_number(key, 0)       -- Valores numéricos iniciales
    elseif setting == "remaining" or setting == "Counting" or setting == "timerAccion" then
        _storage.set_string(key, "0")     -- Valores de cadena numérica
    elseif setting == "statusText" then
        _storage.set_string(key, "Libre") -- Texto predeterminado
    elseif setting == "Modo" then
        local defaultMode = ValorModo("Modo") -- cambiar
        _storage.set_string(key, defaultMode)
        _logger.info("Var. Clave 'Mode'"..numberPlugin.." no encontrada. Se estableció el valor predeterminado: " .. defaultMode)  
    elseif setting == "Type" then
        _storage.set_string(key, "Aula") -- Configuración inicial del tipo
    else
        _storage.set_string(key, "")      -- Valor predeterminado para otros
    end
end
