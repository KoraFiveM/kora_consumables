Config.Consumables = Config.Consumables or {}
Config.ConsumableClasses = Config.ConsumableClasses or {}

local classLabels = {
    drink = 'progress.drink',
    food = 'progress.food',
    smoke = 'progress.smoke',
    liquor = 'progress.liquor',
    custom = 'progress.custom',
}

local function classDefault(class)
    return Config.ConsumableClasses[class] or Config.ConsumableClasses.custom or {}
end

local function classLabel(class)
    local default = Config.ConsumableClasses[class]
    if default and type(default.label) == 'string' and default.label ~= '' then
        return default.label
    end
    return Kora.lang(classLabels[class] or 'progress.custom')
end

local function resolveProp(base, own)
    if type(base) ~= 'table' then return own end

    local merged = {}
    local attach = base.hands and (base.hands[base.hand] or base.hands.default)
    for key, value in pairs(base) do
        if key ~= 'hands' and key ~= 'hand' then merged[key] = value end
    end
    for key, value in pairs(attach or {}) do merged[key] = value end
    for key, value in pairs(own or {}) do merged[key] = value end
    return merged
end

function ConsumableClassLabel(class)
    return classLabel(class)
end

function ApplyConsumableDefaults(class, item, data)
    local default = classDefault(class)
    if data.emote == nil then data.emote = default.emote end
    if not data.label then
        local definition = exports.kora_core:getShared('items', item)
        data.label = classLabel(class) .. (definition and definition.label or '')
    end
    if not data.duration then data.duration = default.duration end
    if not data.anim then data.anim = default.anim end
    if data.prop == nil then
        data.prop = resolveProp(default.prop)
    elseif type(data.prop) == 'table' and not data.prop.coords and default.prop then
        data.prop = resolveProp(default.prop, data.prop)
    end
    if data.proptwo == nil then data.proptwo = default.proptwo end
    if not data.disable then data.disable = default.disable end
    if not data.status then data.status = default.status end
    if not data.effects then data.effects = default.effects end
end

function ConsumableLabel(class, item, data)
    local prefix = classLabel(class)
    if data.label == prefix then
        local definition = exports.kora_core:getShared('items', item)
        if definition and definition.label then return prefix .. definition.label end
    end
    return data.label
end

-- 'complete' applies the item effect (and consumes the item) only once the use
-- animation finishes; 'start' is the old behaviour of applying it up front.
Config.applyStatusOn = Kora.config.enum(Config.applyStatusOn or 'complete', {
    live = true,
    label = 'Apply effects when',
    description = 'Chooses when a consumable takes effect and is used up. '
        .. 'Finished applies hunger, thirst and other effects only after the eating, '
        .. 'drinking or smoking animation completes, and a cancelled use consumes nothing. '
        .. 'Start applies them the moment the item is used, before the animation, '
        .. 'and cancelling does not undo them.',
    options = {
        {value = 'complete', label = 'Finished'},
        {value = 'start', label = 'Start'},
    },
})

Config = Kora.config.adopt(Config)
