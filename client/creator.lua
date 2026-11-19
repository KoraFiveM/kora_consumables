local APP_ID = 'kora_consumables:creator'
local state = {entries = {}, items = {}, classes = {}}
local selectedItem, selectedClass, createClass
local itemStatusDraft, classStatusDraft = {}, {}
local createItemName
local itemSearch = {query = '', results = {}}
local statusKeys = {'hunger', 'thirst', 'stress', 'health', 'armor', 'drunk', 'high'}
local disableOptions = {{value = 'move', label = 'Movement'}, {value = 'combat', label = 'Combat'}, {value = 'vehicle', label = 'Vehicle'}}
local itemOptionFields = {
    {value = 'canCancel', label = 'Can cancel'},
    {value = 'useWhileDead', label = 'Use while dead'},
    {value = 'canMove', label = 'Can move while using'},
    {value = 'keep', label = 'Keep item on use'},
    {value = 'disableMove', label = 'Disable movement controls'},
    {value = 'disableCombat', label = 'Disable combat'},
    {value = 'disableVehicle', label = 'Disable vehicle use'},
}

local function notify(message)
    Kora.notify.send({title = 'Consumable Creator', message = message, type = 'error'})
end

local function classOptions()
    local options = {}
    for class, defaults in pairs(state.classes or {}) do options[#options + 1] = {value = class, label = defaults.label or class} end
    table.sort(options, function(a, b) return a.value < b.value end)
    return options
end

local function entryFor(class, item)
    for _, entry in ipairs(state.entries) do
        if entry.class == class and entry.item == item then return entry end
    end
end

local function itemDefinition(item)
    for _, definition in ipairs(state.items) do if definition.name == item then return definition end end
end

local function itemImage(item)
    local definition = itemDefinition(item)
    return definition and (definition.artwork or definition.imageUrl or definition.image) or nil
end

local function disableList(disable, movement)
    local result = {}
    if disable.move == true or movement == false then result[#result + 1] = 'move' end
    if disable.combat == true then result[#result + 1] = 'combat' end
    if disable.vehicle == true or disable.car == true then result[#result + 1] = 'vehicle' end
    return result
end

local function itemOptionValues(data, disable, movement)
    local selected = {}
    if data.canCancel ~= false then selected[#selected + 1] = 'canCancel' end
    if data.useWhileDead == true then selected[#selected + 1] = 'useWhileDead' end
    if movement == true then selected[#selected + 1] = 'canMove' end
    if data.keep == true then selected[#selected + 1] = 'keep' end
    if disable.move == true then selected[#selected + 1] = 'disableMove' end
    if disable.combat == true then selected[#selected + 1] = 'disableCombat' end
    if disable.vehicle == true or disable.car == true then selected[#selected + 1] = 'disableVehicle' end
    return selected
end

local function itemFields(entry, createClass, createItem)
    local data = entry and entry.data or {}
    local item = entry and entry.item or createItem or ''
    local class = entry and entry.class or createClass or (classOptions()[1] and classOptions()[1].value) or 'custom'
    local definition = itemDefinition(item) or {}
    local classDefaults = state.classes[class] or state.classes.custom or {}
    local animation = data.animation or {}
    local defaultAnimation = classDefaults.anim or {}
    local animationMode = animation.mode
    if not animationMode then
        if data.emote or classDefaults.emote then
            animationMode = 'emote'
        elseif data.anim or defaultAnimation.dict or defaultAnimation.clip then
            animationMode = 'animation'
        else
            animationMode = 'emote'
        end
    end
    local prop = animation.prop or data.prop or classDefaults.prop or {}
    local proptwo = animation.proptwo or data.proptwo or classDefaults.proptwo or {}
    local effects = data.effects or classDefaults.effects or {}
    local disable = data.disable or classDefaults.disable or {}
    local allowMovement = data.allowMovement
    if allowMovement == nil then allowMovement = classDefaults.allowMovement end
    if allowMovement == nil then allowMovement = true end

    local fields = {}
    fields[#fields + 1] = {id = 'label', label = 'Progress label', type = 'text', required = true, default = data.label or ((classDefaults.label or '') .. (definition.label or item))}
    fields[#fields + 1] = {id = 'duration', label = 'Duration (ms)', type = 'number', min = 250, max = 120000, default = data.duration or classDefaults.duration or 4000}
    fields[#fields + 1] = {id = 'useOptions', label = 'Use Options', type = 'multiselect', options = itemOptionFields, default = itemOptionValues(data, disable, allowMovement)}
    fields[#fields + 1] = {id = 'visual', label = 'Visual effect', type = 'select', default = effects.visual or 'none', options = {
        {value = 'none', label = 'None'}, {value = 'buzzed', label = 'Buzzed'}, {value = 'alien', label = 'Alien'}, {value = 'coke', label = 'Coke'}, {value = 'crack', label = 'Crack'}, {value = 'meth', label = 'Meth'}, {value = 'trevor', label = 'Trevor'},
    }}
    fields[#fields + 1] = {id = 'effectDuration', label = 'Effect duration (ms)', type = 'number', min = 1000, max = 600000, default = effects.duration or 15000}
    fields[#fields + 1] = {id = 'animationMode', label = 'Animation setup', type = 'select', default = animationMode, options = {{value = 'emote', label = 'Emote'}, {value = 'animation', label = 'Animation set'}}}
    fields[#fields + 1] = {id = 'emote', label = 'kora_emotemenu emote name', type = 'text', default = animation.emote or data.emote or classDefaults.emote or '', visibleWhen = {fieldId = 'animationMode', equals = 'emote'}}
    fields[#fields + 1] = {id = 'animDict', label = 'Animation dictionary', type = 'text', default = animation.dict or (data.anim and data.anim.dict) or defaultAnimation.dict or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'animClip', label = 'Animation name / clip', type = 'text', default = animation.clip or (data.anim and data.anim.clip) or defaultAnimation.clip or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'animFlag', label = 'Animation flag', type = 'number', min = 0, max = 65535, default = animation.flag or (data.anim and data.anim.flag) or defaultAnimation.flag or 49, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propModel', label = 'Prop model', type = 'text', default = prop.model or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propBone', label = 'Prop bone', type = 'number', min = 0, max = 65535, default = prop.bone or 60309, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    for _, axis in ipairs({'X', 'Y', 'Z'}) do
        local lower = axis:lower()
        fields[#fields + 1] = {id = 'propOffset' .. axis, label = 'Prop offset ' .. axis, type = 'number', default = prop.offset and prop.offset[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propRotation' .. axis, label = 'Prop rotation ' .. axis, type = 'number', default = prop.rotation and prop.rotation[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propTwoOffset' .. axis, label = 'Second prop offset ' .. axis, type = 'number', default = proptwo.offset and proptwo.offset[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propTwoRotation' .. axis, label = 'Second prop rotation ' .. axis, type = 'number', default = proptwo.rotation and proptwo.rotation[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    end
    fields[#fields + 1] = {id = 'propTwoModel', label = 'Second prop model', type = 'text', default = proptwo.model or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propTwoBone', label = 'Second prop bone', type = 'number', min = 0, max = 65535, default = proptwo.bone or 60309, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    return fields
end

local function classFields(class, defaults)
    defaults = defaults or {}
    local animation = defaults.anim or {}
    local prop = defaults.prop or {}
    local propTwo = defaults.proptwo or {}
    local disable = defaults.disable or {}
    local effects = defaults.effects or {}
    local movement = defaults.allowMovement
    if movement == nil then movement = true end
    local animationMode = defaults.emote and 'emote' or (animation.dict or animation.clip) and 'animation' or 'emote'
    local fields = {}
    if not class then fields[#fields + 1] = {id = 'class', label = 'Class key (lowercase)', type = 'text', required = true} end
    fields[#fields + 1] = {id = 'label', label = 'Progress label prefix', type = 'text', required = true, default = defaults.label or ''}
    fields[#fields + 1] = {id = 'duration', label = 'Default duration (ms)', type = 'number', min = 250, max = 120000, default = defaults.duration or 4000}
    fields[#fields + 1] = {id = 'disable', label = 'Disable While Using', type = 'multiselect', options = disableOptions, default = disableList(disable, movement)}
    fields[#fields + 1] = {id = 'animationMode', label = 'Default animation setup', type = 'select', default = animationMode, options = {{value = 'emote', label = 'Emote'}, {value = 'animation', label = 'Animation set'}}}
    fields[#fields + 1] = {id = 'emote', label = 'Default kora_emotemenu emote name', type = 'text', default = defaults.emote or '', visibleWhen = {fieldId = 'animationMode', equals = 'emote'}}
    fields[#fields + 1] = {id = 'animDict', label = 'Default animation dictionary', type = 'text', default = animation.dict or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'animClip', label = 'Default animation clip', type = 'text', default = animation.clip or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'animFlag', label = 'Default animation flag', type = 'number', min = 0, max = 65535, default = animation.flag or 49, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propModel', label = 'Default prop model', type = 'text', default = prop.model or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propBone', label = 'Default prop bone', type = 'number', min = 0, max = 65535, default = prop.bone or 60309, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propTwoModel', label = 'Default second prop model', type = 'text', default = propTwo.model or '', visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    fields[#fields + 1] = {id = 'propTwoBone', label = 'Default second prop bone', type = 'number', min = 0, max = 65535, default = propTwo.bone or 60309, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    for _, axis in ipairs({'X', 'Y', 'Z'}) do
        local lower = axis:lower()
        fields[#fields + 1] = {id = 'propOffset' .. axis, label = 'Prop offset ' .. axis, type = 'number', default = prop.offset and prop.offset[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propRotation' .. axis, label = 'Prop rotation ' .. axis, type = 'number', default = prop.rotation and prop.rotation[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propTwoOffset' .. axis, label = 'Second prop offset ' .. axis, type = 'number', default = propTwo.offset and propTwo.offset[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
        fields[#fields + 1] = {id = 'propTwoRotation' .. axis, label = 'Second prop rotation ' .. axis, type = 'number', default = propTwo.rotation and propTwo.rotation[lower] or 0, visibleWhen = {fieldId = 'animationMode', equals = 'animation'}}
    end
    fields[#fields + 1] = {id = 'visual', label = 'Default visual effect', type = 'select', default = effects.visual or 'none', options = {
        {value = 'none', label = 'None'}, {value = 'buzzed', label = 'Buzzed'}, {value = 'alien', label = 'Alien'}, {value = 'coke', label = 'Coke'}, {value = 'crack', label = 'Crack'}, {value = 'meth', label = 'Meth'}, {value = 'trevor', label = 'Trevor'},
    }}
    fields[#fields + 1] = {id = 'effectDuration', label = 'Default effect duration (ms)', type = 'number', min = 1000, max = 600000, default = effects.duration or 15000}
    return fields
end

local function copyStatus(status)
    local result = {}
    for _, key in ipairs(statusKeys) do
        local value = status and tonumber(status[key])
        if value ~= nil then result[key] = value end
    end
    return result
end

local function statusBlocks(status, prefix, title, actionId)
    local options, cards = {}, {}
    for _, key in ipairs(statusKeys) do
        options[#options + 1] = {value = key, label = key:sub(1, 1):upper() .. key:sub(2)}
        local value = status[key]
        if value ~= nil then
            cards[#cards + 1] = {
                id = key,
                label = key:sub(1, 1):upper() .. key:sub(2),
                description = ('%+g'):format(value),
                actions = {{id = prefix .. ':remove:' .. key, label = 'Remove', variant = 'destructive'}},
            }
        end
    end
    return {
        {type = 'form', id = prefix .. '-change-add', title = 'Add a ' .. title .. ' change', fields = {
            {id = 'key', label = 'Change', type = 'select', default = options[1].value, options = options},
            {id = 'amount', label = 'Amount', type = 'number', min = -100, max = 100, default = 0, required = true},
        }, action = {id = actionId, label = 'Add change'}},
        {type = 'list', id = prefix .. '-changes', title = title, layout = 'cards', columns = 2, items = cards, empty = 'No changes added.'},
    }
end

local function navigation()
    local itemGroups = {}
    for _, entry in ipairs(state.entries) do
        itemGroups[entry.class] = itemGroups[entry.class] or {}
        itemGroups[entry.class][#itemGroups[entry.class] + 1] = {
            id = entry.class .. ':' .. entry.item,
            label = entry.data.label or entry.item,
            description = ('%s · %s'):format(entry.class, entry.item),
            image = itemImage(entry.item),
            metadata = {{label = 'Duration', value = ('%d ms'):format(entry.data.duration or 0)}},
            actions = {
                {id = 'item:select:' .. entry.class .. ':' .. entry.item, label = 'Edit'},
                {id = 'item:delete:' .. entry.class .. ':' .. entry.item, label = 'Delete', variant = 'destructive', confirm = 'Delete this consumable? Its shared inventory item will remain registered.'},
            },
        }
    end
    local itemBlocks = {}
    local itemClasses = {}
    for class in pairs(itemGroups) do itemClasses[#itemClasses + 1] = class end
    table.sort(itemClasses, function(a, b)
        local labelA = ((state.classes[a] and state.classes[a].label) or a):lower()
        local labelB = ((state.classes[b] and state.classes[b].label) or b):lower()
        return labelA == labelB and a < b or labelA < labelB
    end)
    for _, class in ipairs(itemClasses) do
        local defaults = state.classes[class] or {}
        itemBlocks[#itemBlocks + 1] = {type = 'list', id = 'item-catalog-' .. class, title = defaults.label or class, layout = 'cards', columns = 2, items = itemGroups[class], empty = 'No consumables in this class.'}
    end
    if #itemBlocks == 0 then
        itemBlocks[1] = {type = 'list', id = 'item-catalog-empty', title = 'Saved consumables', layout = 'cards', columns = 2, items = {}, empty = 'No consumables are saved.'}
    end
    local classCards = {}
    for class, defaults in pairs(state.classes or {}) do
        local count = 0
        for _, entry in ipairs(state.entries) do if entry.class == class then count = count + 1 end end
        classCards[#classCards + 1] = {
            id = class,
            label = defaults.label or class,
            description = class,
            metadata = {{label = 'Consumables', value = tostring(count)}, {label = 'Default duration', value = ('%d ms'):format(defaults.duration or 0)}},
            actions = {
                {id = 'class:select:' .. class, label = 'Edit defaults'},
                {id = 'class:delete:' .. class, label = 'Delete', variant = 'destructive', disabled = class == 'custom', confirm = 'Delete this class? Classes with consumables cannot be deleted.'},
            },
        }
    end
    table.sort(classCards, function(a, b) return a.id < b.id end)

    local createItemBlocks = {}
    if createClass and state.classes[createClass] then
        createItemBlocks[#createItemBlocks + 1] = {type = 'actions', title = 'New item', actions = {{id = 'item:changeClass', label = 'Choose a different class', variant = 'secondary'}}}
        if createItemName then
            local definition = itemDefinition(createItemName) or {}
            createItemBlocks[#createItemBlocks + 1] = {type = 'actions', title = 'Shared item: ' .. (definition.label or createItemName), actions = {{id = 'item:changeItem', label = 'Choose a different shared item', variant = 'secondary'}}}
            createItemBlocks[#createItemBlocks + 1] = {type = 'list', id = 'item-picked', title = 'Selected shared item', layout = 'cards', columns = 1, items = {{id = createItemName, label = definition.label or createItemName, description = createItemName, image = itemImage(createItemName)}}}
            createItemBlocks[#createItemBlocks + 1] = {type = 'form', id = 'item-create', title = 'Create a usable item · ' .. createClass, fields = itemFields(nil, createClass, createItemName), action = {id = 'item:create', label = 'Create consumable'}}
        else
            createItemBlocks[#createItemBlocks + 1] = {type = 'form', id = 'item-search', title = 'Find a shared item', fields = {{id = 'query', label = 'Search by item name or display name', type = 'text', default = itemSearch.query, required = true}}, action = {id = 'item:search', label = 'Search items'}}
            if itemSearch.query ~= '' then
                local resultCards = {}
                for _, result in ipairs(itemSearch.results) do
                    resultCards[#resultCards + 1] = {id = result.name, label = result.label, description = result.name, image = result.image, actions = {{id = 'item:pick:' .. result.name, label = 'Select'}}}
                end
                createItemBlocks[#createItemBlocks + 1] = {type = 'list', id = 'item-search-results', title = 'Shared item results', layout = 'cards', columns = 3, items = resultCards, empty = 'No matching shared items.'}
            end
        end
    else
        createItemBlocks[#createItemBlocks + 1] = {type = 'form', id = 'item-class', title = 'Choose a class for the new item', fields = {
            {id = 'class', label = 'Class', type = 'select', default = classOptions()[1] and classOptions()[1].value, options = classOptions()},
        }, action = {id = 'item:chooseClass', label = 'Continue'}}
    end
    if createClass and createItemName then
        for _, block in ipairs(statusBlocks(itemStatusDraft, 'item:status', 'Hunger, thirst and other status changes', 'item:status:add')) do createItemBlocks[#createItemBlocks + 1] = block end
    end

    local classBlocks = {}
    if selectedClass and state.classes[selectedClass] then
        classBlocks[#classBlocks + 1] = {
            type = 'form', id = 'class-edit:' .. selectedClass, title = 'Edit class: ' .. selectedClass,
            fields = classFields(selectedClass, state.classes[selectedClass]), action = {id = 'class:save', label = 'Save class defaults'},
        }
    end
    if selectedClass then
        for _, block in ipairs(statusBlocks(classStatusDraft, 'class:status', 'Class default changes', 'class:status:add')) do classBlocks[#classBlocks + 1] = block end
    end
    classBlocks[#classBlocks + 1] = {type = 'list', id = 'class-catalog', title = 'Classes and their defaults', layout = 'cards', columns = 2, items = classCards, empty = 'No classes are configured.'}

    local createClassBlocks = {
        {type = 'form', id = 'class-create', title = 'Create a class', fields = classFields(nil, {}), action = {id = 'class:create', label = 'Create class'}},
    }
    for _, block in ipairs(statusBlocks(classStatusDraft, 'class:status', 'Class default changes', 'class:status:add')) do createClassBlocks[#createClassBlocks + 1] = block end

    local views = {
        {id = 'items', label = 'Consumables', icon = 'Utensils', content = {title = 'Consumable Creator', blocks = itemBlocks}},
        {id = 'classes', label = 'Classes', icon = 'Tags', content = {title = 'Consumable Classes', blocks = classBlocks}},
        {id = 'create-item', label = 'Create Item', icon = 'Plus', onOpen = 'item:createOpen', content = {title = 'Create Consumable', blocks = createItemBlocks}},
        {id = 'create-class', label = 'Create Class', icon = 'Plus', onOpen = 'class:createOpen', content = {title = 'Create Consumable Class', blocks = createClassBlocks}},
    }
    if selectedItem then
        local entry = entryFor(selectedItem.class, selectedItem.item)
        if entry then
            local definition = itemDefinition(selectedItem.item) or {}
            local editBlocks = {
                {type = 'list', id = 'item-edit-image', title = 'Shared item', layout = 'cards', columns = 1, items = {{id = selectedItem.item, label = definition.label or selectedItem.item, description = selectedItem.item, image = itemImage(selectedItem.item)}}},
                {type = 'form', id = 'item-edit:' .. selectedItem.class .. ':' .. selectedItem.item, title = 'Edit consumable', fields = itemFields(entry), action = {id = 'item:save', label = 'Save changes'}},
            }
            for _, block in ipairs(statusBlocks(itemStatusDraft, 'item:status', 'Hunger, thirst and other status changes', 'item:status:add')) do editBlocks[#editBlocks + 1] = block end
            views[#views + 1] = {id = 'item-edit', label = selectedItem.item .. ' Edit', icon = 'Pencil', content = {title = 'Edit ' .. selectedItem.item, blocks = editBlocks}}
        end
    end
    return views
end

local function refresh()
    Kora.nui.updateApp(APP_ID, {navigation = navigation()})
end

local function normalizeItem(values)
    local disabled = {}
    for _, key in ipairs(type(values.useOptions) == 'table' and values.useOptions or {}) do disabled[key] = true end
    values.canCancel = disabled.canCancel == true
    values.useWhileDead = disabled.useWhileDead == true
    values.keep = disabled.keep == true
    values.allowMovement = disabled.canMove == true
    values.disableMove, values.disableCombat, values.disableVehicle = disabled.disableMove == true, disabled.disableCombat == true, disabled.disableVehicle == true
    values.useOptions = nil
    for _, key in ipairs({'weight', 'duration', 'effectDuration', 'animFlag', 'propBone', 'propTwoBone', 'propOffsetX', 'propOffsetY', 'propOffsetZ', 'propRotationX', 'propRotationY', 'propRotationZ', 'propTwoOffsetX', 'propTwoOffsetY', 'propTwoOffsetZ', 'propTwoRotationX', 'propTwoRotationY', 'propTwoRotationZ'}) do
        values[key] = tonumber(values[key])
    end
    return values
end

local function normalizeClass(values)
    for _, key in ipairs({'duration', 'effectDuration', 'animFlag', 'propBone', 'propTwoBone', 'propOffsetX', 'propOffsetY', 'propOffsetZ', 'propRotationX', 'propRotationY', 'propRotationZ', 'propTwoOffsetX', 'propTwoOffsetY', 'propTwoOffsetZ', 'propTwoRotationX', 'propTwoRotationY', 'propTwoRotationZ'}) do
        values[key] = tonumber(values[key])
    end
    local disabled = {}
    for _, key in ipairs(type(values.disable) == 'table' and values.disable or {}) do disabled[key] = true end
    values.disableMove, values.disableCombat, values.disableVehicle = disabled.move == true, disabled.combat == true, disabled.vehicle == true
    values.allowMovement = not values.disableMove
    values.disable = nil
    return values
end

local function onAction(actionId, context)
    local values = context and context.value or {}
    if actionId == 'item:createOpen' then
        createClass, createItemName = nil, nil
        itemSearch = {query = '', results = {}}
        itemStatusDraft = {}
        refresh()
        return
    end
    if actionId == 'class:createOpen' then
        selectedClass = nil
        classStatusDraft = {}
        refresh()
        return
    end
    if actionId == 'item:chooseClass' then
        if not state.classes[values.class] then notify('Choose a valid class'); return end
        createClass = values.class
        createItemName = nil
        itemSearch = {query = '', results = {}}
        itemStatusDraft = copyStatus(state.classes[createClass].status)
        refresh()
        return
    end
    if actionId == 'item:changeClass' then
        createClass = nil
        createItemName = nil
        itemStatusDraft = {}
        refresh()
        return
    end
    if actionId == 'item:changeItem' then
        createItemName = nil
        itemStatusDraft = copyStatus(state.classes[createClass] and state.classes[createClass].status)
        refresh()
        return
    end
    if actionId == 'item:search' then
        local query = type(values.query) == 'string' and values.query:match('^%s*(.-)%s*$') or ''
        if query == '' then notify('Enter an item name or display name to search'); return end
        local result, err = Kora.callback.trigger('kora_consumables:creator:searchItems', query)
        if not result then notify(err or 'Could not search shared items'); return end
        itemSearch = {query = query, results = result.results or {}}
        refresh()
        return
    end
    local pickedItem = actionId:match('^item:pick:(.+)$')
    if pickedItem then
        local found
        for _, result in ipairs(itemSearch.results) do if result.name == pickedItem then found = result break end end
        if not found then notify('Search for the shared item again'); return end
        createItemName = found.name
        itemStatusDraft = copyStatus(state.classes[createClass] and state.classes[createClass].status)
        refresh()
        return
    end
    local statusKey = actionId:match('^item:status:remove:(.+)$')
    if statusKey then itemStatusDraft[statusKey] = nil; refresh(); return end
    if actionId == 'item:status:add' then
        local amount = tonumber(values.amount)
        if not ({hunger = true, thirst = true, stress = true, health = true, armor = true, drunk = true, high = true})[values.key] then notify('Choose a valid change'); return end
        if not amount or amount < -100 or amount > 100 then notify('Amount must be between -100 and 100'); return end
        itemStatusDraft[values.key] = amount
        refresh()
        return
    end
    statusKey = actionId:match('^class:status:remove:(.+)$')
    if statusKey then classStatusDraft[statusKey] = nil; refresh(); return end
    if actionId == 'class:status:add' then
        local amount = tonumber(values.amount)
        if not ({hunger = true, thirst = true, stress = true, health = true, armor = true, drunk = true, high = true})[values.key] then notify('Choose a valid change'); return end
        if not amount or amount < -100 or amount > 100 then notify('Amount must be between -100 and 100'); return end
        classStatusDraft[values.key] = amount
        refresh()
        return
    end
    if actionId == 'item:create' then
        values.class, values.item = createClass, createItemName
        values.status = copyStatus(itemStatusDraft)
        local saved, err = Kora.callback.trigger('kora_consumables:creator:save', normalizeItem(values))
        if not saved then notify(err or 'Could not save consumable'); return end
        state = Kora.callback.trigger('kora_consumables:creator:get') or state
        selectedItem = {class = values.class, item = values.item}
        createClass, createItemName = nil, nil
        refresh()
        return {navigate = {viewId = 'item-edit'}}
    end
    if actionId == 'item:save' then
        if not selectedItem then return end
        values.item, values.class = selectedItem.item, selectedItem.class
        values.status = copyStatus(itemStatusDraft)
        local saved, err = Kora.callback.trigger('kora_consumables:creator:save', normalizeItem(values))
        if not saved then notify(err or 'Could not save consumable'); return end
        state = Kora.callback.trigger('kora_consumables:creator:get') or state
        refresh()
        return {navigate = {viewId = 'item-edit'}}
    end
    if actionId == 'class:create' or actionId == 'class:save' then
        local class = actionId == 'class:save' and selectedClass or values.class
        if not class then notify('Enter a class key'); return end
        values.status = copyStatus(classStatusDraft)
        local saved, err = Kora.callback.trigger('kora_consumables:creator:classSave', class, normalizeClass(values))
        if not saved then notify(err or 'Could not save class'); return end
        state = Kora.callback.trigger('kora_consumables:creator:get') or state
        selectedClass = class
        refresh()
        return {navigate = {viewId = 'classes'}}
    end

    local class, item = actionId:match('^item:select:([^:]+):(.+)$')
    if class then
        selectedItem = {class = class, item = item}
        local entry = entryFor(class, item)
        if not entry then selectedItem = nil; return end
        itemStatusDraft = copyStatus(entry and entry.data.status)
        refresh()
        return {navigate = {viewId = 'item-edit'}}
    end
    class, item = actionId:match('^item:delete:([^:]+):(.+)$')
    if class then
        local ok, err = Kora.callback.trigger('kora_consumables:creator:delete', class, item)
        if not ok then notify(err or 'Could not delete consumable'); return end
        local removedSelection = selectedItem and selectedItem.class == class and selectedItem.item == item
        if removedSelection then selectedItem = nil; itemStatusDraft = {} end
        state = Kora.callback.trigger('kora_consumables:creator:get') or state
        refresh()
        if removedSelection then return {navigate = {viewId = 'items'}} end
        return
    end
    class = actionId:match('^class:select:(.+)$')
    if class then
        selectedClass = class
        classStatusDraft = copyStatus(state.classes[class] and state.classes[class].status)
        refresh()
        return
    end
    class = actionId:match('^class:delete:(.+)$')
    if class then
        local ok, err = Kora.callback.trigger('kora_consumables:creator:classDelete', class)
        if not ok then notify(err or 'Could not delete class'); return end
        if selectedClass == class then selectedClass = nil; classStatusDraft = {} end
        state = Kora.callback.trigger('kora_consumables:creator:get') or state
        refresh()
    end
end

Kora.nui.registerApp({
    id = APP_ID, title = 'Consumable Creator', icon = 'Utensils', layout = 'standard', width = 1100, height = 800,
    defaultView = 'items', navigation = {
        {id = 'items', label = 'Consumables', icon = 'Utensils', content = {title = 'Consumable Creator', blocks = {}}},
        {id = 'classes', label = 'Classes', icon = 'Tags', content = {title = 'Consumable Classes', blocks = {}}},
    },
    onAction = onAction,
})

RegisterNetEvent('kora_consumables:creator:open', function()
    if source ~= 65535 then return end
    local result, err = Kora.callback.trigger('kora_consumables:creator:get')
    if not result then notify(err or 'You do not have permission'); return end
    state = result
    selectedItem, selectedClass, createClass, createItemName = nil, nil, nil, nil
    itemSearch = {query = '', results = {}}
    itemStatusDraft, classStatusDraft = {}, {}
    refresh()
    Kora.nui.openApp(APP_ID, {viewId = 'items'})
end)
