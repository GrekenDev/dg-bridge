Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  FRAMEWORK
--  The core player-data / economy framework running on your server.
--
--  Options:
--    'esx'        → ESX / es_extended (legacy & new)
--    'qbcore'     → QBCore  (qb-core)
--    'qbox'       → QBox    (qbx_core)
--    'nd'         → ND_Core (ND_Core)
--    'standalone' → No framework – identifiers based on license/IP
-- ─────────────────────────────────────────────────────────────────────────────
Config.Framework = 'qbox'

-- ─────────────────────────────────────────────────────────────────────────────
--  INVENTORY
--  Which inventory system is installed on your server.
--
--  Options:
--    'ox_inventory'    → ox_inventory  (overextended)
--    'qb-inventory'    → qb-inventory  (QBCore built-in)
--    'ps-inventory'    → ps-inventory  (project sloth)
--    'codem-inventory' → codem-inventory
--    'origen_inventory'→ origen_inventory
--    'esx'             → es_extended built-in inventory
--    'standalone'      → No inventory — item functions return safe fallbacks
-- ─────────────────────────────────────────────────────────────────────────────
Config.Inventory = 'ox_inventory'

-- ─────────────────────────────────────────────────────────────────────────────
--  NOTIFICATIONS
--  Which notification library to use.
--
--  Options:
--    'ox_lib'      → ox_lib notify          (lib.notify)
--    'qbcore'      → QBCore notify          (QBCore.Functions.Notify)
--    'esx'         → ESX ShowNotification
--    'okok'        → okokNotify             (okokNotify:Alert)
--    'mythic'      → mythic_notify
--    'lation'      → lation_ui notify
--    'ps-ui'       → ps-ui notify
--    'standalone'  → GTA V native DrawNotification
-- ─────────────────────────────────────────────────────────────────────────────
Config.Notify = 'ox_lib'

-- Default duration for notifications in ms (used when no duration is given)
Config.NotifyDuration = 5000

-- ─────────────────────────────────────────────────────────────────────────────
--  PROGRESS BAR
--  Which progress-bar library to use.
--
--  Options:
--    'ox_lib'     → ox_lib progressbar   (lib.progressBar / lib.progressCircle)
--    'qbcore'     → qb-core progressbar  (QBCore.Functions.Progressbar)
--    'esx'        → esx_progressbar
--    'mythic'     → mythic_progbar
--    'standalone' → Simple native timer (no visual bar)
-- ─────────────────────────────────────────────────────────────────────────────
Config.Progress = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  TEXT UI  (press-key hints / interaction labels)
--
--  Options:
--    'ox_lib'     → lib.showTextUI
--    'okok'       → okokTextUI
--    'qbcore'     → QBCore.Functions.DrawText
--    'ps-ui'      → ps-ui DrawText
--    'lation'     → lation_ui textUI
--    'standalone' → 3D text drawn above the player (no extra resource)
-- ─────────────────────────────────────────────────────────────────────────────
Config.TextUI = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  INPUT / DIALOG  (text inputs, number inputs, dropdowns, checkboxes…)
--
--  Options:
--    'ox_lib'     → lib.inputDialog
--    'qb-input'   → qb-input  (exports['qb-input']:ShowInput)
--    'standalone' → no dialog — returns each input's default value and prints a warning
-- ─────────────────────────────────────────────────────────────────────────────
Config.Input = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  CONTEXT MENU  (list-style menus)
--
--  Options:
--    'ox_lib'    → lib.registerContext / lib.showContext
--    'qb-menu'   → qb-menu
--    'lation'    → lation_ui context
-- ─────────────────────────────────────────────────────────────────────────────
Config.ContextMenu = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  RADIAL MENU
--
--  Options:
--    'ox_lib'    → lib.registerRadial / lib.addRadialItem
--    'qb-radial' → qb-radialmenu
-- ─────────────────────────────────────────────────────────────────────────────
Config.RadialMenu = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  TARGET  (3D interaction zones / entity targeting)
--
--  Options:
--    'ox_target'  → ox_target
--    'i_interaction' → i_interaction (ox_target compatible API)
--    'qb-target'  → qb-target
--    'qtarget'    → qtarget
--    'standalone' → distance-based DrawText3D (no extra resource needed)
-- ─────────────────────────────────────────────────────────────────────────────
Config.Target = 'ox_target'

-- ─────────────────────────────────────────────────────────────────────────────
--  DISPATCH  (police/emergency alerts)
--
--  Options:
--    'ps-dispatch'  → ps-dispatch
--    'cd_dispatch'  → cd_dispatch  (Codesign)
--    'qs-dispatch'  → qs-dispatch  (Quasar)
--    'standalone'   → built-in blip + notification to jobs in-game
-- ─────────────────────────────────────────────────────────────────────────────
Config.Dispatch = 'ps-dispatch'

