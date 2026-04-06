--[[
    bridge/client/progress.lua

    Bridge.showProgress(data, callback)
        data = {
            label       = string,               -- text shown on bar
            duration    = number,               -- ms
            useWhileDead = false,               -- optional
            canCancel    = true,                -- optional
            anim = {                            -- optional
                dict       = string,
                clip       = string,
                flag       = number,            -- default 49
                blendIn    = number,            -- default 8.0
                blendOut   = number,            -- default 8.0
                playbackRate = number,          -- default 0.0
                lockX / lockY / lockZ = bool,
            },
            prop = {                            -- optional
                model  = string,
                bone   = number,               -- default 57005
                pos    = vector3,
                rot    = vector3,
            },
            disable = {                         -- optional
                move   = bool,
                car    = bool,
                combat = bool,
                mouse  = bool,
            },
        }
        callback(cancelled: bool)  — called when done or cancelled

    Bridge.cancelProgress()
    Bridge.isProgressActive()  → bool
]]

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
if Config.Progress == 'ox_lib' then
    Bridge.showProgress = function(data, cb)
        local disable = data.disable or {}
        local anim    = data.anim
        local prop    = data.prop

        local options = {
            duration  = data.duration or 5000,
            label     = data.label    or '',
            useWhileDead = data.useWhileDead or false,
            canCancel    = data.canCancel ~= false,
            disable = {
                move   = disable.move   or false,
                car    = disable.car    or false,
                combat = disable.combat or false,
                mouse  = disable.mouse  or false,
            },
        }

        if anim then
            options.anim = {
                dict        = anim.dict,
                clip        = anim.clip,
                flag        = anim.flag        or 49,
                blendIn     = anim.blendIn     or 8.0,
                blendOut    = anim.blendOut    or 8.0,
                playbackRate = anim.playbackRate or 0.0,
                lockX = anim.lockX or false,
                lockY = anim.lockY or false,
                lockZ = anim.lockZ or false,
            }
        end

        if prop then
            options.prop = {
                model = prop.model,
                bone  = prop.bone or 57005,
                pos   = prop.pos  or vec3(0, 0, 0),
                rot   = prop.rot  or vec3(0, 0, 0),
            }
        end

        local cancelled = not exports.ox_lib:progressBar(options)
        if cb then cb(cancelled) end
    end

    Bridge.cancelProgress = function()
        exports.ox_lib:cancelProgress()
    end

    Bridge.isProgressActive = function()
        return exports.ox_lib:progressActive()
    end

-- ─── QBCore ───────────────────────────────────────────────────────────────────
elseif Config.Progress == 'qbcore' then
    local QBCore  = exports['qb-core']:GetCoreObject()
    local _active = false

    Bridge.showProgress = function(data, cb)
        local disable = data.disable or {}
        local anim    = data.anim

        _active = true
        QBCore.Functions.Progressbar(
            'dg_progress_' .. math.random(10000, 99999),
            data.label or '',
            data.duration or 5000,
            data.useWhileDead or false,
            data.canCancel ~= false,
            {
                disableMovement   = disable.move   or false,
                disableCarMovement= disable.car    or false,
                disableMouse      = disable.mouse  or false,
                disableCombat     = disable.combat or false,
            },
            anim and {
                animDict = anim.dict,
                anim     = anim.clip,
                flags    = anim.flag or 49,
            } or {},
            {},
            {},
            function()   -- finished
                _active = false
                if cb then cb(false) end
            end,
            function()   -- cancelled
                _active = false
                if cb then cb(true) end
            end
        )
    end

    Bridge.cancelProgress = function()
        TriggerEvent('progressbar:client:cancel')
    end

    Bridge.isProgressActive = function()
        return _active
    end

-- ─── ESX (esx_progressbar) ────────────────────────────────────────────────────
elseif Config.Progress == 'esx' then
    local _active = false

    Bridge.showProgress = function(data, cb)
        local disable = data.disable or {}
        local anim    = data.anim

        _active = true
        exports['esx_progressbar']:Progressbar(
            'dg_progress',
            data.label or '',
            data.duration or 5000,
            false,
            {
                disableMovement   = disable.move   or false,
                disableCarMovement= disable.car    or false,
                disableMouse      = disable.mouse  or false,
                disableCombat     = disable.combat or false,
            },
            anim and { animDict = anim.dict, anim = anim.clip, flags = anim.flag or 49 } or {},
            {}, {},
            function()
                _active = false
                if cb then cb(false) end
            end
        )
    end

    Bridge.cancelProgress = function()
        TriggerEvent('esx_progressbar:cancel')
    end

    Bridge.isProgressActive = function()
        return _active
    end

-- ─── mythic_progbar ───────────────────────────────────────────────────────────
elseif Config.Progress == 'mythic' then
    local _active = false

    Bridge.showProgress = function(data, cb)
        local disable = data.disable or {}
        local anim    = data.anim

        _active = true
        exports['mythic_progbar']:StartProgressBar('dg_progress', data.label or '', data.duration or 5000, false, {
            disableMovement   = disable.move   or false,
            disableCarMovement= disable.car    or false,
            disableMouse      = disable.mouse  or false,
            disableCombat     = disable.combat or false,
        }, anim and { animDict = anim.dict, anim = anim.clip, flags = anim.flag or 49 } or {}, {}, {},
        function(cancelled)
            _active = false
            if cb then cb(cancelled) end
        end)
    end

    Bridge.cancelProgress = function()
        exports['mythic_progbar']:CancelProgressBar()
    end

    Bridge.isProgressActive = function()
        return _active
    end

-- ─── standalone (simple timer, no visuals) ───────────────────────────────────
else
    local _active    = false
    local _cancelled = false

    Bridge.showProgress = function(data, cb)
        _active    = true
        _cancelled = false
        local duration = data.duration or 5000
        local start    = GetGameTimer()

        CreateThread(function()
            while _active and GetGameTimer() - start < duration do
                Wait(0)
            end
            _active = false
            if cb then cb(_cancelled) end
        end)
    end

    Bridge.cancelProgress = function()
        _cancelled = true
        _active    = false
    end

    Bridge.isProgressActive = function()
        return _active
    end
end
