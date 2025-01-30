local _logger = require("logging")
local _storage = require("storage")
local _core = require("core")
local params = ... or {}


-- Crear los módulos dinámicamente
local function createModule(suffix)
    local module = {}

    module.ACTUADORES_ON = _storage.get_table("settingActuadoresOn" .. suffix) or {}
    module.ACTUADORES_OFF = _storage.get_table("settingActuadoresOff" .. suffix) or {}
    module.MASTERSWITCH_ON = _storage.get_table("settingMasterSwitchOn" .. suffix) or {}
    module.SENSOR_MOV_BATT = _storage.get_table("settingSensorMovBatt" .. suffix) or {}
    module.SENSOR_MOV_ELEC = _storage.get_table("settingSensorMovElec" .. suffix) or {}
    module.TERMOSTATO = _storage.get_table("settingThermostat" .. suffix) or {}
    module.SETPOINTON = _storage.get_table("settingSetPointON" .. suffix) or {}
    module.MODODISPLUCES = _storage.get_table("settingAuxiliarluces" .. suffix) or {}
    module.MODOMASTERSWITCH = _storage.get_table("settingModoMasterSwitch" .. suffix) or {}
    module.MOTIONACTIVATOR = _storage.get_table("settingEncendidoThermostat" .. suffix) or {}
    module.TIEMPOSCAN = _storage.get_table("settingTiempoMovimiento" .. suffix) or {}
    -- module.SENSOR_PUERTA = _storage.get_table("settingSensorPuerta" .. suffix) or {}
    -- module.OFFPUERTAABIERTA = _storage.get_table("settingOffPuertaAbierta" .. suffix) or {}
    -- module.SETPOINTOFF = _storage.get_table("settingSetPointOFF" .. suffix) or {}
    -- module.MODOSETPOINT = _storage.get_table("settingModoSetPoint" .. suffix) or {}

    return module
end

-- Crear los módulos usando la función
local _M1 = createModule(1)
local _M2 = createModule(2)
local _M3 = createModule(3)
local _M4 = createModule(4)
local _M5 = createModule(5)
local _M6 = createModule(6)
local _M7 = createModule(7)
local _M8 = createModule(8)
local _M9 = createModule(9)
local _M10 = createModule(10)
local _M11 = createModule(11)
local _M12 = createModule(12)
local _M13 = createModule(13)
local _M14 = createModule(14)
local _M15 = createModule(15)
local _M16 = createModule(16)
local _M17 = createModule(17)
local _M18 = createModule(18)
local _M19 = createModule(19)
local _M20 = createModule(20)

-- Función para buscar el setting_id en los módulos
local function find_setting_module(setting_id)
    local function compare_and_find(module, setting_id)
        for key, setting_value in pairs(module) do
            if type(setting_value) == "table" then
                -- Para tablas, verificamos si el setting_id está en la lista
                for _, id in ipairs(setting_value) do
                    if tostring(id) == tostring(setting_id) then
                        return true, key
                    end
                end
            elseif tostring(setting_value) == tostring(setting_id) then
                -- Para valores simples
                return true, key
            end
        end
        return false
    end

    -- Buscar en ambos módulos
    local found, key

    found, key = compare_and_find(_M1, setting_id)
    if found then
        return "_M1", key
    end

    found, key = compare_and_find(_M2, setting_id)
    if found then
        return "_M2", key
    end

    found, key = compare_and_find(_M3, setting_id)
    if found then
        return "_M3", key
    end

    found, key = compare_and_find(_M4, setting_id)
    if found then
        return "_M4", key
    end

    found, key = compare_and_find(_M5, setting_id)
    if found then
        return "_M5", key
    end

    found, key = compare_and_find(_M6, setting_id)
    if found then
        return "_M6", key
    end

    found, key = compare_and_find(_M7, setting_id)
    if found then
        return "_M7", key
    end

    found, key = compare_and_find(_M8, setting_id)
    if found then
        return "_M8", key
    end

    found, key = compare_and_find(_M9, setting_id)
    if found then
        return "_M9", key
    end

    found, key = compare_and_find(_M10, setting_id)
    if found then
        return "_M10", key
    end

    found, key = compare_and_find(_M11, setting_id)
    if found then
        return "_M11", key
    end

    found, key = compare_and_find(_M12, setting_id)
    if found then
        return "_M12", key
    end

    found, key = compare_and_find(_M13, setting_id)
    if found then
        return "_M13", key
    end

    found, key = compare_and_find(_M14, setting_id)
    if found then
        return "_M14", key
    end

    found, key = compare_and_find(_M15, setting_id)
    if found then
        return "_M15", key
    end

    found, key = compare_and_find(_M16, setting_id)
    if found then
        return "_M16", key
    end

    found, key = compare_and_find(_M17, setting_id)
    if found then
        return "_M17", key
    end

    found, key = compare_and_find(_M18, setting_id)
    if found then
        return "_M18", key
    end

    found, key = compare_and_find(_M19, setting_id)
    if found then
        return "_M19", key
    end

    found, key = compare_and_find(_M20, setting_id)
    if found then
        return "_M20", key
    end

    return nil, "Setting ID not found in any module"
