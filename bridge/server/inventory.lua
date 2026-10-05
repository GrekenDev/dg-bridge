--[[
    bridge/server/inventory.lua

    Bridge.hasItem(source, item, count)                       → bool
    Bridge.getItemCount(source, item)                         → number
    Bridge.getItem(source, item)                              → item table | nil
    Bridge.getInventory(source)                               → table
    Bridge.addItem(source, item, count, metadata, slot)       → bool
    Bridge.removeItem(source, item, count, metadata, slot)    → bool
    Bridge.clearInventory(source)                             → void
    Bridge.registerUsableItem(item, cb)                       → void
    Bridge.openInventory(source)                              → void
    Bridge.openInventoryFor(source, targetSource)             → void
]]

-- ─── ox_inventory / dg_inventory ─────────────────────────────────────────────
-- dg_inventory is a fork of ox_inventory with the same API, so both share one
-- implementation and only the resource name differs.
if Config.Inventory == 'ox_inventory' or Config.Inventory == 'dg_inventory' then
    local inventory = exports[Config.Inventory]

    Bridge.hasItem = function(source, item, count)
        count = count or 1
        local result = inventory:Search(source, 'count', item)
        return (result or 0) >= count
    end

    Bridge.getItemCount = function(source, item)
        return inventory:Search(source, 'count', item) or 0
    end

    Bridge.getItem = function(source, item)
        local result = inventory:Search(source, 'slots', item)
        return result and result[1] or nil
    end

    Bridge.getInventory = function(source)
        return inventory:GetInventoryItems(source) or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        return inventory:AddItem(source, item, count or 1, metadata, slot) ~= false
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        return inventory:RemoveItem(source, item, count or 1, metadata, slot) ~= false
    end

    Bridge.clearInventory = function(source)
        inventory:ClearInventory(source)
    end

    Bridge.registerUsableItem = function(item, cb)
        inventory:RegisterUsableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent(Config.Inventory .. ':openInventory', source)
    end

    Bridge.openInventoryFor = function(source, targetSource)
        inventory:OpenInventory(source, { type = 'player', id = targetSource })
    end

-- ─── qb-inventory ─────────────────────────────────────────────────────────────
elseif Config.Inventory == 'qb-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()

    Bridge.hasItem = function(source, item, count)
        count = count or 1
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local inv = Player.Functions.GetItemByName(item)
        return inv ~= nil and inv.amount >= count
    end

    Bridge.getItemCount = function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        local inv = Player.Functions.GetItemByName(item)
        return inv and inv.amount or 0
    end

    Bridge.getItem = function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return nil end
        return Player.Functions.GetItemByName(item)
    end

    Bridge.getInventory = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.items or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(item, count or 1, slot, metadata) ~= false
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, count or 1, slot) ~= false
    end

    Bridge.clearInventory = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then Player.Functions.ClearInventory() end
    end

    Bridge.registerUsableItem = function(item, cb)
        QBCore.Functions.CreateUseableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent('inventory:client:SetCurrentInventory', source, 'player', source)
    end

    Bridge.openInventoryFor = function(source, targetSource)
        TriggerClientEvent('inventory:client:SetCurrentInventory', source, 'player', targetSource)
    end

-- ─── ps-inventory ─────────────────────────────────────────────────────────────
elseif Config.Inventory == 'ps-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()

    Bridge.hasItem = function(source, item, count)
        count = count or 1
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local inv = Player.Functions.GetItemByName(item)
        return inv ~= nil and inv.amount >= count
    end

    Bridge.getItemCount = function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        local inv = Player.Functions.GetItemByName(item)
        return inv and inv.amount or 0
    end

    Bridge.getItem = function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return nil end
        return Player.Functions.GetItemByName(item)
    end

    Bridge.getInventory = function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.items or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        return exports['ps-inventory']:AddItem(source, item, count or 1, slot, metadata) ~= false
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        return exports['ps-inventory']:RemoveItem(source, item, count or 1, slot, metadata) ~= false
    end

    Bridge.clearInventory = function(source)
        exports['ps-inventory']:ClearInventory(source)
    end

    Bridge.registerUsableItem = function(item, cb)
        exports['ps-inventory']:CreateUsableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent('ps-inventory:client:openInventory', source)
    end

    Bridge.openInventoryFor = function(source, targetSource)
        TriggerClientEvent('ps-inventory:client:openInventory', source, targetSource)
    end

-- ─── codem-inventory ──────────────────────────────────────────────────────────
elseif Config.Inventory == 'codem-inventory' then
    Bridge.hasItem = function(source, item, count)
        count = count or 1
        return (exports['codem-inventory']:GetItemCount(source, item) or 0) >= count
    end

    Bridge.getItemCount = function(source, item)
        return exports['codem-inventory']:GetItemCount(source, item) or 0
    end

    Bridge.getItem = function(source, item)
        return exports['codem-inventory']:GetItemsByName(source, item)
    end

    Bridge.getInventory = function(source)
        return exports['codem-inventory']:GetInventory(source) or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        return exports['codem-inventory']:AddItem(source, item, count or 1, metadata) ~= false
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        return exports['codem-inventory']:RemoveItem(source, item, count or 1) ~= false
    end

    Bridge.clearInventory = function(source)
        exports['codem-inventory']:ClearInventory(source)
    end

    Bridge.registerUsableItem = function(item, cb)
        exports['codem-inventory']:registerUsableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent('inventory:client:openInventory', source)
    end

    Bridge.openInventoryFor = function(source, targetSource)
        TriggerClientEvent('inventory:client:openInventory', source, targetSource)
    end

