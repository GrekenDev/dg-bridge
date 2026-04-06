--[[
    bridge/server/phone.lua

    Unified interface for phone resources.

    Bridge.getPhoneNumber(source)                   → string | nil
    Bridge.sendSMS(number, title, message)          → void

        source  – player server source
        number  – recipient phone number string
        title   – sender label / display name shown in the conversation
        message – message body

    Config.PhoneBotNumber is used as the "from" number for lb-phone / npwd.

    Supported backends: 'lb-phone', 'gksphone', 'npwd', 'none'
]]

local backend = Config.Phone

-- ─── lb-phone ─────────────────────────────────────────────────────────────────
-- https://docs.lbscripts.com/phone/exports/server-exports/
if backend == 'lb-phone' then

    Bridge.getPhoneNumber = function(source)
        return exports['lb-phone']:GetEquippedPhoneNumber(source)
    end

    -- lb-phone SendMessage(from, to, message, attachments?, cb?, channelId?)
    Bridge.sendSMS = function(number, title, message)
        exports['lb-phone']:SendMessage(
            Config.PhoneBotNumber,  -- from (system / bot number)
            number,                  -- to
            '[' .. title .. '] ' .. message
        )
    end

-- ─── gksphone ─────────────────────────────────────────────────────────────────
-- https://docs.gkshop.org/gksphone-v2/exports-and-events/server-exports
-- gksphone does not expose a direct SMS-sending export; only getPhoneNumber is bridged.
elseif backend == 'gksphone' then

    Bridge.getPhoneNumber = function(source)
        return exports['gksphone']:GetPhoneBySource(source)
    end

    Bridge.sendSMS = function(number, title, message)
        print('^3[dg-bridge] Bridge.sendSMS: gksphone has no SMS export — message not delivered.^0')
    end

-- ─── npwd (New Phone Who Dis) ─────────────────────────────────────────────────
-- https://projecterror.dev/docs/npwd/api/server-exports/
elseif backend == 'npwd' then

    Bridge.getPhoneNumber = function(source)
        return exports['npwd']:getPhoneNumber(source)
    end

    -- npwd emitMessage({ senderNumber, targetNumber, message, embed? })
    Bridge.sendSMS = function(number, title, message)
        exports['npwd']:emitMessage({
            senderNumber = Config.PhoneBotNumber,
            targetNumber = number,
            message      = '[' .. title .. '] ' .. message,
        })
    end

-- ─── none / fallback ──────────────────────────────────────────────────────────
else
    if backend and backend ~= 'none' then
        print('^3[dg-bridge] Unknown Config.Phone value: "' .. tostring(backend) .. '" — phone functions disabled.^0')
    end

    Bridge.getPhoneNumber = function() return nil end
    Bridge.sendSMS        = function() end
end
