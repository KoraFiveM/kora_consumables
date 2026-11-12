-- Run from the resource directory: lua test/startup.lua
-- server.cfg must start kora_consumables, after the resources it depends on and
-- not commented out. Without it the Use button has no consumable handler at all.
local f = io.open('../../../server.cfg')
if not f then print('startup: server.cfg not found next to the resources folder, skipped'); os.exit(0) end
local order = {}
for line in f:lines() do
    local name = line:match('^%s*ensure%s+([%w_%-%[%]]+)') or line:match('^%s*start%s+([%w_%-%[%]]+)')
    if name and not order[name] then order[#order + 1] = name; order[name] = #order end
end
f:close()

local function check(cond, msg) if not cond then io.stderr:write('FAIL: ' .. msg .. '\n'); os.exit(1) end end
check(order.kora_consumables, 'server.cfg does not ensure kora_consumables')
for _, dep in ipairs({ 'kora_lib', 'kora_core', 'kora_inventory' }) do
    check(order[dep], 'server.cfg does not ensure ' .. dep)
    check(order[dep] < order.kora_consumables, dep .. ' must start before kora_consumables')
end

local m = assert(io.open('fxmanifest.lua')):read('*a')
for _, dep in ipairs({ 'kora_lib', 'kora_core' }) do
    check(m:find("dependency '" .. dep .. "'", 1, true), 'fxmanifest missing dependency ' .. dep)
end
print('startup ok')
