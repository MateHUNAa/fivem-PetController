fx_version "cerulean"
game "gta5"

shared_scripts {
    "config.lua"
}

server_scripts {
    "server/functions.lua",
    "server/main.lua"
}

client_scripts {
    "client/functions.lua",
    "client/main.lua"
}

server_script "@oxmysql/lib/MySQL.lua"
shared_script '@es_extended/imports.lua'

dependency {
    'mCore',
    'oxmysql',
}
