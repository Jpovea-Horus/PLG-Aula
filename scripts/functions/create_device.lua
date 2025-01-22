local _core             = require("core")
local _logger           = require("logging")
local _json             = require("json")
local _storage          = require("storage")
local _constants        = require("HUB:aul.aula_inteligente/configs/constants")

local numberPlugin = _storage.get_number("numberPlugin")
local credentials  = _storage.get_table(_constants.STORAGE_ACCOUNT_KEY)

-- Función para establecer una tabla en el almacenamiento de forma segura
local function SafeSetTable(key, table)
    local status = pcall(function()
        _storage.set_table(key, table)
    end)
    if not status then
        _logger.error("Failed to set table in storage with key '" .. key .. "'")
    end
end

-- Función para ejecutar una operación de forma segura
local function SafeExecute(func, operation)
    local status, result = pcall(func)
    if not status then
        _logger.error("Failed to execute operation '" .. (operation or "unknown") .. "': " .. result)
        return nil  -- Devuelve nil en caso de error
    end
    return result
end

_logger.info(">>> Iniciando create device del plugin de ocupación... <<<")

local success, errmsg = pcall(function()
    return _json.encode(credentials)
end)

if not success then
    _logger.error("Failed to encode credentials" .. (errmsg and (", error: " .. errmsg) or ""))
else
    _logger.info("Credentials successfully encoded")
end

local function CreateDevice()
    local gateway = SafeExecute(function()
        return _core.get_gateway() or {}
    end, "Getting gateway")

    local my_gateway_id = gateway and gateway.id

    if not my_gateway_id then
        _logger.error("Failed to get current gateway ID, skipping device creation")
        return nil
    end

    local count = 0
    local devices = SafeExecute(function()
        return _core.get_devices()
    end, "Getting devices")

    for _, device in pairs(devices or {}) do
        if device.gateway_id == my_gateway_id then
            count = count + 1
            if not credentials or count >= 16 then
                return device.id
            end
        end
    end

    local deviceId = SafeExecute(function()
        return _core.add_device {
            gateway_id = my_gateway_id,
            name = "Aula inteligente "..tostring(numberPlugin),
            category = "generic_io",
            subcategory = "generic_io",
            type = "device",
            device_type_id = "600",
            battery_powered = false,
            info = {
                manufacturer = "Horus Smart Control",
                model = _G.constants.VERSION
            },
            persistent = false,
            reachable = true,
            ready = true,
            status = "idle"
        }
    end, "Creating device")

    if not deviceId then
        _logger.error("Failed to create device. Device ID: " .. tostring(deviceId))
        return nil
    end

    if deviceId then
        _logger.info("Device created successfully with ID: " .. deviceId)
        return deviceId
    end
end

local function CreateItem(device_id)
    if not device_id then
        _logger.error("Cannot create items. Missing device_id...")
        return nil
    end

    --- Configuracion de los items para el plugin
    _logger.info("Creating new 'device' items")
    _core.add_item({
        device_id = device_id,
        name = "AccionTexto",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Libre", "Puerta Abierta", "Scan", "Ocupado" },
        value = "Libre",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "EstadoTexto",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Libre", "Ocupado" },
        value = "Libre",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "Modo",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        enum = { "Auto", "Apagado", "Manual" },
        value = "",
        show = true,
    })
    _core.add_item({
        device_id = device_id,
        name = "type",
        value_type = "string",
        has_getter = true,
        has_setter = true,
        value = "hotel",
        show = true,
    })

    -- Configuración de dispositivos para el plugin
    local settings = {
        -- -- Dispositivo 1: Sensor de puerta
        -- -- Se agrega un sensor de puerta para monitorizar la apertura y cierre de puerta y desplegar un evento llamado evento de puerta.
        -- {
        --     label = 'Sensor Puerta',
        --     description = 'Registra itemId del sensor de puerta',
        --     enum = "sensorpuerta",
        --     value_type = "string",
        --     value = "",
        -- },
        -- Dispositivo 2: Sensor de movimiento
        -- Este dispositivo detectará cambios en el entorno y desencadenará acciones correspondientes - como es el evento de movimiento.
        {
            label = 'Sensor Movimiento Batt',
            description = 'Registra itemId del Sensor de movimiento batt',
            enum = "sensormovbatt",
            value_type = "string",
            value = ""
            
        },
        {
            label = 'Sensor Movimiento Elec',
            description = 'Registra itemId del Sensor de movimiento elec',
            enum = "sensormovelec",
            value_type = "string",
            value = ""
        },
        -- Dispositivo 4: Actuadores
        -- Este dispositivo detectará cambios en el entorno y desencadenará acciones correspondientes - como es el evento de Actuadores.
        {
            label = 'Master Switch On',
            description = 'Registra itemId Master Switch a on',
            enum = "masterSwitchon",
            value_type = "string",
            value = ""
        },
        {
            label = 'Actuadores On',
            description = 'Registra itemId dispositivos a on',
            enum = "actuadoreson",
            value_type = "string",
            value = ""
        },
        {
            label = 'Actuadores Off',
            description = 'Registra itemId dispositivos a off',
            enum = "actuadoresoff",
            value_type = "string",
            value = ""
        },
        -- Dispositivo 4: Thermostat
        {
            label = 'Thermostat',
            description = 'Registra DeviceId del Termostato',
            enum = "Aire",
            value_type = "string",
            value = ""
        },
        {
            label = 'Set Point ON',
            description = 'Registra Set Point de Encendido del Termostato',
            enum = "SetpointOn",
            value_type = "int",
            value = _G.constants.SETPOINTON
        },
        --- configuraciones adicionales
        {
            label = 'Tiempo Movimiento',
            description = 'Registrar el tiempo estimado de detección del sensor de movimiento',
            enum = "TiempoScan",
            value_type = "int",
            value = _G.constants.TIEMPOSCAN
        },
        {
            label = 'Modo Encendido Thermostat',
            description = 'Registra Encendido del Termostato',
            enum = "motionActivator",
            value_type = "string",
            value = _G.constants.MOTIONACTIVATOR
        },
        -- {
        --     label = 'Modo SetPoint',
        --     description = 'Registra Si desea Modo Set Point del Termostato',
        --     enum = "ModoSetpoint",
        --     value_type = "string",
        --     value = _G.constants.MODOSETPOINT
        -- },
        -- {
        --     label = 'Modo Off Puerta Abierta',
        --     description = 'Registra Si desea Apagado Por Puerta Abierta',
        --     enum = "offPuertaAbierta",
        --     value_type = "string",
        --     value = _G.constants.OFFPUERTAABIERTA
        -- },
        -- {
        --     label =  'Set Point OFF',
        --     description = 'Registra Set Point de Apagado del Termostato',
        --     enum = "SetpointOff" ,
        --     value_type = "int",
        --     value = _G.constants.SETPOINTOFF
        -- },
        {
            label = 'Modo Disparador Luces',
            description = 'Registrar si se desea activación de luces por disparo de movimiento o actuadores',
            enum = "ModoDispLuces",
            value_type = "string",
            value = _G.constants.MODODISPLUCES
        },
        {
            label = 'Modo Master Switch',
            description = 'Registrar si se desea activación de ModoMasterSwitch por disparo de movimiento o actuadores',
            enum = "ModoMasterSwitch",
            value_type = "string",
            value = _G.constants.MODOMASTERSWITCH
        },
    }

    for _, setting in ipairs(settings) do
        SafeExecute(function()
            _core.add_setting {
                device_id = device_id,
                label = { text = setting.label },
                description = { text = setting.description },
                enum = {text = setting.enum},
                value_type = setting.value_type,
                value = setting.value,
                status = "synced",
                has_setter = true
            }
        end, "Creating setting '" .. setting.label .. "'")
    end
