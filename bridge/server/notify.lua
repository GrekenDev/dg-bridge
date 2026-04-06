--[[
    bridge/server/notify.lua

    Bridge.notify(source, message, type, duration)
        source   : number  (player source; use -1 to notify all players)
        message  : string
        type     : 'success' | 'error' | 'warning' | 'info' | 'primary'
        duration : number (ms)
]]

-- ─── type mappers ─────────────────────────────────────────────────────────────
local function toQBType(t)
    local map = { success='success', error='error', warning='warning', info='primary', primary='primary' }
    return map[t] or 'primary'
end

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
if Config.Notify == 'ox_lib' then
    Bridge.notify = function(source, message, ntype, duration)
        if source == -1 then
            TriggerClientEvent('ox_lib:notify', -1, { title = message, type = ntype or 'inform', duration = duration or Config.NotifyDuration })
        else
            TriggerClientEvent('ox_lib:notify', source, { title = message, type = ntype or 'inform', duration = duration or Config.NotifyDuration })
        end
    end

-- ─── QBCore ───────────────────────────────────────────────────────────────────
elseif Config.Notify == 'qbcore' then
    Bridge.notify = function(source, message, ntype, duration)
        if source == -1 then
            TriggerClientEvent('QBCore:Notify', -1, message, toQBType(ntype), duration or Config.NotifyDuration)
        else
            TriggerClientEvent('QBCore:Notify', source, message, toQBType(ntype), duration or Config.NotifyDuration)
        end
    end

-- ─── ESX ──────────────────────────────────────────────────────────────────────
elseif Config.Notify == 'esx' then
    Bridge.notify = function(source, message, ntype, duration)
        if source == -1 then
            TriggerClientEvent('esx:showNotification', -1, message, ntype or 'info', duration or Config.NotifyDuration)
        else
            TriggerClientEvent('esx:showNotification', source, message, ntype or 'info', duration or Config.NotifyDuration)
        end
    end

-- ─── okokNotify ───────────────────────────────────────────────────────────────
elseif Config.Notify == 'okok' then
    Bridge.notify = function(source, message, ntype, duration)
        local t = ntype or 'info'
        if source == -1 then
            TriggerClientEvent('okokNotify:Alert', -1, 'DG Scripts', message, duration or Config.NotifyDuration, t)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'DG Scripts', message, duration or Config.NotifyDuration, t)
        end
    end

-- ─── mythic_notify ────────────────────────────────────────────────────────────
elseif Config.Notify == 'mythic' then
    local function toMythicType(t)
        local map = { success='success', error='error', warning='warning', info='inform', primary='inform' }
        return map[t] or 'inform'
    end

    Bridge.notify = function(source, message, ntype, duration)
        local payload = { type = toMythicType(ntype), text = message, length = duration or Config.NotifyDuration }
        if source == -1 then
            TriggerClientEvent('mythic_notify:client:SendAlert', -1, payload)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', source, payload)
        end
    end

-- ─── lation_ui ────────────────────────────────────────────────────────────────
elseif Config.Notify == 'lation' then
    Bridge.notify = function(source, message, ntype, duration)
        local payload = { type = ntype or 'inform', description = message, duration = duration or Config.NotifyDuration }
        if source == -1 then
            TriggerClientEvent('dg-bridge:client:lationNotify', -1, payload)
        else
            TriggerClientEvent('dg-bridge:client:lationNotify', source, payload)
        end
    end

    -- Client listener for lation (client-side only export, must call from client)
    -- Registered in client notify.lua via lation config already

-- ─── ps-ui ────────────────────────────────────────────────────────────────────
elseif Config.Notify == 'ps-ui' then
    Bridge.notify = function(source, message, ntype, duration)
        if source == -1 then
            TriggerClientEvent('dg-bridge:client:psNotify', -1, { message = message, type = ntype or 'info', duration = duration or Config.NotifyDuration })
        else
            TriggerClientEvent('dg-bridge:client:psNotify', source, { message = message, type = ntype or 'info', duration = duration or Config.NotifyDuration })
        end
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else
    Bridge.notify = function(source, message)
        -- Trigger the client-side native notify
        if source == -1 then
            TriggerClientEvent('dg-bridge:client:nativeNotify', -1, message)
        else
            TriggerClientEvent('dg-bridge:client:nativeNotify', source, message)
        end
    end
end

-- Note: relay handlers for ps-ui / lation / standalone notify are registered
-- on the CLIENT side in bridge/client/notify.lua

-- ─── notifyAll / notifyJob ────────────────────────────────────────────────────
-- Sugar helpers built on top of Bridge.notify once it is defined above.

--- Notify every connected player.
Bridge.notifyAll = function(message, ntype, duration)
    Bridge.notify(-1, message, ntype, duration)
end

--- Notify all online players currently assigned to `job`.
Bridge.notifyJob = function(job, message, ntype, duration)
    local players = Bridge.getPlayers()
    for _, src in ipairs(players) do
        local j = Bridge.getJob(src)
        if j and j.name == job then
            Bridge.notify(src, message, ntype, duration)
        end
    end
end
