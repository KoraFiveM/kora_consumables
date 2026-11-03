fx_version 'cerulean'
game 'gta5'
lua54 'yes'
-- Keep the legacy resource name resolvable for exports['qbconsumables'] callers.
provide 'qbconsumables'
author 'Kakarot'
description 'its in the name, just read'
version '1.2.1'

dependency 'kora_lib'
dependency 'kora_core'

shared_script {
    '@kora_lib/init.lua',
    -- Config first: defaults.lua reads Config.Consumables at load.
    'shared/Config.lua',
    'shared/defaults.lua'
}

server_script 'server/**.lua'

client_scripts {
    'client/**.lua'
}
