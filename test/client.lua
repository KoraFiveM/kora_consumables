-- Run from the resource directory: lua test/client.lua
-- Check actual callback payloads; live model loading and natives are not emulated.
local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, ('%s: expected %s, got %s'):format(message or 'values differ', tostring(expected), tostring(actual)))
    checks = checks + 1
end
local callback, payload

local completed = true
local visuals = {}
local events = {}
exports = { kora_core = { getShared = function() return {} end } }
QB = {
    callback = { register = function(name, handler)
        equal(name, 'qbconsumables:progress')
        callback = handler
    end },
    config = {
        enum = function(value, options) return { value = value, options = options } end,
        adopt = function(config) return config end,
    },
    progressbar = { start = function(options) payload = options; events[#events + 1] = 'progress'; return completed end },
    visuals = {},
    util = { deepClone = function(flags)
        local copy = {}
        for key, value in pairs(flags) do copy[key] = value end
        return copy
    end },
}
for _, name in ipairs({ 'alien', 'coke', 'crack', 'meth', 'trevor' }) do
    QB.visuals[name] = function(duration) events[#events + 1] = 'visual'; visuals[#visuals + 1] = { name = name, duration = duration } end
end
dofile('shared/Config.lua')
dofile('shared/deafaults.lua')
dofile('client/client.lua')

-- adopt() is a pass-through in this harness, so the enum descriptor is still visible.
local setting = Config.applyStatusOn
equal(setting.value, 'complete', 'effects default to applying on completion')
equal(setting.options.live, true)
equal(type(setting.options.label), 'string')
equal(type(setting.options.description), 'string')
equal(setting.options.options[1].value, 'complete')
equal(setting.options.options[2].value, 'start')

for _, input in ipairs({ { 'drink', 'water' }, { 'food', 'sandwich' }, { 'smoke', 'ak47_joint' }, { 'liquor', 'beer' } }) do
    local class, item = input[1], input[2]
    local definition = Config.Consumables[class][item]
    equal(callback({ class = class, item = item }), true)
    equal(payload.label, definition.label)
    equal(payload.duration, definition.duration)
    equal(payload.anim, definition.anim)
    equal(payload.canCancel, true, 'default remains cancellable')
    equal(type(payload.disable), 'table', 'configured control restrictions are forwarded')
    equal(payload.disable.move, true)
    equal(payload.disable.combat, true)
    equal(payload.disable.car, true, 'existing vehicle flag reaches the car API')
    equal(payload.disable.vehicle, true, 'existing flag is retained in the payload')
    equal(definition.disable.car, nil, 'alias conversion does not mutate defaults')
    equal(payload.prop, nil, 'offset-based default is not sent as a legacy prop')
    if definition.prop then
        equal(#payload.props, 1)
        equal(payload.props[1], definition.prop, 'configured descriptor is preserved')
        equal(definition.prop.coords, nil, 'shared config is not mutated')
    else
        equal(payload.props, nil, 'no prop stays absent')
    end
end

local definition = Config.Consumables.drink.water
local original = definition.prop
local coords = { x = 0.12, y = 0.008, z = 0.03 }
local legacy = { model = 'prop_ld_flow_bottle', bone = 28422, coords = coords, rotation = { x = 1, y = 2, z = 3 } }
definition.prop = legacy
callback({ class = 'drink', item = 'water' })
equal(payload.prop, legacy, 'coords descriptors retain the legacy route')
equal(payload.props, nil)
equal(legacy.offset, nil, 'legacy config is not rewritten')
legacy.offset = { x = 9, y = 9, z = 9 }
callback({ class = 'drink', item = 'water' })
equal(payload.prop, legacy, 'existing coords precedence is retained when both fields exist')
equal(payload.props, nil)
for _, absent in ipairs({ 'nil', 'false' }) do
    if absent == 'nil' then definition.prop = nil else definition.prop = false end
    callback({ class = 'drink', item = 'water' })
    equal(payload.prop, nil)
    equal(payload.props, nil)
end
definition.prop = original

visuals = {}
completed = false
equal(callback({ class = 'smoke', item = 'ak47_joint' }), false, 'cancelled result is preserved')
equal(#visuals, 0, 'cancelled progress does not start visuals')
completed = true
equal(callback({ class = 'smoke', item = 'ak47_joint' }), true)
equal(visuals[1].name, 'alien')
equal(visuals[1].duration, 15000)
payload = nil
events = {}
equal(callback({ class = 'smoke', item = 'ak47_joint' }), true)
equal(events[1], 'progress', 'callback only replies after the blocking progress call returns')
equal(events[2], 'visual', 'visuals follow a completed progress')
equal(#events, 2)
equal(payload.duration, Config.Consumables.smoke.ak47_joint.duration, 'progress runs for the full configured duration')
equal(payload.anim, Config.Consumables.smoke.ak47_joint.anim, 'animation is owned by the progress bar so it ends with it')
payload = nil
equal(callback({ class = 'unknown', item = 'unknown' }), false)
equal(payload, nil, 'unknown consumable does not start progress')

local custom = {
    label = 'Custom', duration = 1234, useWhileDead = true, canCancel = false,
    anim = { dict = 'custom', clip = 'loop' }, emote = 'custom',
    disable = { move = true, combat = false, vehicle = true, car = false, sprint = true, mouse = true },
    disableMovement = { move = false, combat = true },
}
Config.Consumables.food.custom = custom
local function callCustom() return callback({ class = 'food', item = 'custom' }) end
equal(callCustom(), true)
equal(payload.canCancel, false, 'explicit cancellation setting is preserved')
equal(payload.disable, custom.disable, 'explicit car flag needs no conversion')
equal(payload.disable.car, false, 'explicit car=false overrides vehicle=true')
equal(payload.disable.sprint, true)
equal(payload.disable.mouse, true)
for _, key in ipairs({ 'label', 'duration', 'useWhileDead', 'anim', 'emote' }) do
    equal(payload[key], custom[key], 'other progress option is preserved')
end
custom.disable.car = nil
callCustom()
equal(payload.disable == custom.disable, false, 'vehicle alias uses a separate table')
equal(payload.disable.car, true)
equal(payload.disable.combat, false)
equal(custom.disable.car, nil, 'custom configuration remains unchanged')
custom.disable = false
callCustom()
equal(payload.disable, false, 'explicit no-controls setting takes precedence over legacy fallback')
custom.disable = nil
callCustom()
equal(payload.disable, custom.disableMovement, 'legacy restriction table still works')
custom.disableMovement = nil
callCustom()
equal(payload.disable, false, 'absent restrictions remain false')
custom.canCancel = nil
callCustom()
equal(payload.canCancel, true)
custom.canCancel = true
callCustom()
equal(payload.canCancel, true)
custom.canCancel = 0
callCustom()
equal(payload.canCancel, 0, 'invalid option remains available to library validation')
print(('qbconsumables client: %d checks passed'):format(checks))
