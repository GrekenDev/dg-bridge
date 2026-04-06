--[[
    bridge/client/dispatch.lua

    Bridge.sendDispatch(data)
        data = {
            message  = string,                          -- 'Armed Robbery'
            code     = string,                          -- '10-31'
            icon     = string,                          -- Font Awesome class
            coords   = vector3,                         -- defaults to player position
            jobs     = table,                           -- { 'police', 'sheriff' }
            priority = number,                          -- 1-3 (optional)
            metadata = {                                -- optional key-value rows
                { label='Street', value='Vinewood' },
            },
        }

    The client-side call internally triggers the server event dg-bridge:dispatch
    which the server bridge handles with the configured dispatch resource.
    Direct client dispatch is also attempted for resources that support it.
]]

Bridge.sendDispatch = function(data)
    local coords = data.coords or GetEntityCoords(PlayerPedId())
    data.coords  = coords

    -- Forward to server for resources that require server-side triggering
    TriggerServerEvent('dg-bridge:dispatch', data)
end

-- ─── standalone: receive blip event from server ────────────────────────────
RegisterNetEvent('dg-bridge:dispatch:addBlip', function(data)
    if not data or not data.coords then return end
    local c = data.coords

    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, 161)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1)  -- red
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('[%s] %s'):format(data.code or '10-31', data.message or 'Alert'))
    EndTextCommandSetBlipName(blip)

    SetTimeout(data.duration or 30000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)
