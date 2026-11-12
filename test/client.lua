-- Run from the resource directory: lua test/client.lua
-- Check actual callback payloads; live model loading and natives are not emulated.
local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, ('%s: expected %s, got %s'):format(message or 'values differ', tostring(expected), tostring(actual)))
    checks = checks + 1
end
local callback, payload

-- Model validity is emulated: only these names are real models; joaat returns a stable number per name.
local validModels = {}
for _, name in ipairs({ 'prop_ld_flow_bottle', 'prop_cs_burger_01', 'prop_cs_hotdog_01', 'prop_sandwich_01',
    'prop_choc_ego', 'prop_ecola_can', 'p_amb_coffeecup_01', 'prop_cs_beer_bot_01' }) do validModels[name] = true end
local hashes, nextHash = {}, 1000
function joaat(name)
    if not hashes[name] then nextHash = nextHash + 1; hashes[name] = { value = nextHash, name = name } end
    return hashes[name].value
end
function IsModelValid(hash)
    for name, entry in pairs(hashes) do
        if entry.value == hash then return validModels[name] == true end
    end
    return false
end

-- Drunk-visual natives are not emulated; stub them so buzzed() runs without erroring.
function GetGameTimer() return 0 end
function SetTimecycleModifier() end
function SetTimecycleModifierStrength() end
function ClearTimecycleModifier() end
function ShakeGameplayCam() end
function StopGameplayCamShaking() end
function RequestAnimSet() end
function HasAnimSetLoaded() return true end
function SetPedMovementClipset() end
function ResetPedMovementClipset() end
function PlayerPedId() return 1 end
function Wait() end

