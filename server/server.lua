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

for category, v in pairs(Config.Consumables) do
    for item, data in pairs(v) do
        exports.kora_core:createUseable(item, function(source, itemData)
            local src = source
            local itemInfo = itemData.info

            local progressbar = QB.callback.trigger(src,'qbconsumables:progress',  {class = category, item = item})
            if not progressbar then return end
            local remove = false
            if itemInfo and itemInfo.uses then
                itemInfo.uses = itemInfo.uses - 1
                local updated = exports['qb-inventory']:SetItemData(src, item, 'info', itemInfo, itemData.slot)
                if not updated then return end
                if itemInfo.uses <= 0 then
                    remove = true
                end
            elseif not data.keep then
                remove = true
            end
            if remove then
                if exports.kora_inventory:removeItem(source, item, 1, itemData.slot) then
                    if data.status then
                        addStatus(src, data.status)
                    end
                end
            else
                if data.status then
                    addStatus(src, data.status)
                end
            end
        end)
    end
end

