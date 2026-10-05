--[[
    bridge/server/society.lua

    Provides a unified interface for society / boss-banking scripts so that any
    DG script can manage job finances without knowing which banking resource is
    installed.

    ── Job accounts ────────────────────────────────────────────────────────────
    Bridge.getSocietyMoney(job)              → number
    Bridge.addSocietyMoney(job, amount)      → bool
    Bridge.removeSocietyMoney(job, amount)   → bool

    ── Gang accounts ────────────────────────────────────────────────────────────
    Bridge.getGangMoney(gang)               → number
    Bridge.addGangMoney(gang, amount)       → bool
    Bridge.removeGangMoney(gang, amount)    → bool

    `job` / `gang` – name string (e.g. 'police', 'ballas')
    `amount`        – positive integer

    Not all backends support gang accounts. Unsupported ones log a warning and
    return safe no-ops (0 / false).
]]

local sm = Config.SocietyManagement

-- ─── dg-banking ───────────────────────────────────────────────────────────────
-- Development By Greken / DG. Job and gang accounts share one account registry
-- keyed by the job or gang name, so both use the same three exports.
if sm == 'dg-banking' then

    Bridge.getSocietyMoney = function(job)
        return exports['dg-banking']:GetAccountBalance(job) or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        return exports['dg-banking']:AddAccountMoney(job, amount, 'dg-bridge') == true
    end

    Bridge.removeSocietyMoney = function(job, amount)
        return exports['dg-banking']:RemoveAccountMoney(job, amount, 'dg-bridge') == true
    end

    Bridge.getGangMoney = function(gang)
        return exports['dg-banking']:GetAccountBalance(gang) or 0
    end

    Bridge.addGangMoney = function(gang, amount)
        return exports['dg-banking']:AddAccountMoney(gang, amount, 'dg-bridge') == true
    end

    Bridge.removeGangMoney = function(gang, amount)
        return exports['dg-banking']:RemoveAccountMoney(gang, amount, 'dg-bridge') == true
    end

-- ─── Renewed-Banking ──────────────────────────────────────────────────────────
-- https://renewed.dev/banking/exports
-- Gangs use the same account API with the gang name as the account identifier.
elseif sm == 'Renewed-Banking' then

    Bridge.getSocietyMoney = function(job)
        return exports['Renewed-Banking']:getAccountMoney(job) or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        return exports['Renewed-Banking']:addAccountMoney(job, amount) ~= false
    end

    Bridge.removeSocietyMoney = function(job, amount)
        return exports['Renewed-Banking']:removeAccountMoney(job, amount) ~= false
    end

    Bridge.getGangMoney = function(gang)
        return exports['Renewed-Banking']:getAccountMoney(gang) or 0
    end

    Bridge.addGangMoney = function(gang, amount)
        return exports['Renewed-Banking']:addAccountMoney(gang, amount) ~= false
    end

    Bridge.removeGangMoney = function(gang, amount)
        return exports['Renewed-Banking']:removeAccountMoney(gang, amount) ~= false
    end

-- ─── qb-management ────────────────────────────────────────────────────────────
-- https://docs.qbcore.org/qbcore-documentation/qbcore-resources/qb-management
elseif sm == 'qb-management' then

    Bridge.getSocietyMoney = function(job)
        return exports['qb-management']:GetAccount(job) or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        exports['qb-management']:AddMoney(job, amount)
        return true
    end

    Bridge.removeSocietyMoney = function(job, amount)
        exports['qb-management']:RemoveMoney(job, amount)
        return true
    end

    Bridge.getGangMoney = function(gang)
        return exports['qb-management']:GetGangAccount(gang) or 0
    end

    Bridge.addGangMoney = function(gang, amount)
        exports['qb-management']:AddGangMoney(gang, amount)
        return true
    end

    Bridge.removeGangMoney = function(gang, amount)
        exports['qb-management']:RemoveGangMoney(gang, amount)
        return true
    end

