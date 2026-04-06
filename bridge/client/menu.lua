--[[
    bridge/client/menu.lua
    Context menus + Radial menus.

    ── CONTEXT MENU ─────────────────────────────────────────────────────────────
    Bridge.openContext(data)
        data = {
            id      = string,           -- unique menu id
            title   = string,
            options = {
                {
                    title       = string,
                    description = string,           -- optional
                    icon        = string,           -- Font Awesome class e.g. 'fa-solid fa-star'
                    disabled    = bool,             -- optional
                    metadata    = {                 -- optional key-value pairs shown in ox
                        { label='Key', value='Value' }
                    },
                    onSelect    = function() end,   -- callback
                    arrow       = bool,             -- optional (show sub-menu arrow)
                    menu        = string,           -- optional (ox: open another context by id)
                }
            },
        }

    Bridge.closeContext()

    ── RADIAL MENU ──────────────────────────────────────────────────────────────
    Bridge.addRadialItem(data)
        data = {
            id       = string,
            label    = string,
            icon     = string,          -- Font Awesome or game icon name
            menu     = string,          -- optional: open a nested radial
            onSelect = function() end,  -- callback (used when no sub-menu)
        }

    Bridge.removeRadialItem(id)
]]

local _radialItems = {}   -- cache for standalone radial fallback

-- ─────────────────────────────────────────────────────────────────────────────
--  CONTEXT MENU
-- ─────────────────────────────────────────────────────────────────────────────

-- ── ox_lib ───────────────────────────────────────────────────────────────────
if Config.ContextMenu == 'ox_lib' then
    Bridge.openContext = function(data)
        local id   = data.id or ('dg_ctx_' .. math.random(10000, 99999))
        local opts = {}

        for i, opt in ipairs(data.options or {}) do
            opts[i] = {
                title       = opt.title,
                description = opt.description,
                icon        = opt.icon,
                disabled    = opt.disabled,
                metadata    = opt.metadata,
                arrow       = opt.arrow or (opt.menu ~= nil),
                menu        = opt.menu,
                onSelect    = opt.onSelect,
            }
        end

        exports.ox_lib:registerContext({ id = id, title = data.title or '', options = opts })
        exports.ox_lib:showContext(id)
        return id
    end

    Bridge.closeContext = function()
        exports.ox_lib:hideContext()
    end

-- ── qb-menu ──────────────────────────────────────────────────────────────────
elseif Config.ContextMenu == 'qb-menu' then
    Bridge.openContext = function(data)
        local menu = {
            { header = data.title or '', isMenuHeader = true },
        }

        for _, opt in ipairs(data.options or {}) do
            menu[#menu + 1] = {
                header   = opt.title,
                txt      = opt.description or '',
                icon     = opt.icon,
                disabled = opt.disabled,
                onSelect = opt.onSelect,
            }
        end

        exports['qb-menu']:openMenu(menu)
    end

    Bridge.closeContext = function()
        exports['qb-menu']:closeMenu()
    end

-- ── lation_ui ────────────────────────────────────────────────────────────────
elseif Config.ContextMenu == 'lation' then
    Bridge.openContext = function(data)
        local opts = {}
        for _, opt in ipairs(data.options or {}) do
            opts[#opts + 1] = {
                title       = opt.title,
                description = opt.description,
                icon        = opt.icon,
                disabled    = opt.disabled,
                onSelect    = opt.onSelect,
            }
        end

        exports['lation_ui']:openContext({
            title   = data.title or '',
            options = opts,
        })
    end

    Bridge.closeContext = function()
        exports['lation_ui']:closeContext()
    end

-- ── standalone (basic NUI-less list) ─────────────────────────────────────────
else
    local _menuOpen    = false
    local _menuOptions = {}

    Bridge.openContext = function(data)
        _menuOptions = data.options or {}
        _menuOpen    = true

        print('^5[dg-bridge] Context menu opened: ' .. (data.title or '') .. ' — ' .. #_menuOptions .. ' options^0')
        for i, opt in ipairs(_menuOptions) do
            print(('[%d] %s'):format(i, opt.title or 'Option'))
        end
    end

    Bridge.closeContext = function()
        _menuOpen    = false
        _menuOptions = {}
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  RADIAL MENU
-- ─────────────────────────────────────────────────────────────────────────────

-- ── ox_lib ───────────────────────────────────────────────────────────────────
if Config.RadialMenu == 'ox_lib' then
    Bridge.addRadialItem = function(data)
        exports.ox_lib:addRadialItem({
            {
                id       = data.id,
                label    = data.label,
                icon     = data.icon,
                menu     = data.menu,
                onSelect = data.onSelect,
            }
        })
    end

    Bridge.removeRadialItem = function(id)
        exports.ox_lib:removeRadialItem(id)
    end

-- ── qb-radialmenu ────────────────────────────────────────────────────────────
elseif Config.RadialMenu == 'qb-radial' then
    Bridge.addRadialItem = function(data)
        -- qb-radialmenu uses event-based sub-menus; onSelect needs an event
        local eventName = 'dg:radial:' .. (data.id or math.random(10000, 99999))
        if data.onSelect then
            RegisterNetEvent(eventName)
            AddEventHandler(eventName, data.onSelect)
        end

        exports['qb-radialmenu']:AddOption({
            id      = data.id,
            title   = data.label,
            icon    = data.icon or 'hand',
            type    = 'client',
            event   = eventName,
        })

        _radialItems[data.id] = true
    end

    Bridge.removeRadialItem = function(id)
        -- qb-radialmenu does not natively support removal; best-effort
        _radialItems[id] = nil
    end

-- ── standalone ───────────────────────────────────────────────────────────────
else
    Bridge.addRadialItem = function(data)
        _radialItems[data.id] = data
        print(('[dg-bridge] Radial item registered (standalone): %s'):format(data.label or data.id))
    end

    Bridge.removeRadialItem = function(id)
        _radialItems[id] = nil
    end
end
