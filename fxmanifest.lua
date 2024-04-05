fx_version 'cerulean'
game 'gta5'

author '@allroundjonu'
description 'Advanced Drug System for FiveM'
version '1.0.0'


shared_script 'bridge/init.lua'

shared_scripts {
    'shared/config.lua',
    'locales/*.lua',
    '@ox_lib/init.lua',
    'bridge/**/shared.lua',
    '@es_extended/imports.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/CircleZone.lua',

    'bridge/**/client.lua',

    'client/cl_functions.lua',
    'client/cl_menus.lua',
    'client/cl_planting.lua',
    'client/cl_processing.lua',
    'client/cl_selling.lua',
    'client/cl_target.lua',
    'client/cl_using.lua',
    'client/cl_i_hate_esx.lua',
    'client/cl_blips.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'bridge/**/server.lua',
    
    'server/sv_planting.lua',
    'server/sv_processing.lua',
    'server/sv_selling.lua',
    'server/sv_usableitems.lua',
    'server/sv_versioncheck.lua',
    'server/sv_webhooks.lua'
}

dependencies {
    'PolyZone',
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
usefxv2oal 'yes'