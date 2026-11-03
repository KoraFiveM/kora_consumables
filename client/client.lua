-- Liquor's 'buzzed' visual: a light drunk camera shake for the effect duration
-- (F#287). Config.buzzedShake sets the strength; 0 turns it off. One timer per
-- drink, and only the latest drink's timer stops the shake.
local buzzedToken = 0
local function buzzed(duration)
    local shake = tonumber(Config.buzzedShake) or 0
    if shake <= 0 then return end
    buzzedToken = buzzedToken + 1
    local token = buzzedToken
    ShakeGameplayCam('DRUNK_SHAKE', math.min(shake, 1.0))
    SetTimeout(duration, function()
        if token == buzzedToken then StopGameplayCamShaking(true) end
    end)
end

-- status.health / status.armor from the item (F#288). Health never drops below
-- the death threshold, so a consumable can hurt but not kill.
RegisterNetEvent('qbconsumables:client:vitals', function(health, armor)
    local ped = PlayerPedId()
    health, armor = tonumber(health) or 0, tonumber(armor) or 0
    if health ~= 0 and health == health and not IsEntityDead(ped) then
        local current = GetEntityHealth(ped)
        SetEntityHealth(ped, math.floor(math.max(101, math.min(GetEntityMaxHealth(ped), current + health))))
    end
    if armor ~= 0 and armor == armor then
        SetPedArmour(ped, math.floor(math.max(0, math.min(100, GetPedArmour(ped) + armor))))
    end
end)


local function addVisuals(effect)
    if not effect or effect.visual == 'none' then
        return
    end

    if effect.visual == 'alien' then
        Kora.visuals.alien(effect.duration or 15000)
    elseif effect.visual == 'coke' then
        Kora.visuals.coke(effect.duration or 15000)
    elseif effect.visual == 'crack' then
        Kora.visuals.crack(effect.duration or 15000)
    elseif effect.visual == 'meth' then
        Kora.visuals.meth(effect.duration or 15000)
    elseif effect.visual == 'trevor' then
        Kora.visuals.trevor(effect.duration or 15000)
    elseif effect.visual == 'buzzed' then
        buzzed(effect.duration or 15000)
    end
end

-- Returns the prop when its model exists in the game, otherwise nil so the item
-- is still used without it instead of the progress bar asserting.
local function usableProp(prop, item)
    if not prop or Config.skipInvalidProps == false then
        return prop
    end
    local model = type(prop) == 'table' and prop.model or nil
    local hash = type(model) == 'string' and joaat(model) or model
    if type(hash) == 'number' and IsModelValid(hash) then
        return prop
    end
    if Config.Debug then
        print(('[kora_consumables] skipping prop for %s: invalid model %s'):format(tostring(item), tostring(model)))
    end
    return nil
end

-- Whether the player may walk while using this item: a per-item allowMovement wins,
-- then Config.allowMovement (boolean, or a table keyed by class), default true.
local function movementAllowed(itemData, class)
    if itemData.allowMovement ~= nil then
        return itemData.allowMovement == true
    end
    local setting = Config.allowMovement
    if type(setting) == 'table' then
        setting = setting[class]
    end
    return setting ~= false
end

-- Upper-body (16) + allow player control (32) keep the legs free; flag 0/1 would lock the body.
local UPPER_BODY_CONTROL = 48
local function movableAnim(anim)
    if type(anim) ~= 'table' then
        return anim
    end
    local copy = {}
    for key, value in pairs(anim) do copy[key] = value end
    copy.flag = (copy.flag or 1) | UPPER_BODY_CONTROL
    return copy
end

Kora.callback.register('qbconsumables:progress', function(data)
    assert(data and data.class and data.item, "Invalid data passed to qbconsumables:progress")
    local itemData = Config.Consumables[data.class] and Config.Consumables[data.class][data.item] or nil
    if not itemData then
        return false
    end
    local prop = usableProp(itemData.prop, data.item)
    local disable = itemData.disable
    if disable == nil then disable = itemData.disableMovement or false end
    if type(disable) == 'table' and disable.vehicle ~= nil and disable.car == nil then
        disable = Kora.util.deepClone(disable)
        disable.car = disable.vehicle
    end
    local anim = itemData.anim or nil
    if movementAllowed(itemData, data.class) then
        if type(disable) == 'table' and disable.move then
            disable = Kora.util.deepClone(disable)
            disable.move = false
        end
        anim = movableAnim(anim)
    end
    -- An error inside the progress bar must reach the server as a clean failure.
    local started, progress = pcall(Kora.progressbar.start, {
        label = itemData.label or "Using item",
        duration = itemData.duration or 1000,
        useWhileDead = itemData.useWhileDead or false,
        canCancel = itemData.canCancel == nil or itemData.canCancel,
        anim = anim,
        prop = prop and prop.coords and prop or nil,
        props = prop and not prop.coords and { prop } or nil,
        emote = itemData.emote or nil,
        disable = disable,
    })
    if not started then
        if Config.Debug then
            print(('[kora_consumables] progress failed for %s: %s'):format(tostring(data.item), tostring(progress)))
        end
        return false
    end
    if itemData.effects and progress then
        addVisuals(itemData.effects)
    end
    return progress
end)
RegisterNetEvent('qbconsumables:register', function(entries)
    if type(entries) ~= 'table' then return end
    for _, entry in ipairs(entries) do
        if type(entry) == 'table' and type(entry.class) == 'string' and type(entry.item) == 'string' and type(entry.data) == 'table' then
            Config.Consumables[entry.class] = Config.Consumables[entry.class] or {}
            Config.Consumables[entry.class][entry.item] = entry.data
        end
    end
end)

CreateThread(function()
    TriggerServerEvent('qbconsumables:sync')
end)
