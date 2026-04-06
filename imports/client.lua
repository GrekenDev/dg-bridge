--[[
    imports/client.lua
    ─────────────────────────────────────────────────────────────────────────────
    Add this file to your script's fxmanifest.lua to get a lazily-loaded
    Bridge table with all client-side functions pre-linked.

    In fxmanifest.lua of your script:
        shared_scripts {
            '@dg-bridge/imports/client.lua',
        }

    Then in any client Lua file:
        -- Bridge is available as a global
        Bridge.notify('Hello!', 'success', 3000)
        Bridge.showTextUI('[E] Interact', 'default')
        Bridge.showProgress({ label = 'Working...', duration = 5000 }, function(cancelled)
            if not cancelled then
                -- done
            end
        end)

    All functions are loaded on first access (lazy), so there's zero overhead
    until you actually call something.
]]

local _exp = exports['dg-bridge']

---@class Bridge
Bridge = setmetatable({}, {
    __index = function(self, key)
        local fn = _exp[key]
        if fn then
            -- Call the export which returns the actual function reference
            local ref = fn(_exp)
            rawset(self, key, ref)
            return ref
        end
    end,
})
