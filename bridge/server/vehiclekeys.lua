--[[
    bridge/server/vehiclekeys.lua

    Unified API:
        Bridge.giveVehicleKeys(source, plate)       -- give player keys server-side
        Bridge.removeVehicleKeys(source, plate)     -- remove player's keys server-side
        Bridge.hasVehicleKeys(source, plate)        -- returns bool (where supported, else nil)

    `plate` should be a plate string (trimmed/uppercased automatically).

    Supported Config.VehicleKeys values:
        'qb-vehiclekeys'      → TriggerClientEvent to qb-vehiclekeys
        'qbx_vehiclekeys'     → TriggerClientEvent to qbx_vehiclekeys
        'Renewed-vehiclekeys' → Renewed-vehiclekeys server exports
        'mrnewbs_vehiclekeys' → mrnewbs_vehiclekeys server exports
        'wasabi_carlock'      → wasabi_carlock server exports
        't1ger_keys'          → TriggerClientEvent to t1ger_keys
        'mono_keys'           → mono_keys server exports
        'codem-vehiclekeys'   → codem-vehiclekeys server exports
        'standalone'          → TriggerClientEvent to local client store
]]

local function normPlate(plate)
    if not plate then return nil end
    return plate:upper():gsub('%s+', '')
end

local _give, _remove, _has

-- ─── qb-vehiclekeys ───────────────────────────────────────────────────────────
if Config.VehicleKeys == 'qb-vehiclekeys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', source, plate)
    end

    _has = function() return nil end

-- ─── qbx_vehiclekeys ──────────────────────────────────────────────────────────
-- qbx_vehiclekeys is entirely entity-based (no plate API).
-- Internal events let the client trigger give/remove through server exports.
elseif Config.VehicleKeys == 'qbx_vehiclekeys' then

    local function findVehicleByPlate(plate)
        ---@diagnostic disable-next-line: param-type-mismatch
        for _, veh in ipairs(GetAllVehicles()) do
            if GetVehicleNumberPlateText(veh):upper():gsub('%s+', '') == plate then
                return veh
            end
        end
        return nil
    end

    -- Client-initiated give/remove (triggered via TriggerServerEvent from client bridge)
    RegisterNetEvent('dg-bridge:qbx_keys:give', function(netId)
        local src = source
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if vehicle and vehicle ~= 0 then
            exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)
        end
    end)

    RegisterNetEvent('dg-bridge:qbx_keys:remove', function(netId)
        local src = source
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if vehicle and vehicle ~= 0 then
            exports.qbx_vehiclekeys:RemoveKeys(src, vehicle, true)
        end
    end)

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        local vehicle = findVehicleByPlate(plate)
        if not vehicle then return end
        exports.qbx_vehiclekeys:GiveKeys(source, vehicle, true)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        local vehicle = findVehicleByPlate(plate)
        if not vehicle then return end
        exports.qbx_vehiclekeys:RemoveKeys(source, vehicle, true)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        local vehicle = findVehicleByPlate(plate)
        if not vehicle then return false end
        return exports.qbx_vehiclekeys:HasKeys(source, vehicle) == true
    end

-- ─── Renewed-vehiclekeys ──────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'Renewed-vehiclekeys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports['Renewed-vehiclekeys']:addKey(source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports['Renewed-vehiclekeys']:removeKey(source, plate)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        return exports['Renewed-vehiclekeys']:hasKey(source, plate) == true
    end

-- ─── mrnewbs_vehiclekeys ──────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'mrnewbs_vehiclekeys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.mrnewbs_vehiclekeys:GiveKeysByPlate(source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.mrnewbs_vehiclekeys:RemoveKeysByPlate(source, plate)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        return exports.mrnewbs_vehiclekeys:HasKeysByPlate(source, plate) == true
    end

-- ─── wasabi_carlock ───────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'wasabi_carlock' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.wasabi_carlock:GiveKeys(source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.wasabi_carlock:RemoveKeys(source, plate)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        return exports.wasabi_carlock:HasKeys(source, plate) == true
    end

-- ─── t1ger_keys ───────────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 't1ger_keys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('t1ger_keys:client:AddKey', source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('t1ger_keys:client:RemoveKey', source, plate)
    end

    _has = function() return nil end

-- ─── mono_keys ────────────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'mono_keys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.mono_keys:GiveKeys(source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports.mono_keys:RemoveKeys(source, plate)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        return exports.mono_keys:HasKeys(source, plate) == true
    end

-- ─── codem-vehiclekeys ────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'codem-vehiclekeys' then

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports['codem-vehiclekeys']:GiveKey(source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        exports['codem-vehiclekeys']:RemoveKey(source, plate)
    end

    _has = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return false end
        return exports['codem-vehiclekeys']:HasKey(source, plate) == true
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else

    _give = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('dg-bridge:vehiclekeys:give', source, plate)
    end

    _remove = function(source, plate)
        plate = normPlate(plate)
        if not plate or not source then return end
        TriggerClientEvent('dg-bridge:vehiclekeys:remove', source, plate)
    end

    -- Key state lives client-side; not queryable from server in standalone mode
    _has = function() return nil end

end

Bridge.giveVehicleKeys   = _give
Bridge.removeVehicleKeys = _remove
Bridge.hasVehicleKeys    = _has
