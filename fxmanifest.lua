fx_version 'cerulean'

game 'gta5'
author 'Coffeelot and Wuggie'
description 'Head 2 Head races for QB'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua',
}

client_scripts{
    'client/*.lua',
}

server_scripts{
    'server/*.lua',
}

files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'html/fonts/*.otf',
    'html/img/*'
}

dependency{
    'oxmysql',
    'qb-radialmenu'
}
