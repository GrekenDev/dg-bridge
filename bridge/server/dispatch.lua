--[[
    bridge/server/dispatch.lua

    Receives dg-bridge:dispatch event from client and routes to the
    configured dispatch resource.

    data = {
        message  = string,
        code     = string,
        icon     = string,
        coords   = vector3,
        jobs     = table,      -- e.g. { 'police', 'sheriff' }
        priority = number,
        metadata = {
            { label=string, value=string }
        },
    }
]]

local function getStreetName(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(streetHash) or 'Unknown'
end

RegisterNetEvent('dg-bridge:dispatch', function(data)
    local src = source
    if not data then return end

    local coords = data.coords or vector3(0, 0, 0)
    if type(coords) == 'table' then
        coords = vector3(coords.x or 0, coords.y or 0, coords.z or 0)
    end

    -- ─── ps-dispatch ──────────────────────────────────────────────────────────
    if Config.Dispatch == 'ps-dispatch' then
        TriggerClientEvent('ps-dispatch:client:CreateDispatchCall', src, {
            code       = data.code     or '10-31',
            message    = data.message  or 'Alert',
            job_table  = data.jobs     or Config.DispatchJobs,
            coords     = coords,
            street     = getStreetName(coords),
            icon       = data.icon     or 'fas fa-circle-exclamation',
            priority   = data.priority or 2,
            metadata   = data.metadata or {},
        })

    -- ─── cd_dispatch ──────────────────────────────────────────────────────────
    elseif Config.Dispatch == 'cd_dispatch' then
        local meta = {}
        for _, m in ipairs(data.metadata or {}) do
            meta[#meta + 1] = { label = m.label, value = m.value }
        end

        TriggerEvent('cd_dispatch:AddNotification', {
            job_table  = data.jobs      or Config.DispatchJobs,
            coords     = coords,
            title      = ('%s | %s'):format(data.code or '10-31', data.message or 'Alert'),
            message    = data.message   or 'Alert',
            flash      = 0,
            unique_id  = tostring(math.random(0, 9999999)),
            blip = {
                subType = 1,
                flash   = true,
                name    = data.message or 'Alert',
                colour  = data.priority == 1 and 1 or data.priority == 3 and 5 or 3,
                scale   = 1.5,
                alpha   = 255,
            }
        })

    -- ─── qs-dispatch ──────────────────────────────────────────────────────────
    elseif Config.Dispatch == 'qs-dispatch' then
        local details = {}
        if data.metadata then
            for _, m in ipairs(data.metadata) do
                details[#details + 1] = { label = m.label, value = m.value }
            end
        end

        TriggerClientEvent('qs-dispatch:server:CreateDispatchCall', src, {
            job          = data.jobs      or Config.DispatchJobs,
            callLocation = coords,
            callCode     = { code = data.code or '10-31', snippet = (data.message or 'alert'):lower():gsub('%s', '_') },
            message      = data.message   or 'Alert',
            cam_words    = {},
            details      = details,
        })

    -- ─── standalone ───────────────────────────────────────────────────────────
    else
        -- Send a notification to all online players with matching jobs
        local playerJobs = Config.DispatchJobs or {}

        for _, playerSrc in ipairs(GetPlayers()) do
            local pSrc = tonumber(playerSrc)
            if pSrc then
                local job = Bridge.getJob and Bridge.getJob(pSrc)
                if job and job.name then
                    local allowed = false
                    for _, j in ipairs(data.jobs or playerJobs) do
                        if j == job.name then allowed = true; break end
                    end

                    if allowed then
                        Bridge.notify(pSrc,
                            ('[%s] %s'):format(data.code or '10-31', data.message or 'Alert'),
                            'error',
                            8000
                        )
                        -- Add blip on their map
                        TriggerClientEvent('dg-bridge:dispatch:addBlip', pSrc, {
                            coords   = coords,
                            message  = data.message,
                            code     = data.code,
                            icon     = data.icon,
                            duration = 30000,
                        })
                    end
                end
            end
        end
    end
end)

-- Standalone blip handler (client-side)
-- Handled in client to avoid server→client blip complexities
