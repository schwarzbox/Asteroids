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

local Ctrl = {}
function Ctrl:new()
    self.actions = {}
    self.press_event = {}
    self.release_event = {}
    self.move_event = {}
    self.repeat_action = {}
    self.func = {}
    self.init_double = false
    self.timer_double = false
    self.time_double = 0.4
    self.combos = {}
    self.init_combo = false

    self.mmove,self.wmove = false, false
    self.mpos = {x=0, y=0, dx=0, dy=0}

    self.mouse_tag = {['m1']=1,['m2']=2,['m3']=3,['m4']=4,['m5']=5}
    self.mouse_but = {[1]='m1',[2]='m2',[3]='m3',[4]='m4',[5]='m5'}

    local ev = {'keypressed','keyreleased','mousepressed',
            'mousereleased','mousemoved','wheelmoved','update'}
    local init_love = {}
    for i=1,#ev do
        init_love[ev[i]] = love[ev[i]] or function() end
        love[ev[i]] = function(...)
            init_love[ev[i]](...)
            self[ev[i]](self, ...)
        end
    end
end

function Ctrl:bind(key,action,func)
    self.actions[action] = key
    if func then self.func[action] = func end
    if key:find('+') then self.combos[key] = key end
end

function Ctrl:unbind(key)
    if key=='all' then
        self.actions={} self.func={} self.combos={}
        return
    end
    for action, key_act in pairs(self.actions) do
        if key_act==key then
            self.actions[action] = nil
            self.func[action] = nil
            self.combos[key] = nil
        end
    end
end

function Ctrl:keyrepeat(bool) love.keyboard.setKeyRepeat(bool) end

function Ctrl:move(action)
    local key = self.actions[action]
    if self.move_event[key] then
        if self.func[action] then self.func[action]() end
        return true
    end
end

function Ctrl:press(action)
    local key = self.actions[action]
    if self.press_event[key] then
        self.press_event[key] = nil
        if self.func[action] then self.func[action]() end
        return true
    end
end

function Ctrl:release(action)
    local key = self.actions[action]
    if self.release_event[key] then
        self.release_event[key] = nil
        if self.func[action] then self.func[action]() end
        return true
    end
end

function Ctrl:down(action, interval, delay)
    local key = self.actions[action]

    if not self.press_event[key] and self.repeat_action[key] then
        if self.repeat_action[key].done then self.repeat_action[key]=nil end
    end

    if interval and delay then
        if self.press_event[key] and not self.repeat_action[key] then
            self.repeat_action[key]={start=0, interval=interval, delay=delay,
                                        done=false}
        elseif self.repeat_action[key] and self.repeat_action[key].done then
            self.repeat_action[key].start = 0
            self.repeat_action[key].done = false
            if self.func[action] then self.func[action]() end
            return true
        end

    elseif interval and not delay then
        if self.press_event[key] and not self.repeat_action[key] then

            self.repeat_action[key]={start=0, interval=interval, delay=0,
                                        done=false}
            if self.func[action] then self.func[action]() end
            return true
        elseif self.repeat_action[key] and self.repeat_action[key].done then
            self.repeat_action[key].start = 0
            self.repeat_action[key].done = false
            if self.func[action] then self.func[action]() end
            return true
        end
    else
        if self.mouse_tag[key] then
            if love.mouse.isDown(self.mouse_tag[key]) then
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

function Ctrl:keypressed(key,unicode)
    self.press_event[key] = true
    -- combo
    if self.init_combo and self.combos[self.init_combo..'+'..key] then
        self.press_event[self.init_combo..'+'..key] = true
    end
    if not self.init_combo then self.init_combo = key end
end

function Ctrl:keyreleased(key,unicode)
    self.press_event[key] = nil
    self.release_event[key] = true
    if self.init_combo==key then self.init_combo = false end
end

function Ctrl:mousepressed(x,y,button,istouch)
    self.press_event[self.mouse_but[button]]=true
    -- double click
    if self.timer_double then
        local delta = love.timer.getTime()-self.timer_double
        if self.time_double>delta and self.init_double==button then
            self.press_event['double'] = true
            return
        end
    end
    self.timer_double = love.timer.getTime()
    self.init_double = button
end

function Ctrl:mousereleased(x,y,button,istouch)
    self.press_event[self.mouse_but[button]] = nil
    self.release_event[self.mouse_but[button]] = true
end

function Ctrl:mousemoved(x,y,dx,dy,istouch)
    self.mmove = true
    self.move_event['mmove'] = true
    self.mpos = {x=x,y=y,dx=dx,dy=dy}
end

function Ctrl:wheelmoved(x,y)
    self.wmove=true
    if x>0 then self.move_event['wright']=true end
    if x<0 then self.move_event['wleft']=true end
    if y>0 then self.move_event['wup']=true end
    if y<0 then self.move_event['wdown']=true end
end

function Ctrl:update(dt)
    self.mmove, self.wmove = false, false
    self.move_event['mmove'] = false
    self.move_event['wup'] = false
    self.move_event['wdown'] = false
    self.move_event['wright'] = false
    self.move_event['wleft'] = false

    for _, timer in pairs(self.repeat_action) do
        if timer and timer.delay>0 then timer.delay = timer.delay-dt end
        if timer and timer.delay<=0 then
            timer.start = timer.start+dt
            if timer.start>=timer.interval then timer.done = true  end
        end
    end
end

return Ctrl
