--[[
    bridge/client/textui.lua

    Bridge.showTextUI(text, type, position)
        text     : string
        type     : 'default' | 'success' | 'error' | 'warning'  (optional)
        position : 'left-center' | 'top-center' | 'right-center' (optional, ox_lib)

    Bridge.hideTextUI()
    Bridge.isTextUIOpen() → bool
]]

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
if Config.TextUI == 'ox_lib' then
    Bridge.showTextUI = function(text, ntype, position)
        exports.ox_lib:showTextUI(text, {
            position = position or 'left-center',
            icon     = ntype == 'success' and 'check'
                    or ntype == 'error'   and 'xmark'
                    or ntype == 'warning' and 'triangle-exclamation'
                    or nil,
        })
    end

    Bridge.hideTextUI = function()
        exports.ox_lib:hideTextUI()
    end

    Bridge.isTextUIOpen = function()
        return exports.ox_lib:isTextUIOpen()
    end

-- ─── okokTextUI ───────────────────────────────────────────────────────────────
elseif Config.TextUI == 'okok' then
    local _open = false

    Bridge.showTextUI = function(text, ntype, position)
        _open = true
        exports['okokTextUI']:Open(text, 'white', 'left')
    end

    Bridge.hideTextUI = function()
        _open = false
        exports['okokTextUI']:Close()
    end

    Bridge.isTextUIOpen = function()
        return _open
    end

-- ─── QBCore DrawText ──────────────────────────────────────────────────────────
elseif Config.TextUI == 'qbcore' then
    local QBCore = exports['qb-core']:GetCoreObject()
    local _open  = false

    Bridge.showTextUI = function(text, ntype, position)
        _open = true
        QBCore.Functions.DrawText(text, 'left')
    end

    Bridge.hideTextUI = function()
        _open = false
        QBCore.Functions.HideText()
    end

    Bridge.isTextUIOpen = function()
        return _open
    end

-- ─── ps-ui ────────────────────────────────────────────────────────────────────
elseif Config.TextUI == 'ps-ui' then
    local _open = false

    Bridge.showTextUI = function(text, ntype, position)
        _open = true
        exports['ps-ui']:ShowText(text, 'left')
    end

    Bridge.hideTextUI = function()
        _open = false
        exports['ps-ui']:HideText()
    end

    Bridge.isTextUIOpen = function()
        return _open
    end

-- ─── lation_ui ────────────────────────────────────────────────────────────────
elseif Config.TextUI == 'lation' then
    local _open = false

    Bridge.showTextUI = function(text, ntype, position)
        _open = true
        exports['lation_ui']:textUI(text, ntype or 'default')
    end

    Bridge.hideTextUI = function()
        _open = false
        exports['lation_ui']:hideTextUI()
    end

    Bridge.isTextUIOpen = function()
        return _open
    end

-- ─── standalone (3D DrawText above ped) ──────────────────────────────────────
else
    local _open  = false
    local _text  = ''

    Bridge.showTextUI = function(text, ntype, position)
        _text = text
        if _open then return end
        _open = true

        CreateThread(function()
            while _open do
                local ped    = PlayerPedId()
                local coords = GetEntityCoords(ped)
                DrawText3D(coords.x, coords.y, coords.z + 1.0, _text)
                Wait(0)
            end
        end)
    end

    Bridge.hideTextUI = function()
        _open = false
        _text = ''
    end

    Bridge.isTextUIOpen = function()
        return _open
    end

    -- Simple 3D text helper used by standalone fallback
    function DrawText3D(x, y, z, text)
        local onScreen, sx, sy = World3dToScreen2d(x, y, z)
        if not onScreen then return end
        local px, py, pz = table.unpack(GetGameplayCamCoords())
        local dist = #(vector3(px, py, pz) - vector3(x, y, z))
        local scale = (1 / dist) * 2
        local fov   = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov

        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(sx, sy)
    end
end
