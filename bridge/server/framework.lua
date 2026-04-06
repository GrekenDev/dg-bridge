--[[
    bridge/server/framework.lua

    Normalised player object returned by Bridge.getPlayer(source):
    {
        source     = number,
        raw        = <framework player>,   -- original framework object
        identifier = string,
        name       = string,
        getJob()   = function → { name, label, grade, gradeLabel, isBoss, onDuty, salary }
        getGang()  = function → { name, label, grade, gradeLabel, isBoss } | nil
        getMoney(account)        → number
        addMoney(account, amt, reason) → bool
        removeMoney(account, amt, reason) → bool
        setMoney(account, amt) → bool
        setJob(name, grade)  → void
        getInventory()       → table
    }

    Bridge.getPlayer(source)                     → normalised player | nil
    Bridge.getPlayerData(source)                 → raw data table | nil
    Bridge.getJob(source)                        → job table | nil
    Bridge.getGang(source)                       → gang table | nil
    Bridge.getIdentifier(source)                 → string
    Bridge.getPlayerName(source)                 → string
    Bridge.getMoney(source, account)             → number
    Bridge.addMoney(source, account, amt, reason)→ bool
    Bridge.removeMoney(source, account, amt, reason) → bool
    Bridge.setJob(source, job, grade)            → void
    Bridge.getPlayers()                          → table of sources
]]

-- Canonical → framework account name mapper
local function mapAccount(canonical)
    return Config.MoneyAccounts[canonical] or canonical
end

