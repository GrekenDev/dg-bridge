--[[
    bridge/client/notify.lua

    Bridge.notify(message, type, duration)
        message  : string
        type     : 'success' | 'error' | 'warning' | 'info' | 'primary'
        duration : number (ms) — defaults to Config.NotifyDuration
]]

-- ─── type helpers ─────────────────────────────────────────────────────────────

-- Map canonical type → qb-core type string
local function toQBType(t)
    local map = { success = 'success', error = 'error', warning = 'warning', info = 'primary', primary = 'primary' }
    return map[t] or 'primary'
end

-- Map canonical type → ESX type string
local function toESXType(t)
    local map = { success = 'success', error = 'error', warning = 'warning', info = 'info', primary = 'info' }
    return map[t] or 'info'
end

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
if Config.Notify == 'ox_lib' then
    Bridge.notify = function(message, ntype, duration)
        exports.ox_lib:notify({
            title    = message,
            type     = ntype or 'inform',
            duration = duration or Config.NotifyDuration,
        })
    end

-- ─── QBCore ───────────────────────────────────────────────────────────────────
elseif Config.Notify == 'qbcore' then
    local QBCore = exports['qb-core']:GetCoreObject()

    Bridge.notify = function(message, ntype, duration)
        QBCore.Functions.Notify(message, toQBType(ntype), duration or Config.NotifyDuration)
    end

-- ─── ESX ──────────────────────────────────────────────────────────────────────
elseif Config.Notify == 'esx' then
    Bridge.notify = function(message, ntype, duration)
        -- ESX ShowNotification accepts a string; type is shown via colour
        TriggerEvent('esx:showNotification', message, toESXType(ntype), duration or Config.NotifyDuration)
    end

-- ─── okokNotify ───────────────────────────────────────────────────────────────
elseif Config.Notify == 'okok' then
    local function toOkokType(t)
        local map = { success = 'success', error = 'error', warning = 'warning', info = 'info', primary = 'info' }
        return map[t] or 'info'
    end

    Bridge.notify = function(message, ntype, duration)
        exports['okokNotify']:Alert('DG Scripts', message, duration or Config.NotifyDuration, toOkokType(ntype))
    end

-- ─── mythic_notify ────────────────────────────────────────────────────────────
elseif Config.Notify == 'mythic' then
    local function toMythicType(t)
        local map = { success = 'success', error = 'error', warning = 'warning', info = 'inform', primary = 'inform' }
        return map[t] or 'inform'
    end

    Bridge.notify = function(message, ntype, duration)
        TriggerEvent('mythic_notify:client:SendAlert', {
            type     = toMythicType(ntype),
            text     = message,
            length   = duration or Config.NotifyDuration,
        })
    end

-- ─── lation_ui ────────────────────────────────────────────────────────────────
elseif Config.Notify == 'lation' then
    Bridge.notify = function(message, ntype, duration)
        exports['lation_ui']:notify({
            type        = ntype or 'inform',
            description = message,
            duration    = duration or Config.NotifyDuration,
        })
    end

-- ─── ps-ui ────────────────────────────────────────────────────────────────────
elseif Config.Notify == 'ps-ui' then
    local function toPsType(t)
        local map = { success = 'success', error = 'error', warning = 'warning', info = 'info', primary = 'info' }
        return map[t] or 'info'
    end

    Bridge.notify = function(message, ntype, duration)
        exports['ps-ui']:Notify(message, toPsType(ntype), duration or Config.NotifyDuration)
    end

-- ─── standalone (native) ──────────────────────────────────────────────────────
else
    Bridge.notify = function(message, ntype, duration)
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-- ─── Server→Client relay handlers ────────────────────────────────────────────
-- These receive TriggerClientEvent calls from bridge/server/notify.lua
-- for systems that require client-side exports.

RegisterNetEvent('dg-bridge:client:nativeNotify', function(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('dg-bridge:client:lationNotify', function(data)
    if exports['lation_ui'] then
        exports['lation_ui']:notify(data)
    end
end)

RegisterNetEvent('dg-bridge:client:psNotify', function(data)
    if exports['ps-ui'] then
        exports['ps-ui']:Notify(data.message, data.type or 'info', data.duration or Config.NotifyDuration)
    end
end)
