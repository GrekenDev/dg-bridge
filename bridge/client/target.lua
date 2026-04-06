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

-- Convert { job='police' } or { job={'police','sheriff'} } to ox groups table
local function toOxGroups(opt)
    if not opt.job then return nil end
    local groups = {}
    if type(opt.job) == 'table' then
        for _, j in ipairs(opt.job) do groups[j] = 0 end
    else
        groups[opt.job] = 0
    end
    if opt.gang then
        if type(opt.gang) == 'table' then
            for _, g in ipairs(opt.gang) do groups[g] = 0 end
        else
            groups[opt.gang] = 0
        end
    end
    return groups
end

-- Build ox_target targets list from unified options
local function toOxTargets(options, distance)
    local targets = {}
    for i, opt in ipairs(options) do
        targets[i] = {
            name        = opt.label:lower():gsub('%s+', '_') .. '_' .. i,
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

-- ─── ox_target ───────────────────────────────────────────────────────────────
if Config.Target == 'ox_target' then
    Bridge.addEntityTarget = function(entity, options, distance)
        exports.ox_target:addEntity(entity, toOxTargets(options, distance))
    end

    Bridge.addModelTarget = function(models, options, distance)
        if type(models) == 'string' or type(models) == 'number' then
            models = { models }
        end
        exports.ox_target:addModel(models, toOxTargets(options, distance))
    end

    Bridge.addBoxZone = function(name, coords, width, length, heading, options, distance)
        exports.ox_target:addBoxZone({
            name     = name,
            coords   = coords,
            size     = vec3(width, length, 2.0),
            rotation = heading or 0.0,
            debug    = false,
            options  = toOxTargets(options, distance),
        })
    end

    Bridge.addSphereZone = function(name, coords, radius, options, distance)
        exports.ox_target:addSphereZone({
            name    = name,
            coords  = coords,
            radius  = radius or 1.5,
            debug   = false,
            options = toOxTargets(options, distance),
        })
    end

    Bridge.removeZone = function(name)
        exports.ox_target:removeZone(name)
    end

    Bridge.removeEntityTarget = function(entity, names)
        if type(names) == 'string' then names = { names } end
        exports.ox_target:removeEntity(entity, names)
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
        exports['qb-target']:RemoveTargetEntity(entity)
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
        exports['qtarget']:RemoveTargetEntity(entity)
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
