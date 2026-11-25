fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kora'
description 'its in the name, just read'
version '0.2.2'

dependency 'kora_lib'
dependency 'kora_core'
dependency 'kora_sql'

shared_script {
    '@kora_lib/init.lua',
    'shared/**.lua'
}

server_scripts {
    '@kora_sql/init.lua',
    'server/schema.lua',
    'server/data.lua',
    'server/server.lua',
    'server/creator.lua',
}

client_scripts { 'client/client.lua', 'client/creator.lua' }

files { 'locales/*.lua' }

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'

server_script 'kora_versioncheck.lua'
