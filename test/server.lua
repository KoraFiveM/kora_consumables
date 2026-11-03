-- Run from the resource directory: lua test/server.lua
-- Execute the actual registration/defaults/server code; host APIs record calls.
local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, ('%s: expected %s, got %s'):format(message or 'values differ', tostring(expected), tostring(actual)))
    checks = checks + 1
end

local handlers, items, updates, removals, statuses = {}, {}, {}, {}, {}
local progress = true
local metadataAccepted, removeAccepted = true, true
exports = setmetatable({
    kora_core = {
        getShared = function(_, name) equal(name, 'items'); return nil end,
        createUseable = function(_, name, callback) handlers[name] = callback end,
        incrementMetaData = function(_, src, key, amount, low, high)
            statuses[#statuses + 1] = { src = src, key = key, amount = amount, low = low, high = high }
        end,
    },
    ['qb-inventory'] = {
        SetItemData = function(_, src, name, key, value, slot)
            updates[#updates + 1] = { src = src, name = name, key = key, slot = slot }
            if not metadataAccepted then return metadataAccepted end
            local target = items[slot or 1]
            if not target or target.name ~= name then return false end
            target[key] = value
            return true
        end,
    },
    kora_inventory = {
        removeItem = function(_, src, name, amount, slot)
            removals[#removals + 1] = { src = src, name = name, amount = amount, slot = slot }
            if not removeAccepted then return false end
            local target = items[slot or 1]
            if not target or target.name ~= name then return false end
            items[slot or 1] = nil
            return true
        end,
    },
}, { __call = function() end })
local clock, elapsed, duringProgress = 0, 4000, nil
GetGameTimer = function() return clock end
Kora = {
    compat = { provideExport = function() end },
    config = {
        enum = function(value) return value end,
        adopt = function(config) return config end,
    },
    callback = { trigger = function(src, name, payload)
        equal(src, 17)
        equal(name, 'qbconsumables:progress')
        equal(payload.class, 'food')
        equal(payload.item, 'sandwich')
        if duringProgress then duringProgress() end
        clock = clock + elapsed
        return progress
    end },
}
local startHandlers = {}
RegisterNetEvent = function() end
local clientEvents = {}
TriggerClientEvent = function(name, target, ...) clientEvents[#clientEvents + 1] = { name = name, target = target, args = { ... } } end
AddEventHandler = function(name, fn) if name == 'onResourceStart' then startHandlers[#startHandlers + 1] = fn end end
dofile('test/kora_helpers.lua')(Kora)
dofile('shared/Config.lua')
dofile('shared/defaults.lua')
dofile('server/server.lua')

local function seed(uses)
    items = {
        [1] = { name = 'sandwich', info = { uses = 9, note = 'first' } },
        [2] = { name = 'sandwich', info = { uses = uses, note = 'second' } },
    }
    updates, removals, statuses = {}, {}, {}
end
local function use(slot, legacy)
    local item = items[slot]
    local snapshot = { name = item.name, slot = not legacy and slot or nil,
        info = { uses = item.info.uses, note = item.info.note } }
    equal(handlers.sandwich(17, snapshot), nil, 'callback return stays compatible')
end

seed(2)
use(2)
equal(items[1].info.uses, 9, 'using second copy must not modify first copy')
equal(items[1].info.note, 'first')
equal(items[2].info.uses, 1)
equal(items[2].info.note, 'second')
equal(updates[1].src, 17)
equal(updates[1].key, 'info')
equal(updates[1].slot, 2)
equal(#removals, 0, 'retained multi-use item is not removed')

seed(nil)
use(2)
equal(items[1].info.uses, 9, 'single-use removal leaves the other copy intact')
equal(items[2], nil)
equal(removals[1].src, 17)
equal(removals[1].name, 'sandwich')
equal(removals[1].amount, 1)
equal(removals[1].slot, 2)

seed(2)
use(1, true)
equal(items[1].info.uses, 8, 'legacy callback without a slot keeps name-based fallback')
equal(items[2].info.uses, 2)
equal(updates[1].slot, nil)

seed(2)
progress = false
use(2)
equal(#updates, 0, 'cancelled progress cannot update metadata')
equal(#removals, 0)
equal(#statuses, 0)
equal(items[2].info.uses, 2)

progress = true
local definition = Config.Consumables.food.sandwich
for _, keep in ipairs({ false, true }) do
    definition.keep = keep
    seed(2)
    use(2)
    equal(items[2].info.uses, 1)
    equal(#removals, 0, 'first use retains item even when keep is false')
    equal(#statuses, 1, 'retained use applies its effect')
    equal(statuses[1].src, 17)
    equal(statuses[1].key, 'hunger')
    equal(statuses[1].amount, 20)
    equal(statuses[1].low, 0)
    equal(statuses[1].high, 100)
    use(2)
    equal(items[2], nil, 'final use removes exhausted item even when keep is true')
    equal(items[1].info.uses, 9)
    equal(#removals, 1)
    equal(removals[1].slot, 2)
    equal(#statuses, 2, 'final use applies its effect once')
    equal(statuses[2].amount, 20)

    seed(nil)
    use(2)
    equal(#updates, 0, 'ordinary items do not acquire a uses counter')
    equal(#statuses, 1)
    if keep then
        equal(#removals, 0, 'ordinary keep items remain reusable')
        equal(items[2].info.note, 'second')
    else
        equal(#removals, 1, 'ordinary single-use item remains consumed')
        equal(items[2], nil)
    end
end
definition.keep = nil

for _, failure in ipairs({ 'false', 'nil' }) do
    seed(2)
    if failure == 'false' then metadataAccepted = false else metadataAccepted = nil end
    use(2)
    equal(items[2].info.uses, 2, 'failed metadata write cannot consume a use')
    equal(#statuses, 0, 'failed metadata write must not grant effects')
    equal(#removals, 0)
end
metadataAccepted = true

seed(1)
removeAccepted = false
use(2)
equal(#removals, 1)
equal(items[2].info.uses, 0)
equal(#statuses, 0, 'failed final removal retains existing no-effect behavior')
removeAccepted = true

seed(2)
progress = nil
use(2)
equal(#updates, 0, 'missing progress result is rejected')
equal(#removals, 0)
equal(#statuses, 0)
-- Effect timing and the per-player guard.
progress = true
definition = Config.Consumables.food.sandwich
equal(Config.applyStatusOn, 'complete', 'default waits for the use to finish')

seed(nil)
local statusAtProgress
duringProgress = function() statusAtProgress = #statuses + #removals end
use(2)
equal(statusAtProgress, 0, 'nothing is applied or consumed while the animation runs')
equal(#statuses, 1, 'status applied once the use completes')
duringProgress = nil

seed(nil)
progress = false
use(2)
equal(#statuses, 0, 'cancel applies no status')
equal(#removals, 0, 'cancel does not consume the item')
progress = true

seed(nil)
elapsed = 100
use(2)
equal(#statuses, 0, 'a reply faster than the duration is ignored')
equal(#removals, 0)
elapsed = definition.duration - 100
use(2)
equal(#statuses, 1, 'timer granularity allowance still accepts a real use')
elapsed = 4000

seed(nil)
local secondResult, secondRan
duringProgress = function()
    if secondRan then return end
    secondRan = true
    secondResult = handlers.sandwich(17, { name = 'sandwich', slot = 2, info = {} })
end
use(2)
duringProgress = nil
equal(secondResult, false, 'second use during an active use is rejected')
equal(#statuses, 1, 'rejected use does not stack the effect')
equal(#removals, 1)
seed(nil)
use(2)
equal(#statuses, 1, 'guard is released after a completed use')

seed(nil)
duringProgress = function() error('boom') end
equal(pcall(handlers.sandwich, 17, { name = 'sandwich', slot = 2, info = {} }), false)
duringProgress = nil
use(2)
equal(#statuses, 1, 'guard is released after an error')

seed(nil)
progress = false
use(2)
progress = true
use(2)
equal(#statuses, 1, 'guard is released after a cancel')

Config.applyStatusOn = 'start'
seed(nil)
statusAtProgress = nil
duringProgress = function() statusAtProgress = #statuses + #removals end
use(2)
equal(statusAtProgress, 2, 'start mode applies the effect and consumes before the animation')
equal(#statuses, 1)
equal(#removals, 1)
progress = false
seed(nil)
duringProgress = nil
use(2)
equal(#statuses, 1, 'start mode keeps the effect even if the animation is cancelled')
elapsed = 0
progress = true
seed(nil)
use(2)
equal(#statuses, 1, 'start mode ignores the reply timing')
secondRan, secondResult = false, nil
seed(nil)
duringProgress = function()
    if secondRan then return end
    secondRan = true
    secondResult = handlers.sandwich(17, { name = 'sandwich', slot = 2, info = {} })
end
use(2)
equal(secondResult, false, 'start mode also rejects a concurrent use')
Config.applyStatusOn = 'complete'

-- Items kora_inventory also handles instantly are covered, and survive its restart.
for _, name in ipairs({ 'water_bottle', 'soda', 'bread', 'chocolate_bar', 'sandwich', 'beer', 'whiskey' }) do
    assert(handlers[name], name .. ' must be handled by kora_consumables')
    checks = checks + 1
end
handlers.water_bottle = nil
for _, fn in ipairs(startHandlers) do fn('some_other_resource') end
equal(handlers.water_bottle, nil, 'unrelated resource start does not re-register')
for _, fn in ipairs(startHandlers) do fn('kora_inventory') end
assert(handlers.water_bottle, 'kora_inventory start re-registers consumables')
checks = checks + 1

-- F#288: health/armor go to the owning client, not into unused metadata.
progress = true
definition.keep = nil
duringProgress = nil
local oldStatus = definition.status
definition.status = { hunger = 10, health = -5, armor = 20 }
seed(2)
elapsed = definition.duration or 4000
clientEvents = {}
use(2)
for _, entry in ipairs(statuses) do
    equal(entry.key ~= 'health' and entry.key ~= 'armor', true, 'health/armor are not written to metadata')
end
local vitals
for _, event in ipairs(clientEvents) do if event.name == 'qbconsumables:client:vitals' then vitals = event end end
equal(vitals ~= nil, true, 'vitals are sent to the client')
equal(vitals.target, 17); equal(vitals.args[1], -5); equal(vitals.args[2], 20)
definition.status = oldStatus

print(('qbconsumables server: %d checks passed'):format(checks))
