fx_version 'cerulean'
game 'gta5'

name 'Ferp_restaurants'
version '1.5.0'
description 'Complete Restaurant System for QBX'
author 'Ferp'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
    'qbx_management'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

lua54 'yes'