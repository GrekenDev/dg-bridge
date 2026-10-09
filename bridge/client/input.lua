--[[
    bridge/client/input.lua

    Bridge.showInput(data, callback)
        data = {
            title  = string,
            inputs = {
                {
                    type        = 'text'|'number'|'select'|'checkbox'|'date'|'textarea',
                    name        = string,         -- key in the result table
                    label       = string,
                    placeholder = string,         -- optional
                    required    = bool,           -- optional
                    min         = number,         -- optional (number type)
                    max         = number,         -- optional (number type)
                    options     = {               -- for 'select' type
                        { value = string, label = string }
                    },
                    default     = any,            -- optional default value
                }
            },
        }
        callback(result)
            result : table { [name] = value } or nil if cancelled
]]

-- ─── ox_lib ───────────────────────────────────────────────────────────────────
if Config.Input == 'ox_lib' then
    Bridge.showInput = function(data, cb)
        local rows = {}
        for i, input in ipairs(data.inputs or {}) do
            rows[i] = {
                type        = (input.type == 'text' or not input.type) and 'input' or input.type,
                label       = input.label       or '',
                placeholder = input.placeholder or '',
                required    = input.required    or false,
                min         = input.min,
                max         = input.max,
                options     = input.options,
                default     = input.default,
            }
        end

        local result = exports.ox_lib:inputDialog(data.title or '', rows)

        if not result then
            if cb then cb(nil) end
            return
        end

        -- Map positional array result to named table
        local out = {}
        for i, input in ipairs(data.inputs or {}) do
            out[input.name] = result[i]
        end

        if cb then cb(out) end
    end

-- ─── qb-input ─────────────────────────────────────────────────────────────────
elseif Config.Input == 'qb-input' then
    Bridge.showInput = function(data, cb)
        local inputs = {}
        for i, input in ipairs(data.inputs or {}) do
            inputs[i] = {
                type    = input.type == 'select' and 'radio' or (input.type or 'text'),
                name    = input.name,
                text    = input.label,
                isRequired = input.required or false,
            }
            if input.options then
                inputs[i].options = input.options
            end
        end

        exports['qb-input']:ShowInput({
            header    = data.title or '',
            submitBtn = 'Confirm',
            inputs    = inputs,
        }, function(result)
            if not result then
                if cb then cb(nil) end
                return
            end
            if cb then cb(result) end
        end)
    end

-- ─── standalone (no dialog) ───────────────────────────────────────────────────
-- Shows nothing: every input resolves to its `default` (or '') and a warning is
-- printed. Configure ox_lib or qb-input for real player input.
else
    Bridge.showInput = function(data, cb)
        -- Warn server owners this is a basic fallback
        print('^3[dg-bridge] WARNING: No input resource configured. Using minimal standalone fallback.^0')

        local results = {}
        local inputs  = data.inputs or {}

        CreateThread(function()
            for _, input in ipairs(inputs) do
                -- Default values only — no actual keyboard capture without NUI
                results[input.name] = input.default or ''
            end
            if cb then cb(results) end
        end)
    end
end
