
local buzzedToken = 0

-- Drunk screen effect for alcohol; kora_lib has no buzzed visual, so it is applied here.
local function buzzed(duration)
    buzzedToken = buzzedToken + 1
    local token = buzzedToken
    SetTimecycleModifier('drug_drive_blend01')
    SetTimecycleModifierStrength(0.6)
    ShakeGameplayCam('DRUNK_SHAKE', 0.6)
    if Config.DrunkNotify ~= false and Kora and Kora.notify and Kora.notify.send then
        Kora.notify.send({ title = 'Drunk', message = "Congratulations! You've unlocked drunk mode.", type = 'info' })
    end
    local walk = Config.DrunkWalk ~= false and Config.DrunkWalkClipset or nil
    if walk then
        RequestAnimSet(walk)
        local timeout = GetGameTimer() + 5000
        while not HasAnimSetLoaded(walk) and GetGameTimer() < timeout do Wait(0) end
        if HasAnimSetLoaded(walk) then
            SetPedMovementClipset(PlayerPedId(), walk, 1.0)
        else
            walk = nil
        end
    end
    CreateThread(function()
        Wait(duration)
        if token ~= buzzedToken then return end
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        if walk then ResetPedMovementClipset(PlayerPedId(), 1.0) end
    end)
end

local function addVisuals(effect)
    if not effect or effect.visual == 'none' then
        return
    end

    if effect.visual == 'buzzed' then
        buzzed(effect.duration or 15000)
    elseif effect.visual == 'alien' then
        Kora.visuals.alien(effect.duration or 15000)
    elseif effect.visual == 'coke' then
        Kora.visuals.coke(effect.duration or 15000)
    elseif effect.visual == 'crack' then
        Kora.visuals.crack(effect.duration or 15000)
    elseif effect.visual == 'meth' then
        Kora.visuals.meth(effect.duration or 15000)
    elseif effect.visual == 'trevor' then
        Kora.visuals.trevor(effect.duration or 15000)
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

Kora.callback.register('kora_consumables:progress', function(data)
    assert(data and data.class and data.item, "Invalid data passed to kora_consumables:progress")
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
        label = ConsumableLabel(data.class, data.item, itemData) or "Using item",
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
RegisterNetEvent('kora_consumables:register', function(entries)
    if type(entries) ~= 'table' then return end
    for _, entry in ipairs(entries) do
        if type(entry) == 'table' and type(entry.class) == 'string' and type(entry.item) == 'string' and type(entry.data) == 'table' then
            Config.Consumables[entry.class] = Config.Consumables[entry.class] or {}
            Config.Consumables[entry.class][entry.item] = entry.data
        end
    end
end)

CreateThread(function()
    TriggerServerEvent('kora_consumables:sync')
end)
