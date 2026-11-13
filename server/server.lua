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

local function applyUse(src, item, data, itemData)
    if not takeItem(src, item, data, itemData) then return end
    addStatus(src, data.status)
    if data.event then TriggerClientEvent(data.event, src, item) end
end

local function useConsumable(src, category, item, data, itemData)
    local payload = {class = category, item = item}

    if Config.applyStatusOn == 'start' then
        applyUse(src, item, data, itemData)
        Kora.callback.trigger(src, 'kora_consumables:progress', payload)
        return
    end

    local startedAt = GetGameTimer()
    local progressbar = Kora.callback.trigger(src, 'kora_consumables:progress', payload)
    if not progressbar then return end

    -- The client reports its own result, so a modified client could answer at once.
    -- A real use cannot come back before the progress duration has elapsed.
    if GetGameTimer() - startedAt < (data.duration or 1000) - FINISH_TOLERANCE then
        print(('[kora_consumables] %s used %s faster than its %sms duration; ignored'):format(src, item, data.duration or 1000))
        return
    end

    applyUse(src, item, data, itemData)
end

local function registerUseable(category, item, data)
    exports.kora_core:createUseable(item, function(source, itemData)
        local src = source
        if using[src] then return false end

        using[src] = true
        local ok, err = pcall(useConsumable, src, category, item, data, itemData)
        using[src] = nil
        if not ok then error(err, 0) end
    end)
end

local function registerUseables()
    for category, v in pairs(Config.Consumables) do
        for item, data in pairs(v) do
            registerUseable(category, item, data)
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

-- Legacy qb-smallresources AddFood/AddDrink/AddAlcohol/AddCustom. Only another
-- server resource can call these. Items still go through the normal useable
-- flow above, so a use needs the item held and the server removes it.
local legacyClass = { AddFood = 'food', AddDrink = 'drink', AddAlcohol = 'liquor', AddCustom = 'custom' }
local legacyStatus = { food = 'hunger', drink = 'thirst', liquor = 'thirst' }
local added = {}
local lastSync = {}
local SYNC_COOLDOWN = 5000

local function amount(value)
    return type(value) == 'number' and value == value and value >= 0 and value <= 100 and value or nil
end

local function vec(value)
    if type(value) ~= 'table' and type(value) ~= 'vector3' then return nil end
    local x, y, z = value.x, value.y, value.z
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return nil end
    return {x = x, y = y, z = z}
end

local function customData(source)
    if type(source) ~= 'table' then return nil end
    local data = {}
    local progress, animation, prop, replenish = source.progress, source.animation, source.prop, source.replenish
    if type(progress) == 'table' then
        if type(progress.label) == 'string' then data.label = progress.label end
        if type(progress.time) == 'number' and progress.time > 0 then data.duration = progress.time end
    end
    if type(animation) == 'table' and type(animation.animDict) == 'string' and type(animation.anim) == 'string' then
        data.anim = {dict = animation.animDict, clip = animation.anim, flag = animation.flags}
    end
    if type(prop) == 'table' and type(prop.model) == 'string' then
        data.prop = {model = prop.model, bone = type(prop.bone) == 'number' and prop.bone or 60309,
            offset = vec(prop.coords) or {x = 0.0, y = 0.0, z = 0.0},
            rotation = vec(prop.rotation) or {x = 0.0, y = 0.0, z = 0.0}}
    end
    if type(replenish) == 'table' then
        local key = replenish.type == 'Hunger' and 'hunger' or replenish.type == 'Thirst' and 'thirst' or nil
        local value = amount(replenish.replenish)
        if key and value then data.status = {[key] = value} end
        if replenish.isAlcohol then data.effects = {visual = 'buzzed', duration = 15000} end
        if type(replenish.event) == 'string' and replenish.event ~= '' and not replenish.server then
            data.event = replenish.event
        end
    end
    return data
end

local function legacyAdd(export, name, value)
    local class = legacyClass[export]
    if type(name) ~= 'string' or name == '' then return false, 'invalid arguments' end
    for _, items in pairs(Config.Consumables) do
        if items[name] ~= nil then return false, 'already added' end
    end
    local data
    if class == 'custom' then
        data = customData(value)
    elseif amount(value) then
        data = {status = {[legacyStatus[class]] = value}}
    end
    if not data then return false, 'invalid arguments' end
    if not exports.kora_core:getShared('items', name) then return false, 'item does not exist' end

    Config.Consumables[class] = Config.Consumables[class] or {}
    Config.Consumables[class][name] = data
    ApplyConsumableDefaults(class, name, data)
    added[#added + 1] = {class = class, item = name, data = data}
    registerUseable(class, name, data)
    TriggerClientEvent('kora_consumables:register', -1, {added[#added]})
    return true, 'success'
end

for export in pairs(legacyClass) do
    local handler = function(name, value) return legacyAdd(export, name, value) end
    exports(export, handler)
    Kora.compat.provideExport('qb-smallresources', export, handler)
end

RegisterNetEvent('kora_consumables:sync', function()
    local src = source
    local now = GetGameTimer()
    if #added == 0 or (lastSync[src] and now - lastSync[src] < SYNC_COOLDOWN) then return end
    lastSync[src] = now
    TriggerClientEvent('kora_consumables:register', src, added)
end)

AddEventHandler('playerDropped', function() lastSync[source] = nil end)
