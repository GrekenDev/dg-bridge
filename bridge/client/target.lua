--[[
    bridge/client/target.lua

    Unified option format (single option table):
    {
        label       = string,
        icon        = string,           -- Font Awesome  e.g. 'fa-solid fa-hand'
        distance    = number,           -- optional, overrides zone/call distance
        job         = string|table,     -- restrict to job(s) e.g. 'police' or {'police','sheriff'}
        gang        = string|table,     -- restrict to gang(s)
        item        = string|table,     -- require item(s)
        canInteract = function(entity) return bool end,   -- optional
        action      = function(entity) end,               -- called on select
    }

    API:
        Bridge.addEntityTarget(entity, options, distance)
        Bridge.addModelTarget(models, options, distance)
        Bridge.addBoxZone(name, coords, width, length, heading, options, distance)
        Bridge.addSphereZone(name, coords, radius, options, distance)
        Bridge.removeZone(name)
        Bridge.removeEntityTarget(entity, names)   -- names: string or table of label strings
]]

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function addGroups(groups, value)
    if type(value) == 'table' then
        for _, name in ipairs(value) do groups[name] = 0 end
    elseif value then
        groups[value] = 0
    end
end

-- Convert job/gang restrictions to an ox groups table, e.g. { police = 0, ballas = 0 }.
-- ox groups match ANY listed group, so job + gang together means job OR gang.
local function toOxGroups(opt)
    if not opt.job and not opt.gang then return nil end
    local groups = {}
    addGroups(groups, opt.job)
    addGroups(groups, opt.gang)
    return groups
end

-- Option names are derived from the label alone so removeEntityTarget can
-- remove options by label.
local function toOxName(label)
    return (label:lower():gsub('%s+', '_'))
end

-- Build ox_target / i_interaction targets list from unified options
local function toOxTargets(options, distance)
    local targets = {}
    for i, opt in ipairs(options) do
        targets[i] = {
            name        = toOxName(opt.label),
            label       = opt.label,
            icon        = opt.icon,
            distance    = opt.distance or distance or 2.5,
            groups      = toOxGroups(opt),
            items       = opt.item,
            canInteract = opt.canInteract and function(entity, dist, data)
                local ok, result = pcall(opt.canInteract, entity, dist, data)
                return ok and result
            end or nil,
            onSelect    = function(data)
                if opt.action then opt.action(data.entity) end
            end,
        }
    end
    return targets
end

-- Build qb-target / qtarget options list from unified options
local function toQBOptions(options)
    local out = {}
    for _, opt in ipairs(options) do
        out[#out + 1] = {
            label       = opt.label,
            icon        = opt.icon,
            distance    = opt.distance,
            job         = opt.job,
            gang        = opt.gang,
            item        = opt.item,
            canInteract = opt.canInteract,
            action      = opt.action,
        }
    end
    return out
end

-- ─── ox_target / i_interaction ───────────────────────────────────────────────
if Config.Target == 'ox_target' or Config.Target == 'i_interaction' then
    local target = exports[Config.Target]

    -- Both split entity targeting in two: addEntity/removeEntity take
    -- NETWORK ids, while addLocalEntity/removeLocalEntity take entity handles.
    -- Every other backend in this file takes a handle, and so does this API's
    -- documented signature, so accept a handle and route it to whichever
    -- function is right for that entity.
    --
    -- This matters because addEntity silently ignores anything that is not a
    -- live network id — a locally created prop, or an entity handle passed
    -- where a net id was expected, simply never gains an option.
    local function netIdOf(entity)
        if not entity or not DoesEntityExist(entity) then return nil end
        if not NetworkGetEntityIsNetworked(entity) then return nil end

        local netId = NetworkGetNetworkIdFromEntity(entity)
        return (netId and netId ~= 0 and NetworkDoesNetworkIdExist(netId)) and netId or nil
    end

    Bridge.addEntityTarget = function(entity, options, distance)
        local targets = toOxTargets(options, distance)
        local netId   = netIdOf(entity)

        if netId then
            target:addEntity(netId, targets)
        else
            target:addLocalEntity(entity, targets)
        end
    end

    Bridge.addModelTarget = function(models, options, distance)
        if type(models) == 'string' or type(models) == 'number' then
            models = { models }
        end
        target:addModel(models, toOxTargets(options, distance))
    end

    Bridge.addBoxZone = function(name, coords, width, length, heading, options, distance)
        target:addBoxZone({
            name     = name,
            coords   = coords,
            size     = vec3(width, length, 2.0),
            rotation = heading or 0.0,
            debug    = false,
            options  = toOxTargets(options, distance),
        })
    end

    Bridge.addSphereZone = function(name, coords, radius, options, distance)
        target:addSphereZone({
            name    = name,
            coords  = coords,
            radius  = radius or 1.5,
            debug   = false,
            options = toOxTargets(options, distance),
        })
    end

    Bridge.removeZone = function(name)
        target:removeZone(name)
    end

    Bridge.removeEntityTarget = function(entity, names)
        if type(names) == 'string' then names = { names } end

        if names then
            local oxNames = {}
            for i, label in ipairs(names) do oxNames[i] = toOxName(label) end
            names = oxNames
        end

        local netId = netIdOf(entity)
        if netId then
            target:removeEntity(netId, names)
        else
            target:removeLocalEntity(entity, names)
        end
    end

