local visuals = {none = true, buzzed = true, alien = true, coke = true, crack = true, meth = true, trevor = true}
local ITEM_IMAGE_CDN = 'https://cdn.koraframe.work/inventory'
local CREATOR_LEVELS = {'god', 'admin', 'mod', 'user'}
local CREATOR_PERMISSION_OPTIONS = {prefix = 'kora_core'}

local function itemArtwork(item)
    local candidates = {item.image, item.imageUrl}
    for index = 1, 2 do
        local candidate = candidates[index]
        if type(candidate) == 'string' and (candidate:match('^https://') or candidate:match('^nui://') or candidate:match('^cfx%-nui://')) then
            return candidate
        end
    end
    if type(item.name) == 'string' and item.name:match('^[%w_%-]+$') then
        return ITEM_IMAGE_CDN .. '/' .. item.name .. '.webp'
    end
end

local function admin(src)
    return type(src) == 'number' and src > 0
        and Kora.permissions.hasLevel(src, 'admin', CREATOR_LEVELS, CREATOR_PERMISSION_OPTIONS)
end

local function callback(name, handler)
    Kora.callback.register('kora_consumables:creator:' .. name, function(src, ...)
        if not admin(src) then return nil, 'You do not have permission to edit consumables' end
        if not ConsumableDataLoaded then return nil, 'Consumable database is not ready' end
        return handler(src, ...)
    end)
end

local function allItems()
    local items = exports.kora_core:allShared('items') or {}
    local result = {}
    for _, info in ipairs(items) do
        local name = info.name
        result[#result + 1] = {
            name = name,
            label = type(info) == 'table' and info.label or name,
            weight = type(info) == 'table' and info.weight or nil,
            image = type(info) == 'table' and info.image or nil,
            imageUrl = type(info) == 'table' and info.imageUrl or nil,
            description = type(info) == 'table' and info.description or nil,
            artwork = type(info) == 'table' and itemArtwork(info) or nil,
        }
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

