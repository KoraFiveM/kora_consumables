local function addStatus(src, status)
    if not status then return end
    if status.hunger then
        exports.kora_core:incrementMetaData(src, 'hunger', status.hunger, 0, 100)
    end
    if status.thirst then
        exports.kora_core:incrementMetaData(src, 'thirst', status.thirst, 0, 100)
    end
    if status.stress then
        exports.kora_core:incrementMetaData(src, 'stress', status.stress, 0, 100)
    end
    if status.health then
        exports.kora_core:incrementMetaData(src, 'health', status.health, 0, 100)
    end
    if status.armor then
        exports.kora_core:incrementMetaData(src, 'armor', status.armor, 0, 100)
    end
    if status.drunk then
        exports.kora_core:incrementMetaData(src, 'drunk', status.drunk, 0, 100)
    end
    if status.high then
        exports.kora_core:incrementMetaData(src, 'high', status.high, 0, 100)
    end
end

-- Allowance for timer granularity when checking the reported duration.
local FINISH_TOLERANCE = 250

-- Players with a use in flight. A use spans a client round trip, so without this
-- a second use would run alongside the first and stack its effect.
local using = {}

-- Returns true when the item was consumed (or kept) and its status may apply.
local function takeItem(src, item, data, itemData)
    local itemInfo = itemData.info
    local remove = false
    if itemInfo and itemInfo.uses then
        itemInfo.uses = itemInfo.uses - 1
        local updated = exports['qb-inventory']:SetItemData(src, item, 'info', itemInfo, itemData.slot)
        if not updated then return false end
        remove = itemInfo.uses <= 0
    elseif not data.keep then
        remove = true
    end
    if remove then
        return exports.kora_inventory:removeItem(src, item, 1, itemData.slot) and true or false
    end
    return true
end

local function useConsumable(src, category, item, data, itemData)
    local payload = {class = category, item = item}

    if Config.applyStatusOn == 'start' then
        if takeItem(src, item, data, itemData) and data.status then
            addStatus(src, data.status)
        end
        Kora.callback.trigger(src, 'qbconsumables:progress', payload)
        return
    end

    local startedAt = GetGameTimer()
    local progressbar = Kora.callback.trigger(src, 'qbconsumables:progress', payload)
    if not progressbar then return end

    -- The client reports its own result, so a modified client could answer at once.
    -- A real use cannot come back before the progress duration has elapsed.
    if GetGameTimer() - startedAt < (data.duration or 1000) - FINISH_TOLERANCE then
        print(('[kora_consumables] %s used %s faster than its %sms duration; ignored'):format(src, item, data.duration or 1000))
        return
    end

    if takeItem(src, item, data, itemData) and data.status then
        addStatus(src, data.status)
    end
end

local function registerUseables()
    for category, v in pairs(Config.Consumables) do
        for item, data in pairs(v) do
            exports.kora_core:createUseable(item, function(source, itemData)
                local src = source
                if using[src] then return false end

                using[src] = true
                local ok, err = pcall(useConsumable, src, category, item, data, itemData)
                using[src] = nil
                if not ok then error(err, 0) end
            end)
        end
    end
end

registerUseables()

-- kora_inventory ships instant built-in handlers for some of the same items
-- (water_bottle, sandwich, beer...). Its handlers register when it starts, so a
-- later inventory (re)start would replace ours; register again to keep ours.
AddEventHandler('onResourceStart', function(resource)
    if resource == 'kora_inventory' then registerUseables() end
end)
