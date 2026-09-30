-- Run from the resource directory: lua test/server.lua
-- Execute the actual registration/defaults/server code; host APIs record calls.
local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, ('%s: expected %s, got %s'):format(message or 'values differ', tostring(expected), tostring(actual)))
    checks = checks + 1
end

local handlers, items, updates, removals, statuses = {}, {}, {}, {}, {}
local progress = true
exports = {
    qbcore = {
        createUseable = function(_, name, callback) handlers[name] = callback end,
        incrementMetaData = function(_, src, key, amount, low, high)
            statuses[#statuses + 1] = { src = src, key = key, amount = amount, low = low, high = high }
        end,
    },
    ['qb-core'] = { GetShared = function(_, name) equal(name, 'Items'); return {} end },
    ['qb-inventory'] = {
        SetItemData = function(_, src, name, key, value, slot)
            updates[#updates + 1] = { src = src, name = name, key = key, slot = slot }
            local target = items[slot or 1]
            if not target or target.name ~= name then return false end
            target[key] = value
            return true
        end,
    },
    qbinventory = {
        removeItem = function(_, src, name, amount, slot)
            removals[#removals + 1] = { src = src, name = name, amount = amount, slot = slot }
            local target = items[slot or 1]
            if not target or target.name ~= name then return false end
            items[slot or 1] = nil
            return true
        end,
    },
}
QB = { callback = { trigger = function(src, name, payload)
    equal(src, 17)
    equal(name, 'qbconsumables:progress')
    equal(payload.class, 'food')
    equal(payload.item, 'sandwich')
    return progress
end } }
dofile('shared/Config.lua')
dofile('shared/deafaults.lua')
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
print(('qbconsumables server: %d checks passed'):format(checks))
