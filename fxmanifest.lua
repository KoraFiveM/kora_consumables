fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'its in the name, just read'
version '0.2.0'

dependency 'kora_lib'
dependency 'kora_core'

shared_script {
    '@kora_lib/init.lua',
    'shared/**.lua'
}

server_script 'server/**.lua'

client_scripts {
    'client/**.lua'
}

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
