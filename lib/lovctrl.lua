#!/usr/bin/env love
-- LOVCTRL
-- 3.0
-- Controller (love2d)
-- lovctrl.lua

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
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

if arg[1] then print('3.0 LOVCTRL Controller (love2d)', arg[1]) end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local CTRL = {}
function CTRL.load()
    CTRL.actions = {}
    CTRL.pressevent = {}
    CTRL.releaseevent = {}
    CTRL.moveevent = {}
    CTRL.repeatevent = {}
    CTRL.func = {}
    CTRL.doubleclick = false
    CTRL.doubletimer = false
    CTRL.doubledelay = 0.4
    CTRL.combos = {}
    CTRL.combokey = false

    CTRL.mouse,CTRL.wheel = false, false
    CTRL.pos = {x=0, y=0, dx=0, dy=0}

    CTRL.mousetag = {['m1']=1,['m2']=2,['m3']=3,['m4']=4,['m5']=5}
    CTRL.mousebut = {[1]='m1',[2]='m2',[3]='m3',[4]='m4',[5]='m5'}

    local events = {'keypressed','keyreleased','mousepressed',
            'mousereleased','mousemoved','wheelmoved','update'}
    local default = {}
    for i=1,#events do
        default[events[i]] = love[events[i]] or function() end
        love[events[i]] = function(...)
            local output = {default[events[i]](...)}
            if #output>0 then
                CTRL[events[i]](CTRL,unpack(output))
                return unpack(output)
            else CTRL[events[i]](CTRL, ...) end
        end
    end
end

function CTRL:bind(key,action,func)
    self.actions[action] = key
    if func then self.func[action] = func end
    if key:find('+') then self.combos[key] = key end
end

function CTRL:unbind(key)
    if key=='all' then
        self.actions={} self.func={} self.combos={}
        return
    end
    for action, key_ in pairs(self.actions) do
        if key_==key then
            self.actions[action] = nil
            self.func[action] = nil
            self.combos[key] = nil
        end
    end
end

function CTRL:move(action)
    local key = self.actions[action]
    if self.moveevent[key] then
        if self.func[action] then self.func[action]() end
        return true
    end
end

function CTRL:press(action)
    local key = self.actions[action]
    if self.pressevent[key] then
        self.pressevent[key] = nil
        if self.func[action] then self.func[action]() end
        return true
    end
end

function CTRL:release(action)
    local key = self.actions[action]
    if self.releaseevent[key] then
        self.releaseevent[key] = nil
        if self.func[action] then self.func[action]() end
        return true
    end
end

function CTRL:position()
    return self.pos.x,self.pos.y,self.pos.dx,self.pos.dy
end

function CTRL:down(action, interval, delay)
    local key = self.actions[action]

    if not self.pressevent[key] and self.repeatevent[key] then
        if self.repeatevent[key].done then self.repeatevent[key]=nil end
    end

    if interval and delay then
        if self.pressevent[key] and not self.repeatevent[key] then
            self.repeatevent[key]={start=0, interval=interval, delay=delay,
                                        done=false}
        elseif self.repeatevent[key] and self.repeatevent[key].done then
            self.repeatevent[key].start = 0
            self.repeatevent[key].done = false
            if self.func[action] then self.func[action]() end
            return true
        end

    elseif interval and not delay then
        if self.pressevent[key] and not self.repeatevent[key] then

            self.repeatevent[key]={start=0, interval=interval, delay=0,
                                        done=false}
            if self.func[action] then self.func[action]() end
            return true
        elseif self.repeatevent[key] and self.repeatevent[key].done then
            self.repeatevent[key].start = 0
            self.repeatevent[key].done = false
            if self.func[action] then self.func[action]() end
            return true
        end
    else
        if self.mousetag[key] then
            if love.mouse.isDown(self.mousetag[key]) then
                if self.func[action] then self.func[action]() end
                return true
            end
        else
            if love.keyboard.isDown(key) then
                if self.func[action] then self.func[action]() end
                return true
            end
        end
    end
end

-- love
function CTRL:keypressed(key,unicode)
    self.pressevent[key] = true
    -- combo
    if self.combokey and self.combos[self.combokey..'+'..key] then
        self.pressevent[self.combokey..'+'..key] = true
        self.pressevent[key] = false
    end
    if not self.combokey then self.combokey = key end
end

function CTRL:keyreleased(key,unicode)
    self.pressevent[key] = nil
    self.releaseevent[key] = true
    if self.combokey==key then self.combokey = false end
end

function CTRL:mousepressed(x,y,button,istouch)
    self.pressevent[self.mousebut[button]]=true
    -- double click
    if self.doubletimer then
        local delta = love.timer.getTime()-self.doubletimer
        if self.doubledelay>delta and self.doubleclick==button then
            self.pressevent['double'] = true
            return
        end
    end
    self.doubletimer = love.timer.getTime()
    self.doubleclick = button
end

function CTRL:mousereleased(x,y,button,istouch)
    self.pressevent[self.mousebut[button]] = nil
    self.releaseevent[self.mousebut[button]] = true
end

function CTRL:mousemoved(x,y,dx,dy,istouch)
    self.mouse = true
    self.moveevent['mouse'] = true
    self.pos = {x=x,y=y,dx=dx,dy=dy}
end

function CTRL:wheelmoved(x,y)
    self.wheel=true
    if x>0 then self.moveevent['wheelright']=true end
    if x<0 then self.moveevent['wheelleft']=true end
    if y>0 then self.moveevent['wheelup']=true end
    if y<0 then self.moveevent['wheeldown']=true end
end

function CTRL:update(dt)
    self.mouse, self.wheel = false, false
    self.moveevent['mouse'] = false
    self.moveevent['wheelup'] = false
    self.moveevent['wheeldown'] = false
    self.moveevent['wheelright'] = false
    self.moveevent['wheelleft'] = false

    for _, timer in pairs(self.repeatevent) do
        if timer and timer.delay>0 then timer.delay = timer.delay-dt end
        if timer and timer.delay<=0 then
            timer.start = timer.start+dt
            if timer.start>=timer.interval then timer.done = true  end
        end
    end
end

return CTRL
