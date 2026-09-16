
local function addVisuals(effect)
    if not effect or effect == '' or effect == 'none' then return end
    if effect == 'alien' then
        QB.visuals.alien(15000)
    elseif effect == 'coke' then
        QB.visuals.coke(15000)
    elseif effect == 'crack' then
        QB.visuals.crack(15000)
    elseif effect == 'meth' then
        QB.visuals.meth(15000)
    elseif effect == 'trevor' then
        QB.visuals.trevor(15000)
    end
end

QB.callback.register('qbconsumables:progress', function(source, data)
    assert(data and data.class and data.item, "Invalid data passed to qbconsumables:progress")
    local itemData = Config.Consumables[data.class] and Config.Consumables[data.class][data.item] or nil
    if not itemData then
        return false
    end
    local progress = QB.progressbar.start({
        label = itemData.label or "Using item",
        duration = itemData.duration or 1000,
        useWhileDead = itemData.useWhileDead or false,
        canCancel = itemData.canCancel or true,
        anim = itemData.anim or nil,
        prop = itemData.prop or nil,
        disable = itemData.disableMovement or false,
    })
    if itemData.effects and progress then
        addVisuals(itemData.effects)
    end
    return progress
end)