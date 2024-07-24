fx_version 'cerulean'
game 'gta5'
Author 'rzk'
description 'QB-Core Weapon Ban with automatic database saving'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
    'server.lua'
}

client_scripts {
    'client.lua'
}