-- ─── esx_society ──────────────────────────────────────────────────────────────
-- esx_society has no direct server exports for money ops; uses esx_addonaccount
-- shared accounts named 'society_<job>' (e.g. 'society_police').
-- ESX has no gang system so gang money variants are no-ops.
elseif sm == 'esx_society' then

    local function getAccount(name, cb)
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. name, cb)
    end

    Bridge.getSocietyMoney = function(job)
        local p = promise.new()
        getAccount(job, function(account)
            p:resolve(account and account.money or 0)
        end)
        return Citizen.Await(p)
    end

    Bridge.addSocietyMoney = function(job, amount)
        local p = promise.new()
        getAccount(job, function(account)
            if account then account.addMoney(amount) end
            p:resolve(account ~= nil)
        end)
        return Citizen.Await(p)
    end

    Bridge.removeSocietyMoney = function(job, amount)
        local p = promise.new()
        getAccount(job, function(account)
            if account then account.removeMoney(amount) end
            p:resolve(account ~= nil)
        end)
        return Citizen.Await(p)
    end

    Bridge.getGangMoney    = function() return 0 end
    Bridge.addGangMoney    = function() return false end
    Bridge.removeGangMoney = function() return false end

-- ─── fd_banking ───────────────────────────────────────────────────────────────
-- https://docs.felis.gg/banking/exports
elseif sm == 'fd_banking' then

    Bridge.getSocietyMoney = function(job)
        local account = exports.fd_banking:GetAccount(job)
        return account and account.balance or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        exports.fd_banking:AddMoney(job, amount)
        return true
    end

    Bridge.removeSocietyMoney = function(job, amount)
        exports.fd_banking:RemoveMoney(job, amount)
        return true
    end

    Bridge.getGangMoney = function(gang)
        local account = exports.fd_banking:GetGangAccount(gang)
        return account and account.balance or 0
    end

    Bridge.addGangMoney = function(gang, amount)
        exports.fd_banking:AddGangMoney(gang, amount)
        return true
    end

    Bridge.removeGangMoney = function(gang, amount)
        exports.fd_banking:RemoveGangMoney(gang, amount)
        return true
    end

-- ─── wasabi_banking ───────────────────────────────────────────────────────────
-- https://docs.wasabiscripts.com/wasabi-scripts/core-ui-series/wasabi_banking/exports
-- wasabi_banking does not have dedicated gang account exports.
elseif sm == 'wasabi_banking' then

    Bridge.getSocietyMoney = function(job)
        return exports.wasabi_banking:GetAccountBalance(job, 'society') or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        return exports.wasabi_banking:AddMoney('society', job, amount) ~= false
    end

    Bridge.removeSocietyMoney = function(job, amount)
        return exports.wasabi_banking:RemoveMoney('society', job, amount) ~= false
    end

    Bridge.getGangMoney    = function() return 0 end
    Bridge.addGangMoney    = function() return false end
    Bridge.removeGangMoney = function() return false end

-- ─── crm-banking ──────────────────────────────────────────────────────────────
-- https://corem.gitbook.io/welcome/crm-banking/exports
-- crm-banking does not expose dedicated gang account exports.
elseif sm == 'crm-banking' then

    Bridge.getSocietyMoney = function(job)
        return exports['crm-banking']:getSocietyMoney(job) or 0
    end

    Bridge.addSocietyMoney = function(job, amount)
        return exports['crm-banking']:addSocietyMoney(job, amount) ~= false
    end

    Bridge.removeSocietyMoney = function(job, amount)
        return exports['crm-banking']:removeSocietyMoney(job, amount) ~= false
    end

    Bridge.getGangMoney    = function() return 0 end
    Bridge.addGangMoney    = function() return false end
    Bridge.removeGangMoney = function() return false end

-- ─── none / fallback ──────────────────────────────────────────────────────────
else
    if sm and sm ~= 'none' then
        print('^3[dg-bridge] Unknown Config.SocietyManagement value: "' .. tostring(sm) .. '" — society functions disabled.^0')
    end

    Bridge.getSocietyMoney    = function() return 0 end
    Bridge.addSocietyMoney    = function() return false end
    Bridge.removeSocietyMoney = function() return false end
    Bridge.getGangMoney       = function() return 0 end
    Bridge.addGangMoney       = function() return false end
    Bridge.removeGangMoney    = function() return false end
end
