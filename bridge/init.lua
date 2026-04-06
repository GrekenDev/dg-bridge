--[[
    bridge/init.lua  (shared — runs on both client and server)

    Creates the global `Bridge` table.  Every function assigned to Bridge is
    automatically registered as an export so other resources can call it via
        exports['dg-bridge']:functionName(...)
    and retrieve a direct reference via the import helpers.
]]

---@class Bridge
Bridge = setmetatable({}, {
    __newindex = function(self, name, fn)
        exports(name, function() return fn end)
        rawset(self, name, fn)
    end,
})