-- ─────────────────────────────────────────────────────────────────────────────
--  MONEY ACCOUNT MAPPING  (QBCore / QBox only)
--  Maps Bridge's canonical account names to your framework's internal names.
--  Only change if your server uses custom account/wallet names.
--
--  Canonical names used by Bridge: 'cash', 'bank', 'black'
--
--  Ignored by the other frameworks: ESX maps cash → money and
--  black → black_money itself, and ND_Core passes names through unchanged.
-- ─────────────────────────────────────────────────────────────────────────────
Config.MoneyAccounts = {
    -- [canonical] = [framework internal name]
    cash  = 'cash',
    bank  = 'bank',
    black = 'crypto', -- QBCore / QBox call dirty money "crypto" by default
}

-- ─────────────────────────────────────────────────────────────────────────────
--  SOCIETY MANAGEMENT
--  If your server uses a society/boss-banking script for job finances, set it here.
--  This is used by Bridge.getSocietyMoney / addSocietyMoney / removeSocietyMoney.
--
--  Options:
--    'dg-banking'      → dg-banking     (QBox / QBCore) — Development By Greken
--    'Renewed-Banking' → Renewed-Banking (QBCore / QBox)
--    'qb-management'   → qb-management  (QBCore)
--    'esx_society'     → esx_society    (ESX)  — uses esx_addonaccount internally
--    'fd_banking'      → fd_banking     (QBCore / QBox)
--    'wasabi_banking'  → wasabi_banking (QBCore / QBox)
--    'crm-banking'     → crm-banking    (QBCore / QBox)
--    'none'            → disabled — all society calls return safe no-ops
--
--  Want another script supported? Open a ticket or contribute a PR!
-- ─────────────────────────────────────────────────────────────────────────────
Config.SocietyManagement = 'Renewed-Banking'

-- ─────────────────────────────────────────────────────────────────────────────
--  DISPATCH JOBS
--  Default job list for dispatch alerts that don't pass their own `jobs`.
--  Used by every Config.Dispatch backend; with 'standalone', online players
--  with one of these jobs get the blip + notification.
-- ─────────────────────────────────────────────────────────────────────────────
Config.DispatchJobs = { 'police', 'sheriff', 'ambulance' }

-- ─────────────────────────────────────────────────────────────────────────────
--  NPC DIALOG  (immersive conversation-style UI with a ped)
--
--  Options:
--    'bl_dialog'  → bl_dialog  (exports.bl_dialog:showDialog)
--    'ox_lib'     → ox_lib context menu fallback (multi-page via openContext)
--    'standalone' → no-op (logs to console)
-- ─────────────────────────────────────────────────────────────────────────────
Config.NPCDialog = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  VEHICLE KEYS
--  Which vehicle key script is installed on your server.
--
--  Options:
--    'qb-vehiclekeys'      → qb-vehiclekeys      (QBCore)
--    'qbx_vehiclekeys'     → qbx_vehiclekeys     (QBox)
--    'Renewed-vehiclekeys' → Renewed-vehiclekeys (Renewed)
--    'mrnewbs_vehiclekeys' → mrnewbs_vehiclekeys (MrNewb)
--    'wasabi_carlock'      → wasabi_carlock      (Wasabi Scripts)
--    't1ger_keys'          → t1ger_keys          (t1ger)
--    'mono_keys'           → mono_keys           (Nox_Aeterna)
--    'codem-vehiclekeys'   → codem-vehiclekeys   (CodeM)
--    'standalone'          → keys tracked in the bridge + SetVehicleDoorsLocked (no extra resource)
-- ─────────────────────────────────────────────────────────────────────────────
Config.VehicleKeys = 'qbx_vehiclekeys'

-- ─────────────────────────────────────────────────────────────────────────────
--  FUEL SYSTEM
--  Which fuel resource is installed on your server.
--
--  Options:
--    'ox_fuel'     → ox_fuel
--    'LegacyFuel'  → LegacyFuel
--    'ps-fuel'     → ps-fuel
--    'cdn-fuel'    → cdn-fuel
--    'standalone'  → SetVehicleFuelLevel native (no extra resource)
-- ─────────────────────────────────────────────────────────────────────────────
Config.Fuel = 'ox_fuel'

-- ─────────────────────────────────────────────────────────────────────────────
--  LOGGING / AUDIT
--  Backend used by Bridge.log() for audit trails and economy logging.
--
--  Options:
--    'ox_lib'   → lib.logger  (Datadog / Fivemanage / Loki, picked with the ox:logger convar)
--                 ox_lib must be started before dg-bridge, otherwise logging is disabled.
--    'discord'  → Discord webhook  — requires Config.LoggingWebhook below
--    'none'     → silent no-op
-- ─────────────────────────────────────────────────────────────────────────────
Config.Logging = 'none'
Config.LoggingWebhook = ''   -- Discord webhook URL (only used when Config.Logging = 'discord')

-- ─────────────────────────────────────────────────────────────────────────────
--  PHONE SYSTEM
--  Which phone resource is installed on your server.
--  Used by Bridge.getPhoneNumber() and Bridge.sendSMS().
--
--  Options:
--    'lb-phone' → lb-phone
--    'gksphone' → GKSPhone
--    'npwd'     → NPWD (New Phone Who Dis)
--    'none'     → silent no-op
-- ─────────────────────────────────────────────────────────────────────────────
Config.Phone = 'none'
Config.PhoneBotNumber = '555-0000'   -- "from" number used when sending SMS (lb-phone / npwd)
