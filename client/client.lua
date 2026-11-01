
local function addVisuals(effect)
   if not effect then 
       return
   end
   if effect.visual == 'none' then
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
    -- An error inside the progress bar must reach the server as a clean failure.
    local started, progress = pcall(Kora.progressbar.start, {
        label = itemData.label or "Using item",
        duration = itemData.duration or 1000,
        useWhileDead = itemData.useWhileDead or false,
        canCancel = itemData.canCancel == nil or itemData.canCancel,
        anim = itemData.anim or nil,
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