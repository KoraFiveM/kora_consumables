
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

Kora.callback.register('qbconsumables:progress', function(data)
    assert(data and data.class and data.item, "Invalid data passed to qbconsumables:progress")
    local itemData = Config.Consumables[data.class] and Config.Consumables[data.class][data.item] or nil
    if not itemData then
        return false
    end
    local prop = itemData.prop
    local disable = itemData.disable
    if disable == nil then disable = itemData.disableMovement or false end
    if type(disable) == 'table' and disable.vehicle ~= nil and disable.car == nil then
        disable = Kora.util.deepClone(disable)
        disable.car = disable.vehicle
    end
    local progress = Kora.progressbar.start({
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
    if itemData.effects and progress then
        addVisuals(itemData.effects)
    end
    return progress
end)