-- modificada para interpretación y seguirdad -- Jpovea
local _logger = require("logging")
local _storage = require("storage")
local _json = require("json")
local _core = require("core")
local _timer = require("timer")
local params = ... or {}

local function numeroPlugin()
    local my_gateway_id = (_core.get_gateway() or {}).id
    if not my_gateway_id then
        _logger.error("Failed to get current gateway ID, skip creating devices")
        return nil
    end
    for _, device in pairs(_core.get_devices() or {}) do
        if device.gateway_id == my_gateway_id then 
            if device.name == "Aula inteligente" then
                _logger.info("existe Aula inteligente: " .. _storage.get_number("numberPlugin"))
                return
            end
        end
    end
end

local _constants = require("HUB:aul.aula_inteligente/configs/constants")

_logger.info("<<<Aula inteligente starting up...>>>")
_G.constants = _constants or {}
local CREDENTIALS = _storage.get_string("CREDENTIALS")
 
if not _json then
    _timer.set_timeout(20000, "HUB:aul.aula_inteligente/scripts/startup", { arg_name = "arg_value" })
    _logger.info("failt start up, call delay...")
else
    -- Estas son las representaciones del load de las constantes
    --_logger.info("params: " .. _json.encode(params))
    --_logger.info("_constants: " .. _json.encode(_constants))
    _logger.info("params: Ok")
    _logger.info("_constrants: Ok")
    if CREDENTIALS == _G.constants.CREDENTIALS then
        local numberPlugin = _storage.get_number("numberPlugin")
        _G.constants.OFFPUERTAABIERTA = _storage.get_string("OFFPUERTAABIERTA_M"..tostring(numberPlugin))
        _G.constants.MODODISPLUCES = _storage.get_string("MODODISPLUCES_M"..tostring(numberPlugin))
        _G.constants.MODOMASTERSWITCH = _storage.get_string("MODOMASTERSWITCH_M"..tostring(numberPlugin))
        _G.constants.MOTIONACTIVATOR = _storage.get_string("MOTIONACTIVATOR_M"..tostring(numberPlugin))
        _G.constants.SENSOR_PUERTA = _storage.get_string("SENSOR_PUERTA_M"..tostring(numberPlugin))
        _G.constants.MASTERSWITCH_ON = _storage.get_table("MASTERSWITCH_ON_M"..tostring(numberPlugin))
        _G.constants.ACTUADORES_ON = _storage.get_table("ACTUADORES_ON_M"..tostring(numberPlugin))
        _G.constants.ACTUADORES_OFF = _storage.get_table("ACTUADORES_OFF_M"..tostring(numberPlugin))
        _G.constants.SENSOR_MOV_BATT = _storage.get_table("SENSOR_MOV_BATT_M"..tostring(numberPlugin))
        _G.constants.SENSOR_MOV_ELEC = _storage.get_table("SENSOR_MOV_ELEC_M"..tostring(numberPlugin))
        _G.constants.TERMOSTATO = _storage.get_table("TERMOSTATO_M"..tostring(numberPlugin))
        _G.constants.SETPOINTON = _storage.get_number("SETPOINTON_M"..tostring(numberPlugin))
        _G.constants.SETPOINTOFF = _storage.get_number("SETPOINTOFF_M"..tostring(numberPlugin))
        _G.constants.MODOSETPOINT = _storage.get_string("MODOSETPOINT_M"..tostring(numberPlugin))
        _G.constants.TIEMPOSCAN = _storage.get_number("TIEMPOSCAN_M"..tostring(numberPlugin))
        
        loadfile("HUB:aul.aula_inteligente/scripts/functions/initialdata")()
        loadfile("HUB:aul.aula_inteligente/scripts/functions/element")()
        loadfile("HUB:aul.aula_inteligente/scripts/functions/SubscribeRoom")()
        numeroPlugin()
    else
        _logger.info("no cargado los item ID  -- Favor ingresarlos")
    end
end