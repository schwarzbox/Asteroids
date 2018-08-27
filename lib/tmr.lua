#!/usr/bin/env lua
-- TMR
-- 1.0
-- Timer (lua+love2d)
-- tmr.lua

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

-- 2.0
-- add function with additional args ease elastic
-- meta function len

-- Based on Tweener's easing functions (Penner's Easing Equations)

-- elapsed = elapsed time
-- st = start value
-- diff = fin - st
-- time = total time
-- step = step back

if arg[0] then print('1.0 TMR Timer (lua+love2d)', arg[0]) end
if arg[1] then print('1.0 TMR Timer (lua+love2d)', arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local Ease = {}
function Ease.linear(elapsed,st,diff,time) return diff*elapsed/time+st end

function Ease.in_quad(elapsed,st,diff,time)
  elapsed = elapsed/time
  return diff*elapsed*elapsed+st
end

function Ease.out_quad(elapsed,st,diff,time)
  elapsed = elapsed/time
  return -diff*elapsed*(elapsed-2)+st
end

function Ease.in_out_quad(elapsed, st, diff, time)
    elapsed = elapsed/time*2
    if elapsed < 1 then
        return diff/2*elapsed*elapsed+st
    else
        return -diff/2*((elapsed-1)*(elapsed-3)-1)+ st
    end
end

function Ease.out_in_quad(elapsed,st,diff,time)
    if elapsed < time/2 then
      return Ease.out_quad(elapsed*2, st, diff/2, time)
    else
      return Ease.in_quad((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

function Ease.in_out_cubic(elapsed,st,diff,time)
    elapsed = elapsed/time*2
    if elapsed<1 then return diff/2*elapsed*elapsed*elapsed+st end
    elapsed = elapsed-2
    return diff/2*(elapsed*elapsed*elapsed+2)+st
end

function Ease.in_cubic(elapsed,st,diff,time)
    elapsed = elapsed/time
    return diff*(elapsed*elapsed*elapsed)+st
end

function Ease.out_cubic(elapsed,st,diff,time)
    elapsed = elapsed/time-1
    return diff*((elapsed*elapsed*elapsed)+1)+st
end

function Ease.out_in_cubic(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.out_cubic(elapsed*2, st, diff/2, time)
    else
        return Ease.in_cubic((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

function Ease.in_expo(elapsed,st,diff,time)
    if elapsed==0 then return st
    else
        return diff*math.pow(2, 10*(elapsed/time-1))+st-diff*0.001
    end
end

function  Ease.out_expo(elapsed,st,diff,time)
    if elapsed==time then
        return st+diff
    else
        return diff*1.001*(-math.pow(2, -10*elapsed/time)+1)+st
    end
end

function Ease.in_out_expo(elapsed,st,diff,time)
    if elapsed==0 then return st end
    if elapsed==time then return st+diff end
    elapsed = elapsed/time*2
    if elapsed<1 then
        return diff/2*math.pow(2, 10*(elapsed-1))+st-diff * 0.0005
    else
    elapsed = elapsed-1
    return diff/2*1.0005*(-math.pow(2, -10*elapsed)+2)+ st
    end
end

function Ease.out_in_expo(elapsed,st,diff,time)
  if elapsed<time/2 then
    return Ease.out_expo(elapsed*2, st, diff/2, time)
  else
    return Ease.in_expo((elapsed*2)-time, st+diff/2, diff/2, time)
  end
end

function Ease.in_back(elapsed,st,diff,time,step)
  if not step then step = 2.70158 end
  elapsed = elapsed / time
  return diff*elapsed*elapsed*((step+1)*elapsed-step)+st
end

function Ease.out_back(elapsed,st,diff,time,step)
  if not step then step = 2.70158 end
  elapsed = elapsed/time-1
  return diff*(elapsed*elapsed*((step+1)*elapsed+step)+1)+st
end

function Ease.in_out_back(elapsed,st,diff,time,step)
  if not step then step = 2.70158 end
  step = step*1.525
  elapsed = elapsed/time*2
  if elapsed<1 then
    return diff/2*(elapsed*elapsed*((step+1)*elapsed-step))+st
  else
    elapsed = elapsed-2
    return diff/2*(elapsed*elapsed*((step+1)*elapsed+step)+2)+st
  end
end

function Ease.out_in_back(elapsed,st,diff,time,s)
  if elapsed<time/2 then
    return Ease.out_back(elapsed*2, st, diff/2, time, s)
  else
    return Ease.in_back((elapsed*2)-time, st+diff/2, diff/2, time, s)
  end
end

function Ease.out_bounce(elapsed,st,diff,time)
    elapsed = elapsed/time

    if elapsed<1/2.75 then
        return diff*(7.5625*elapsed*elapsed)+st
    elseif elapsed < 2 / 2.75 then
        elapsed = elapsed - (1.5 / 2.75)
        return diff*(7.5625*elapsed*elapsed+0.75)+st
    elseif elapsed<2.5/2.75 then
        elapsed = elapsed-(2.25/2.75)
        return diff*(7.5625*elapsed * elapsed + 0.9375) + st
    else
        elapsed = elapsed-(2.625/2.75)
        return diff*(7.5625*elapsed*elapsed+0.984375)+st
    end
end

function Ease.in_bounce(elapsed,st,diff,time)
    return diff-Ease.out_bounce(time-elapsed, 0, diff, time)+st
end

function Ease.in_out_bounce(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.in_bounce(elapsed*2, 0, diff, time)*0.5+st
    else
        return Ease.out_bounce(elapsed*2-time, 0, diff, time)*0.5+diff*0.5+st
    end
end

function Ease.out_in_bounce(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.out_bounce(elapsed*2, st, diff/2, time)
    else
        return Ease.in_bounce((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

local TMR = {}
function TMR:new()
    self.__index = self
    self=setmetatable({},self)
    self:clear()
    self.all_timers = {self.after_timers, self.every_timers,
                        self.during_timers, self.tween_timers,
                        self.script_timers}

    if  love and love.update then
        local loveupdate = love.update
        love.update = function(...) loveupdate(...) self.update(self,...) end
    else
        local timerupdate=self.update
        self.init_time=os.clock()
        self.update = function(_,...)
                        local dt = os.clock()-_.init_time
                        _.dt=dt
                        timerupdate(_,dt,...)
                        _.init_time=_.init_time+dt
                        return dt
                    end
    end

    self.ease = Ease

    return self
end

function TMR.sleep(time)
    local final_time=os.clock()+time
    repeat until os.clock()>final_time
end

function TMR:len()
    local len = 0
    for i=1,#self.all_timers do
        local count=0
        for _ in pairs(self.all_timers[i]) do
            count = count+1
        end
        len = len+count
    end
    return len
end

function TMR:cancel(timer)
    for i=1,#self.all_timers do
        self.all_timers[i][timer] = nil
    end
end

function TMR:clear()
    self.after_timers = {} self.every_timers = {}
    self.during_timers = {} self.tween_timers = {}
    self.script_timers = {}
end

function TMR:keycancel(timers,key)
    for timer in pairs(timers) do
        if timer.key and timer.key==key then self:cancel(timer) end
    end
end

function TMR:after(time,func,key)
    local timer = {elapsed=0, time=time, func=func, key=key}
    self:keycancel(self.after_timers,key)
    self.after_timers[timer] = timer
    return timer
end

function TMR:every(time,func,count,key)
    count = count or math.huge
    local timer ={elapsed=0, time=time, func=func, count=count, key=key}
    self:keycancel(self.every_timers,key)
    self.every_timers[timer]=timer
    return timer
end

function TMR:during(time,func,after,key)
    after = after or function() end
    local timer = {elapsed=0, time=time, func=func, after=after, key=key}
    self:keycancel(self.during_timers, key)
    self.during_timers[timer] = timer
    return timer
end

function TMR:script(func, key)
    local coroutine_func = coroutine.wrap(func)
    local timer = {func=coroutine_func, key=key}
    self:keycancel(self.script_timers, key)
    self.script_timers[timer] = timer
end

function TMR:tween(time,init,fin,ease,after,key)
    ease = ease or 'linear'
    local st = {}
    for k,v in pairs(init) do st[k] = v end
    local diff = {}
    for k,v in pairs(fin) do diff[k] = v-st[k] end

    local timer = {elapsed=0, time=time, st=st,diff=diff, delta=init,
                                        ease=ease,after=after, key=key}
    self:keycancel(self.tween_timers, key)
    self.tween_timers[timer] = timer
    return timer
end

function TMR:update(dt)
    local remove = {}
    for timer in pairs(self.after_timers) do
        timer.elapsed = timer.elapsed+dt
        if timer.elapsed>=timer.time then
            remove[#remove+1] = timer
            timer.func()
        end
    end

    for i in pairs(self.every_timers) do
        local timer = self.every_timers[i]
        timer.elapsed = timer.elapsed+dt
        if timer.elapsed>=timer.time and timer.count>0 then
            timer.elapsed=0
            timer.func()
            timer.count = timer.count-1
        end
        if timer.count==0 then
            remove[#remove+1] = timer
        end
    end

    for timer in pairs(self.during_timers) do
        timer.elapsed = timer.elapsed+dt
        timer.func()
        if timer.elapsed>=timer.time then
            remove[#remove+1] = timer
            timer.after()
        end
    end

    for timer in pairs(self.script_timers) do
        -- on the fly create wait function with arg time
        timer.func(function(time)
                        self:after(time, timer.func)
                        coroutine.yield()
                    end)
        remove[#remove+1] = timer
    end

    for timer in pairs(self.tween_timers) do
        timer.elapsed = timer.elapsed+dt
        for k,_ in pairs(timer.diff) do
            timer.delta[k] = self.ease[timer.ease](timer.elapsed,
                            timer.st[k], timer.diff[k], timer.time)
        end
        if timer.elapsed>=timer.time then
            remove[#remove+1] = timer
            if timer.after then timer.after() end
        end
    end
    -- save remove
    for i=1, #remove do self:cancel(remove[i]) end
end

return TMR
