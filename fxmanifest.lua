fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'its in the name, just read'
version '1.2.1'

dependency 'qblib'

shared_script {
    '@qblib/init.lua',
    'shared/**.lua'
}

server_script 'server/**.lua'

client_scripts {
    'client/**.lua'
}
