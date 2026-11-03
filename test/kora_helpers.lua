-- Minimal stand-ins for the kora_lib helpers this resource uses (kora_lib#24:
-- Kora.util.toAmount, Kora.timers.cooldown), with the same contracts.
return function(Kora)
    Kora.util = Kora.util or {}
    local function finite(v) return type(v) == 'number' and v == v and v > -math.huge and v < math.huge end
    Kora.util.isFiniteNumber = finite
    Kora.util.toAmount = function(value, opts)
        opts = opts or {}
        local min, max = opts.min or 1, opts.max or 1000000
        if type(value) ~= 'number' then return nil, 'not_number' end
        if not finite(value) then return nil, 'not_finite' end
        if opts.integer ~= false and value % 1 ~= 0 then return nil, 'not_integer' end
        if value < min then return nil, 'below_min' end
        if value > max then return nil, 'above_max' end
        return value
    end
    Kora.timers = Kora.timers or {}
    Kora.timers.cooldown = function(interval, opts)
        local usedAt, cd = {}, { opts = opts }
        function cd.use(key)
            local now = GetGameTimer()
            if usedAt[key] and now - usedAt[key] < interval then return false end
            usedAt[key] = now
            return true
        end
        function cd.reset(key) if key == nil then usedAt = {} else usedAt[key] = nil end end
        return cd
    end
    return Kora
end
