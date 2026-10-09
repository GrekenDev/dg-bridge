--[[
    bridge/client/vehiclekeys.lua

    Unified API:
        Bridge.giveVehicleKeys(vehicle, plate)      -- give local player keys
        Bridge.removeVehicleKeys(vehicle, plate)    -- remove local player's keys
        Bridge.hasVehicleKeys(plate)                -- returns bool
        Bridge.setVehicleLocked(vehicle, locked)    -- true = locked, false = unlocked

    `vehicle` may be an entity handle or nil.
    `plate`   may be a plate string or nil (derived from vehicle when omitted).
    At least one of the two must be provided.

    Supported Config.VehicleKeys values:
        'qb-vehiclekeys'      → qb-vehiclekeys       (QBCore / QBox)
        'qbx_vehiclekeys'     → qbx_vehiclekeys      (QBox community)
        'Renewed-vehiclekeys' → Renewed-vehiclekeys  (Renewed)
        'mrnewbs_vehiclekeys' → mrnewbs_vehiclekeys  (MrNewb)
        'wasabi_carlock'      → wasabi_carlock        (Wasabi Scripts)
        't1ger_keys'          → t1ger_keys            (t1ger)
        'mono_keys'           → mono_keys             (Nox_Aeterna)
        'codem-vehiclekeys'   → codem-vehiclekeys     (CodeM)
        'standalone'          → SetVehicleDoorsLocked native (no extra resource)
]]

local function normPlate(vehicle, plate)
    if plate then return plate:upper():gsub('%s+', '') end
    if vehicle and DoesEntityExist(vehicle) then
        return GetVehicleNumberPlateText(vehicle):upper():gsub('%s+', '')
    end
    return nil
end

local _give, _remove, _has, _setLocked

-- ─── qb-vehiclekeys ───────────────────────────────────────────────────────────
if Config.VehicleKeys == 'qb-vehiclekeys' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['qb-vehiclekeys']:GiveKeys(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['qb-vehiclekeys']:RemoveKeys(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports['qb-vehiclekeys']:HasKeys(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── qbx_vehiclekeys ──────────────────────────────────────────────────────────
-- qbx_vehiclekeys is entirely entity-based (no plate API).
-- Give/Remove are server-only exports, so the client triggers internal events.
elseif Config.VehicleKeys == 'qbx_vehiclekeys' then

    local function findVehicleByPlate(plate)
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if GetVehicleNumberPlateText(veh):upper():gsub('%s+', '') == plate then
                return veh
            end
        end
        return nil
    end

    _give = function(vehicle, plate)
        local veh = (vehicle and DoesEntityExist(vehicle)) and vehicle
                    or findVehicleByPlate(normPlate(nil, plate))
        if not veh then return end
        TriggerServerEvent('dg-bridge:qbx_keys:give', NetworkGetNetworkIdFromEntity(veh))
    end

    _remove = function(vehicle, plate)
        local veh = (vehicle and DoesEntityExist(vehicle)) and vehicle
                    or findVehicleByPlate(normPlate(nil, plate))
        if not veh then return end
        TriggerServerEvent('dg-bridge:qbx_keys:remove', NetworkGetNetworkIdFromEntity(veh))
    end

    _has = function(plate)
        if not plate then return false end
        local veh = findVehicleByPlate(plate:upper():gsub('%s+', ''))
        if not veh then return false end
        return exports.qbx_vehiclekeys:HasKeys(veh) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── Renewed-vehiclekeys ──────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'Renewed-vehiclekeys' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['Renewed-vehiclekeys']:addKey(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['Renewed-vehiclekeys']:removeKey(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports['Renewed-vehiclekeys']:hasKey(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── mrnewbs_vehiclekeys ──────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'mrnewbs_vehiclekeys' then

    _give = function(vehicle, plate)
        if vehicle and DoesEntityExist(vehicle) then
            exports.mrnewbs_vehiclekeys:GiveKeys(vehicle)
        else
            plate = normPlate(vehicle, plate)
            if plate then exports.mrnewbs_vehiclekeys:GiveKeysByPlate(plate) end
        end
    end

    _remove = function(vehicle, plate)
        if vehicle and DoesEntityExist(vehicle) then
            exports.mrnewbs_vehiclekeys:RemoveKeys(vehicle)
        else
            plate = normPlate(vehicle, plate)
            if plate then exports.mrnewbs_vehiclekeys:RemoveKeysByPlate(plate) end
        end
    end

    _has = function(plate)
        if not plate then return false end
        return exports.mrnewbs_vehiclekeys:HasKeysByPlate(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── wasabi_carlock ───────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'wasabi_carlock' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.wasabi_carlock:GiveKeys(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.wasabi_carlock:RemoveKeys(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports.wasabi_carlock:HasKeys(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        local plate = normPlate(vehicle, nil)
        if locked then
            exports.wasabi_carlock:lockVehicle(vehicle, plate)
        else
            exports.wasabi_carlock:unlockVehicle(vehicle, plate)
        end
    end

-- ─── t1ger_keys ───────────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 't1ger_keys' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.t1ger_keys:AddKey(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.t1ger_keys:RemoveKey(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports.t1ger_keys:HasKey(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── mono_keys ────────────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'mono_keys' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.mono_keys:GiveKeys(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports.mono_keys:RemoveKeys(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports.mono_keys:HasKeys(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── codem-vehiclekeys ────────────────────────────────────────────────────────
elseif Config.VehicleKeys == 'codem-vehiclekeys' then

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['codem-vehiclekeys']:GiveKey(plate)
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if not plate then return end
        exports['codem-vehiclekeys']:RemoveKey(plate)
    end

    _has = function(plate)
        if not plate then return false end
        return exports['codem-vehiclekeys']:HasKey(plate:upper():gsub('%s+', '')) == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else

    -- Key ownership tracked locally in a simple plate set.
    -- Server-side give/remove relay via dg-bridge:vehiclekeys client events.
    local _ownedPlates = {}

    RegisterNetEvent('dg-bridge:vehiclekeys:give', function(plate)
        if plate then _ownedPlates[plate] = true end
    end)

    RegisterNetEvent('dg-bridge:vehiclekeys:remove', function(plate)
        if plate then _ownedPlates[plate] = nil end
    end)

    _give = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if plate then _ownedPlates[plate] = true end
    end

    _remove = function(vehicle, plate)
        plate = normPlate(vehicle, plate)
        if plate then _ownedPlates[plate] = nil end
    end

    _has = function(plate)
        if not plate then return false end
        return _ownedPlates[plate:upper():gsub('%s+', '')] == true
    end

    _setLocked = function(vehicle, locked)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end

end

Bridge.giveVehicleKeys  = _give
Bridge.removeVehicleKeys = _remove
Bridge.hasVehicleKeys   = _has
Bridge.setVehicleLocked = _setLocked