local completed = true
local visuals = {}
local events = {}
exports = { kora_core = { getShared = function() return {} end } }
Kora = {
    callback = { register = function(name, handler)
        equal(name, 'kora_consumables:progress')
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
    Kora.visuals[name] = function(duration) events[#events + 1] = 'visual'; visuals[#visuals + 1] = { name = name, duration = duration } end
end
local netEvents, serverEvents = {}, {}
function RegisterNetEvent(name, fn) netEvents[name] = fn end
function TriggerServerEvent(name) serverEvents[#serverEvents + 1] = name end
function CreateThread(fn) fn() end
dofile('shared/Config.lua')
dofile('shared/deafaults.lua')
dofile('client/client.lua')

equal(serverEvents[1], 'kora_consumables:sync', 'client asks the server for runtime-added items')
netEvents['kora_consumables:register']('bad')
netEvents['kora_consumables:register']({ { class = 'food', item = 'late_snack', data = { label = 'Late', duration = 10 } }, { class = 7 } })
equal(Config.Consumables.food.late_snack.label, 'Late', 'server-registered item is usable on the client')
equal(callback ~= nil, true)

equal(Config.allowMovement, true, 'walking while using an item is allowed by default')
-- The legacy restriction checks below assume the frozen behaviour.
Config.allowMovement = false

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
print(('kora_consumables client: %d checks passed'):format(checks))

-- Every default and per-item prop model must be a real model, on the right hand bone with an offset.
for class, items in pairs(Config.Consumables) do
    for item, data in pairs(items) do
        if data.prop then
            equal(validModels[data.prop.model], true, class .. '.' .. item .. ' prop model is valid')
            equal(data.prop.bone, (class == 'liquor' or item == 'coffee' or item == 'soda') and 28422 or 60309, class .. '.' .. item .. ' prop is on the hand the animation uses')
            equal(type(data.prop.offset), 'table', class .. '.' .. item .. ' has an offset')
            equal(type(data.prop.rotation), 'table', class .. '.' .. item .. ' has a rotation')
        end
    end
end
equal(Config.Consumables.food.hot_dog.prop.model, 'prop_cs_hotdog_01', 'per-item model override applies')
equal(Config.Consumables.food.hot_dog.prop.bone, Config.Consumables.food.sandwich.prop.bone, 'override inherits the class bone')
equal(Config.Consumables.drink.water.prop.bone, 60309, 'drink props use the left hand')
equal(Config.Consumables.drink.water.prop.hands, nil, 'hand table is not leaked into the resolved prop')

-- An invalid configured model is skipped and the item is still used.
Config.Consumables.food.broken = { prop = { model = '60309', bone = 28422, offset = { x = 0, y = 0, z = 0 }, rotation = { x = 0, y = 0, z = 0 } } }
payload = nil
equal(callback({ class = 'food', item = 'broken' }), true, 'item with invalid prop is still used')
equal(payload.props, nil, 'invalid prop is not forwarded')
equal(payload.prop, nil)
Config.skipInvalidProps = false
callback({ class = 'food', item = 'broken' })
equal(payload.props[1].model, '60309', 'skipping can be disabled')
Config.skipInvalidProps = true

-- A progress bar error becomes a clean false, not a thrown error.
local realStart = Kora.progressbar.start
Kora.progressbar.start = function() error('Progress bar prop 1 has an invalid model.') end
equal(callback({ class = 'drink', item = 'water' }), false, 'progress error returns false')
Kora.progressbar.start = realStart

-- Movement while eating and drinking (Config.allowMovement).
Config.allowMovement = true
for _, input in ipairs({ { 'drink', 'water' }, { 'food', 'sandwich' }, { 'smoke', 'ak47_joint' }, { 'liquor', 'beer' } }) do
    local definition = Config.Consumables[input[1]][input[2]]
    equal(callback({ class = input[1], item = input[2] }), true)
    equal(payload.disable.move, false, input[1] .. ' does not freeze movement by default')
    equal(payload.disable.combat, true, 'combat stays disabled')
    equal(payload.disable.car, true, 'vehicle use stays disabled')
    equal(payload.anim.flag & 48, 48, input[1] .. ' anim is upper body + allow control')
    equal(payload.anim.dict, definition.anim.dict)
    equal(payload.anim.clip, definition.anim.clip)
    equal(definition.disable.move, true, 'shared defaults are not mutated')
end
equal(Config.Consumables.drink.water.anim.flag, nil, 'drink default anim is not mutated')
equal(Config.Consumables.food.sandwich.anim.flag, 49, 'food default flag stays 49')
callback({ class = 'drink', item = 'water' })
equal(payload.anim.flag, 49, 'a flagless anim becomes 49 when movement is allowed')

Config.allowMovement = false
callback({ class = 'drink', item = 'water' })
equal(payload.disable.move, true, 'Config.allowMovement=false freezes movement')
equal(payload.anim, Config.Consumables.drink.water.anim, 'anim untouched when frozen')

Config.allowMovement = { food = false }
callback({ class = 'food', item = 'sandwich' })
equal(payload.disable.move, true, 'per-class false freezes that class')
callback({ class = 'drink', item = 'water' })
equal(payload.disable.move, false, 'classes missing from the table default to allowed')

Config.allowMovement = true
Config.Consumables.drink.water.allowMovement = false
callback({ class = 'drink', item = 'water' })
equal(payload.disable.move, true, 'item allowMovement=false overrides the global setting')
Config.allowMovement = false
Config.Consumables.drink.water.allowMovement = true
callback({ class = 'drink', item = 'water' })
equal(payload.disable.move, false, 'item allowMovement=true overrides the global setting')
equal(payload.anim.flag, 49)
Config.Consumables.drink.water.allowMovement = nil
Config.allowMovement = true

Config.Consumables.food.looped = { anim = { dict = 'd', clip = 'c', flag = 0 }, disable = false }
callback({ class = 'food', item = 'looped' })
equal(payload.disable, false, 'no restrictions stays false')
equal(payload.anim.flag, 48, 'flag 0 is upgraded to allow movement')
print(('kora_consumables movement: %d checks passed'):format(checks))

-- Per-item offsets: soda and the other drink/food items carry non-zero attachments, coffee reuses the emote menu placement.
local function nonZero(v) return v.x ~= 0.0 or v.y ~= 0.0 or v.z ~= 0.0 end
for _, ref in ipairs({ { 'drink', 'water' }, { 'food', 'sandwich' }, { 'food', 'bread' }, { 'food', 'chocolate_bar' } }) do
    equal(nonZero(Config.Consumables[ref[1]][ref[2]].prop.offset), true, ref[2] .. ' has a non-zero offset')
    equal(Config.Consumables[ref[1]][ref[2]].prop.bone, 60309, ref[2] .. ' keeps the left hand bone')
end
equal(Config.Consumables.drink.soda.prop.model, 'prop_ecola_can', 'soda keeps its model')
equal(Config.Consumables.drink.soda.prop.bone, 28422, 'soda can is on the right hand like the soda emote')
equal(Config.Consumables.drink.soda.prop.rotation.z, 130.0, 'soda can rotation matches the soda emote')
local cup = Config.Consumables.drink.coffee
equal(cup.prop.bone, 28422, 'coffee cup is on the right hand like the emote menu')
equal(cup.prop.rotation.z, 130.0, 'coffee cup rotation matches the emote menu')
equal(cup.anim.dict, 'amb@world_human_drinking@coffee@male@idle_a', 'coffee plays the animation the placement was made for')
print('kora_consumables client: per-item prop offsets ok')
