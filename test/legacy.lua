-- Run from the resource directory: lua test/legacy.lua
local checks = 0
local function equal(actual, expected, message)
    assert(actual == expected, ('%s: expected %s, got %s'):format(message or 'values differ', tostring(expected), tostring(actual)))
    checks = checks + 1
end

local handlers, shared, statuses, removals, sent, provided, exported, netEvents = {}, {}, {}, {}, {}, {}, {}, {}
local clock, owned = 0, true
exports = setmetatable({
    kora_core = {
        getShared = function(_, kind, name) if kind == 'items' and shared[name] then return { label = shared[name] } end end,
        createUseable = function(_, name, callback) handlers[name] = callback end,
        incrementMetaData = function(_, src, key, amount) statuses[#statuses + 1] = { src = src, key = key, amount = amount } end,
    },
    ['qb-inventory'] = { SetItemData = function() return true end },
    kora_inventory = { removeItem = function(_, src, name) removals[#removals + 1] = { src = src, name = name }; return owned end },
}, { __call = function(_, name, fn) exported[name] = fn end })
GetGameTimer = function() return clock end
Kora = {
    compat = { provideExport = function(resource, name, fn) equal(resource, 'qb-smallresources'); provided[name] = fn end },
    config = { enum = function(value) return value end, adopt = function(config) return config end },
    callback = { trigger = function() clock = clock + 5000; return true end },
}
function RegisterNetEvent(name, fn) netEvents[name] = fn end
function TriggerClientEvent(name, target, ...) sent[#sent + 1] = { name = name, target = target, args = { ... } } end
function AddEventHandler() end
source = nil
dofile('shared/Config.lua')
dofile('shared/deafaults.lua')
dofile('server/server.lua')

for _, name in ipairs({ 'AddFood', 'AddDrink', 'AddAlcohol', 'AddCustom' }) do
    equal(provided[name], exported[name], name .. ' provided under qb-smallresources and natively')
end

shared.jerky, shared.cola, shared.rum, shared.tonic = 'Jerky', 'Cola', 'Rum', 'Tonic'
local ok, reason = provided.AddFood('jerky', 35)
equal(ok, true); equal(reason, 'success')
equal(Config.Consumables.food.jerky.status.hunger, 35)
equal(Config.Consumables.food.jerky.label, 'Eating Jerky', 'class defaults are applied')
equal(sent[#sent].name, 'qbconsumables:register'); equal(sent[#sent].target, -1)
equal(sent[#sent].args[1][1].item, 'jerky')
equal(select(2, provided.AddFood('jerky', 10)), 'already added')
equal(select(2, provided.AddDrink('jerky', 10)), 'already added', 'any configured item counts as added')
equal(select(2, provided.AddFood('water', 10)), 'already added', 'configured items cannot be overridden')
equal(select(2, provided.AddFood('ghost', 10)), 'item does not exist')
equal(Config.Consumables.food.ghost, nil, 'unknown item is not registered')
for _, bad in ipairs({ -1, 101, 'x', 0 / 0 }) do equal(provided.AddFood('jerky2', bad), false, 'invalid replenish rejected') end
equal(provided.AddFood(nil, 5), false); equal(provided.AddFood('', 5), false)
equal(handlers.ghost, nil)

equal(provided.AddDrink('cola', 20), true)
equal(Config.Consumables.drink.cola.status.thirst, 20)
equal(provided.AddAlcohol('rum', 15), true)
equal(Config.Consumables.liquor.rum.status.thirst, 15)
equal(Config.Consumables.liquor.rum.effects.visual, 'buzzed')

local function use(name, class)
    statuses, removals = {}, {}
    return handlers[name](9, { name = name, slot = 3, info = {} })
end
use('jerky')
equal(removals[1].name, 'jerky', 'server removes the held item')
equal(statuses[1].key, 'hunger'); equal(statuses[1].amount, 35)
owned = false
use('jerky')
equal(#statuses, 0, 'no effect when the item is not actually removed')
owned = true

equal(select(2, provided.AddCustom('tonic', 'bad')), 'invalid arguments')
equal(select(2, provided.AddCustom('tonic', { replenish = { type = 'Thirst', replenish = 500 } })), 'success')
equal(Config.Consumables.custom.tonic.status, nil, 'out of range replenish is dropped')
shared.pill, shared.syrup = 'Pill', 'Syrup'
local sent_before = #sent
equal(provided.AddCustom('pill', {
    progress = { label = 'Swallowing', time = 2500 },
    animation = { animDict = 'mp_suicide', anim = 'pill', flags = 49 },
    prop = { model = 'prop_cs_pills', bone = 18905, coords = { x = 0.1, y = 0.2, z = 0.3 }, rotation = false },
    replenish = { type = 'Hunger', replenish = 10, isAlcohol = true, event = 'drug:client:pill' },
}), true)
local pill = Config.Consumables.custom.pill
equal(pill.label, 'Swallowing'); equal(pill.duration, 2500)
equal(pill.anim.dict, 'mp_suicide'); equal(pill.anim.clip, 'pill'); equal(pill.anim.flag, 49)
equal(pill.prop.bone, 18905); equal(pill.prop.offset.y, 0.2); equal(pill.prop.rotation.x, 0.0)
equal(pill.status.hunger, 10); equal(pill.effects.visual, 'buzzed')
equal(#sent, sent_before + 1)
sent = {}
use('pill')
equal(sent[1].name, 'drug:client:pill', 'client event is raised by the server after a completed use')
equal(sent[1].target, 9)
equal(provided.AddCustom('syrup', { replenish = { type = 'Hunger', replenish = 5, event = 'x:server', server = true } }), true)
equal(Config.Consumables.custom.syrup.event, nil, 'client-trusted server events are not wired')

sent = {}
source = 4
netEvents['qbconsumables:sync']()
equal(sent[1].target, 4); equal(#sent[1].args[1] >= 4, true, 'late joiner receives every runtime item')
sent = {}
netEvents['qbconsumables:sync']()
equal(#sent, 0, 'sync is rate limited per player')
clock = clock + 6000
netEvents['qbconsumables:sync']()
equal(#sent, 1)

print(('qbconsumables legacy exports: %d checks passed'):format(checks))
