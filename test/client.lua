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
exports = { ['qb-core'] = { GetShared = function() return {} end } }
QB = {
    callback = { register = function(name, handler)
        equal(name, 'qbconsumables:progress')
        callback = handler
    end },
    progressbar = { start = function(options) payload = options; return completed end },
    visuals = {},
}
for _, name in ipairs({ 'alien', 'coke', 'crack', 'meth', 'trevor' }) do
    QB.visuals[name] = function(duration) visuals[#visuals + 1] = { name = name, duration = duration } end
end
dofile('shared/Config.lua')
dofile('shared/deafaults.lua')
dofile('client/client.lua')

for _, input in ipairs({ { 'drink', 'water' }, { 'food', 'sandwich' }, { 'smoke', 'ak47_joint' }, { 'liquor', 'beer' } }) do
    local class, item = input[1], input[2]
    local definition = Config.Consumables[class][item]
    equal(callback({ class = class, item = item }), true)
    equal(payload.label, definition.label)
    equal(payload.duration, definition.duration)
    equal(payload.anim, definition.anim)
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
equal(callback({ class = 'unknown', item = 'unknown' }), false)
equal(payload, nil, 'unknown consumable does not start progress')
print(('qbconsumables client: %d checks passed'):format(checks))
