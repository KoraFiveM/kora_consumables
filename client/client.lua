
local function addVisuals(effect)
   if not effect then 
       return
   end
   if effect.visual == 'none' then
       return
   end

    if effect.visual == 'alien' then
        QB.visuals.alien(effect.duration or 15000)
    elseif effect.visual == 'coke' then
        QB.visuals.coke(effect.duration or 15000)
    elseif effect.visual == 'crack' then
        QB.visuals.crack(effect.duration or 15000)
    elseif effect.visual == 'meth' then
        QB.visuals.meth(effect.duration or 15000)
    elseif effect.visual == 'trevor' then
        QB.visuals.trevor(effect.duration or 15000)
    end
end

QB.callback.register('qbconsumables:progress', function(data)
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
        emote = itemData.emote or nil,
        disable = itemData.disableMovement or false,
    })
    if itemData.effects and progress then
        addVisuals(itemData.effects)
    end
    return progress
end)