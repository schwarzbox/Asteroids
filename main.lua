#!/usr/bin/env love
-- ASTEROIDS
-- 1.5
-- Game (love2d)
-- main.lua

-- MIT License
-- Copyright (c) 2018 Alexander Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HObLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION ObF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- 2.0
-- + dim screen in first menu
-- auto stop rotation ship
-- refactor radar

local imd = require('lib/lovimd')
Model = love.filesystem.load('lib/model.lua')()
View = love.filesystem.load('lib/view.lua')()
Ctrl = love.filesystem.load('lib/lovctrl.lua')()
local set = require('lib/set')

io.stdout:setvbuf('no')
function love.load()
    if arg[1] then print(set.VER, set.GAMENAME, 'Game (love2d)', arg[1]) end
    -- set title in conf.lua
    love.window.setTitle(string.format('%s %s', set.GAMENAME, set.VER))
    love.window.setFullscreen(set.FULLSCR, 'desktop')
    -- make icon
    love.window.setIcon(imd.rotate_imd(set.OBJ['wasp'],'CCW'))

    -- set controller
    Ctrl:new()
    -- set model & view
    View:new()
    Model:new()

    -- ship
    Ctrl:bind('w','forward')
    Ctrl:bind('w','stop', function() set.AUD['engine']:stop() end)
    Ctrl:bind('d','right')
    Ctrl:bind('a','left')

    --love
    Ctrl:bind('lgui+r','restart',function() love.event.quit('restart') end)
    Ctrl:bind('lgui+p','pause', function()
                            if View.scr=='game_scr' then
                                Model.pause = not Model.pause
                                View:set_label('PAUSE',Model.pause) end
                            end)

    Ctrl:bind('escape','quit', function() love.quit() love.event.quit() end)
    Ctrl:bind('lgui+q','cmdq', function() love.event.quit(1) end)
end

-- dt around 0.016618420952
function love.update(dt)
    local upd_title = string.format('%s %s fps %.2d', set.GAMENAME, set.VER,
                                   love.timer.getFPS())
    love.window.setTitle(upd_title)

    -- update model
    Model:update(dt)
    -- ctrl ship
    if Model.avatar and not Model.pause then
        local ava=Model.avatar
        Ctrl:release('stop')
        if Ctrl:down('forward') then ava:move() end
        if Ctrl:down('right') then ava:rotate(1) end
        if Ctrl:down('left') then ava:rotate(-1) end
        if Ctrl:down('fire', ava.weapon.cooldown) then
            -- change gun
            ava.weapon_delta={ava.weapon_delta[1],-ava.weapon_delta[2]}
            ava:shot(ava.weapon_side,ava.weapon_delta,ava.weapon.inertion)
        end
    end
    Ctrl:press('start')
    -- ctrl love
    Ctrl:press('pause')
    Ctrl:press('restart')
    Ctrl:press('quit')
    Ctrl:press('cmdq')
end

function love.draw()
    View:draw()
 end

function love.focus(focus)
    if View.scr=='game_scr' then
        if not focus then Model.pause = true else Model.pause = false end
        View:set_label('PAUSE',Model.pause)
    end
end

function love.keypressed(key, unicode, isrepeat) end
function love.keyreleased(key, unicode,isrepeat) end
function love.mousepressed(x, y, button, istouch) end
function love.mousereleased(x, y, button, istouch) end
function love.mousemoved(x, y, dx, dy, istouch) end
function love.wheelmoved(x, y) end
function love.quit() print('game over') end
