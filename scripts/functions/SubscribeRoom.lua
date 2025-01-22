local _core = require("core")
local _logger = require("logging")
local _storage = require("storage")

local numberPlugin = _storage.get_number("numberPlugin")

-- Error Managment
local function errorHandler(err)
    _logger.error("Error reported: " .. err)
end

-- Function subscription room: 
local function subscribeToRooms()
    local status, resultado

    for i = 1, numberPlugin do
        local roomScript = "HUB:aul.aula_inteligente/scripts/rooms/room" .. i
        status, resultado = xpcall(_core.subscribe, errorHandler, roomScript)

        if not status then
            _logger.error("Failed to subscribe to " .. roomScript)
            _core.send_ui_broadcast {status = 'error', message = "Failed to subscribe to " .. roomScript}
            return
        end
    end

    -- Send message
    _logger.info('Successfully subscribed to rooms to: ' .. numberPlugin)
    _core.send_ui_broadcast {
        status = 'success',
        message = 'Subscribed to rooms to: ' .. numberPlugin
    }
end

-- Call Function Main 
subscribeToRooms()