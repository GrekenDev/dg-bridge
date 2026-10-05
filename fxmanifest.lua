fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'dg-bridge'
description 'DG Universal Bridge — Framework, Inventory, UI & more'
author      'Greken'
version     '1.2.0'

dependencies {
    '/onesync',
}

shared_scripts {
    'config.lua',
    'bridge/init.lua',
}

client_scripts {
    'bridge/client/framework.lua',
    'bridge/client/notify.lua',
    'bridge/client/progress.lua',
    'bridge/client/textui.lua',
    'bridge/client/input.lua',
    'bridge/client/menu.lua',
    'bridge/client/dialog.lua',
    'bridge/client/target.lua',
    'bridge/client/inventory.lua',
    'bridge/client/dispatch.lua',
    'bridge/client/fuel.lua',
    'bridge/client/vehiclekeys.lua',
}

server_scripts {
    'bridge/server/framework.lua',
    'bridge/server/inventory.lua',
    'bridge/server/notify.lua',
    'bridge/server/dispatch.lua',
    'bridge/server/society.lua',
    'bridge/server/log.lua',
    'bridge/server/phone.lua',
    'bridge/server/vehiclekeys.lua',
}

files {
    'imports/client.lua',
    'imports/server.lua',
}

escrow_ignore {
    'config.lua',
    'imports/client.lua',
    'imports/server.lua',
}