-- ─── ESX ──────────────────────────────────────────────────────────────────────
if Config.Framework == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    local function wrapPlayer(xPlayer)
        if not xPlayer then return nil end
        return {
            source     = xPlayer.source,
            raw        = xPlayer,
            identifier = xPlayer.identifier,
            name       = xPlayer.getName(),

            getJob = function()
                local j = xPlayer.getJob()
                return {
                    name       = j.name,
                    label      = j.label,
                    grade      = j.grade,
                    gradeLabel = j.grade_label,
                    isBoss     = j.grade_is_boss,
                    onDuty     = true,
                    salary     = j.grade_salary or 0,
                }
            end,

            getGang = function() return nil end,

            getMoney = function(account)
                local acc = xPlayer.getAccount(account == 'cash' and 'money' or account == 'black' and 'black_money' or account)
                return acc and acc.money or 0
            end,

            addMoney = function(account, amount, reason)
                local fwAccount = account == 'cash' and 'money' or account == 'black' and 'black_money' or account
                xPlayer.addAccountMoney(fwAccount, amount)
                return true
            end,

            removeMoney = function(account, amount, reason)
                local fwAccount = account == 'cash' and 'money' or account == 'black' and 'black_money' or account
                xPlayer.removeAccountMoney(fwAccount, amount)
                return true
            end,

            setMoney = function(account, amount)
                local fwAccount = account == 'cash' and 'money' or account == 'black' and 'black_money' or account
                xPlayer.setAccountMoney(fwAccount, amount)
                return true
            end,

            setJob = function(name, grade)
                xPlayer.setJob(name, grade or 0)
            end,

            getInventory = function()
                return xPlayer.inventory or {}
            end,
        }
    end

    Bridge.getPlayer = function(source)
        return wrapPlayer(ESX.GetPlayerFromId(source))
    end

    Bridge.getPlayerData = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.PlayerData or nil
    end

    Bridge.getJob = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getJob() or nil
    end

    Bridge.getGang = function(source) return nil end

    Bridge.getIdentifier = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or ''
    end

    Bridge.getPlayerName = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or GetPlayerName(source) or ''
    end

    Bridge.getMoney = function(source, account)
        local p = Bridge.getPlayer(source)
        return p and p.getMoney(account or 'cash') or 0
    end

    Bridge.addMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.addMoney(account or 'cash', amount, reason)
    end

    Bridge.removeMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.removeMoney(account or 'cash', amount, reason)
    end

    Bridge.setJob = function(source, job, grade)
        local p = Bridge.getPlayer(source)
        if p then p.setJob(job, grade) end
    end

    Bridge.getPlayers = function()
        local players = {}
        for _, xPlayer in ipairs(ESX.GetPlayers()) do
            players[#players + 1] = xPlayer.source
        end
        return players
    end

-- ─── QBCore ───────────────────────────────────────────────────────────────────
elseif Config.Framework == 'qbcore' then
    local QBCore = exports['qb-core']:GetCoreObject()

    local function wrapPlayer(Player)
        if not Player then return nil end
        local pd = Player.PlayerData
        return {
            source     = Player.PlayerData.source,
            raw        = Player,
            identifier = pd.citizenid,
            name       = (pd.charinfo and (pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)) or GetPlayerName(pd.source) or '',

            getJob = function()
                local j = pd.job
                return {
                    name       = j.name,
                    label      = j.label,
                    grade      = j.grade.level,
                    gradeLabel = j.grade.name,
                    isBoss     = j.isboss,
                    onDuty     = j.onduty,
                    salary     = j.payment or 0,
                }
            end,

            getGang = function()
                local g = pd.gang
                if not g then return nil end
                return {
                    name       = g.name,
                    label      = g.label,
                    grade      = g.grade.level,
                    gradeLabel = g.grade.label,
                    isBoss     = g.isboss,
                }
            end,

            getMoney = function(account)
                return pd.money[mapAccount(account)] or 0
            end,

            addMoney = function(account, amount, reason)
                Player.Functions.AddMoney(mapAccount(account), amount, reason or '')
                return true
            end,

            removeMoney = function(account, amount, reason)
                Player.Functions.RemoveMoney(mapAccount(account), amount, reason or '')
                return true
            end,

            setMoney = function(account, amount)
                Player.Functions.SetMoney(mapAccount(account), amount)
                return true
            end,

            setJob = function(name, grade)
                Player.Functions.SetJob(name, grade or 0)
            end,

            getInventory = function()
                return pd.items or {}
            end,
        }
    end

    Bridge.getPlayer = function(source)
        return wrapPlayer(QBCore.Functions.GetPlayer(source))
    end

    Bridge.getPlayerData = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData or nil
    end

    Bridge.getJob = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getJob() or nil
    end

    Bridge.getGang = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getGang() or nil
    end

    Bridge.getIdentifier = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or ''
    end

    Bridge.getPlayerName = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return GetPlayerName(source) or '' end
        local ci = Player.PlayerData.charinfo
        return ci and (ci.firstname .. ' ' .. ci.lastname) or GetPlayerName(source) or ''
    end

    Bridge.getMoney = function(source, account)
        local p = Bridge.getPlayer(source)
        return p and p.getMoney(account or 'cash') or 0
    end

    Bridge.addMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.addMoney(account or 'cash', amount, reason)
    end

    Bridge.removeMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.removeMoney(account or 'cash', amount, reason)
    end

    Bridge.setJob = function(source, job, grade)
        local p = Bridge.getPlayer(source)
        if p then p.setJob(job, grade) end
    end

    Bridge.getPlayers = function()
        local players = {}
        for _, Player in pairs(QBCore.Functions.GetPlayers()) do
            players[#players + 1] = Player
        end
        return players
    end

-- ─── QBox (qbx_core) ──────────────────────────────────────────────────────────
elseif Config.Framework == 'qbox' then
    local QBX = exports.qbx_core

    local function wrapPlayer(Player)
        if not Player then return nil end
        local pd = Player.PlayerData
        return {
            source     = pd.source,
            raw        = Player,
            identifier = pd.citizenid,
            name       = (pd.charinfo and (pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)) or GetPlayerName(pd.source) or '',

            getJob = function()
                local j = pd.job
                return {
                    name       = j.name,
                    label      = j.label,
                    grade      = j.grade.level,
                    gradeLabel = j.grade.name,
                    isBoss     = j.isboss,
                    onDuty     = j.onduty,
                    salary     = j.payment or 0,
                }
            end,

            getGang = function()
                local g = pd.gang
                if not g then return nil end
                return { name = g.name, label = g.label, grade = g.grade.level, gradeLabel = g.grade.label, isBoss = g.isboss }
            end,

            getMoney = function(account)
                return pd.money[mapAccount(account)] or 0
            end,

            addMoney = function(account, amount, reason)
                Player.Functions.AddMoney(mapAccount(account), amount, reason or '')
                return true
            end,

            removeMoney = function(account, amount, reason)
                Player.Functions.RemoveMoney(mapAccount(account), amount, reason or '')
                return true
            end,

            setMoney = function(account, amount)
                Player.Functions.SetMoney(mapAccount(account), amount)
                return true
            end,

            setJob = function(name, grade)
                Player.Functions.SetJob(name, grade or 0)
            end,

            getInventory = function()
                return pd.items or {}
            end,
        }
    end

    Bridge.getPlayer = function(source)
        return wrapPlayer(QBX:GetPlayer(source))
    end

    Bridge.getPlayerData = function(source)
        local p = QBX:GetPlayer(source)
        return p and p.PlayerData or nil
    end

    Bridge.getJob = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getJob() or nil
    end

    Bridge.getGang = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getGang() or nil
    end

    Bridge.getIdentifier = function(source)
        local p = QBX:GetPlayer(source)
        return p and p.PlayerData.citizenid or ''
    end

    Bridge.getPlayerName = function(source)
        local p = QBX:GetPlayer(source)
        if not p then return GetPlayerName(source) or '' end
        local ci = p.PlayerData.charinfo
        return ci and (ci.firstname .. ' ' .. ci.lastname) or GetPlayerName(source) or ''
    end

    Bridge.getMoney = function(source, account)
        local p = Bridge.getPlayer(source)
        return p and p.getMoney(account or 'cash') or 0
    end

    Bridge.addMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.addMoney(account or 'cash', amount, reason)
    end

    Bridge.removeMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.removeMoney(account or 'cash', amount, reason)
    end

    Bridge.setJob = function(source, job, grade)
        local p = Bridge.getPlayer(source)
        if p then p.setJob(job, grade) end
    end

    Bridge.getPlayers = function()
        local sources = {}
        for src, _ in pairs(QBX:GetQBPlayers()) do
            sources[#sources + 1] = src
        end
        return sources
    end

-- ─── ND_Core ──────────────────────────────────────────────────────────────────
elseif Config.Framework == 'nd' then
    local ND = exports['ND_Core']

    local function wrapPlayer(player, source)
        if not player then return nil end
        local jobInfo = player.jobInfo or {}
        return {
            source     = source,
            raw        = player,
            identifier = tostring(player.id),
            name       = (player.firstname or '') .. ' ' .. (player.lastname or ''),

            getJob = function()
                return {
                    name       = player.job      or 'unemployed',
                    label      = jobInfo.label   or 'Unemployed',
                    grade      = jobInfo.rank    or 0,
                    gradeLabel = jobInfo.rankName or '',
                    isBoss     = jobInfo.isBoss  or false,
                    onDuty     = true,
                    salary     = 0,
                }
            end,

            getGang = function() return nil end,

            getMoney = function(account)
                return player[account == 'cash' and 'cash' or account] or 0
            end,

            addMoney = function(account, amount, reason)
                ND:addMoney(source, account == 'cash' and 'cash' or account, amount)
                return true
            end,

            removeMoney = function(account, amount, reason)
                ND:removeMoney(source, account == 'cash' and 'cash' or account, amount)
                return true
            end,

            setMoney = function(account, amount)
                ND:setMoney(source, account, amount)
                return true
            end,

            setJob = function(name, grade)
                ND:setJob(source, name, grade or 0)
            end,

            getInventory = function()
                return {}
            end,
        }
    end

    Bridge.getPlayer = function(source)
        return wrapPlayer(ND:getPlayer(source), source)
    end

    Bridge.getPlayerData = function(source)
        return ND:getPlayer(source)
    end

    Bridge.getJob = function(source)
        local p = Bridge.getPlayer(source)
        return p and p.getJob() or nil
    end

    Bridge.getGang = function(source) return nil end

    Bridge.getIdentifier = function(source)
        local p = ND:getPlayer(source)
        return p and tostring(p.id) or ''
    end

    Bridge.getPlayerName = function(source)
        local p = ND:getPlayer(source)
        if not p then return GetPlayerName(source) or '' end
        return (p.firstname or '') .. ' ' .. (p.lastname or '')
    end

    Bridge.getMoney = function(source, account)
        local p = Bridge.getPlayer(source)
        return p and p.getMoney(account or 'cash') or 0
    end

    Bridge.addMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.addMoney(account or 'cash', amount, reason)
    end

    Bridge.removeMoney = function(source, account, amount, reason)
        local p = Bridge.getPlayer(source)
        if not p then return false end
        return p.removeMoney(account or 'cash', amount, reason)
    end

    Bridge.setJob = function(source, job, grade)
        local p = Bridge.getPlayer(source)
        if p then p.setJob(job, grade) end
    end

    Bridge.getPlayers = function()
        local sources = {}
        for src in pairs(ND:getPlayers()) do
            sources[#sources + 1] = src
        end
        return sources
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else
    local function getLicense(source)
        for i = 0, GetNumPlayerIdentifiers(source) - 1 do
            local id = GetPlayerIdentifier(source, i)
            if id:find('license:') then return id end
        end
        return 'license:' .. tostring(source)
    end

    Bridge.getPlayer = function(source)
        return {
            source     = source,
            raw        = nil,
            identifier = getLicense(source),
            name       = GetPlayerName(source) or '',
            getJob     = function() return { name = 'unemployed', label = 'Unemployed', grade = 0, gradeLabel = '', isBoss = false, onDuty = true, salary = 0 } end,
            getGang    = function() return nil end,
            getMoney   = function() return 0 end,
            addMoney   = function() return false end,
            removeMoney = function() return false end,
            setMoney   = function() return false end,
            setJob     = function() end,
            getInventory = function() return {} end,
        }
    end

    Bridge.getPlayerData  = function(source) return {} end
    Bridge.getJob         = function(source) return { name = 'unemployed', label = 'Unemployed', grade = 0, gradeLabel = '', isBoss = false, onDuty = true, salary = 0 } end
    Bridge.getGang        = function(source) return nil end
    Bridge.getIdentifier  = function(source) return getLicense(source) end
    Bridge.getPlayerName  = function(source) return GetPlayerName(source) or '' end
    Bridge.getMoney       = function(source, account) return 0 end
    Bridge.addMoney       = function(source, account, amount, reason) return false end
    Bridge.removeMoney    = function(source, account, amount, reason) return false end
    Bridge.setJob         = function(source, job, grade) end
    Bridge.getPlayers     = function()
        local sources = {}
        for _, src in ipairs(GetPlayers()) do
            sources[#sources + 1] = tonumber(src)
        end
        return sources
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  EXTENDED FUNCTIONS  (appended after per-framework blocks)
--
--  Bridge.setGang(source, gang, grade)
--  Bridge.getPlayerByIdentifier(identifier)   → normalised player | nil
--
--  Bridge.getMetadata(source, key)            → any
--  Bridge.setMetadata(source, key, value)     → void
--
--  Bridge.getLicenses(source)                 → table
--  Bridge.hasLicense(source, license)         → bool
--  Bridge.addLicense(source, license)         → void
--  Bridge.removeLicense(source, license)      → void
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── setGang ──────────────────────────────────────────────────────────────────
if Config.Framework == 'qbcore' then
    local _QBCore = exports['qb-core']:GetCoreObject()

    Bridge.setGang = function(source, gang, grade)
        local Player = _QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.SetGang(gang, grade or 0) end
    end

elseif Config.Framework == 'qbox' then
    local _QBX = exports.qbx_core

    Bridge.setGang = function(source, gang, grade)
        local Player = _QBX:GetPlayer(source)
        if Player then Player.Functions.SetGang(gang, grade or 0) end
    end

else
    -- ESX and ND_Core have no gang system
    Bridge.setGang = function() end
end

-- ─── getPlayerByIdentifier ────────────────────────────────────────────────────
if Config.Framework == 'qbcore' then
    local _QBCore2 = exports['qb-core']:GetCoreObject()

    Bridge.getPlayerByIdentifier = function(identifier)
        local Player = _QBCore2.Functions.GetPlayerByCitizenId(identifier)
        return Player and Bridge.getPlayer(Player.PlayerData.source) or nil
    end

elseif Config.Framework == 'qbox' then
    local _QBX2 = exports.qbx_core

    Bridge.getPlayerByIdentifier = function(identifier)
        local Player = _QBX2:GetPlayerByCitizenId(identifier)
        return Player and Bridge.getPlayer(Player.PlayerData.source) or nil
    end

elseif Config.Framework == 'esx' then
    local _ESX2 = exports['es_extended']:getSharedObject()

    Bridge.getPlayerByIdentifier = function(identifier)
        for _, xPlayer in ipairs(_ESX2.GetPlayers()) do
            if xPlayer.identifier == identifier then
                return Bridge.getPlayer(xPlayer.source)
            end
        end
        return nil
    end

elseif Config.Framework == 'nd' then
    local _ND2 = exports['ND_Core']

    Bridge.getPlayerByIdentifier = function(identifier)
        for src, player in pairs(_ND2:getPlayers()) do
            if tostring(player.id) == tostring(identifier) then
                return Bridge.getPlayer(src)
            end
        end
        return nil
    end

else
    Bridge.getPlayerByIdentifier = function() return nil end
end

-- ─── Metadata ─────────────────────────────────────────────────────────────────
if Config.Framework == 'qbcore' then
    local _QBCoreMeta = exports['qb-core']:GetCoreObject()

    Bridge.getMetadata = function(source, key)
        local Player = _QBCoreMeta.Functions.GetPlayer(source)
        return Player and Player.Functions.GetMetaData(key) or nil
    end

    Bridge.setMetadata = function(source, key, value)
        local Player = _QBCoreMeta.Functions.GetPlayer(source)
        if Player then Player.Functions.SetMetaData(key, value) end
    end

elseif Config.Framework == 'qbox' then
    local _QBXMeta = exports.qbx_core

    Bridge.getMetadata = function(source, key)
        local Player = _QBXMeta:GetPlayer(source)
        return Player and Player.Functions.GetMetaData(key) or nil
    end

    Bridge.setMetadata = function(source, key, value)
        local Player = _QBXMeta:GetPlayer(source)
        if Player then Player.Functions.SetMetaData(key, value) end
    end

elseif Config.Framework == 'esx' then
    -- ESX has no native metadata; use FiveM statebags as a universal store.
    Bridge.getMetadata = function(source, key)
        return Player(source).state[key]
    end

    Bridge.setMetadata = function(source, key, value)
        Player(source).state:set(key, value, true)
    end

elseif Config.Framework == 'nd' then
    local _NDMeta = exports['ND_Core']

    Bridge.getMetadata = function(source, key)
        local p = _NDMeta:getPlayer(source)
        return p and p[key] or nil
    end

    Bridge.setMetadata = function(source, key, value)
        _NDMeta:setPlayerData(source, key, value)
    end

else
    Bridge.getMetadata = function() return nil end
    Bridge.setMetadata = function() end
end

-- ─── Licenses ─────────────────────────────────────────────────────────────────
if Config.Framework == 'qbcore' then
    local _QBCoreLic = exports['qb-core']:GetCoreObject()

    Bridge.getLicenses = function(source)
        local Player = _QBCoreLic.Functions.GetPlayer(source)
        return Player and Player.Functions.GetMetaData('licences') or {}
    end

    Bridge.hasLicense = function(source, license)
        local lics = Bridge.getLicenses(source)
        return lics[license] == true
    end

    Bridge.addLicense = function(source, license)
        local Player = _QBCoreLic.Functions.GetPlayer(source)
        if Player then Player.Functions.AddLicence(license) end
    end

    Bridge.removeLicense = function(source, license)
        local Player = _QBCoreLic.Functions.GetPlayer(source)
        if Player then Player.Functions.RemoveLicence(license) end
    end

elseif Config.Framework == 'qbox' then
    local _QBXLic = exports.qbx_core

    Bridge.getLicenses = function(source)
        local Player = _QBXLic:GetPlayer(source)
        return Player and Player.Functions.GetMetaData('licences') or {}
    end

    Bridge.hasLicense = function(source, license)
        local lics = Bridge.getLicenses(source)
        return lics[license] == true
    end

    Bridge.addLicense = function(source, license)
        local Player = _QBXLic:GetPlayer(source)
        if Player then Player.Functions.AddLicence(license) end
    end

    Bridge.removeLicense = function(source, license)
        local Player = _QBXLic:GetPlayer(source)
        if Player then Player.Functions.RemoveLicence(license) end
    end

elseif Config.Framework == 'esx' then
    local _ESXLic = exports['es_extended']:getSharedObject()

    Bridge.getLicenses = function(source)
        local xPlayer = _ESXLic.GetPlayerFromId(source)
        return xPlayer and xPlayer.getLicences() or {}
    end

    Bridge.hasLicense = function(source, license)
        for _, lic in ipairs(Bridge.getLicenses(source)) do
            if lic.type == license then return true end
        end
        return false
    end

    Bridge.addLicense = function(source, license)
        local xPlayer = _ESXLic.GetPlayerFromId(source)
        if xPlayer then xPlayer.addLicence(license, license) end
    end

    Bridge.removeLicense = function(source, license)
        local xPlayer = _ESXLic.GetPlayerFromId(source)
        if xPlayer then xPlayer.removeLicence(license) end
    end

else
    -- ND_Core and standalone have no license system
    Bridge.getLicenses   = function() return {} end
    Bridge.hasLicense    = function() return false end
    Bridge.addLicense    = function() end
    Bridge.removeLicense = function() end
end
