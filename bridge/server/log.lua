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
-- (Loki, Datadog, Fivemanage) via the ox:logger convar — see ox_lib docs.
if backend == 'ox_lib' then

    -- lib.logger is an ox_lib import module, not an export, so it is only
    -- reachable through @ox_lib/init.lua. It is loaded here instead of in the
    -- manifest so servers without ox_lib can still run the bridge.
    local function loadOxLib()
        local chunk = LoadResourceFile('ox_lib', 'init.lua')
        if not chunk then return nil, 'ox_lib/init.lua not found' end

        local fn, err = load(chunk, '@@ox_lib/init.lua')
        if not fn then return nil, err end

        local ok, loadErr = pcall(fn)
        if not ok then return nil, loadErr end

        return rawget(_G, 'lib')
    end

    local lib, err = loadOxLib()

    if not lib then
        print(('^3[dg-bridge] Config.Logging = "ox_lib" but ox_lib could not be loaded (%s) — logging disabled.^0'):format(tostring(err)))
        Bridge.log = function() end
    else
        Bridge.log = function(source, action, details, level)
            local message = { action }
            local tags    = { 'level:' .. (level or 'info') }

            for key, value in pairs(details or {}) do
                local text = tostring(value)
                message[#message + 1] = ('%s=%s'):format(key, text)
                -- ox_lib's providers split tags on ',' and ':'
                tags[#tags + 1] = ('%s:%s'):format(key, (text:gsub('[,:]', ' ')))
            end

            -- ox_lib adds the player's name and identifiers itself when source > 0
            lib.logger(source or 0, action, table.concat(message, ' '), table.unpack(tags))
        end
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