callback('get', function()
    local entries = {}
    for class, items in pairs(Config.Consumables) do
        for item, data in pairs(items) do entries[#entries + 1] = {class = class, item = item, data = data} end
    end
    table.sort(entries, function(a, b) return a.class == b.class and a.item < b.item or a.class < b.class end)
    return {entries = entries, items = allItems(), classes = Config.ConsumableClasses}
end)

callback('searchItems', function(_, query)
    local needle = type(query) == 'string' and query:match('^%s*(.-)%s*$'):sub(1, 64):lower() or ''
    if needle == '' then return nil, 'Enter an item name or display name to search' end
    local results = {}
    for _, item in ipairs(allItems()) do
        local name, label = item.name, tostring(item.label or item.name)
        if name:lower():find(needle, 1, true) or label:lower():find(needle, 1, true) then
            results[#results + 1] = {
                name = name,
                label = label,
                image = item.artwork,
            }
        end
    end
    table.sort(results, function(a, b)
        local left, right = a.label:lower(), b.label:lower()
        return left == right and a.name < b.name or left < right
    end)
    local total = #results
    while #results > 24 do results[#results] = nil end
    return {results = results, total = total}
end)

callback('save', function(_, entry)
    if type(entry) ~= 'table' or type(entry.item) ~= 'string' or #entry.item > 64 or not entry.item:match('^[%w_%-]+$') then
        return nil, 'Enter a valid shared item name'
    end
    local class = entry.class
    if type(class) ~= 'string' or not Config.ConsumableClasses[class] then return nil, 'Invalid consumable class' end
    for otherClass, items in pairs(Config.Consumables) do
        if otherClass ~= class and items[entry.item] then return nil, 'That item is already assigned to ' .. otherClass end
    end

    local itemDefinition = exports.kora_core:getShared('items', entry.item)
    local current = Config.Consumables[class] and Config.Consumables[class][entry.item]
    local prior = current or {}
    local sharedItem = prior.sharedItem
    if not itemDefinition or sharedItem then
        local itemLabel = type(entry.itemLabel) == 'string' and entry.itemLabel:match('^%s*(.-)%s*$') or ''
        if itemLabel == '' then
            itemLabel = entry.item:gsub('_', ' '):gsub('(%S)(%S*)', function(first, rest) return first:upper() .. rest end)
        end
        local weight = tonumber(entry.weight) or 100
        if weight < 0 or weight > 100000 then return nil, 'Item weight must be between 0 and 100000' end
        local shouldClose = true
        if itemDefinition and itemDefinition.shouldClose ~= nil then shouldClose = itemDefinition.shouldClose end
        sharedItem = {
            name = entry.item,
            label = itemLabel:sub(1, 80),
            weight = math.floor(weight),
            type = itemDefinition and itemDefinition.type or 'item',
            image = type(entry.image) == 'string' and entry.image:sub(1, 128) or (entry.item .. '.png'),
            unique = itemDefinition and itemDefinition.unique == true or false,
            useable = true,
            shouldClose = shouldClose,
            description = type(entry.description) == 'string' and entry.description:sub(1, 256) or '',
            createdByConsumables = true,
        }
    end
    local duration = tonumber(entry.duration)
    if not duration or duration < 250 or duration > 120000 then return nil, 'Duration must be between 250 and 120000 milliseconds' end
    local effectDuration = tonumber(entry.effectDuration) or 15000
    if effectDuration < 1000 or effectDuration > 600000 then return nil, 'Effect duration must be between 1000 and 600000 milliseconds' end
    local data = {
        label = type(entry.label) == 'string' and entry.label:match('^%s*(.-)%s*$'):sub(1, 80) or nil,
        duration = math.floor(duration),
        canCancel = entry.canCancel ~= false,
        useWhileDead = entry.useWhileDead == true,
        allowMovement = entry.allowMovement == true,
        keep = entry.keep == true,
        disable = {move = entry.disableMove == true, combat = entry.disableCombat == true, vehicle = entry.disableVehicle == true},
        status = {},
        effects = {visual = visuals[entry.visual] and entry.visual or 'none', duration = math.floor(effectDuration)},
    }
    if sharedItem then data.sharedItem = sharedItem end
    local submittedStatus = type(entry.status) == 'table' and entry.status or {}
    for _, key in ipairs({'hunger', 'thirst', 'stress', 'health', 'armor', 'drunk', 'high'}) do
        local value = tonumber(submittedStatus[key])
        if value then
            if value < -100 or value > 100 then return nil, key .. ' must be between -100 and 100' end
            data.status[key] = value
        end
    end
    if entry.animationMode == 'emote' then
        local emote = type(entry.emote) == 'string' and entry.emote:match('^%s*(.-)%s*$') or ''
        if emote == '' or #emote > 64 then return nil, 'Enter the kora_emotemenu emote name' end
        data.animation = {mode = 'emote', emote = emote}
    else
        local dict = type(entry.animDict) == 'string' and entry.animDict:match('^%s*(.-)%s*$') or ''
        local clip = type(entry.animClip) == 'string' and entry.animClip:match('^%s*(.-)%s*$') or ''
        if dict == '' or clip == '' then return nil, 'Animation mode requires both a dictionary and animation name' end
        local flag = tonumber(entry.animFlag) or 49
        if flag < 0 or flag > 65535 then return nil, 'Animation flag must be between 0 and 65535' end
        data.animation = {mode = 'animation', dict = dict, clip = clip, flag = math.floor(flag)}
        for _, slot in ipairs({'prop', 'proptwo'}) do
            local model = type(entry[slot .. 'Model']) == 'string' and entry[slot .. 'Model']:match('^%s*(.-)%s*$') or ''
            if model ~= '' then
                local prop = {model = model, bone = math.floor(tonumber(entry[slot .. 'Bone']) or 60309)}
                local prefix = slot == 'prop' and 'prop' or 'propTwo'
                for _, axis in ipairs({'x', 'y', 'z'}) do
                    prop.offset = prop.offset or {}; prop.rotation = prop.rotation or {}
                    local cap = axis:upper()
                    prop.offset[axis] = tonumber(entry[prefix .. 'Offset' .. cap]) or 0
                    prop.rotation[axis] = tonumber(entry[prefix .. 'Rotation' .. cap]) or 0
                end
                data.animation[slot] = prop
            end
        end
    end

    data.canCancel = entry.canCancel ~= false
    ApplyConsumableDefaults(class, entry.item, data)
    local saved, err = SaveConsumable(class, entry.item, data)
    if not saved then return nil, err end
    if data.sharedItem then
        local itemRegistered, itemError = exports.kora_core:registerShared('items', entry.item, data.sharedItem)
        if not itemRegistered then return nil, itemError or 'Could not register item in kora_core' end
    end
    upsertConsumable(class, entry.item, data)
    return {entries = {{class = class, item = entry.item, data = data}}, items = allItems()}
end)

callback('delete', function(_, class, item)
    if not Config.ConsumableClasses[class] or type(item) ~= 'string' or not (Config.Consumables[class] and Config.Consumables[class][item]) then return nil, 'Consumable not found' end
    local ok, err = DisableConsumable(class, item)
    if not ok then return nil, err end
    Config.Consumables[class][item] = nil
    syncConsumableCatalog()
    return true
end)

local function validClass(class)
    return type(class) == 'string' and #class > 0 and #class <= 32 and class:match('^[a-z][a-z0-9_%-]*$') ~= nil
end

callback('classSave', function(_, class, entry)
    if not validClass(class) then return nil, 'Class names must start with a lowercase letter and use only lowercase letters, numbers, underscores or hyphens' end
    if type(entry) ~= 'table' then return nil, 'Invalid class settings' end
    local label = type(entry.label) == 'string' and entry.label:match('^%s*(.-)%s*$') or ''
    if label == '' or #label > 80 then return nil, 'Enter a class label up to 80 characters' end
    local duration = tonumber(entry.duration)
    if not duration or duration < 250 or duration > 120000 then return nil, 'Duration must be between 250 and 120000 milliseconds' end
    local effectDuration = tonumber(entry.effectDuration) or 15000
    if effectDuration < 1000 or effectDuration > 600000 then return nil, 'Effect duration must be between 1000 and 600000 milliseconds' end
    local status = {}
    local submittedStatus = type(entry.status) == 'table' and entry.status or {}
    for _, key in ipairs({'hunger', 'thirst', 'stress', 'health', 'armor', 'drunk', 'high'}) do
        local value = tonumber(submittedStatus[key])
        if value then
            if value < -100 or value > 100 then return nil, key .. ' must be between -100 and 100' end
            status[key] = value
        end
    end
    local animation, emote = nil, nil
    if entry.animationMode == 'emote' then
        emote = type(entry.emote) == 'string' and entry.emote:match('^%s*(.-)%s*$') or ''
        if emote == '' or #emote > 64 then return nil, 'Enter the default kora_emotemenu emote name' end
    else
        local dict = type(entry.animDict) == 'string' and entry.animDict:match('^%s*(.-)%s*$') or ''
        local clip = type(entry.animClip) == 'string' and entry.animClip:match('^%s*(.-)%s*$') or ''
        if dict ~= '' or clip ~= '' then
            if dict == '' or clip == '' then return nil, 'Animation defaults need both a dictionary and a clip' end
            local flag = tonumber(entry.animFlag) or 49
            if flag < 0 or flag > 65535 then return nil, 'Animation flag must be between 0 and 65535' end
            animation = {dict = dict, clip = clip, flag = math.floor(flag)}
        end
    end
    local prop
    local model = type(entry.propModel) == 'string' and entry.propModel:match('^%s*(.-)%s*$') or ''
    if model ~= '' then
        prop = {model = model, bone = math.floor(tonumber(entry.propBone) or 60309), offset = {}, rotation = {}}
        for _, axis in ipairs({'x', 'y', 'z'}) do
            local cap = axis:upper()
            prop.offset[axis] = tonumber(entry['propOffset' .. cap]) or 0
            prop.rotation[axis] = tonumber(entry['propRotation' .. cap]) or 0
        end
    end
    local propTwo
    local modelTwo = type(entry.propTwoModel) == 'string' and entry.propTwoModel:match('^%s*(.-)%s*$') or ''
    if modelTwo ~= '' then
        propTwo = {model = modelTwo, bone = math.floor(tonumber(entry.propTwoBone) or 60309), offset = {}, rotation = {}}
        for _, axis in ipairs({'x', 'y', 'z'}) do
            local cap = axis:upper()
            propTwo.offset[axis] = tonumber(entry['propTwoOffset' .. cap]) or 0
            propTwo.rotation[axis] = tonumber(entry['propTwoRotation' .. cap]) or 0
        end
    end
    local effects = {visual = visuals[entry.visual] and entry.visual or 'none', duration = math.floor(effectDuration)}
    local data = {
        label = label,
        duration = math.floor(duration),
        anim = animation,
        emote = emote,
        prop = prop,
        proptwo = propTwo,
        disable = {move = entry.disableMove == true, combat = entry.disableCombat == true, vehicle = entry.disableVehicle == true},
        status = status,
        effects = effects,
        allowMovement = entry.allowMovement == true,
    }
    local saved, err = SaveConsumableClass(class, data)
    if not saved then return nil, err end
    Config.ConsumableClasses[class] = data
    syncConsumableCatalog()
    return {classes = Config.ConsumableClasses}
end)

callback('classDelete', function(_, class)
    if not validClass(class) or not Config.ConsumableClasses[class] then return nil, 'Class not found' end
    if class == 'custom' then return nil, 'The custom class is reserved for legacy AddCustom integrations' end
    if next(Config.Consumables[class] or {}) then return nil, 'Move or delete this class’s consumables before deleting the class' end
    local disabled, err = DisableConsumableClass(class)
    if not disabled then return nil, err end
    Config.ConsumableClasses[class] = nil
    syncConsumableCatalog()
    return true
end)

local command = Config.CreatorCommand or 'consumableCreator'
Kora.commands.add(command, 'Open the consumables creator', nil, false, function(src)
    if src == 0 then return end
    TriggerClientEvent('kora_consumables:creator:open', src)
end, {
    permission = 'admin',
    checkPermission = function(src, permission)
        return type(src) == 'number' and src > 0
            and Kora.permissions.hasLevel(src, permission, CREATOR_LEVELS, CREATOR_PERMISSION_OPTIONS)
    end,
    resource = GetCurrentResourceName(),
})
