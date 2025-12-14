QBCore = exports['qb-core']:GetCoreObject()

local placing = false
local previewObj = nil
local benchRotation = 0.0
local spawnedBenches = {}
local benchModel = `gr_prop_gr_bench_04b`

-- Use the bench item
RegisterNetEvent("bench:useItem", function()
    local ped = PlayerPedId()
    TriggerServerEvent("bench:removeItem", "crafting_bench", 1)

    if placing then return end
    placing = true
    benchRotation = GetEntityHeading(ped)

    RequestModel(benchModel)
    while not HasModelLoaded(benchModel) do Wait(0) end

    local coords = GetEntityCoords(ped)
    previewObj = CreateObject(benchModel, coords.x, coords.y, coords.z, false, false, false)
    FreezeEntityPosition(previewObj, true)
    SetEntityCollision(previewObj, false, false)
    SetEntityAlpha(previewObj, 150, false)

    CreateThread(function()
        while placing do
            Wait(0)
            local pedCoords = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local target = pedCoords + forward * 1.5

            -- Snap to ground
            local ok, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z + 10.0, false)
            if ok then target = vector3(target.x, target.y, groundZ + 0.05) end

            SetEntityCoords(previewObj, target.x, target.y, target.z, false, false, false, true)

            -- Scroll wheel rotates
            if IsControlPressed(0, 15) then benchRotation = benchRotation + 1.0 end
            if IsControlPressed(0, 14) then benchRotation = benchRotation - 1.0 end
            SetEntityHeading(previewObj, benchRotation)

            -- LEFT CLICK: place bench
            if IsControlJustPressed(0, 24) then
                placing = false
                local finalPos = GetEntityCoords(previewObj)
                DeleteEntity(previewObj)
                previewObj = nil

                TriggerServerEvent("bench:place", finalPos.x, finalPos.y, finalPos.z, benchRotation)
            end

            -- RIGHT CLICK: cancel placement & return item
            if IsControlJustPressed(0, 25) then
                placing = false
                if previewObj then
                    DeleteEntity(previewObj)
                    previewObj = nil
                end
                TriggerServerEvent("bench:returnItem", "crafting_bench", 1)
            end
        end
    end)
end)

-- Spawn benches received from server
RegisterNetEvent("bench:spawnSaved", function(data)
    if not data.id or spawnedBenches[data.id] then return end

    RequestModel(benchModel)
    while not HasModelLoaded(benchModel) do Wait(0) end

    local obj = CreateObject(benchModel, data.x, data.y, data.z, false, false, false)
    SetEntityHeading(obj, data.heading)
    FreezeEntityPosition(obj, true)

    spawnedBenches[data.id] = obj
end)

-- Request all benches when client fully loaded
CreateThread(function()
    Wait(1000)
    QBCore.Functions.TriggerCallback("bench:getAll", function(benches)
        for _, bench in ipairs(benches) do
            TriggerEvent("bench:spawnSaved", bench)
        end
    end)
end)

-- ox_target setup
CreateThread(function()
    Wait(1000)
    exports.ox_target:addModel(benchModel, {
        {
            name = "bench_open",
            icon = "fa-solid fa-hammer",
            label = "Open Crafting",
            onSelect = function(data)
                TriggerEvent("koja_crafting:open")
            end
        },
        {
            name = "bench_pickup",
            icon = "fa-solid fa-box",
            label = "Pick Up Bench",
            distance = 2.0,
            onSelect = function(data)
                local entity = data.entity
                local benchId = nil
                for id, obj in pairs(spawnedBenches) do
                    if obj == entity then
                        benchId = id
                        break
                    end
                end

                if benchId then
                    DeleteEntity(entity)
                    spawnedBenches[benchId] = nil
                    TriggerServerEvent("bench:pickup", benchId)
                end
            end
        }
    })
end)
