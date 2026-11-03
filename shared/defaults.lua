
local defaults = {
    drink = {
        label = 'Drinking ',
        duration = 4000,
        anim = {
            dict = "mp_player_intdrink",
            clip = "loop_bottle"
        },
        prop = {
            model = "prop_ld_flow_bottle",
            -- mp_player_intdrink raises the LEFT hand to the mouth, so the bottle follows it.
            hands = {
                left = {bone = 60309, offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 0.0}},
                right = {bone = 28422, offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 130.0}}
            },
            hand = "left"
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {thirst = 20}
    },
    food = {
        label = 'Eating ',
        duration = 4000,
        anim = {
            dict = "mp_player_inteat@burger",
            clip = "mp_player_int_eat_burger",
            flag = 49
        },
        prop = {
            model = "prop_cs_burger_01",
            -- mp_player_inteat@burger brings the LEFT hand to the mouth, so the food follows it.
            hands = {
                left = {bone = 60309, offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 0.0}},
                right = {bone = 28422, offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 130.0}}
            },
            hand = "left"
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {hunger = 20}
    },
    smoke = {
        label = 'Smoking ',
        duration = 4000,
        anim = {
            dict = "mp_player_int_smoke",
            clip = "loop"
        },
        status = {stress = -10},
        disable = {move = true, combat = true, vehicle = true},
        effects = {visual = 'alien', duration = 15000}
    },
    liquor = {
        label = 'Drinking ',
        duration = 4000,
        anim = {
            dict = "amb@world_human_drinking@coffee@male@idle_a",
            clip = "idle_c"
        },
        prop = {
            model = "prop_cs_beer_bot_01",
            -- The coffee idle_c clip is a right-handed drink.
            hands = {
                left = {bone = 60309, offset = {x = -0.01, y = -0.01, z = -0.06}, rotation = {x = 0.0, y = 0.0, z = 0.0}},
                right = {bone = 28422, offset = {x = 0.01, y = -0.01, z = -0.06}, rotation = {x = 0.0, y = 0.0, z = 0.0}}
            },
            hand = "right"
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {thirst = 10},
        effects = {visual = 'buzzed', duration = 15000}
    }
}

-- Class default attachment for the configured hand, then Config.propBone, then whatever the
-- item sets itself (bone, offset, rotation).
local function classSetting(setting, class, fallback)
    if type(setting) == "table" then setting = setting[class] end
    if setting == nil then return fallback end
    return setting
end

local function resolveProp(base, class, own)
    if not base then return nil end
    local merged = {}
    local hand = classSetting(Config.propHand, class, base.hand)
    local attach = base.hands and (base.hands[hand] or base.hands[base.hand])
    for key, value in pairs(base) do
        if key ~= "hands" and key ~= "hand" then merged[key] = value end
    end
    for key, value in pairs(attach or {}) do merged[key] = value end
    merged.bone = classSetting(Config.propBone, class, merged.bone)
    for key, value in pairs(own or {}) do merged[key] = value end
    return merged
end

defaults.custom = {
    label = 'Using ',
    duration = 4000,
    disable = {move = true, combat = true, vehicle = true}
}

function ApplyConsumableDefaults(class, item, data)
    local default = defaults[class]
    if not data.label then
        local definition = exports.kora_core:getShared('items', item)
        data.label = default.label .. (definition and definition.label or "")
    end
    if not data.duration then
        data.duration = default.duration
    end
    if not data.anim then
        data.anim = default.anim
    end
    if data.prop == nil then
        data.prop = resolveProp(default.prop, class, nil)
    elseif type(data.prop) == "table" and not data.prop.coords and default.prop then
        -- A partial prop (for example only a model) inherits the class bone, offset and rotation.
        data.prop = resolveProp(default.prop, class, data.prop)
    end
    if not data.disable then
        data.disable = default.disable
    end
    if not data.status then
        data.status = default.status
    end
    if not data.effects then
        data.effects = default.effects
    end
end

for class, items in pairs(Config.Consumables) do
    for item, data in pairs(items) do
        ApplyConsumableDefaults(class, item, data)
    end
end

-- 'complete' applies the item effect (and consumes the item) only once the use
-- animation finishes; 'start' is the old behaviour of applying it up front.
Config.applyStatusOn = Kora.config.enum(Config.applyStatusOn or 'complete', {
    live = true,
    label = 'Apply effects when',
    description = 'Chooses when a consumable takes effect and is used up. Finished applies hunger, thirst and other effects only after the eating, drinking or smoking animation completes, and a cancelled use consumes nothing. Start applies them the moment the item is used, before the animation, and cancelling does not undo them.',
    options = {
        { value = 'complete', label = 'Finished' },
        { value = 'start', label = 'Start' },
    },
})

Config = Kora.config.adopt(Config)
