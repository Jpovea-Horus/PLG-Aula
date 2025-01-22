local _core = require("core")
local _logger = require("logging")
local args = ... or {}


local function setItemValue(itemId, value)
    local success, result = xpcall(
        function()
            return _core.set_item_value(itemId, value)
        end,
        function(err)
            _logger.error("Error al establecer el valor del ítem " .. itemId .. ": " .. (err or "Error desconocido"))
            return err -- Importante: devolver el error para xpcall
        end
    )
    if not success then
        _logger.error("Error en el manejador de errores para " .. itemId .. ": " .. (result or "Error desconocido"))
    else
        _logger.info("device: " .. itemId .. ", value: " .. value)
    end
end

if args.itemId and args.itemValue then
    setItemValue(args.itemId, args.itemValue)
    return _logger.info("command sent")
else
    return _logger.error("no device found")
end