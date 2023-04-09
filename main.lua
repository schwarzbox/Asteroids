#!/usr/bin/env love
-- ASTEROIDS
-- 3.0
-- Game (love2d)
-- main.lua

-- MIT License
-- Copyright (c) 2018 Aliaksandr Veledzimovich veledz@gmail.com

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
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION ObF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- Music by Eric Matyas
-- www.soundimage.org

local imd = require('lib/lovimd')

Model = love.filesystem.load('lib/model.lua')()
View = love.filesystem.load('lib/view.lua')()
Ctrl = love.filesystem.load('lib/lovctrl.lua')()
local set = require('lib/set')

io.stdout:setvbuf('no')
function love.load()
    if arg[1] then print(set.VER, set.APPNAME, 'Game (love2d)', arg[1]) end
    love.window.setFullscreen(set.FULLSCR, 'desktop')
    -- make icon
    love.window.setIcon(imd.rotate(set.IMG['wasp'],'CCW'))
    -- set controller
    Ctrl.load()
    -- set model & view
    View:new()
    Model:new()

    -- ctrl ship
    Ctrl:bind('w','forward')
    Ctrl:bind('w','stop', function() set.AUD['engine']:stop() end)
    Ctrl:bind('d','right')
    Ctrl:bind('d','right_stop')
    Ctrl:bind('a','left')
    Ctrl:bind('a','left_stop')
    Ctrl:bind('up','arr_forward')
    Ctrl:bind('up','arr_stop', function() set.AUD['engine']:stop() end)
    Ctrl:bind('right','arr_right')
    Ctrl:bind('right','arr_right_stop')
    Ctrl:bind('left','arr_left')
    Ctrl:bind('left','arr_left_stop')
    -- ctrl game
    Ctrl:bind('space','start',function() Model:startgame() end)
    -- Ctrl:bind('escape','pause', function() Model:set_pause() end)
    Ctrl:bind('lgui+r','cmdr',function() love.event.quit('restart') end)
    Ctrl:bind('lgui+q','cmdq', function() love.event.quit(1) end)

    local upd_title = string.format('%s %s', set.APPNAME, set.VER)
    love.window.setTitle(upd_title)
end

-- dt around 0.016618420952
function love.update(dt)
    -- update model
    Model:update(dt)
    -- ctrl ship
    if Model.avatar and not Model.pause then
        local ava=Model.avatar
        Ctrl:release('stop')
        Ctrl:release('arr_stop')

        if (Ctrl:release('arr_left_stop') or Ctrl:release('arr_right_stop') or
            Ctrl:release('left_stop') or Ctrl:release('right_stop')) then
            ava.auto_stop = true
        end

        if Ctrl:down('forward') or Ctrl:down('arr_forward')then ava:move() end
        if Ctrl:down('right') or Ctrl:down('arr_right') then
            ava:rotate(1) ava.auto_stop = false end
        if Ctrl:down('left') or Ctrl:down('arr_left') then
            ava:rotate(-1) ava.auto_stop = false end
        if Ctrl:down('fire', ava.weapon.type.cooldown) then
            -- change gun
            ava:setWeapon(nil,nil,{ava.weapon.offset[1],-ava.weapon.offset[2]})
            ava:shot()

        end
    end
    -- ctrl game
    Ctrl:press('start')
    Ctrl:press('pause')
    Ctrl:press('cmdr')
    Ctrl:press('cmdq')
end

function love.draw()
    View:draw()
 end

function love.focus(focus)
    if not focus then Model:set_pause(true) else Model:set_pause(false) end
end

function love.keypressed(key,unicode,isrepeat) end
function love.keyreleased(key,unicode) end
function love.mousepressed(x,y,button,istouch) end
function love.mousereleased(x,y,button,istouch) end
function love.mousemoved(x,y,dx,dy,istouch) end
function love.wheelmoved(x, y) end
