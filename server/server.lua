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
    if data.event then
        TriggerClientEvent(data.event, src, item)
    end
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
        Kora.logging.warn('consume.too_fast_ignored', 'Item use finished faster than its duration and was ignored', {playerId = src, item = item, durationMs = data.duration or 1000})
        return
    end

    applyUse(src, item, data, itemData)
end

function registerUseable(category, item, data)
    exports.kora_core:createUseable(item, function(source, itemData)
        local src = source
        if using[src] then return false end

        using[src] = true
        local ok, err = pcall(useConsumable, src, category, item, data, itemData)
        using[src] = nil
        if not ok then
            error(err, 0)
        end
    end)
end

function syncConsumableCatalog()
    TriggerClientEvent('kora_consumables:catalog', -1, Config.Consumables, Config.ConsumableClasses)
end

function upsertConsumable(category, item, data)
    Config.Consumables[category] = Config.Consumables[category] or {}
    Config.Consumables[category][item] = data
    registerUseable(category, item, data)
    syncConsumableCatalog()
end

local function registerUseables()
    for category, v in pairs(Config.Consumables) do
        for item, data in pairs(v) do
            registerUseable(category, item, data)
        end
    end
end


CreateThread(function()
    while not ConsumableDataLoaded and not ConsumableDataFailed do Wait(100) end
    if ConsumableDataLoaded then registerUseables() end
end)

-- kora_inventory ships instant built-in handlers for some of the same items
-- (water_bottle, sandwich, beer...). Its handlers register when it starts, so a
-- later inventory (re)start would replace ours; register again to keep ours.
AddEventHandler('onResourceStart', function(resource)
    if resource == 'kora_inventory' then
        if ConsumableDataLoaded then registerUseables() end
    end
end)

-- Legacy qb-smallresources AddFood/AddDrink/AddAlcohol/AddCustom. Only another
-- server resource can call these. Items still go through the normal useable
-- flow above, so a use needs the item held and the server removes it.
local legacyClass = {AddFood = 'food', AddDrink = 'drink', AddAlcohol = 'liquor', AddCustom = 'custom'}
local legacyStatus = {food = 'hunger', drink = 'thirst', liquor = 'thirst'}
local lastSync = {}
local SYNC_COOLDOWN = 5000

local function amount(value)
    if type(value) ~= 'number' then return nil end
    if value ~= value or value < 0 or value > 100 then return nil end
    return value
end

local function vec(value)
    if type(value) ~= 'table' and type(value) ~= 'vector3' then return nil end
    local x = value.x
    local y = value.y
    local z = value.z
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return nil end
    return {x = x, y = y, z = z}
end

local function customData(source)
    if type(source) ~= 'table' then return nil end
    local data = {}
    local progress = source.progress
    local animation = source.animation
    local prop = source.prop
    local replenish = source.replenish
    if type(progress) == 'table' then
        if type(progress.label) == 'string' then
            data.label = progress.label
        end
        if type(progress.time) == 'number' and progress.time > 0 then
            data.duration = progress.time
        end
    end
    if type(animation) == 'table'
        and type(animation.animDict) == 'string'
        and type(animation.anim) == 'string'
    then
        data.anim = {dict = animation.animDict, clip = animation.anim, flag = animation.flags}
    end
    if type(prop) == 'table' and type(prop.model) == 'string' then
        data.prop = {
            model = prop.model,
            bone = type(prop.bone) == 'number' and prop.bone or 60309,
            offset = vec(prop.coords) or {
                x = 0.0,
                y = 0.0,
                z = 0.0,
            },
            rotation = vec(prop.rotation) or {
                x = 0.0,
                y = 0.0,
                z = 0.0,
            },
        }
    end
    if type(replenish) == 'table' then
        local key
        if replenish.type == 'Hunger' then
            key = 'hunger'
        elseif replenish.type == 'Thirst' then
            key = 'thirst'
        end
        local value = amount(replenish.replenish)
        if key and value then
            data.status = {[key] = value}
        end
        if replenish.isAlcohol then
            data.effects = {visual = 'buzzed', duration = 15000}
        end
        if type(replenish.event) == 'string' and replenish.event ~= '' and not replenish.server then
            data.event = replenish.event
        end
    end
    return data
end

local function legacyAdd(export, name, value)
    local class = legacyClass[export]
    if type(name) ~= 'string' or name == '' then
        return false, 'invalid arguments'
    end
    for _, items in pairs(Config.Consumables) do
        if items[name] ~= nil then
            return false, 'already added'
        end
    end
    local data
    if class == 'custom' then
        data = customData(value)
    elseif amount(value) then
        data = {
            status = {
                [legacyStatus[class]] = value,
            },
        }
    end
    if not data then
        return false, 'invalid arguments'
    end
    if not exports.kora_core:getShared('items', name) then
        return false, 'item does not exist'
    end

    ApplyConsumableDefaults(class, name, data)
    local saved, saveError = SaveConsumable(class, name, data)
    if not saved then return false, saveError end
    upsertConsumable(class, name, data)
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
    if lastSync[src] and now - lastSync[src] < SYNC_COOLDOWN then return end
    lastSync[src] = now
    CreateThread(function()
        while not ConsumableDataLoaded and not ConsumableDataFailed do Wait(100) end
        if ConsumableDataLoaded then TriggerClientEvent('kora_consumables:catalog', src, Config.Consumables, Config.ConsumableClasses) end
    end)
end)

AddEventHandler('playerDropped', function()
    lastSync[source] = nil
end)
