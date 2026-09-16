
local defaults = {
    drink = {
        label = 'Drinking ',
        duration = 4000,
        anim = {
            dict = "mp_player_intdrink",
            clip = "loop_bottle"
        },
        prop = {
            model = "prop_cs_bottle_01",
            bone = 28422,
            offset = {x = 0.0, y = 0.0, z = 0.0},
            rotation = {x = 0.0, y = 0.0, z = 0.0}
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {thirst = 10}
    },
    food = {
        label = 'Eating ',
        duration = 4000,
        anim = {
            dict = "mp_player_inteat",
            clip = "loop_bite"
        },
        prop = {
            model = "prop_cs_burger_01",
            bone = 28422,
            offset = {x = 0.0, y = 0.0, z = 0.0},
            rotation = {x = 0.0, y = 0.0, z = 0.0}
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {hunger = 10}
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
        effects = 'alien'
    },
    liquor = {
        label = 'Drinking ',
        duration = 4000,
        anim = {
            dict = "mp_player_intdrink",
            clip = "loop_bottle"
        },
        prop = {
            model = "prop_cs_bottle_01",
            bone = 28422,
            offset = {x = 0.0, y = 0.0, z = 0.0},
            rotation = {x = 0.0, y = 0.0, z = 0.0}
        },
        disable = {move = true, combat = true, vehicle = true},
        status = {drunk = 10},
        effects = 'buzzed'
    }
}

local Items = exports['qb-core']:GetShared('Items')

if not Config.Consumables then
    repeat
        Wait(20)
    until Config.Consumables
end

for k, v in pairs (Config.Consumables) do
    local default = defaults[k]
    for item, data in pairs(v) do
        if not data.label then
            data.label = default.label .. (Items[item] and Items[item].label or "")
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
Items = nil