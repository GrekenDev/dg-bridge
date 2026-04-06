--[[
    bridge/client/inventory.lua
    Client-side inventory checks (read-only).

    Bridge.hasItem(item, count)       → bool
    Bridge.getItemCount(item)         → number
    Bridge.openInventory()            → void  (opens own inventory UI)

    NOTE: Not all inventory systems expose client-side item checks.
          For definitive checks, always use the server-side bridge functions.
]]

-- ─── ox_inventory ─────────────────────────────────────────────────────────────
if Config.Inventory == 'ox_inventory' then
    Bridge.hasItem = function(item, count)
        count = count or 1
        local items = exports.ox_inventory:Search('count', item)
        return (items or 0) >= count
    end

    Bridge.getItemCount = function(item)
        return exports.ox_inventory:Search('count', item) or 0
    end

    Bridge.openInventory = function()
        -- ox_inventory does not expose a client-side open export in all versions
        TriggerEvent('ox_inventory:openInventory')
    end

-- ─── qb-inventory ─────────────────────────────────────────────────────────────
elseif Config.Inventory == 'qb-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()

    Bridge.hasItem = function(item, count)
        count = count or 1
        local items = QBCore.Functions.GetPlayerData().items
        if not items then return false end
        local total = 0
        for _, v in pairs(items) do
            if v.name == item then
                total = total + (v.amount or 1)
            end
        end
        return total >= count
    end

    Bridge.getItemCount = function(item)
        local items = QBCore.Functions.GetPlayerData().items
        if not items then return 0 end
        local total = 0
        for _, v in pairs(items) do
            if v.name == item then
                total = total + (v.amount or 1)
            end
        end
        return total
    end

    Bridge.openInventory = function()
        TriggerEvent('inventory:client:SetCurrentInventory')
    end

-- ─── ps-inventory ─────────────────────────────────────────────────────────────
elseif Config.Inventory == 'ps-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()

    Bridge.hasItem = function(item, count)
        count = count or 1
        local items = QBCore.Functions.GetPlayerData().items
        if not items then return false end
        local total = 0
        for _, v in pairs(items) do
            if v and v.name == item then
                total = total + (v.amount or 1)
            end
        end
        return total >= count
    end

    Bridge.getItemCount = function(item)
        local items = QBCore.Functions.GetPlayerData().items
        if not items then return 0 end
        local total = 0
        for _, v in pairs(items) do
            if v and v.name == item then
                total = total + (v.amount or 1)
            end
        end
        return total
    end

    Bridge.openInventory = function()
        TriggerEvent('ps-inventory:client:openInventory')
    end

-- ─── codem-inventory ──────────────────────────────────────────────────────────
elseif Config.Inventory == 'codem-inventory' then
    Bridge.hasItem = function(item, count)
        count = count or 1
        local result = exports['codem-inventory']:GetItemCount(item)
        return (result or 0) >= count
    end

    Bridge.getItemCount = function(item)
        return exports['codem-inventory']:GetItemCount(item) or 0
    end

    Bridge.openInventory = function()
        TriggerEvent('inventory:client:openInventory')
    end

-- ─── origen_inventory ─────────────────────────────────────────────────────────
elseif Config.Inventory == 'origen_inventory' then
    Bridge.hasItem = function(item, count)
        count = count or 1
        local result = exports['origen_inventory']:GetItemCount(item)
        return (result or 0) >= count
    end

    Bridge.getItemCount = function(item)
        return exports['origen_inventory']:GetItemCount(item) or 0
    end

    Bridge.openInventory = function()
        TriggerEvent('origen_inventory:openInventory')
    end

-- ─── esx default ──────────────────────────────────────────────────────────────
elseif Config.Inventory == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    Bridge.hasItem = function(item, count)
        count = count or 1
        local data = ESX.GetPlayerData()
        if not data or not data.inventory then return false end
        for _, v in pairs(data.inventory) do
            if v.name == item and v.count >= count then return true end
        end
        return false
    end

    Bridge.getItemCount = function(item)
        local data = ESX.GetPlayerData()
        if not data or not data.inventory then return 0 end
        for _, v in pairs(data.inventory) do
            if v.name == item then return v.count or 0 end
        end
        return 0
    end

    Bridge.openInventory = function()
        TriggerEvent('esx_inventoryhud:openInventory')
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else
    Bridge.hasItem = function(item, count)
        return false -- No inventory configured
    end

    Bridge.getItemCount = function(item)
        return 0
    end

    Bridge.openInventory = function() end
end
