
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
            bone = 28422,
            offset = {x = 0.12, y = 0.008, z = 0.03},
            rotation = {x = 240.0, y = -60.0, z = 0.0}
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
            model = "60309",
            bone = 28422,
            offset = {x = 0.0, y = 0.0, z = -0.02},
            rotation = {x = 30.0, y = 0.0, z = 0.0}
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
        status = {stress = -10, health = -5},
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
            model = "prop_cs_bottle_01",
            bone = 28422,
            offset = {x = 0.01, y = -0.01, z = -0.06},
            rotation = {x = 0.0, y = 0.0, z = 0.0}
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {thirst = 10},
        effects = {visual = 'buzzed', duration = 15000}
    }
}

if not Config.Consumables then
    repeat
        Wait(20)
    until Config.Consumables
end

for k, v in pairs (Config.Consumables) do
    local default = defaults[k]
    for item, data in pairs(v) do
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
        if not data.prop then
            data.prop = default.prop
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
end

-- 'complete' applies the item effect (and consumes the item) only once the use
-- animation finishes; 'start' is the old behaviour of applying it up front.
Config.applyStatusOn = QB.config.enum(Config.applyStatusOn or 'complete', {
    live = true,
    label = 'Apply effects when',
    description = 'Chooses when a consumable takes effect and is used up. Finished applies hunger, thirst and other effects only after the eating, drinking or smoking animation completes, and a cancelled use consumes nothing. Start applies them the moment the item is used, before the animation, and cancelling does not undo them.',
    options = {
        { value = 'complete', label = 'Finished' },
        { value = 'start', label = 'Start' },
    },
})

Config = QB.config.adopt(Config)