end

local device_id = CreateDevice()
_storage.set_table("PluginID"..numberPlugin, device_id)


if device_id then
    CreateItem(device_id)
    _G.idPg = device_id
    _G.ID_PLUGIN = SafeExecute(function()
        return _core.get_items_by_device_id(device_id)
    end, "Getting items by device ID")

    if _G.ID_PLUGIN then
        for _, item in ipairs(_G.ID_PLUGIN) do
            if item.name == "AccionTexto" then
                _G.AccionTexto = item.id
                _storage.set_string("AccionTextoId" .. numberPlugin, item.id)
                -- _logger.info("AccionTextoId" .. numberPlugin .." , ".. tostring(item.id))
            end
            if item.name == "EstadoTexto" then
                _storage.set_string("EstadoTextoId" .. numberPlugin, item.id)
                -- _logger.info("EstadoTextoId" .. numberPlugin .." , ".. tostring(item.id))
            end
            if item.name == "Modo" then
                _storage.set_string("ModoId" .. numberPlugin, item.id)
                -- _logger.info("Registro de modoId: ")
                -- _logger.info("ModoId" .. numberPlugin .." , ".. tostring(item.id))
            end
            if item.name == "type" then
                _storage.set_string("TypeId" .. numberPlugin, item.id)
                -- _logger.info("TypeId" .. numberPlugin .." , ".. tostring(item.id))
            end
        end
    end

    local setting_ids = SafeExecute(function()
        return _core.get_setting_ids_by_device_id(device_id)
    end, "Getting setting IDs by device ID")

    if setting_ids then
        for _, setting_id in pairs(setting_ids) do
            local setting = SafeExecute(function()
                return _core.get_setting(tostring(setting_id))
            end, "Getting setting for ID " .. setting_id)

            if setting then
                if setting.label.text == 'Sensor Movimiento Batt' then
                    SafeSetTable("settingSensorMovBatt" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Sensor Movimiento Elec' then
                    SafeSetTable("settingSensorMovElec" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Master Switch On' then
                    SafeSetTable("settingMasterSwitchOn" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Actuadores On' then
                    SafeSetTable("settingActuadoresOn" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Actuadores Off' then
                    SafeSetTable("settingActuadoresOff" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Thermostat' then
                    SafeSetTable("settingThermostat" .. numberPlugin, setting_id)
                elseif setting.label.text == 'Set Point ON' then
                    SafeSetTable("settingSetPointON"..numberPlugin, setting_id)
                elseif setting.label.text == 'Encendido Thermostat' then
                    SafeSetTable("settingEncendidoThermostat"..numberPlugin, setting_id)
                elseif setting.label.text == 'Tiempo Movimiento' then
                    SafeSetTable("settingTiempoMovimiento"..numberPlugin, setting_id)                 
                elseif setting.label.text == 'Disparador Luces' then
                    SafeSetTable("settingAuxiliarluces"..numberPlugin, setting_id)
                -- if setting.label.text == 'Sensor Puerta' then
                --     SafeSetTable("settingSensorPuerta" .. numberPlugin, setting_id)
                -- elseif setting.label.text == 'Set Point OFF' then
                --     SafeSetTable("settingSetPointOFF"..numberPlugin, setting_id)
                -- elseif setting.label.text == 'Modo SetPoint' then
                --     SafeSetTable("settingModoSetPoint"..numberPlugin, setting_id)  
                -- elseif setting.label.text == 'Off Puerta Abierta' then
                --     SafeSetTable("settingOffPuertaAbierta"..numberPlugin, setting_id)   
                end
            end
        end
    end
end
loadfile("HUB:aul.aula_inteligente/scripts/startup")()