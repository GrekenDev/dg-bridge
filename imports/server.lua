--[[
    imports/server.lua
    ─────────────────────────────────────────────────────────────────────────────
    Add this file to your script's fxmanifest.lua to get a lazily-loaded
    Bridge table with all server-side functions pre-linked.

    In fxmanifest.lua of your script:
        shared_scripts {
            '@dg-bridge/imports/server.lua',
        }

    Then in any server Lua file:
        -- Bridge is available as a global
        local player = Bridge.getPlayer(source)
        Bridge.addItem(source, 'bread', 1)
        Bridge.notify(source, 'You received bread!', 'success', 4000)

    All functions are loaded on first access (lazy).
]]

local _exp = exports['dg-bridge']

---@class Bridge
Bridge = setmetatable({}, {
    __index = function(self, key)
        local fn = _exp[key]
        if fn then
            local ref = fn(_exp)
            rawset(self, key, ref)
            return ref
        end
    end,
})
