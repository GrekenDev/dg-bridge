--[[
    bridge/client/fuel.lua

    Bridge.getVehicleFuel(vehicle) → number  (0.0 – 100.0)
    Bridge.setVehicleFuel(vehicle, amount)   → void

    `vehicle` – vehicle entity handle (number)
    `amount`  – fuel level 0–100
]]

local fuel = Config.Fuel

-- ─── ox_fuel ──────────────────────────────────────────────────────────────────
-- ox_fuel exposes no GetFuel/SetFuel exports — its README states outright that
-- the API is the entity statebag, and calling exports on it throws "No such
-- export". Reading falls back to the native so a vehicle that ox_fuel has not
-- touched yet still reports a sane level; writing mirrors what ox_fuel's own
-- setFuel does: set the native, then the replicated statebag.
if fuel == 'ox_fuel' then

    Bridge.getVehicleFuel = function(vehicle)
        return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        amount = math.max(0.0, math.min(100.0, (amount or 0) + 0.0))
        SetVehicleFuelLevel(vehicle, amount)
        Entity(vehicle).state:set('fuel', amount, true)
    end

-- ─── LegacyFuel ───────────────────────────────────────────────────────────────
elseif fuel == 'LegacyFuel' then

    Bridge.getVehicleFuel = function(vehicle)
        return exports['LegacyFuel']:GetFuel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        exports['LegacyFuel']:SetFuel(vehicle, amount)
    end

-- ─── ps-fuel ──────────────────────────────────────────────────────────────────
elseif fuel == 'ps-fuel' then

    Bridge.getVehicleFuel = function(vehicle)
        return exports['ps-fuel']:GetFuel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        exports['ps-fuel']:SetFuel(vehicle, amount)
    end

-- ─── cdn-fuel ─────────────────────────────────────────────────────────────────
elseif fuel == 'cdn-fuel' then

    Bridge.getVehicleFuel = function(vehicle)
        return exports['cdn-fuel']:GetFuel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        exports['cdn-fuel']:SetFuel(vehicle, amount)
    end

-- ─── standalone ───────────────────────────────────────────────────────────────
else
    if fuel and fuel ~= 'standalone' then
        print('^3[dg-bridge] Unknown Config.Fuel value: "' .. tostring(fuel) .. '" — using native fuel level.^0')
    end

    Bridge.getVehicleFuel = function(vehicle)
        return GetVehicleFuelLevel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        SetVehicleFuelLevel(vehicle, amount + 0.0)
    end
end
