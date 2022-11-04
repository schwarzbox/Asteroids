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
-- add ease elastic

-- Based on Tweener's easing functions (Penner's Easing Equations)

-- elapsed = elapsed time
-- st = start value
-- diff = fin - st
-- time = total time
-- step = step back

-- if use timer inside objects (use loc=true)

if arg[0] then print('1.0 TMR Timer (lua+love2d)', arg[0]) end
if arg[1] then print('1.0 TMR Timer (lua+love2d)', arg[1]) end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local Ease = {}
function Ease.linear(elapsed,st,diff,time) return diff*elapsed/time+st end

function Ease.inQuad(elapsed,st,diff,time)
  elapsed = elapsed/time
  return diff*elapsed*elapsed+st
end

function Ease.outQuad(elapsed,st,diff,time)
  elapsed = elapsed/time
  return -diff*elapsed*(elapsed-2)+st
end

function Ease.inOutQuad(elapsed, st, diff, time)
    elapsed = elapsed/time*2
    if elapsed < 1 then
        return diff/2*elapsed*elapsed+st
    else
        return -diff/2*((elapsed-1)*(elapsed-3)-1)+ st
    end
end

function Ease.outInQuad(elapsed,st,diff,time)
    if elapsed < time/2 then
      return Ease.outQuad(elapsed*2, st, diff/2, time)
    else
      return Ease.inQuad((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

function Ease.inOutCubic(elapsed,st,diff,time)
    elapsed = elapsed/time*2
    if elapsed<1 then return diff/2*elapsed*elapsed*elapsed+st end
    elapsed = elapsed-2
    return diff/2*(elapsed*elapsed*elapsed+2)+st
end

function Ease.inCubic(elapsed,st,diff,time)
    elapsed = elapsed/time
    return diff*(elapsed*elapsed*elapsed)+st
end

function Ease.outCubic(elapsed,st,diff,time)
    elapsed = elapsed/time-1
    return diff*((elapsed*elapsed*elapsed)+1)+st
end

function Ease.outInCubic(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.outCubic(elapsed*2, st, diff/2, time)
    else
        return Ease.inCubic((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

function Ease.inExpo(elapsed,st,diff,time)
    if elapsed==0 then return st
    else
        return diff*math.pow(2, 10*(elapsed/time-1))+st-diff*0.001
    end
end

function  Ease.outExpo(elapsed,st,diff,time)
    if elapsed==time then
        return st+diff
    else
        return diff*1.001*(-math.pow(2, -10*elapsed/time)+1)+st
    end
end

function Ease.inOutExpo(elapsed,st,diff,time)
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

function Ease.outInExpo(elapsed,st,diff,time)
  if elapsed<time/2 then
    return Ease.outExpo(elapsed*2, st, diff/2, time)
  else
    return Ease.inExpo((elapsed*2)-time, st+diff/2, diff/2, time)
  end
end

function Ease.inBack(elapsed,st,diff,time,step)
  if not step then step = 2.70158 end
  elapsed = elapsed / time
  return diff*elapsed*elapsed*((step+1)*elapsed-step)+st
end

function Ease.outBack(elapsed,st,diff,time,step)
  if not step then step = 2.70158 end
  elapsed = elapsed/time-1
  return diff*(elapsed*elapsed*((step+1)*elapsed+step)+1)+st
end

function Ease.inOutBack(elapsed,st,diff,time,step)
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

function Ease.outInBack(elapsed,st,diff,time,step)
  if elapsed<time/2 then
    return Ease.outBack(elapsed*2, st, diff/2, time, step)
  else
    return Ease.inBack((elapsed*2)-time, st+diff/2, diff/2, time, step)
  end
end

function Ease.outBounce(elapsed,st,diff,time)
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

function Ease.inBounce(elapsed,st,diff,time)
    return diff-Ease.outBounce(time-elapsed, 0, diff, time)+st
end

function Ease.inOutBounce(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.inBounce(elapsed*2, 0, diff, time)*0.5+st
    else
        return Ease.outBounce(elapsed*2-time, 0, diff, time)*0.5+diff*0.5+st
    end
end

function Ease.outInBounce(elapsed,st,diff,time)
    if elapsed<time/2 then
        return Ease.outBounce(elapsed*2, st, diff/2, time)
    else
        return Ease.inBounce((elapsed*2)-time, st+diff/2, diff/2, time)
    end
end

local TMR = {}
function TMR:new(loc)
    self.__index = self
    self = setmetatable({},self)
    self.alltmr = {}
    self:clear()

    if not loc then
        local update
        if  love and love.update then
            update = love.update
            love.update = function(...) update(...) self.update(self,...) end
        else
            update = self.update
            self.clock=os.clock()
            self.update = function(_,...)
                            local dt = os.clock()-_.clock
                            _.dt=dt
                            update(_,dt,...)
                            _.clock=_.clock+dt
                            return dt
                        end
        end
    end

    self.ease = Ease

    return self
end

function TMR.delete(self,timers,key)
    for timer in pairs(timers) do
        if timer.key and timer.key==key then self:remove(timer) end
    end
end

function TMR.sleep(time)
    local final = os.clock()+time
    repeat until os.clock()>final
end

function TMR:len(timers)
    local len = 0
    if timers then
        for _ in pairs(timers) do len = len+1 end
    else
        for i=1,#self.alltmr do
            local count=0
            for _ in pairs(self.alltmr[i]) do
                count = count+1
            end
            len = len+count
        end
    end
    return len
end

function TMR:remove(timer)
    for i=1,#self.alltmr do
        self.alltmr[i][timer] = nil
    end
end

function TMR:clear()
    for i=1, #self.alltmr do
        for timer in pairs(self.alltmr[i]) do
            self.alltmr[i][timer] = nil
        end
    end
    self.aftertmr = {} self.everytmr = {}
    self.duringtmr = {} self.tweentmr = {}
    self.scripttmr = {}
    self.alltmr = {self.aftertmr,self.everytmr,self.duringtmr,
                    self.tweentmr,self.scripttmr}
end

function TMR:destroy()
    self:clear()
    self=nil
end

function TMR:after(time,func,key)
    local timer = {elapsed=0, time=time, func=func, key=key}
    TMR.delete(self, self.aftertmr,key)
    self.aftertmr[timer] = timer
    return timer
end

function TMR:every(time,func,count,key)
    count = count or math.huge
    local timer ={elapsed=0, time=time, func=func, count=count, key=key}
    TMR.delete(self, self.everytmr,key)
    self.everytmr[timer] = timer
    return timer
end

function TMR:during(time,func,after,key)
    after = after or function() end
    local timer = {elapsed=0, time=time, func=func, after=after, key=key}
    TMR.delete(self, self.duringtmr, key)
    self.duringtmr[timer] = timer
    return timer
end

function TMR:script(func,key)
    local coroutinefunc = coroutine.wrap(func)
    local timer = {func=coroutinefunc, key=key}
    TMR.delete(self, self.scripttmr, key)
    self.scripttmr[timer] = timer
end

function TMR:tween(time,init,fin,ease,after,key)
    ease = ease or 'linear'
    local st = {}
    for k,v in pairs(init) do st[k] = v end
    local diff = {}
    for k,v in pairs(fin) do diff[k] = v-st[k] end

    local timer = {
        elapsed=0, time=time, st=st, diff=diff, delta=init,
        ease=ease, after=after, key=key
    }
    TMR.delete(self, self.tweentmr, key)
    self.tweentmr[timer] = timer
    return timer
end

function TMR:update(dt)
    local trash = {}
    for timer in pairs(self.aftertmr) do
        timer.elapsed = timer.elapsed+dt
        if timer.elapsed>=timer.time then
            trash[#trash+1] = timer
            timer.func()
        end
    end

    for i in pairs(self.everytmr) do
        local timer = self.everytmr[i]
        timer.elapsed = timer.elapsed+dt
        if timer.elapsed>=timer.time and timer.count>0 then
            timer.elapsed=0
            timer.func()
            timer.count = timer.count-1
        end
        if timer.count==0 then
            trash[#trash+1] = timer
        end
    end

    for timer in pairs(self.duringtmr) do
        timer.elapsed = timer.elapsed+dt
        timer.func()
        if timer.elapsed>=timer.time then
            trash[#trash+1] = timer
            timer.after()
        end
    end

    for timer in pairs(self.scripttmr) do
        -- on the fly create wait function with arg time
        timer.func(function(time)
                        self:after(time, timer.func)
                        coroutine.yield()
                    end)
        trash[#trash+1] = timer
    end

    for timer in pairs(self.tweentmr) do
        timer.elapsed = timer.elapsed+dt
        for k,_ in pairs(timer.diff) do
            timer.delta[k] = self.ease[timer.ease](timer.elapsed,
                            timer.st[k], timer.diff[k], timer.time)
        end
        if timer.elapsed>=timer.time then
            trash[#trash+1] = timer
            if timer.after then timer.after() end
        end
    end
    -- clean trash
    for i=1, #trash do self:remove(trash[i]) end
end

return TMR
