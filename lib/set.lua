-- Sun May 13 23:35:21 2018
-- (c) Alexander Veledzimovich
-- set ASTEROIDS

local fl = require('lib/lovfl')
local set = {
    APPNAME = 'Asteroids!',
    SAVE = 'asteroids!save.lua',
    VER = '3.0',
    FULLSCR = love.window.getFullscreen(),
    WID = love.graphics.getWidth(),
    HEI = love.graphics.getHeight(),
    MIDWID = love.graphics.getWidth() / 2,
    MIDHEI = love.graphics.getHeight() / 2,
    SCALE = 0.4,
    NUMASTER = 3,

    EMPTY ={0, 0, 0, 0},
    WHITE = {1, 1, 1, 1},
    BLACK = {0, 0, 0, 1},
    RED = {1, 0, 0, 1},
    YELLOW = {1, 1, 0, 1},
    GREEN = {0, 1, 0, 1},
    BLUE = {0, 0, 1, 1},

    DARKGRAY = {64/255, 64/255, 64/255, 1},
    DARKGRAYHF = {32/255, 32/255, 32/255, 0.5},
    DARKGRAYF = {32/255, 32/255, 32/255, 0},
    GRAY = {0.5, 0.5, 0.5, 1},
    GRAYF = {0.5, 0.5, 0.5, 0},
    LIGHTGRAY = {192/255, 192/255, 192/255, 1},
    LIGHTGRAYF = {192/255, 192/255, 192/255, 0},

    DARKWHITE = {232/255, 232/255, 232/255, 1},

    WHITEHHF = {1, 1, 1, 100/255},
    WHITEHF = {1, 1, 1, 50/255},
    WHITEF = {1, 1, 1, 25/255},
    WHITEFF = {1, 1, 1, 0},

    DISPGREEN = {85/255,212/255,0,1},
    DISPYELLOW = {243/255,221/255,91/255,0.6},
    DISPBLACK = {28/255,36/255,34/255,0.8},
    BLACKBLUE = {16/255, 16/255, 64/255, 1},
    DARKRED = {128/255, 0, 0, 1},
    ORANGE = {1, 164/255, 32/255, 200/255},
    -- aster color
    LIGHTBROWN = {164/255,128/255,64/255,1},
    BROWN = {128/255,64/255,32/255,1},

    MAINFNT = 'res/fnt/slkscr.ttf',

    IMG = {},
    AUD = {},
    -- default sound
    LOOPV = 0.3,
    BULV = 0.6,
    BOOMV = 0.5,
    ENGV = 0.4,
    HITV = 0.4,
}

set.TITLEFNT = {set.MAINFNT,64}
set.MENUFNT = {set.MAINFNT,32}
set.GAMEFNT = {set.MAINFNT,16}
set.UIFNT = {set.MAINFNT,8}

for k,path in pairs(fl.loadAll('res/img','png')) do
    set.IMG[k] = love.image.newImageData(path)
end

for k,path in pairs(fl.loadAll('res/aud','wav','mp3')) do
    if path:match('[^.]+$')=='wav' then
        set.AUD[k] = love.audio.newSource(path,'static')
    else
        set.AUD[k] = love.audio.newSource(path,'stream')
    end
end

return set
