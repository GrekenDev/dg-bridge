--[[
    bridge/server/log.lua

    Unified audit/action logging bridge.

    Bridge.log(source, action, details, level)
        source  : number  — player source (pass 0 for system events)
        action  : string  — short action identifier, e.g. 'society:withdraw'
        details : table   — arbitrary key/value pairs included in the log entry
        level   : string  — 'info' | 'warn' | 'error' | 'critical'  (default: 'info')
]]

local backend = Config.Logging

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
-- lib.logger routes to whichever backend ox_lib is configured for
-- (Loki, Datadog, Fivemanage, etc.) — see ox_lib server config.
if backend == 'ox_lib' then
    local lib = rawget(_G, 'lib') ---@type table

    Bridge.log = function(source, action, details, level)
        local meta = details or {}
        if source and source > 0 then
            meta.source     = source
            meta.playerName = GetPlayerName(source) or 'unknown'
        end
        lib.logger(GetCurrentResourceName(), level or 'info', action, meta)
    end

-- ─── discord ──────────────────────────────────────────────────────────────────
-- Posts a simple embed to a Discord webhook.
elseif backend == 'discord' then

    local webhook = Config.LoggingWebhook
    local colours = { info = 3447003, warn = 16776960, error = 15158332, critical = 10038562 }

    Bridge.log = function(source, action, details, level)
        if not webhook or webhook == '' then return end
        local lvl    = level or 'info'
        local colour = colours[lvl] or colours.info

        local fields = {}
        if source and source > 0 then
            fields[#fields + 1] = { name = 'Player', value = GetPlayerName(source) or 'unknown', inline = true }
            fields[#fields + 1] = { name = 'Source', value = tostring(source), inline = true }
        end
        if details then
            for k, v in pairs(details) do
                fields[#fields + 1] = { name = tostring(k), value = tostring(v), inline = true }
            end
        end

        local payload = json.encode({
            embeds = {{
                title       = '[' .. string.upper(lvl) .. '] ' .. action,
                color       = colour,
                fields      = fields,
                footer      = { text = GetCurrentResourceName() },
                timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            }}
        })

        PerformHttpRequest(webhook, function() end, 'POST', payload, { ['Content-Type'] = 'application/json' })
    end

-- ─── none / fallback ──────────────────────────────────────────────────────────
else
    if backend and backend ~= 'none' then
        print('^3[dg-bridge] Unknown Config.Logging value: "' .. tostring(backend) .. '" — logging disabled.^0')
    end

    Bridge.log = function() end
end
