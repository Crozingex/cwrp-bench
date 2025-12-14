QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.ox_inventory

-- Remove bench item when using it
RegisterNetEvent("bench:removeItem", function(item, amount)
    local src = source
    ox:RemoveItem(src, item, amount)
end)

-- Return bench item if placement canceled
RegisterNetEvent("bench:returnItem", function(item, amount)
    local src = source
    ox:AddItem(src, item, amount)
end)

-- Place bench: save in DB and broadcast
RegisterNetEvent("bench:place", function(x, y, z, heading)
    local src = source
    exports.oxmysql:insert(
        "INSERT INTO benches (x, y, z, heading) VALUES (?, ?, ?, ?)",
        {x, y, z, heading},
        function(insertId)
            if not insertId then return end
            -- Broadcast to all clients immediately
            TriggerClientEvent("bench:spawnSaved", -1, {
                id = insertId,
                x = x,
                y = y,
                z = z,
                heading = heading
            })
        end
    )
end)

-- Pickup bench by ID
RegisterNetEvent("bench:pickup", function(benchId)
    local src = source
    if not benchId then return end
    benchId = tonumber(benchId)

    exports.oxmysql:execute(
        "DELETE FROM benches WHERE id = ? LIMIT 1",
        {benchId},
        function(rowsChanged)
            if rowsChanged == 0 then
                print("^1ERROR:^7 Bench ID "..benchId.." not found in database!")
            end
        end
    )
    ox:AddItem(src, "crafting_bench", 1)
end)

-- Callback for clients to request all benches
QBCore.Functions.CreateCallback("bench:getAll", function(source, cb)
    local benches = exports.oxmysql:executeSync("SELECT * FROM benches", {})
    cb(benches)
end)

