local _logger = require "logging"
local _json = require "json"
local _storage = require "storage"
local _core = require "core"
local args = ... or {}
local STORAGE_ACCOUNT_KEY = _G.constants.STORAGE_ACCOUNT_KEY
local numberPlugin = 0
local account_credentials = {}
local inputs_data = {}

_logger.info(">>> Iniciando configuración del plugin de ocupación... <<<")

local function Registro(message)
    _logger.info("[ Horus Smart Energy ] " .. message)
end


--- Auxiliar functions
local function Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


local function store_data(key_prefix, data_key, value, is_number)
    if value and value ~= "" then
        if is_number then
            if type(value) == "number" or tonumber(value) then
                _storage.set_number(key_prefix..tostring(numberPlugin), tonumber(value))
                inputs_data[data_key] = tonumber(value)
            else
                _logger.warning("Expected a number for key " .. data_key .. ", but received: " .. tostring(value))
                return false
            end
        else
            if type(value) == "string" then
                _storage.set_string(key_prefix..tostring(numberPlugin), value)
                inputs_data[data_key] = value
            elseif type(value) == "boolean" then
                _storage.set_bool(key_prefix..tostring(numberPlugin), value)
                inputs_data[data_key] = value
            else
                _logger.warning("Expected boolean o String for key " .. data_key .. ", but received: " .. tostring(value))
                return false 
            end
        end
    else
        inputs_data[data_key] = nil
    end
    return true
end

--- Function for processing multiple Item_id by thermostat
local function process_device_ids(device_ids) -- Original
    local thermostat = {}
    for _, device_id in ipairs(device_ids) do
        local items = _core.get_items_by_device_id(device_id)
        if items then
            for _, item in ipairs(items) do
                if item.name == "thermostat_setpoint_cooling" then
                    thermostat.setpoint = {
                        _id = item.id,
                        name = item.name,
                        value = item.value
                    }
                elseif item.name == "thermostat_mode" then
                    thermostat.mode = {
                        name = item.name,
                        _id = item.id,
                        value = item.value
                    }
                elseif item.name == "thermostat_fan_state" then
                    thermostat.fanState = {
                        name = item.name,
                        _id = item.id,
                        value = item.value
                    }
                elseif item.name == "thermostat_fan_mode" then
                    thermostat.fanMode = {
                        name = item.name,
                        _id = item.id
                    }
                elseif item.name == "thermostat_operating_state" then
                    thermostat.operatingState = {
                        name = item.name,
                        _id = item.id
                    }
                elseif item.name == "temp" then
                    thermostat.temp = {
                        name = item.name,
                        _id = item.id
                    }
                end
            end
        end
    end
    return thermostat
end

--- Autentication Process
if type(args.password) == "string" and args.password ~= "" then
    account_credentials.password = args.password
end

