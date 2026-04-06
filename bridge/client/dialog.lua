--[[
    bridge/client/dialog.lua
    Immersive NPC conversation dialog — multi-page with ped face-cam.

    ── USAGE ────────────────────────────────────────────────────────────────────
    Bridge.showDialog(data)
        data = {
            ped     = number,           -- ped entity handle (for bl_dialog cam)
            title   = string,           -- fallback title (used by ox_lib context menu)
            dialogs = {
                {
                    id   = string,      -- unique page id
                    name = string,      -- NPC display name
                    text = string,      -- dialog body text
                    buttons = {
                        {
                            label      = string,
                            nextDialog = string,    -- switch to this page id on click
                            close      = bool,      -- close dialog on click
                            onSelect   = function(switchDialog) end,  -- optional callback
                        }
                    }
                }
            }
        }

    ── CONFIG ────────────────────────────────────────────────────────────────────
    Set Config.NPCDialog in config.lua:
        'bl_dialog'  → bl_dialog (exports.bl_dialog:showDialog)
        'ox_lib'     → ox_lib context menu fallback
        'standalone' → console no-op
]]

-- ── bl_dialog ─────────────────────────────────────────────────────────────────
if Config.NPCDialog == 'bl_dialog' then
    Bridge.showDialog = function(data)
        exports.bl_dialog:showDialog({
            ped    = data.ped,
            dialog = data.dialogs,
        })
    end

-- ── ox_lib (context menu fallback) ───────────────────────────────────────────
elseif Config.NPCDialog == 'ox_lib' then
    Bridge.showDialog = function(data)
        local dialogs = data.dialogs or {}
        local pageMap = {}
        for _, d in ipairs(dialogs) do
            pageMap[d.id] = d
        end

        local function openPage(pageId)
            local page = pageMap[pageId]
            if not page then return end

            local options = {}
            for _, btn in ipairs(page.buttons or {}) do
                local b = btn
                options[#options + 1] = {
                    title    = b.label,
                    onSelect = function()
                        if b.onSelect then b.onSelect(openPage) end
                        if b.nextDialog then
                            openPage(b.nextDialog)
                        elseif b.close then
                            Bridge.closeContext()
                        end
                    end,
                }
            end

            local menuId = 'dg_dialog_' .. pageId
            exports.ox_lib:registerContext({
                id      = menuId,
                title   = page.name or data.title or '',
                options = options,
            })
            exports.ox_lib:showContext(menuId)
        end

        if dialogs[1] then
            openPage(dialogs[1].id)
        end
    end

-- ── standalone (no-op) ────────────────────────────────────────────────────────
else
    Bridge.showDialog = function(data)
        print('^3[dg-bridge] showDialog: Config.NPCDialog is "standalone" — no dialog shown.^0')
        if data and data.dialogs and data.dialogs[1] then
            local d = data.dialogs[1]
            print(('  NPC: %s | Text: %s'):format(d.name or '?', d.text or '?'))
            for i, btn in ipairs(d.buttons or {}) do
                print(('  [%d] %s'):format(i, btn.label or '?'))
            end
        end
    end
end
