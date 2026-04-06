--[[
    bridge/client/framework.lua
    Fires unified events and exposes player-data helpers.

    Events fired (listen to these in your scripts):
        dg-bridge:client:playerLoaded    ()
        dg-bridge:client:playerUnloaded  ()
        dg-bridge:client:jobUpdated      (jobData)
        dg-bridge:client:gangUpdated     (gangData)

    Unified playerData table:
        {
            cid        = string,     -- citizen/identifier
            firstName  = string,
            lastName   = string,
            phone      = string,
            gender     = 'male'|'female',
            dob        = string,     -- MM/DD/YYYY
            money      = table,      -- { cash=n, bank=n, black=n }
            job        = { name, label, grade, gradeLabel, isBoss, onDuty, salary },
            gang       = { name, label, grade, gradeLabel, isBoss } | nil,
        }
]]

-- ─── ESX ──────────────────────────────────────────────────────────────────────
if Config.Framework == 'esx' then
    local ESX = nil

    -- Support both legacy (export) and old (event) ESX
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end

    local function waitForESX()
        while not ESX or not ESX.IsPlayerLoaded() do Wait(500) end
    end

    RegisterNetEvent('esx:playerLoaded', function()
        TriggerEvent('dg-bridge:client:playerLoaded')
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        TriggerEvent('dg-bridge:client:playerUnloaded')
    end)

    RegisterNetEvent('esx:setJob', function(job)
        TriggerEvent('dg-bridge:client:jobUpdated', {
            name       = job.name,
            label      = job.label,
            grade      = job.grade,
            gradeLabel = job.grade_label,
            isBoss     = job.grade_is_boss,
            onDuty     = true,
            salary     = job.grade_salary or 0,
        })
    end)

    Bridge.getPlayerData = function()
        waitForESX()
        local data = ESX.GetPlayerData()
        local job  = data.job

        local month, day, year = '01', '01', '2000'
        if data.dateofbirth then
            month, day, year = data.dateofbirth:match('(%d+)/(%d+)/(%d+)')
        end

        local money = {}
        if data.accounts then
            for _, acc in ipairs(data.accounts) do
                local canonical = acc.name == 'money' and 'cash' or acc.name == 'black_money' and 'black' or acc.name
                money[canonical] = acc.money
            end
        end

        return {
            cid        = data.identifier,
            firstName  = data.firstName  or 'Unknown',
            lastName   = data.lastName   or 'Unknown',
            phone      = data.phone_number or '0',
            gender     = data.sex == 'm' and 'male' or 'female',
            dob        = ('%s/%s/%s'):format(month, day, year),
            money      = money,
            job        = {
                name       = job.name,
                label      = job.label,
                grade      = job.grade,
                gradeLabel = job.grade_label,
                isBoss     = job.grade_is_boss,
                onDuty     = true,
                salary     = job.grade_salary or 0,
            },
            gang = nil,
        }
    end

    Bridge.playerLoaded = function()
        return ESX ~= nil and ESX.IsPlayerLoaded()
    end

-- ─── QBCore ───────────────────────────────────────────────────────────────────
elseif Config.Framework == 'qbcore' then
    local QBCore = exports['qb-core']:GetCoreObject()

    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerEvent('dg-bridge:client:playerLoaded')
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        TriggerEvent('dg-bridge:client:playerUnloaded')
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        TriggerEvent('dg-bridge:client:jobUpdated', {
            name       = job.name,
            label      = job.label,
            grade      = job.grade.level,
            gradeLabel = job.grade.name,
            isBoss     = job.isboss,
            onDuty     = job.onduty,
            salary     = job.payment or 0,
        })
    end)

    RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
        TriggerEvent('dg-bridge:client:gangUpdated', {
            name       = gang.name,
            label      = gang.label,
            grade      = gang.grade.level,
            gradeLabel = gang.grade.label,
            isBoss     = gang.isboss,
        })
    end)

    Bridge.getPlayerData = function()
        while not LocalPlayer.state.isLoggedIn do Wait(500) end
        local data     = QBCore.Functions.GetPlayerData()
        local job      = data.job
        local gang     = data.gang
        local charinfo = data.charinfo

        local year, month, day = '2000', '01', '01'
        if charinfo.birthdate then
            year, month, day = charinfo.birthdate:match('(%d+)-(%d+)-(%d+)')
        end

        return {
            cid        = data.citizenid,
            firstName  = charinfo.firstname or 'Unknown',
            lastName   = charinfo.lastname  or 'Unknown',
            phone      = charinfo.phone     or '0000000',
            gender     = charinfo.gender == 1 and 'female' or 'male',
            dob        = ('%s/%s/%s'):format(month, day, year),
            money      = data.money or {},
            job        = {
                name       = job.name,
                label      = job.label,
                grade      = job.grade.level,
                gradeLabel = job.grade.name,
                isBoss     = job.isboss,
                onDuty     = job.onduty,
                salary     = job.payment or 0,
            },
            gang = gang and {
                name       = gang.name,
                label      = gang.label,
                grade      = gang.grade.level,
                gradeLabel = gang.grade.label,
                isBoss     = gang.isboss,
            } or nil,
        }
    end

    Bridge.playerLoaded = function()
        return LocalPlayer.state.isLoggedIn == true
    end

