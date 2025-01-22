local _logger = require("logging")
local _core = require("core")
local _storage = require("storage")
local _json = require("json")

local numberPlugin = _storage.get_number("numberPlugin")

_logger.info("*** Aula inteligente ejecucion element ***")

_G.thermostatvar = {}

local function initializeThermostat()
    if _G.constants.TERMOSTATO then   
        _logger.info("TERMOSTATO items: " .. _json.encode(_G.constants.TERMOSTATO))
    else
        _logger.warning("TERMOSTATO is null")
    end
end

local function configureSetting(itemId, storageVar, settingName)
    local item = _core.get_item(itemId)
    _logger.info("name: " .. storageVar .. ", id: " .. item.id)
    _logger.info("settingId: " .. settingName)
    local settingIdString =  _storage.get_string(settingName)

    local success, errmsg = pcall(_core.set_setting_value, settingIdString, tostring(item.id), "synced")

    if not success then
        _logger.error("Failed set setting: " .. (errmsg and (", error: " .. errmsg) or ""))
    else
        _logger.info("Success set setting: " .. item.name)
    end
end

local function initializeElectricMotionSensor()
    if _G.constants.SENSOR_MOV_ELEC then
        for _, itemId in ipairs(_G.constants.SENSOR_MOV_ELEC) do
            configureSetting(itemId, "sernsorMovElec", "settingSensorMovElec" .. tostring(numberPlugin))
        end
    else
        _logger.warning("SENSOR_MOV_ELEC is null")
    end
end

local function initializeBatteryMotionSensor()
    if _G.constants.SENSOR_MOV_BATT then
        for _, itemId in ipairs(_G.constants.SENSOR_MOV_BATT) do
            configureSetting(itemId, "sernsorMovBatt", "settingSensorMovBatt" .. tostring(numberPlugin))
        end
    else
        _logger.warning("SENSOR_MOV_BATT is null")
    end
end

local function initializeActuatorsOn()
    if _G.constants.ACTUADORES_ON then
        _logger.info("ACTUADORES_ON: ".._json.encode(_G.constants.ACTUADORES_ON))
        for _, itemId in ipairs(_G.constants.ACTUADORES_ON) do
            configureSetting(itemId, "actuadoresOn" .. tostring(numberPlugin),
                "settingActuadoresOn" .. tostring(numberPlugin))
        end
    else
        _logger.warning("ACTUADORES_ON is null")
    end
end

local function initializeActuatorsOff()
    if _G.constants.ACTUADORES_OFF then
        _logger.info("ACTUADORES_OFF: ".._json.encode(_G.constants.ACTUADORES_OFF))
        for _, itemId in ipairs(_G.constants.ACTUADORES_OFF) do
            configureSetting(itemId, "actuadoresOff" .. tostring(numberPlugin),
                "settingActuadoresOff" .. tostring(numberPlugin))
        end
    else
        _logger.warning("ACTUADORES_OFF is null")
    end
end

local function initializeMasterSwitchOn()
    if _G.constants.MASTERSWITCH_ON then
        _logger.info("MASTERSWITCH_ON: ".._json.encode(_G.constants.MASTERSWITCH_ON))
        for _, itemId in ipairs(_G.constants.MASTERSWITCH_ON) do
            configureSetting(itemId, "masterSwitchon" .. tostring(numberPlugin),
                "settingMasterSwitchOn" .. tostring(numberPlugin))
        end
        
    else
        _logger.warning("MASTERSWITCH_ON is null")
    end
end

local function initializeDoorSensor()
    if _G.constants.SENSOR_PUERTA then
        _logger.info("SENSOR_PUERTA: ".._json.encode(_G.constants.SENSOR_PUERTA))
        for _, itemId in ipairs(_G.constants.SENSOR_PUERTA) do
            configureSetting(itemId, "sensorPuerta" .. tostring(numberPlugin),
            "settingSensorPuerta" .. tostring(numberPlugin))
        end
    else
        _logger.warning("SENSOR_PUERTA is null")

    end
end

_core.send_ui_broadcast {
    status = 'success',
    message = 'Variables successfully in the file element',
}

initializeThermostat()
initializeElectricMotionSensor()
initializeBatteryMotionSensor()
initializeMasterSwitchOn()
initializeActuatorsOn()
initializeActuatorsOff()
-- initializeDoorSensor()