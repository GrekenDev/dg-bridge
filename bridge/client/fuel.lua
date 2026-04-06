--[[
    bridge/client/fuel.lua

    Bridge.getVehicleFuel(vehicle) → number  (0.0 – 100.0)
    Bridge.setVehicleFuel(vehicle, amount)   → void

    `vehicle` – vehicle entity handle (number)
    `amount`  – fuel level 0–100
]]

local fuel = Config.Fuel

-- ─── ox_fuel ──────────────────────────────────────────────────────────────────
if fuel == 'ox_fuel' then

    Bridge.getVehicleFuel = function(vehicle)
        return exports.ox_fuel:GetFuel(vehicle) or 0.0
    end

    Bridge.setVehicleFuel = function(vehicle, amount)
        exports.ox_fuel:SetFuel(vehicle, amount)
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
