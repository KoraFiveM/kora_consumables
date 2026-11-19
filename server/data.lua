ConsumableDataLoaded = false
ConsumableDataFailed = false

local function logError(id, message, err)
    Kora.logging.error(id, message, { error = tostring(err) })
end

function SaveConsumable(class, item, data)
    if not ConsumableDataLoaded then return false, 'Consumable database is not ready' end
    local encoded = json.encode(data)
    local ok, err = pcall(Kora.sql.update, [[
        INSERT INTO `kora_consumables_items` (`class`, `item`, `data`, `enabled`)
        VALUES (?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE `data` = VALUES(`data`), `enabled` = 1
    ]], { class, item, encoded })
    if not ok then return false, tostring(err) end
    return true
end

function DisableConsumable(class, item)
    if not ConsumableDataLoaded then return false, 'Consumable database is not ready' end
    local ok, err = pcall(Kora.sql.update, [[
        INSERT INTO `kora_consumables_items` (`class`, `item`, `data`, `enabled`)
        VALUES (?, ?, '{}', 0)
        ON DUPLICATE KEY UPDATE `enabled` = 0
    ]], { class, item })
    if not ok then return false, tostring(err) end
    return true
end

function SaveConsumableClass(class, data)
    if not ConsumableDataLoaded then return false, 'Consumable database is not ready' end
    local ok, err = pcall(Kora.sql.update, [[
        INSERT INTO `kora_consumables_classes` (`class`, `data`, `enabled`)
        VALUES (?, ?, 1)
        ON DUPLICATE KEY UPDATE `data` = VALUES(`data`), `enabled` = 1
    ]], {class, json.encode(data)})
    if not ok then return false, tostring(err) end
    return true
end

function DisableConsumableClass(class)
    if not ConsumableDataLoaded then return false, 'Consumable database is not ready' end
    local ok, err = pcall(Kora.sql.update, [[
        INSERT INTO `kora_consumables_classes` (`class`, `data`, `enabled`)
        VALUES (?, '{}', 0)
        ON DUPLICATE KEY UPDATE `enabled` = 0
    ]], {class})
    if not ok then return false, tostring(err) end
    return true
end

CreateThread(function()
    Wait(1000)
    if not Kora.sql.ready(60000) then
        ConsumableDataFailed = true
        logError('data.sql_unavailable', 'kora_sql was unavailable; consumables will not register until restart', 'timeout')
        return
    end

    local reports, schemaErr = Kora.sql.ensureTables(KoraConsumablesSchema)
    if schemaErr then
        ConsumableDataFailed = true
        logError('data.schema_failed', 'Consumables schema setup failed', schemaErr)
        return
    end
    for _, report in ipairs(reports or {}) do
        for _, warning in ipairs(report.warnings or {}) do
            Kora.logging.warn('data.schema_warning', 'Consumables schema warning', { table = report.table, warning = tostring(warning) })
        end
    end

    local ok, rows = pcall(Kora.sql.query, 'SELECT `class`, `item`, `data`, `enabled` FROM `kora_consumables_items`')
    if not ok then
        ConsumableDataFailed = true
        logError('data.read_failed', 'Could not read consumable data', rows)
        return
    end

    local classesOk, classRows = pcall(Kora.sql.query, 'SELECT `class`, `data`, `enabled` FROM `kora_consumables_classes`')
    if not classesOk then
        ConsumableDataFailed = true
        logError('data.classes_read_failed', 'Could not read consumable classes', classRows)
        return
    end

    for _, row in ipairs(classRows or {}) do
        if tonumber(row.enabled) == 0 then
            Config.ConsumableClasses[row.class] = nil
        else
            local decodedOk, data = pcall(json.decode, row.data or '{}')
            if decodedOk and type(data) == 'table' then
                if not data.label then data.label = ConsumableClassLabel(row.class) end
                local classData = Config.ConsumableClasses[row.class] or {}
                for key, value in pairs(data) do classData[key] = value end
                Config.ConsumableClasses[row.class] = classData
            else
                Kora.logging.warn('data.invalid_class_json', 'Skipping class with invalid database data', {class = row.class})
            end
        end
    end

    for _, row in ipairs(rows or {}) do
        Config.Consumables[row.class] = Config.Consumables[row.class] or {}
        local decodedOk, data = pcall(json.decode, row.data or '{}')
        if decodedOk and type(data) == 'table' and type(data.sharedItem) == 'table' and data.sharedItem.createdByConsumables == true then
            local registered, registerError = exports.kora_core:registerShared('items', row.item, data.sharedItem)
            if not registered then
                Kora.logging.warn('data.item_register_failed', 'Could not register saved shared item', { item = row.item, error = tostring(registerError) })
            end
        end
        if tonumber(row.enabled) == 0 then
            Config.Consumables[row.class][row.item] = nil
        else
            if decodedOk and type(data) == 'table' then
                ApplyConsumableDefaults(row.class, row.item, data)
                Config.Consumables[row.class][row.item] = data
            else
                Kora.logging.warn('data.invalid_json', 'Skipping consumable with invalid database data', { class = row.class, item = row.item })
            end
        end
    end

    ConsumableDataLoaded = true
    TriggerClientEvent('kora_consumables:catalog', -1, Config.Consumables, Config.ConsumableClasses)
end)
