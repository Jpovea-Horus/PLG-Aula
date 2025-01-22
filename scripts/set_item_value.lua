local _core = require("core")
local _logger = require("logging")
local _json = require('json')

local params = ... or {}
local items = {}


_logger.info("████████████████████   Aula inteligente set_item_value up...   ████████████████████")

if type(params.item_id) == "string" then
    items = {
        [params.item_id] = {
            value = params.value
        }
    }
elseif type(params.item_ids) == "table" then
    for _, item_id in ipairs(params.item_ids) do
        items[item_id] = {
            value = params.value
        }
    end
elseif type(params.items) == "table" then
    items = params.items
end

_logger.info("params: ".. _json.encode(params))

for item_id, item_value in pairs(items) do
    local item = _core.get_item(item_id)

    _logger.info("item: " .. item.name)
    local item_script = loadfile("HUB:aul.aula_inteligente/scripts/items/" .. item.name)

    if item_script then
        local success, errmsg = pcall(item_script, {
            device_id = item.device_id,
            item_id = item_id,
            value = item_value.value,
            source = params.source
        })
        if not success then
            _logger.error("Failed to set item: " .. item.name .. (errmsg and (", error: " .. errmsg) or ""))
        end
    else
        _logger.error("Failed to load handler for item: " .. item.name)
    end
    local current_process = _core.get_current_notified_process()
    if current_process ~= nil then
        _core.notify_process_stopped(current_process)
        return true
    end
    item = _core.get_item(item_id)
    _logger.info("item name: " .. item.name .. " valor:" .. _json.encode(item_value))

    if item.name == "Mode" then
        
    end

end