-- ─── qb-target ───────────────────────────────────────────────────────────────
elseif Config.Target == 'qb-target' then
    Bridge.addEntityTarget = function(entity, options, distance)
        exports['qb-target']:AddTargetEntity(entity, {
            options  = toQBOptions(options),
            distance = distance or 2.5,
        })
    end

    Bridge.addModelTarget = function(models, options, distance)
        if type(models) == 'string' or type(models) == 'number' then
            models = { models }
        end
        exports['qb-target']:AddTargetModel(models, {
            options  = toQBOptions(options),
            distance = distance or 2.5,
        })
    end

    Bridge.addBoxZone = function(name, coords, width, length, heading, options, distance)
        exports['qb-target']:AddBoxZone(name, coords, length, width,
            { heading = heading or 0.0, debugPoly = false, minZ = coords.z - 1.5, maxZ = coords.z + 1.5 },
            { options = toQBOptions(options), distance = distance or 2.5 }
        )
    end

    Bridge.addSphereZone = function(name, coords, radius, options, distance)
        exports['qb-target']:AddCircleZone(name, coords, radius or 1.5,
            { debugPoly = false },
            { options = toQBOptions(options), distance = distance or 2.5 }
        )
    end

    Bridge.removeZone = function(name)
        exports['qb-target']:RemoveZone(name)
    end

    Bridge.removeEntityTarget = function(entity, names)
        exports['qb-target']:RemoveTargetEntity(entity, names)
    end

-- ─── qtarget ─────────────────────────────────────────────────────────────────
elseif Config.Target == 'qtarget' then
    Bridge.addEntityTarget = function(entity, options, distance)
        exports['qtarget']:AddTargetEntity(entity, {
            options  = toQBOptions(options),
            distance = distance or 2.5,
        })
    end

    Bridge.addModelTarget = function(models, options, distance)
        if type(models) == 'string' or type(models) == 'number' then
            models = { models }
        end
        exports['qtarget']:AddTargetModel(models, {
            options  = toQBOptions(options),
            distance = distance or 2.5,
        })
    end

    Bridge.addBoxZone = function(name, coords, width, length, heading, options, distance)
        exports['qtarget']:AddBoxZone(name, coords, length, width,
            { heading = heading or 0.0, debugPoly = false, minZ = coords.z - 1.5, maxZ = coords.z + 1.5 },
            { options = toQBOptions(options), distance = distance or 2.5 }
        )
    end

    Bridge.addSphereZone = function(name, coords, radius, options, distance)
        exports['qtarget']:AddCircleZone(name, coords, radius or 1.5,
            { debugPoly = false },
            { options = toQBOptions(options), distance = distance or 2.5 }
        )
    end

    Bridge.removeZone = function(name)
        exports['qtarget']:RemoveZone(name)
    end

    Bridge.removeEntityTarget = function(entity, names)
        exports['qtarget']:RemoveTargetEntity(entity, names)
    end

