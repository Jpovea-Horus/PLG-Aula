local _core = require("core")
local _logger = require("logging")
local _json = require("json")
local _storage = require("storage")
local numberPlugin = _storage.get_number("numberPlugin")
local securitySensor = _storage.get_table("SENSOR_MOV_ELEC_M"..tostring(numberPlugin))

-- Función para procesar sensores y obtener nombres de dispositivos
local function process_sensors(securitySensor)
    local deviceIdName = ""
    if #securitySensor >= 1 then
        _logger.debug("Hay uno o más sensores de seguridad.")
        for _, sensorId in pairs(securitySensor) do
            local data = _core.get_item(sensorId)
            if data and data.device_id then
                _logger.info(data.device_id)
                local dataDevice = _core.get_device(data.device_id)
                if dataDevice then
                    _logger.info(dataDevice.name)
                    deviceIdName = dataDevice.name
                end
            end
        end
    end
    return deviceIdName
end

-- Función para crear un nuevo dispositivo virtual
local function create_device(numberPlugin)
    local my_gateway_id = (_core.get_gateway() or {}).id
    if not my_gateway_id then
        _logger.error("Error al obtener el ID del gateway actual. Se omite la creación de dispositivos.")
        return nil
    end

    local count = 0
    for _, device in pairs(_core.get_devices() or {}) do
        if device.gateway_id == my_gateway_id then
            count = count + 1
            if not securitySensor or count >= 12 then
                return device.id
            end
        end
    end

    _logger.info("Creando un nuevo dispositivo falso")
    return _core.add_device {
        armed = false,
        type = "sensor",
        device_type_id = "351_43011_4945",
        category = "security_sensor",
        subcategory = "motion",
        battery_powered = false,
        gateway_id = my_gateway_id,
        name = "Virt Sensor " .. tostring(numberPlugin),  -- Nombre del dispositivo con la variable añadida
        info = {
            manufacturer = "Horus Smart Control",
            model = "1.0"
        },
        persistent = false,
        reachable = true,
        ready = true,
        status = "idle"
    }
end

-- Función para crear ítems para un dispositivo
local function create_items(device_id)
    if not device_id then
        _logger.error("No se puede crear el ítem. Falta device_id...")
        return nil
    end

    local items = {
        {
            device_id = device_id,
            name = "motion",
            value_type = "bool",
            has_getter = true,
            has_setter = true,
            value = false,
            valueFormatted = "false",
            show = true
        },
        {
            device_id = device_id,
            name = "security_threat",
            value_type = "bool",
            has_getter = true,
            has_setter = true,
            value = false,
            valueFormatted = "false",
            show = true
        }
    }

    for _, item in ipairs(items) do
        _core.add_item(item)
    end
end

-- Función para almacenar IDs de ítems en el almacenamiento
local function store_item_ids(items, numberPlugin)
    if items then
        _logger.info("Almacenando IDs de ítems de sensores de movimiento")
        for _, item in ipairs(items) do
            if item.name == "motion" then
                _storage.set_string("motion"..tostring(numberPlugin), item.id)
            end

            if item.name == "security_threat" then
                _storage.set_string("securityThreat"..tostring(numberPlugin), item.id)
            end
        end
    end
end

-- Ejecución Principal
local function main()
    local securitySensorDeviceIdName = process_sensors(securitySensor)

    local device_id = create_device(numberPlugin)
    _logger.info(device_id)

    create_items(device_id)

    local securitySensorItems = _core.get_items_by_device_id(device_id)
    store_item_ids(securitySensorItems, numberPlugin)
end

-- Llamada a la función principal
main()