if account_credentials.password == _G.constants.DEFAULT_PASSWORD then
    ---- Send message
    _logger.info("Logged in successfully…")
    _core.send_ui_broadcast { status = 'success',message = '"Logged in successfully'}
    _storage.set_table(STORAGE_ACCOUNT_KEY, account_credentials)
    _storage.set_string("CREDENTIALS", "true")
    Registro("load successfully completed")
    
	---- Plugin Init
    numberPlugin = (_storage.get_number("numberPlugin") or 0) + 1
    _storage.set_number("numberPlugin", numberPlugin)
        
    --- Data storage
    if args.TiempoScan then
        inputs_data.TiempoScan = args.TiempoScan
        store_data("TIEMPOSCAN_M", "TiempoScan", args.TiempoScan, true)
    else
        inputs_data.TiempoScan = _G.constants.TIEMPOSCAN
        store_data("TIEMPOSCAN_M", "TiempoScan", _G.constants.TIEMPOSCAN, true)
    end
    if args.SetpointOn then
        inputs_data.SetpointOn = args.SetpointOn
        store_data("SETPOINTON_M", "SetpointOn", args.SetpointOn, true)
    else
        inputs_data.SetpointOn = _G.constants.SETPOINTON
        store_data("SETPOINTON_M", "SetpointOn", _G.constants.SETPOINTON, true)
    end
    if args.SetpointOff then
        inputs_data.SetpointOff = args.SetpointOff
        store_data("SETPOINTOFF_M", "SetpointOff", args.SetpointOff, true)
    else
        inputs_data.SetpointOff = _G.constants.SETPOINTOFF
        store_data("SETPOINTOFF_M", "SetpointOff", _G.constants.SETPOINTOFF, true)
    end
    if args.ModoSetpoint then
        inputs_data.ModoSetpoint = args.ModoSetpoint
        store_data("MODOSETPOINT_M", "ModoSetpoint", args.ModoSetpoint, false)
    else
        inputs_data.ModoSetpoint = _G.constants.MODOSETPOINT
        store_data("MODOSETPOINT_M", "ModoSetpoint", _G.constants.MODOSETPOINT, false)
    end
    if args.offPuertaAbierta then
        inputs_data.offPuertaAbierta = args.offPuertaAbierta
        store_data("OFFPUERTAABIERTA_M", "offPuertaAbierta", args.offPuertaAbierta, false)
    else
        inputs_data.offPuertaAbierta = _G.constants.OFFPUERTAABIERTA
        store_data("OFFPUERTAABIERTA_M", "offPuertaAbierta", _G.constants.OFFPUERTAABIERTA, false)
    end
    if args.ModoDispLuces then
        inputs_data.ModoDispLuces = args.ModoDispLuces
        store_data("MODODISPLUCES_M", "ModoDispLuces", args.ModoDispLuces, false)
    else
        inputs_data.ModoDispLuces = _G.constants.MODODISPLUCES
        store_data("MODODISPLUCES_M", "ModoDispLuces", _G.constants.MODODISPLUCES, false)
    end
    if args.ModoMasterSwitch then
        inputs_data.ModoMasterSwitch = args.ModoMasterSwitch
        store_data("MODOMASTERSWITCH_M", "ModoMasterSwitch", args.ModoMasterSwitch, false)
    else
        inputs_data.ModoMasterSwitch = _G.constants.MODOMASTERSWITCH
        store_data("MODOMASTERSWITCH_M", "ModoMasterSwitch", _G.constants.MODOMASTERSWITCH, false)
    end
    if args.motionActivator then
        inputs_data.motionActivator = args.motionActivator
        store_data("MOTIONACTIVATOR_M", "motionActivator", args.motionActivator, false)
    else
        inputs_data.motionActivator = _G.constants.MOTIONACTIVATOR
        store_data("MOTIONACTIVATOR_M", "motionActivator", _G.constants.MOTIONACTIVATOR, false)
    end
    if args.sensor_puerta then
        store_data("SENSOR_PUERTA_M", "sensorpuerta", args.sensor_puerta, false)
        inputs_data.sensorpuerta = Split(args.sensor_puerta, ",")
    else
        inputs_data.sensorpuerta = nil
    end
    if args.sensor_movbatt then
        store_data("sensorMovBatt", "sensormovbatt", args.sensor_movbatt, false)
        inputs_data.sensormovbatt = Split(args.sensor_movbatt, ",")
    else
        inputs_data.sensormovbatt = nil
    end
    if args.sensor_movelec then
        store_data("sensorMovElec", "sensormovelec", args.sensor_movelec, false)
        inputs_data.sensormovelec = Split(args.sensor_movelec, ",")
    else
        inputs_data.sensormovelec = nil
    end
    if args.actuadores_on then
        store_data("ACTUADORES_ON_M", "actuadoreson", args.actuadores_on, false)
        inputs_data.actuadoreson = Split(args.actuadores_on, ",")
    else
        inputs_data.actuadoreson = nil
    end
    if args.actuadores_off then
        store_data("ACTUADORES_OFF_M", "actuadoresoff", args.actuadores_off, false)
        inputs_data.actuadoresoff = Split(args.actuadores_off, ",")
    else
        inputs_data.actuadoresoff = nil
    end
    if args.masterSwitch_on then
        store_data("MASTERSWITCH_ON_M", "masterSwitchon", args.masterSwitch_on, false)
        inputs_data.masterSwitchon = Split(args.masterSwitch_on, ",")
    else
        inputs_data.masterSwitchon = nil
    end

    --- Gestión de varios device_id en el campo "Aire"
    if args.Aire ~= nil and args.Aire then
        _storage.set_string("aire", args.Aire)
        local device_ids = {}
        
        -- Divide la cadena device_ids separada por comas en una tabla
        for device_id in string.gmatch(args.Aire, '([^,]+)') do
            table.insert(device_ids, device_id)
        end
        
        -- Procesa todos los device_ids
        inputs_data.Aire = process_device_ids(device_ids)
        
        -- Almacena la información del termostato
        _storage.set_table("TERMOSTATO_M" .. tostring(numberPlugin), inputs_data.Aire)
    else
        inputs_data.Aire = nil
    end

    -- - Addiitonal storage -- se elimina sensor de movimiento virtual
    if inputs_data.sensormovelec then
        _logger.info("SENSOR_MOV_ELEC_M"..tostring(numberPlugin))
        _storage.set_table("SENSOR_MOV_ELEC_M"..tostring(numberPlugin), inputs_data.sensormovelec)
        loadfile("HUB:aul.aula_inteligente/scripts/functions/createSensorMotion")()
    end

    _storage.set_table("ACTUADORES_ON_M"..tostring(numberPlugin), inputs_data.actuadoreson)
    _storage.set_table("ACTUADORES_OFF_M"..tostring(numberPlugin), inputs_data.actuadoresoff)
    _storage.set_table("MASTERSWITCH_ON_M"..tostring(numberPlugin), inputs_data.masterSwitchon)
    _storage.set_table("SENSOR_MOV_BATT_M"..tostring(numberPlugin), inputs_data.sensormovbatt)
    _storage.set_table("SENSOR_MOV_ELEC_M"..tostring(numberPlugin), inputs_data.sensormovelec)
    loadfile("HUB:aul.aula_inteligente/scripts/functions/create_device")()
else
    _logger.warning("The provided credentials are invalid.")
    _core.send_ui_broadcast {status = 'error', message = 'Password invalid.'}
	return
end