-- ─── standalone (distance-check DrawText3D) ───────────────────────────────────
else
    local _zones    = {}
    local _entities = {}

    -- Internal helper: check job/gang/item restrictions client-side
    local function passesRestrictions(opt)
        if opt.job then
            local playerJob = Bridge.getPlayerData and Bridge.getPlayerData().job.name or ''
            if type(opt.job) == 'table' then
                local found = false
                for _, j in ipairs(opt.job) do if j == playerJob then found = true; break end end
                if not found then return false end
            else
                if opt.job ~= playerJob then return false end
            end
        end
        return true
    end

    -- Zone/entity polling thread
    local _running = false
    local function startPolling()
        if _running then return end
        _running = true

        CreateThread(function()
            while _running do
                local ped    = PlayerPedId()
                local pCoords = GetEntityCoords(ped)
                local closest, closestDist, closestAction = nil, math.huge, nil

                -- Check zones
                for name, zone in pairs(_zones) do
                    local dist = #(pCoords - zone.coords)
                    if dist < (zone.distance or 3.0) then
                        for _, opt in ipairs(zone.options) do
                            if passesRestrictions(opt) and (not opt.canInteract or opt.canInteract(0)) then
                                if dist < closestDist then
                                    closest      = opt
                                    closestDist  = dist
                                    closestAction = opt.action
                                end
                            end
                        end
                    end
                end

                -- Check entities
                for _, data in ipairs(_entities) do
                    if DoesEntityExist(data.entity) then
                        local eCoords = GetEntityCoords(data.entity)
                        local dist    = #(pCoords - eCoords)
                        if dist < (data.distance or 2.5) then
                            for _, opt in ipairs(data.options) do
                                if passesRestrictions(opt) and (not opt.canInteract or opt.canInteract(data.entity)) then
                                    if dist < closestDist then
                                        closest      = opt
                                        closestDist  = dist
                                        closestAction = function() opt.action(data.entity) end
                                    end
                                end
                            end
                        end
                    end
                end

                if closest then
                    local c = GetEntityCoords(ped)
                    if _G.DrawText3D then
                        DrawText3D(c.x, c.y, c.z + 1.0, '[E] ' .. closest.label)
                    end
                    if IsControlJustReleased(0, 38) and closestAction then -- E key
                        closestAction()
                    end
                end

                Wait(0)
            end
        end)
    end

    Bridge.addEntityTarget = function(entity, options, distance)
        _entities[#_entities + 1] = { entity = entity, options = options, distance = distance or 2.5 }
        startPolling()
    end

    Bridge.addModelTarget = function(models, options, distance)
        -- For standalone, scan for entities with the given model hash
        if type(models) ~= 'table' then models = { models } end
        CreateThread(function()
            while true do
                Wait(5000)
                local ped    = PlayerPedId()
                local pCoords = GetEntityCoords(ped)
                local objs   = GetGamePool('CObject')
                local peds2  = GetGamePool('CPed')
                local vehs   = GetGamePool('CVehicle')
                local all    = {}
                for _, e in ipairs(objs)  do all[#all+1] = e end
                for _, e in ipairs(peds2) do all[#all+1] = e end
                for _, e in ipairs(vehs)  do all[#all+1] = e end

                for _, ent in ipairs(all) do
                    local model = GetEntityModel(ent)
                    for _, m in ipairs(models) do
                        if GetHashKey(tostring(m)) == model or m == model then
                            Bridge.addEntityTarget(ent, options, distance)
                        end
                    end
                end
            end
        end)
    end

    Bridge.addBoxZone = function(name, coords, width, length, heading, options, distance)
        _zones[name] = { coords = coords, width = width, length = length, heading = heading, options = options, distance = distance or 3.0 }
        startPolling()
    end

    Bridge.addSphereZone = function(name, coords, radius, options, distance)
        _zones[name] = { coords = coords, radius = radius, options = options, distance = distance or radius or 1.5 }
        startPolling()
    end

    Bridge.removeZone = function(name)
        _zones[name] = nil
        if next(_zones) == nil and #_entities == 0 then _running = false end
    end

    Bridge.removeEntityTarget = function(entity, names)
        for i, data in ipairs(_entities) do
            if data.entity == entity then
                table.remove(_entities, i)
                break
            end
        end
        if next(_zones) == nil and #_entities == 0 then _running = false end
    end
end
