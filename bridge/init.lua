--[[
    bridge/init.lua  (shared — runs on both client and server)

    Creates the global `Bridge` table.  Every function assigned to Bridge is
    automatically registered as an export that RETURNS the function instead of
    calling it, so a direct call takes two steps:
        local notify = exports['dg-bridge']:notify()
        notify('Hello!', 'success')
    imports/client.lua and imports/server.lua rely on this to hand out direct
    references, so other resources should normally use those instead.
    Don't change this: DG scripts depend on it.
]]

---@class Bridge
Bridge = setmetatable({}, {
    __newindex = function(self, name, fn)
        exports(name, function() return fn end)
        rawset(self, name, fn)
    end,
})