-- ─── origen_inventory ─────────────────────────────────────────────────────────
elseif Config.Inventory == 'origen_inventory' then
    Bridge.hasItem = function(source, item, count)
        count = count or 1
        return (exports['origen_inventory']:GetItemCount(source, item) or 0) >= count
    end

    Bridge.getItemCount = function(source, item)
        return exports['origen_inventory']:GetItemCount(source, item) or 0
    end

    Bridge.getItem = function(source, item)
        return exports['origen_inventory']:GetItemByName(source, item)
    end

    Bridge.getInventory = function(source)
        return exports['origen_inventory']:GetInventory(source) or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        return exports['origen_inventory']:AddItem(source, item, count or 1, metadata, slot) ~= false
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        return exports['origen_inventory']:RemoveItem(source, item, count or 1, metadata, slot) ~= false
    end

    Bridge.clearInventory = function(source)
        exports['origen_inventory']:ClearInventory(source)
    end

    Bridge.registerUsableItem = function(item, cb)
        exports['origen_inventory']:CreateUsableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent('origen_inventory:openInventory', source)
    end

    Bridge.openInventoryFor = function(source, targetSource)
        TriggerClientEvent('origen_inventory:openInventory', source, targetSource)
    end

-- ─── esx default ──────────────────────────────────────────────────────────────
elseif Config.Inventory == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    Bridge.hasItem = function(source, item, count)
        count = count or 1
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local inv = xPlayer.getInventoryItem(item)
        return inv ~= nil and inv.count >= count
    end

    Bridge.getItemCount = function(source, item)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end
        local inv = xPlayer.getInventoryItem(item)
        return inv and inv.count or 0
    end

    Bridge.getItem = function(source, item)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end
        return xPlayer.getInventoryItem(item)
    end

    Bridge.getInventory = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.inventory or {}
    end

    Bridge.addItem = function(source, item, count, metadata, slot)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.addInventoryItem(item, count or 1)
        return true
    end

    Bridge.removeItem = function(source, item, count, metadata, slot)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.removeInventoryItem(item, count or 1)
        return true
    end

    Bridge.clearInventory = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.clearInventory() end
    end

    Bridge.registerUsableItem = function(item, cb)
        ESX.RegisterUsableItem(item, function(source)
            cb(source)
        end)
    end

    Bridge.openInventory = function(source)
        TriggerClientEvent('esx_inventoryhud:openInventory', source)
    end

    Bridge.openInventoryFor = function(source, targetSource) end

-- ─── standalone ───────────────────────────────────────────────────────────────
else
    Bridge.hasItem           = function(source, item, count) return false end
    Bridge.getItemCount      = function(source, item) return 0 end
    Bridge.getItem           = function(source, item) return nil end
    Bridge.getInventory      = function(source) return {} end
    Bridge.addItem           = function(source, item, count, metadata, slot) return false end
    Bridge.removeItem        = function(source, item, count, metadata, slot) return false end
    Bridge.clearInventory    = function(source) end
    Bridge.registerUsableItem = function(item, cb) end
    Bridge.openInventory     = function(source) end
    Bridge.openInventoryFor  = function(source, targetSource) end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  ITEM DEFINITIONS
--
--  Bridge.getItemInfo(item)                  → { name, label, weight, description, image } | nil
--  Bridge.canCarryItem(source, item, count, metadata) → bool
--
--  `image` is a full nui:// URL the UI can use directly.
-- ─────────────────────────────────────────────────────────────────────────────

local function imageUrl(resource, item, custom)
    if type(custom) == 'string' and custom ~= '' then
        if custom:match('^[%w]+://') then return custom end
        return ('nui://%s/web/images/%s'):format(resource, custom)
    end
    return ('nui://%s/web/images/%s.png'):format(resource, item)
end

if Config.Inventory == 'ox_inventory' or Config.Inventory == 'dg_inventory' then
    local inventory = exports[Config.Inventory]
    local imagePath = GetConvar('inventory:imagepath', ('nui://%s/web/images'):format(Config.Inventory))

    Bridge.getItemInfo = function(item)
        local data = inventory:Items(item)
        if not data then return nil end

        local image = data.client and data.client.image
        if type(image) ~= 'string' or image == '' then
            image = ('%s/%s.png'):format(imagePath, item)
        elseif not image:match('^[%w]+://') then
            image = ('%s/%s'):format(imagePath, image)
        end

        return {
            name        = item,
            label       = data.label or item,
            weight      = data.weight or 0,
            description = data.description,
            image       = image,
        }
    end

    Bridge.canCarryItem = function(source, item, count, metadata)
        return inventory:CanCarryItem(source, item, count or 1, metadata) == true
    end

elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()
    local resource = Config.Inventory

    Bridge.getItemInfo = function(item)
        local data = QBCore.Shared.Items[item]
        if not data then return nil end

        return {
            name        = item,
            label       = data.label or item,
            weight      = data.weight or 0,
            description = data.description,
            image       = imageUrl(resource == 'ps-inventory' and 'ps-inventory' or 'qb-inventory', item, data.image),
        }
    end

    Bridge.canCarryItem = function(source, item, count)
        local ok, result = pcall(function()
            return exports[resource]:CanAddItem(source, item, count or 1)
        end)
        if not ok then return true end
        return result ~= false
    end

elseif Config.Inventory == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    Bridge.getItemInfo = function(item)
        local label = ESX.GetItemLabel(item)
        if not label then return nil end

        return { name = item, label = label, weight = 0, image = imageUrl('esx_inventoryhud', item) }
    end

    Bridge.canCarryItem = function(source, item, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        return xPlayer.canCarryItem(item, count or 1)
    end

else
    -- codem / origen / standalone: no reliable definition lookup, so callers
    -- fall back to their own config.
    Bridge.getItemInfo  = function() return nil end
    Bridge.canCarryItem = function() return true end
end
