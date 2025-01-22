local _core = require("core")
local _logger = require("logging")
local params = ... or {}


if not params.deviceId then  
    _logger.warning("Missing device ID, can't delete device")
    return
end
_logger.info("Delete device: " .. params.deviceId)
_core.remove_device(params.deviceId)