end

-- Procesar los valores del Params y actualiza los setting
if type(params) == "table" then
    local module_name, key = find_setting_module(params.setting_id)
    local setting_id = params.setting_id
    local value = params.value
    local setting = _core.get_setting(setting_id)        

    if not setting then
        _logger.warning("Setting with id " .. tostring(setting_id) .. " not found")
        return
    end

    -- Actualizar el setting en el core
    _core.set_setting_value(params.setting_id, value, "synced")

    if module_name then
        _logger.info("Setting ID " .. tostring(params.setting_id) .. " found in module: " .. module_name .. ", key: " .. key)
    else
        _logger.warning(key)
    end

    -- Se localiza la configuracion perteneciente y se actualizam las variables de las Habitaciones
    local setting_handlers = {
        ["Sensor Movimiento Batt"] = function()
            _storage.set_table("SENSOR_MOV_BATT"..module_name , value)
            _logger.info("SENSOR_MOV_BATT"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Sensor Movimiento Elec"] = function()
            _storage.set_table("SENSOR_MOV_ELEC"..module_name , value)
            _logger.info("SENSOR_MOV_ELEC"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Actuadores On"] = function()
            _storage.set_table("ACTUADORES_ON"..module_name , value)
            _logger.info("ACTUADORES_ON"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Actuadores Off"] = function()
            _storage.set_table("ACTUADORES_OFF"..module_name , value)
            _logger.info("ACTUADORES_OFF"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Master Switch"] = function()
            _storage.set_table("MASTERSWITCH_ON"..module_name , value)
            _logger.info("MASTERSWITCH_ON"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Thermostat"] = function()
            _storage.set_table("TERMOSTATO"..module_name , value)
            _logger.info("TERMOSTATO"..module_name  .. " with value: " .. tostring(value))
        end,
        ["Valor Set Point ON"] = function()
            _storage.set_table("SETPOINTON"..module_name , value)
            _logger.info("SETPOINTON"..module_name .. " with value: " .. tostring(value))
        end,
        ["Modo Encendido Thermostat"] = function()
            _storage.set_table("MOTIONACTIVATOR"..module_name , value)
            _logger.info("MOTIONACTIVATOR"..module_name .. " with value: " .. tostring(value))
        end,
        ["Modo Luces"] = function()
            _storage.set_table("MODODISPLUCES"..module_name , value)
            _logger.info("MODODISPLUCES"..module_name .. " with value: " .. tostring(value))
        end,
        ["Modo Master Switch"] = function()
            _storage.set_table("MODOMASTERSWITCH"..module_name , value)
            _logger.info("MODOMASTERSWITCH"..module_name .. " with value: " .. tostring(value))
        end,
        ["Valor Tiempo Movimiento"] = function()
            _storage.set_table("TIEMPOSCAN"..module_name , value)
            _logger.info("TIEMPOSCAN"..module_name .. " with value: " .. tostring(value))
        end
        -- ["Sensor Puerta"] = function()
        --     _storage.set_table("SENSOR_PUERTA".. module_name , value)
        --     _logger.info("SENSOR_PUERTA".. module_name .. " with value: " .. tostring(value))
        -- end,
        -- ["Valor Set Point OFF"] = function()
        --     _storage.set_table("SETPOINTOFF"..module_name , value)
        --     _logger.info("SETPOINTOFF"..module_name .. " with value: " .. tostring(value))
        -- end,
        -- ["Modo SetPoint"] = function()
        --     _storage.set_table("MODOSETPOINT"..module_name , value)
        --     _logger.info("MODOSETPOINT"..module_name .. " with value: " .. tostring(value))
        -- end,
        -- ["Modo Off Puerta Abierta"] = function()
        --     _storage.set_table("OFFPUERTAABIERTA"..module_name , value)
        --     _logger.info("OFFPUERTAABIERTA"..module_name .. " with value: " .. tostring(value))
        -- end,
    }
    if setting_handlers[setting.label.text] then
        setting_handlers[setting.label.text]()
        _logger.info(setting.label.text.." ".. tostring(value))
    else
        _logger.warning("Unknown setting: " .. setting.label.text)
    end

else
    _logger.warning("Expected params to be a table, but received: " .. tostring(params))
end