-- ─── QBox (qbx_core) ──────────────────────────────────────────────────────────
elseif Config.Framework == 'qbox' then
    local QBX = exports.qbx_core

    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerEvent('dg-bridge:client:playerLoaded')
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        TriggerEvent('dg-bridge:client:playerUnloaded')
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        TriggerEvent('dg-bridge:client:jobUpdated', {
            name       = job.name,
            label      = job.label,
            grade      = job.grade.level,
            gradeLabel = job.grade.name,
            isBoss     = job.isboss,
            onDuty     = job.onduty,
            salary     = job.payment or 0,
        })
    end)

    RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
        TriggerEvent('dg-bridge:client:gangUpdated', {
            name       = gang.name,
            label      = gang.label,
            grade      = gang.grade.level,
            gradeLabel = gang.grade.label,
            isBoss     = gang.isboss,
        })
    end)

    Bridge.getPlayerData = function()
        while not LocalPlayer.state.isLoggedIn do Wait(500) end
        local data     = QBX:GetPlayerData()
        local job      = data.job
        local gang     = data.gang
        local charinfo = data.charinfo

        local year, month, day = '2000', '01', '01'
        if charinfo and charinfo.birthdate then
            year, month, day = charinfo.birthdate:match('(%d+)-(%d+)-(%d+)')
        end

        return {
            cid        = data.citizenid,
            firstName  = charinfo and charinfo.firstname or 'Unknown',
            lastName   = charinfo and charinfo.lastname  or 'Unknown',
            phone      = charinfo and charinfo.phone     or '0000000',
            gender     = charinfo and (charinfo.gender == 1 and 'female' or 'male') or 'male',
            dob        = ('%s/%s/%s'):format(month, day, year),
            money      = data.money or {},
            job        = {
                name       = job.name,
                label      = job.label,
                grade      = job.grade.level,
                gradeLabel = job.grade.name,
                isBoss     = job.isboss,
                onDuty     = job.onduty,
                salary     = job.payment or 0,
            },
            gang = gang and {
                name       = gang.name,
                label      = gang.label,
                grade      = gang.grade.level,
                gradeLabel = gang.grade.label,
                isBoss     = gang.isboss,
            } or nil,
        }
    end

    Bridge.playerLoaded = function()
        return LocalPlayer.state.isLoggedIn == true
    end

-- ─── ND_Core ──────────────────────────────────────────────────────────────────
elseif Config.Framework == 'nd' then
    local ND      = exports['ND_Core']
    local _loaded = false

    RegisterNetEvent('ND:characterLoaded', function()
        _loaded = true
        TriggerEvent('dg-bridge:client:playerLoaded')
    end)

    AddEventHandler('ND:characterUnloaded', function()
        _loaded = false
        TriggerEvent('dg-bridge:client:playerUnloaded')
    end)

    RegisterNetEvent('ND:updateCharacter', function(character)
        if not character then return end
        local jobInfo = character.jobInfo or {}
        TriggerEvent('dg-bridge:client:jobUpdated', {
            name       = character.job,
            label      = jobInfo.label      or character.job,
            grade      = jobInfo.rank       or 0,
            gradeLabel = jobInfo.rankName   or '',
            isBoss     = jobInfo.isBoss     or false,
            onDuty     = true,
            salary     = 0,
        })
    end)

    Bridge.getPlayerData = function()
        while not _loaded do Wait(500) end
        local data    = ND:getPlayer()
        local jobInfo = data.jobInfo or {}

        local year, month, day = '2000', '01', '01'
        if data.dob then
            year, month, day = data.dob:match('(%d+)-(%d+)-(%d+)')
        end

        return {
            cid        = tostring(data.id),
            firstName  = data.firstname or 'Unknown',
            lastName   = data.lastname  or 'Unknown',
            phone      = 'Unknown',
            gender     = data.gender and string.lower(data.gender) or 'male',
            dob        = ('%s/%s/%s'):format(month, day, year),
            money      = { cash = data.cash or 0, bank = data.bank or 0 },
            job        = {
                name       = data.job       or 'unemployed',
                label      = jobInfo.label  or 'Unemployed',
                grade      = jobInfo.rank   or 0,
                gradeLabel = jobInfo.rankName or '',
                isBoss     = jobInfo.isBoss or false,
                onDuty     = true,
                salary     = 0,
            },
            gang = nil,
        }
    end

    Bridge.playerLoaded = function()
        return _loaded
    end

-- ─── Standalone ───────────────────────────────────────────────────────────────
else
    Bridge.getPlayerData = function()
        return {
            cid       = tostring(GetPlayerServerId(PlayerId())),
            firstName = 'Player',
            lastName  = '',
            phone     = '0',
            gender    = 'male',
            dob       = '01/01/2000',
            money     = { cash = 0, bank = 0 },
            job       = { name = 'unemployed', label = 'Unemployed', grade = 0, gradeLabel = 'Employee', isBoss = false, onDuty = true, salary = 0 },
            gang      = nil,
        }
    end

    Bridge.playerLoaded = function() return true end
end
