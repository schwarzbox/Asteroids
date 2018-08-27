#!/usr/bin/env lua
-- LOVUI
-- 2.0
-- GUI (love2d)
-- lovui.lua

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

-- 256 obj 60 fps
-- 3.0
-- Hbox remove
-- folditems
-- input utf support
-- make faster

if arg[1] then print('2.0 LOVUI GUI (love2d)', arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local EMPTY = {1,1,1,0}
local WHITE = {1,1,1,1}
local FNTCLR = {128/255,128/255,128/255,1}
local FRMCLR = {64/255,64/255,64/255,1}
local BOXCLR = {64/255-0.1,64/255-0.1,64/255-0.1,1}
local POPCLR = {64/255-0.05,64/255-0.05,64/255-0.05,0.95}
local FNT = {nil,16}

local UI = {kpress={},krelease={},mpress={},mrelease={},
            mmove={0,0,0,0,false},wmove={0,0}}
UI.DT = 0.017
function UI.init()
    local ev = {'keypressed','keyreleased','mousepressed',
            'mousereleased','mousemoved','wheelmoved'}
    -- add to love events
    local init_love = {}
    for i=1,#ev do
        init_love[ev[i]] = love[ev[i]] or function() end
        love[ev[i]] = function(...)
            init_love[ev[i]](...)
            UI[ev[i]](...)
        end
    end
end
-- OOP
function UI.Cls(Super, cls)
    Super = Super or {}
    cls = cls or {}
    cls.Super = Super
    local meta = {__index=Super}
    meta.__call = function(self,o)
                    o = o or {}
                    self.__index = self
                    self = setmetatable(o,self)
                    if self.new then self.new(self,o) end
                    return self
                end

    for k,v in pairs(Super) do
        if rawget(Super,k) and k:match('^__') and type(v)=='function' then
            cls[k] = v
        end
    end
    return setmetatable(cls,meta)
end
-- private
function UI.keypressed(key,unicode,isrepeat)
    UI.kpress = {key,unicode,isrepeat}
end
function UI.keyreleased(key,unicode)
    UI.krelease = {key,unicode}
end
function UI.mousepressed(x,y,button,istouch)
    UI.mpress = {x,y,button,istouch}
end
function UI.mousereleased(x,y,button,istouch)
    UI.mrelease = {x,y,button,istouch}
end
function UI.mousemoved(x,y,dx,dy,istouch) UI.mmove = {x,y,dx,dy,istouch} end
function UI.wheelmoved(x, y) UI.wmove = {x,y} end
-- public
function UI.get_dt() return UI.DT end
function UI.keypress() return unpack(UI.kpress) end
function UI.keyrelease() return unpack(UI.krelease) end
function UI.mousepress() return unpack(UI.mpress) end
function UI.mouserelease() return unpack(UI.mrelease) end
function UI.mousemove() return unpack(UI.mmove) end
function UI.wheelmove() return unpack(UI.wmove) end
function UI.clearevent()
    UI.kpress={}
    UI.krelease={}
    UI.mpress={}
    UI.mrelease={}
    UI.mmove={UI.mmove[1],UI.mmove[2],0,0,false}
    UI.wmove={0,0}
end

-- UI Manager
UI.Manager = {items={}}
function UI.Manager.draw()
    for _, item in pairs( UI.Manager.items) do item:draw() end
end
function UI.Manager.update(dt)
    for _, item in pairs( UI.Manager.items) do item:update(dt) end
    UI.clearevent()
end

function UI.Manager.len() return #UI.Manager.items end
function UI.Manager.add(item) UI.Manager.items[#UI.Manager.items+1] = item end
function UI.Manager.clear() UI.Manager.items = {} end
function UI.Manager.remove(item)
    for i=1,#UI.Manager.items do
        if UI.Manager.items[i] and UI.Manager.items[i]==item then
            table.remove(UI.Manager.items,i)
        end
    end
end

function UI.Manager.focus(bool)
    for i=1, #UI.Manager.items do
        if UI.Manager.items[i] and (UI.Manager.items[i].type~='input' and
                                    UI.Manager.items[i].type~='popup' and
                                    UI.Manager.items[i].type~='foldlist') then
            UI.Manager.items[i].focus = bool
        end
    end
end


local Proto = UI.Cls({x=nil, y=nil, anchor='center', frame=0, frmclr=FRMCLR,
    mode='line',wid=0,hei=0,corner={0,0,0},hide=false,focus=true,drag=false})
function Proto:__tostring() return self.type end
function Proto:set(vars) for k,v in pairs(vars) do self[k] = v end end
function Proto:get(var) return self[var] end
function Proto:set_focus(bool) self.focus = bool end
function Proto:set_hide(bool) self.hide = bool end
function Proto:remove() UI.Manager.remove(self) end

function Proto.get_place(itx,ity,itwid,ithei,frame,side)
    local x,y
    itwid,ithei = itwid+frame*2,ithei+frame*2
    local midx,midy = itwid/2,ithei/2
    if side=='n' then x, y = itx-midx,ity
    elseif side=='s'then x,y = itx-midx,ity-ithei
    elseif side=='w' then x,y = itx,ity-midy
    elseif side=='e' then x,y = itx-itwid,ity-midy
    elseif side=='nw' then x,y = itx,ity
    elseif side=='ne' then x,y = itx-itwid,ity
    elseif side=='se' then x,y = itx-itwid,ity-ithei
    elseif side=='sw' then x,y = itx,ity-ithei
    else x,y = itx-midx, ity-midy
    end
    return x,y
end

function Proto.get_pivot(itwid,ithei,pivot)
    local x,y
    local midx, midy = itwid/2, ithei/2
    if pivot=='nw' then x,y = 0,0
    elseif pivot=='ne' then x,y = itwid,0
    elseif pivot=='sw' then x,y = itwid,ithei
    elseif pivot=='se'then x,y = 0,ithei
    else x,y = midx,midy
    end
    return x,y
end

function Proto:set_widhei(wid,hei)
    if wid>self.wid then self.wid = wid end
    if hei>self.hei then self.hei = hei end
    self.wid = self.wid+self.wid%2
    self.hei = self.hei+self.hei%2
end

function Proto:draw_frame()
    local frmclr = self.deffrm or EMPTY
    if self.frame>0 and self.wid>0 then
        love.graphics.setColor(frmclr)

        love.graphics.rectangle(self.mode, self.rect_posx, self.rect_posy,
                                self.wid+self.frame*2, self.hei+self.frame*2,
                                unpack(self.corner))
        love.graphics.setColor(WHITE)
    end

end

function Proto:collide(x,y)
    return ((x>self.rect_posx and x<self.rect_posx+self.wid+self.frame*2) and
        (y>self.rect_posy and y<self.rect_posy+self.hei+self.frame*2))
end

function Proto:mouse_collide(x,y)
    local xx, yy ,dx, dy, istouch = UI.mousemove()
    if not x or not y then  x=xx y=yy end
    if self:collide(x,y) then return true end
end

function Proto:mouse_colpress(but,touch)
    local x, y, button, istouch = UI.mousepress()
    if button==but and self:mouse_collide(x,y) then
        return true
    end
end

function Proto:mouse_colrelease(but,touch)
    local x, y, button, istouch = UI.mouserelease()
    if button==but and self:mouse_collide(x,y) then
        return true
    end
end

function Proto:mouse_coldown(but)
    if love.mouse.isDown(but) and self:mouse_collide() then return true end
end

function Proto:mouse_press(but,touch)
    local x, y, button, istouch = UI.mousepress()
    if button==but then
        return x, y, button, istouch
    end
end

function Proto:mouse_release(but,touch)
    local x, y, button, istouch = UI.mouserelease()
    if button==but then
        return x, y, button, istouch
    end
end

function Proto:mouse_down(but)
    local xx, yy ,dx, dy, istouch = UI.mousemove()
    if love.mouse.isDown(but) then
        return xx, yy ,dx, dy, istouch
    end
end

function Proto:key_press(keypress,scancode)
    local key, unicode, isrepeat = UI.keypress()
    if keypress==key then
        return true
    end
end

function Proto:key_release(keyrelease,scancode)
    local key, unicode = UI.keyrelease()
    if keyrelease==key then
        return true
    end
end

function Proto:key_down(key)
    if love.keyboard.isDown(key) then return true end
end

function Proto:mouse_move()
    local x,y,dx,dy,istouch = UI.mousemove()
    return x,y,dx,dy,istouch
end

function Proto:wheel_move()
    local x,y = UI.wheelmove()
    return x,y
end


UI.Sep = UI.Cls(Proto)
UI.Sep.type = 'sep'
function UI.Sep:new(o)
    self.deffrm = self.frmclr
    self.wid=2
    self.hei=2
    self.frame=0.5
    self.mode = 'fill'
    self:setup()
    UI.Manager.add(self)
end

function UI.Sep:setup()
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.get_place(self.x,self.y,
                                           self.wid,self.hei,self.frame,
                                           self.anchor)
end

function UI.Sep:draw() if not self.hide then self:draw_frame() end end
function UI.Sep:update(dt) dt=dt or UI.get_dt() self:setup() end


UI.HBox = UI.Cls(Proto,{frmclr=BOXCLR,sep=8,drag=false})
UI.HBox.type = 'hbox'
function UI.HBox:new(o)
    self.deffrm = self.frmclr
    self.items = {}
    self:setup()
    UI.Manager.add(self)
end

function UI.HBox:setup()
    local wid,hei = 0,0
    for i=1,#self.items do
        if self.items[i] then
            local itwid = self.items[i]:get('wid')
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frame')
            wid = wid+itwid+itfrm*2
            if hei<ithei+itfrm*2 then hei = ithei+itfrm*2 end
        end
    end

    wid = wid+self.sep*(#self.items-1)
    self:set_widhei(wid, hei)
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.get_place(self.x,self.y,
                                           self.wid,self.hei,self.frame,
                                           self.anchor)
    self.conx = self.rect_posx+self.frame
    self.cony = self.rect_posy+self.frame
    local tot_wid = 0
    for i=1, #self.items do
        if self.items[i] then
            -- get w anchor
            local itwid = self.items[i]:get('wid')
            local itfrm = self.items[i]:get('frame')

            self.items[i]:set({x=self.conx+tot_wid,
                              y=self.cony+self.hei/2,
                              anchor='w'})

            if self.items[i]:get('type')=='sep' then
                self.items[i]:set({wid=1,hei=self.hei-2})
            end
            tot_wid = tot_wid+itwid+itfrm*2+self.sep
            if (self.items[i]:get('type')=='counter' or
                self.items[i]:get('type')=='slider' or
                self.items[i]:get('type')=='progbar' or
                self.items[i]:get('type')=='list' or
                self.items[i]:get('type')=='foldlist') then
                self.items[i]:setup()
            end
        end
    end
end

function UI.HBox:add(...)
    local fargs = {...}
    for i=1, #fargs do self.items[#self.items+1] = fargs[i] end
    self:setup()
end

function UI.HBox:set_drag(bool) self.drag = bool end
function UI.HBox:set_hide(bool)
    self.hide=bool
    for i=1,#self.items do
        if self.items[i] then self.items[i]:set_hide(bool) end
    end
end

function UI.HBox:draw() if not self.hide then self:draw_frame() end end
function UI.HBox:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        if self:mouse_coldown(1) and self.drag then
            local x,y,dx,dy,istouch = self:mouse_move()
            self.x,self.y=self.x+dx,self.y+dy
        end
    end
end

function UI.HBox:remove()
    for i=#self.items, 1,-1 do
        if self.items[i] then self.items[i]:remove() end
    end
    UI.Manager.remove(self)
end


UI.VBox = UI.Cls(UI.HBox)
UI.VBox.type = 'vbox'
function UI.VBox:setup()
    local wid,hei = 0,0
    for i=1,#self.items do
        if self.items[i] then
            local itwid = self.items[i]:get('wid')
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frame')
            hei = hei+ithei+itfrm*2
            if wid<itwid+itfrm*2 then wid = itwid+itfrm*2 end
        end
    end

    hei = hei+self.sep*(#self.items-1)
    self:set_widhei(wid, hei)
    -- problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.get_place(self.x,self.y,
                                           self.wid,self.hei,self.frame,
                                           self.anchor)
    self.conx = self.rect_posx+self.frame
    self.cony = self.rect_posy+self.frame
    local tot_hei = 0
    for i=1, #self.items do
        if self.items[i] then
            -- get n anchor
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frame')
            self.items[i]:set({x=self.conx+self.wid/2,
                                y=self.cony+tot_hei,
                                anchor='n'})
            if self.items[i]:get('type')=='sep' then
                self.items[i]:set({wid=self.wid-2,hei=1})
            end

            tot_hei = tot_hei+ithei+itfrm*2+self.sep

            if (self.items[i]:get('type') == 'counter' or
                self.items[i]:get('type') == 'slider' or
                self.items[i]:get('type') == 'progbar' or
                self.items[i]:get('type') == 'list' or
                self.items[i]:get('type') == 'foldlist') then
                self.items[i]:setup()
            end
        end
    end
end


UI.PopUp = UI.Cls(UI.VBox{frmclr=POPCLR,focus=false})
UI.PopUp.type = 'popup'
function UI.PopUp:new()
    self.frame = 2
    self.deffrm=self.frmclr
    self.mode='fill'
    self.sep = 4
    self.drag = false
    self.txt = nil

    UI.Manager.add(self)

    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end

    self.items = {self.txt,UI.Sep(),unpack(self.items,1,#self.items)}
    self:set_hide(self.hide)
    self:setup()
end

function UI.PopUp:add(...)
    UI.PopUp.Super.add(self,...)
    for i=2,#self.items do
        if self.items[i]:get('type')~='sep' then
            local butcom = self.items[i]:get('command') or function() end
            local command = function() butcom()
                                self.x, self.y = 0,0 self.anchor='sw'
                                UI.Manager.focus(true)
                            end
            self.items[i]:set({fnt=self.fnt, fntclr=self.fntclr,
                                                        command=command})
        end
    end
end

function UI.PopUp:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        if self:mouse_press(1) and not self:mouse_collide() then
            self.x, self.y = 0,0 self.anchor='sw'
            UI.Manager.focus(true)
            self:set_focus(false)
        end
    end
    local x2,y2 = self:mouse_press(2)
    if x2 and y2 then
        self.x, self.y = x2,y2 self.anchor='nw'
        UI.Manager.focus(false)
        for i=1,#self.items do
            self.items[i]:set_focus(true)
        end
        self:set_focus(true)
    end
end


UI.Label = UI.Cls(Proto,{text='', fnt=FNT, fntclr=FNTCLR, isrepeat=nil,
                variable=nil, command=function() end, image=nil,
                rotate=0, rot_dt=nil, scalex=1, scaley=1, scewx=0,scewy=0})
UI.Label.type = 'label'
function UI.Label:new(o)
    self.pivot='center'
    self:set_image(self.image)
    self.rotate=math.rad(self.rotate)

    self.defclr = self.fntclr
    self.onclr = {self.fntclr[1]+0.4,self.fntclr[2]+0.4,self.fntclr[3]+0.4,1}

    self.deffrm = self.frmclr
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    if self.fnt[1] then
        self.font = love.graphics.newFont(self.fnt[1], self.fnt[2])
    else
        self.font = love.graphics.newFont(self.fnt[2])
    end
    -- repeat button and input
    self.rtime = self.isrepeat
    self:setup()
    UI.Manager.add(self)
end

function UI.Label:setup()
    local fargs
    if self.image then
        fargs = {self.image}
    else
        fargs = {self.font, self.text}
    end

    local wid,hei = self.get_size(unpack(fargs))
    self:set_widhei(wid, hei)
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end

    self.rect_posx, self.rect_posy = self.get_place(self.x, self.y,
                                           self.wid,self.hei,self.frame,
                                           self.anchor)

    self.pivx, self.pivy = self.get_pivot(wid, hei, self.pivot)
    self.cenx = self.rect_posx+(self.wid+self.frame*2)/2
    self.ceny = self.rect_posy+(self.hei+self.frame*2)/2
end

function UI.Label:set_image(image)
    if image then self.image = love.graphics.newImage(image) end
end

function UI.Label:get_repeat(event,evarg,dt)
    if self.isrepeat then
        if self.isrepeat>0 then
            self.isrepeat = self.isrepeat-dt
        else
            self.isrepeat = self.rtime/8
            local press=event(self,evarg)
            return press
        end
    end
end

function UI.Label.get_size(item,other)
    local wid,hei = item:getWidth(other),item:getHeight()
    wid = wid+wid%2
    hei = hei+hei%2
    return wid,hei
end

function UI.Label:set_rotate(dt)
    if self.rot_dt then self.rotate = self.rotate+self.rot_dt*dt end
end

function UI.Label:update(dt)
    dt=dt or UI.get_dt()
    self:set_rotate(dt)
    self:setup()
    if self.focus and not self.hide then
        if self.variable then self.text = self.variable.val end
        local press = self:mouse_colpress(1)
        return press
    end
end

function UI.Label:draw()
    if not self.hide  then
        self:draw_frame()
        love.graphics.setColor(self.defclr)
        if self.image then
            love.graphics.draw(self.image, self.cenx, self.ceny, self.rotate,
                               self.scalex, self.scaley, self.pivx, self.pivy,
                               self.scewx, self.scewy)
        else
            love.graphics.setFont(self.font)
            love.graphics.print(self.text, self.cenx, self.ceny,self.rotate,
                                self.scalex, self.scaley,
                                self.pivx, self.pivy,
                                self.scewx, self.scewy)
        end
        love.graphics.setColor(WHITE)
    end
end


UI.Input = UI.Cls(UI.Label,{isrepeat=1, frame=2,focus=false,chars=8,
                            mode='line'})
UI.Input.type = 'input'
function UI.Input:new(o)
    local loveinput = love.textinput or function() end
    love.textinput = function(...)
        loveinput(...)
        self.textinput(self,...)
    end
    self.variable = self.variable or {val=''}
    -- set cursor
    self.curx,self.cury = 0,0
    self.cursize=1
    if self.image then self.cursize = 0 end
    local image = self.image
    self.offset = 0
    -- init size (include left offset)
    self.chars = self.chars+1
    UI.Input.Super.new(self)
    self.cursor=UI.Label{text='',fnt={self.fnt[1],self.fnt[2]-1},
                        frmclr=self.onclr, frame=self.cursize,
                        mode='fill', image=image,rot_dt=self.rot_dt,hide=true}
    -- input setup
    self:clear(true)
end

function UI.Input:setup()
    local wid,hei = self.get_size(self.font,string.rep('0', self.chars))
    self:set_widhei(wid, hei)
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.get_place(self.x, self.y,
                                           self.wid,self.hei,self.frame,
                                           self.anchor)
    self.pivx, self.pivy = self.get_pivot(wid, hei, self.pivot)
    self.cenx = self.rect_posx+(self.wid+self.frame*2)/2
    self.ceny = self.rect_posy+(self.hei+self.frame*2)/2
    -- left offset
    self.offsetwid,self.offsethei=self.get_size(self.font,string.rep('0', 1))
    self.addsize = self.offsetwid*2+self.cursize*2

    if self.cursor then
        local correction = self.curx+self.frame+self.offsetwid-self.offset
        local cx = self.rect_posx+correction
        local cy = self.rect_posy+self.frame
        -- use wid to show cursor
        self.cursor:set({x=cx,y=cy,wid=0.01,anchor='n'})
    end
end

function UI.Input:clear(init)
    self.variable.val=''
    if not init then
        self.text = self.variable.val
    end
    self.curpos = 0
    self.curblink = 1
    self.blink = self.curblink
    self.leftoff=1
    self.rightoff=0
    self.offset = 0
    self.curx, self.cury=self:get_curpos()
end

function UI.Input:set_text(itext)
    local wid,_ = self.get_size(self.font, itext)
    local leftoff = 1
    self.offset=0
    while wid+self.addsize>self.wid do
        if wid+self.addsize-self.wid<self.offsetwid then
            self.offset = wid+self.addsize-self.wid
            break
        end
        itext=itext:sub(2,#itext)
        wid,_ = self.get_size(self.font, itext)
        leftoff = leftoff+1
    end
    return leftoff
end

function UI.Input:get_curpos()
    local dtxt = #self.variable.val-self.curpos
    local curtext = self.text:sub(1, #self.text+self.rightoff-dtxt)
    return self.get_size(self.font, curtext)
end

function UI.Input:left()
    if self.curpos>=1 then self.curpos = self.curpos-1 end

    local itext = self.variable.val
    self.curx, self.cury=self:get_curpos()
    if self.curx-self.offset<0 then
        -- local itext = self.variable.val
        local righttxt = itext:sub(1,self.curpos)
        local offset,_ = self.get_size(self.font, righttxt)
        self.leftoff = 1
        while offset>self.offsetwid do
            righttxt=righttxt:sub(2,#righttxt)
            offset,_ = self.get_size(self.font, righttxt)
            self.leftoff = self.leftoff+1
        end
        self.offset = offset

        local lefttxt = itext:sub(self.curpos+1,#itext)
        local wid,_ = self.get_size(self.font,lefttxt)
        self.rightoff = 0
        while wid+self.addsize>self.wid do
            lefttxt=lefttxt:sub(1,#lefttxt-1)
            wid,_ = self.get_size(self.font, lefttxt)
            self.rightoff = self.rightoff+1
        end
    end
    self.text=itext:sub(self.leftoff,#itext-self.rightoff)
end

function UI.Input:right()
    if self.curpos<#self.variable.val then self.curpos = self.curpos+1 end

    local curwid,_ = self.get_size(self.font,self.text)
    if self.curx>=curwid then
        self.leftoff = self:set_text(self.variable.val:sub(1,self.curpos))

        if self.rightoff>0 then self.rightoff=self.rightoff-1 end
        self.text = self.variable.val:sub(self.leftoff,self.curpos)
    end
end

function UI.Input:erase()
    local itext = self.variable.val
    local last = utf8.offset(itext:sub(1, self.curpos), -1)
    if last then
        itext = itext:sub(1,last-1)..itext:sub(self.curpos+1, #itext)
        self.variable.val = itext
        self.curpos = self.curpos-1
    end
    self.leftoff = self:set_text(itext:sub(1,#itext))
    self.text = itext:sub(self.leftoff,#itext)
end

function UI.Input:textinput(t)
    if self.focus and not self.hide then
        local itext = self.variable.val
        itext = itext:sub(1,self.curpos)..t..itext:sub(self.curpos+1, #itext)
        self.variable.val = itext
        self.curpos = self.curpos+1
        self.leftoff = self:set_text(itext:sub(1,#itext))
        self.text = itext:sub(self.leftoff,#itext)
    end
end

function UI.Input:draw()
    if not self.hide then
        self:draw_frame()
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.defclr)
        love.graphics.print(self.text,
                            self.cenx+self.offsetwid-self.offset, self.ceny,
                            self.rotate,self.scalex, self.scaley,
                            self.pivx, self.pivy,self.scewx, self.scewy)
        love.graphics.setColor(WHITE)
    end
end

function UI.Input:update(dt)
    dt=dt or UI.get_dt()
    if self.blink>0 then self.blink = self.blink-dt
    else self.blink = self.curblink end
    -- cursor
    if self.focus and not self.hide and self.blink>self.curblink/2 then
        self.cursor:set_hide(false)
    else
        self.cursor:set_hide(true)
    end

    self:setup()
    if self.focus and not self.hide then
        if self:key_press('backspace') then
            self.isrepeat = self.rtime
            self:erase()
        end
        if self:get_repeat(self.key_down,'backspace',dt) then
            self:erase()
        end
        if self:key_press('left') then
            self.isrepeat = self.rtime
            self:left()
        end
        if self:get_repeat(self.key_down,'left',dt) then self:left() end
        if self:key_press('right') then
            self.isrepeat = self.rtime
            self:right()
        end
        if self:get_repeat(self.key_down,'right',dt) then self:right() end

        if self:key_press('return') then
            UI.Manager.focus(true)
            self:set_focus(false)
        end
        if self:mouse_press(1) and not self:mouse_collide() then
            UI.Manager.focus(true)
            self:set_focus(false)
        end
    end

    self.curx, self.cury = self:get_curpos()
    local press = self:mouse_colpress(1)
    if press and not self.focus then
        UI.Manager.focus(false)
        self.text = self.variable.val:sub(self.leftoff,#self.variable.val)
        self.curx, self.cury=self:get_curpos()
        self:set_focus(true)
    end
    return press
end

function UI.Input:remove() self.cursor:remove() UI.Manager.remove(self) end


UI.CheckBox = UI.Cls(UI.Label,{frame=2, mode='fill',corner={4,4,2}})
UI.CheckBox.type = 'checkbox'
function UI.CheckBox:new(o)
    self.variable = self.variable or {bool=false}
    UI.CheckBox.Super.new(self)
    if self.variable.bool then self.defclr=self.onclr end
end

function UI.CheckBox:update(dt)
    dt=dt or UI.get_dt()
    self:set_rotate(dt)
    self:setup()

    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        if press then
            self.variable.bool = not self.variable.bool
            self:command()
        end
        if self.variable.bool then self.defclr = self.onclr
        else self.defclr = self.fntclr end
        return press
    end
end


UI.LabelExe = UI.Cls(UI.Label,{time=60})
UI.LabelExe.type = 'labelexe'
function UI.LabelExe:update(dt)
    dt=dt or UI.get_dt()
    self:set_rotate(dt)
    self:setup()

    if self.time<=0 then self:command() self:remove() return end
    self.time = self.time-1
end


UI.Button = UI.Cls(UI.Label,{frame=2,corner={4,4,2}})
UI.Button.type = 'button'
function UI.Button:set_clr()
    self.deffrm = self.frmclr
    self.defclr = self.fntclr
end

function UI.Button:update(dt)
    dt=dt or UI.get_dt()
    self:set_rotate(dt)
    self:setup()

    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        local release = self:mouse_colrelease(1)

        if self:mouse_collide() then
            self.defclr = self.onclr
        else
            self:set_clr()
        end

        if press then
            self.isrepeat = self.rtime
            self.deffrm = self.onfrm
        end

        local repeat_press = self:get_repeat(self.mouse_coldown,1,dt)
        if repeat_press then
            self:set_clr()
            self:command()
            return repeat_press
        end

        if release then self:set_clr() self:command() end
        return press
    end
end


UI.Selector = UI.Cls(UI.Label, {variable={val=''},corner={4,4,2}})
UI.Selector.type = 'selector'
function UI.Selector:setup()
    if self.variable.val==self.text then self.defclr = self.onclr
    else self.defclr = self.fntclr end
    UI.Selector.Super.setup(self)
end

function UI.Selector:update(dt)
    dt=dt or UI.get_dt()
    self:set_rotate(dt)
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        if press then
            self.variable.val = self.text
            self:command()
        end
        return press
    end
end


UI.Counter = UI.Cls(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                    image=nil,modifier=1, min=0, max=1000})
UI.Counter.type = 'counter'
function UI.Counter:new(o)
    self.deffrm = self.frmclr
    self.variable = self.variable or {val=0}
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1

    self.txt = nil
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,image=self.image,
                             fnt=self.fnt, fntclr=self.fntclr}
    end

    self.right = UI.Button{text='>', fnt=self.fnt, fntclr=self.fntclr,
                command=function() self:add() end, isrepeat=1,
                frame=2, frmclr=self.frmclr,mode=self.mode}
    self.left = UI.Button{text='<', fnt=self.fnt, fntclr=self.fntclr,
                command=function() self:sub() end, isrepeat=1,
                frame=2, frmclr=self.frmclr,mode=self.mode}
    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr, variable=self.variable,
                    frame=2, frmclr=self.frmclr,
                    mode=self.mode}
    self.display:set({text = self.min})
    self.frame = 0
    self.items = {self.txt, self.left, self.display, self.right}
    self:set_hide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.Counter:add()
    local num = self.variable.val + self.modifier
    if num > self.max then num = self.max end
    num = tonumber(string.format('%.1f', num))
    self.variable.val = num
end

function UI.Counter:sub()
    local num = self.variable.val - self.modifier
    if num < self.min then num = self.min end
    num = tonumber(string.format('%.1f', num))
    self.variable.val = num
end

function UI.Counter:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        return press
    end
end


UI.Slider=UI.Cls(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                        image=nil,min=0, max=100})
UI.Slider.type = 'slider'
function UI.Slider:new(o)
    self.deffrm = self.frmclr
    self.variable = self.variable or {val=0}
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    self.txt=nil
    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{frame=0,frmclr=self.frmclr,mode=self.mode}

    local barfrm = 2
    if self.image then barfrm=0 end
    self.bar = UI.Label{fnt=self.fnt, fntclr=self.onfrm, image=self.image,
        frame=barfrm,frmclr=self.onfrm,mode='fill'}
    -- setup cursor wid and max len
    self:set_size()
    self.border:add(self.bar)
    -- redefine HBox update to move slider
    local borupdate = self.border:get('update')
    self.border:set({update = function(...)
                    borupdate(self.border,...)
                    local oldx = math.floor(self.bar:get('x'))
                    self.bar:set({x=oldx+self.variable.val})
                    end})
    self.border:set({draw = function(...)
            if not self.hide then
                local frmclr = self.border:get('deffrm') or EMPTY
                love.graphics.setColor(frmclr)
                local wid = self.border:get('wid')
                local hei = self.border:get('hei')
                local frame = 2
                local rect_posx = self.border:get('rect_posx')
                local rect_posy = self.border:get('rect_posy')
                love.graphics.rectangle('fill',rect_posx+frame,
                                                rect_posy-frame+hei/2,
                                                wid,frame*2)
                love.graphics.setColor(WHITE)
            end
            end})

    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr,
                    variable=self.variable,
                    frame=2, frmclr=self.frmclr,
                    mode=self.mode}
    self.frame = 0
    self.items = {self.txt, self.border, self.display}
    self:set_hide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.Slider:set_value()
    local oldx = math.floor(self.bar:get('x'))
    local halfbarwid = self.bar:get('wid')/2
    local x,_ = self:mouse_move()
    local newx = x-halfbarwid

    if self.variable.val+newx-oldx>self.max then return end
    if self.variable.val+newx-oldx<self.min then return end
    self.variable.val = self.variable.val+newx-oldx
    -- fix mouse
    love.mouse.setPosition(newx+halfbarwid,self.bar:get('y'))
    self.bar:set({x=newx})
end

function UI.Slider:set_size()
    local barhei = self.bar:get('hei')
    self.bar:set({wid=barhei})
    local barwid = self.bar:get('wid')
    local borwid=self.max+barwid+self.border:get('frame')*2
    self.border:set{wid=borwid}
end

function UI.Slider:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        if self.bar:mouse_coldown(1) then self:set_value() end
        return press
    end
end


UI.ProgBar=UI.Cls(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                frame=2, image=nil, barchar='|',barmode='fill',min=0,max=10})
UI.ProgBar.type = 'progbar'
function UI.ProgBar:new(o)
    self.deffrm = self.frmclr
    self.variable = self.variable or {val=0}

    self.barvar = {val=string.rep(self.barchar, self.max)}
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    self.txt = nil
    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{sep=2,frame=self.frame, frmclr=self.frmclr,
                                                            mode=self.mode}
    local barfrm=2
    if self.barmode=='line' then barfrm=0 end
    if self.barmode=='fill' then self.barchar= ' ' end
    if self.image then
        for _=1, self.max do
            self.border:add(UI.Label{text='', fnt=self.fnt,
                                fntclr=self.onfrm, variable=nil,
                                image=self.image, rot_dt=self.rot_dt,
                                frame=0,frmclr=self.onfrm})
        end
    else
        self.bar = UI.Label{text=self.barvar.val, fnt=self.fnt,
                            fntclr=self.onfrm, variable=self.barvar,
                            image=self.image, frame=barfrm,
                            frmclr=self.onfrm, mode=self.barmode}
        self.border:add(self.bar)
    end
    self.frame = 0
    self.items = {self.txt, self.border}
    self:set_hide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.ProgBar:set_image(image)
    local items = self.border:get('items')
    for i=1, self.max do
        items[i]:set_image(image)
    end
end

function UI.ProgBar:set_value()
    if self.variable.val<self.min then self.variable.val=self.min end
    if self.variable.val>self.max then self.variable.val=self.max end
    self.barvar.val = string.rep(self.barchar,self.variable.val)
end

function UI.ProgBar:set_size()
    if self.image then
        local items = self.border:get('items')
        for i=1,self.max do
            items[i]:set_hide(false)
        end
        for i=self.max,#self.barvar.val+1,-1 do
            items[i]:set_hide(true)
        end
    else
        local w,h = self.bar.get_size(self.bar:get('font'),self.barvar.val)
        self.bar:set({wid=w,hei=h})
    end
end

function UI.ProgBar:update(dt)
    dt=dt or UI.get_dt()
    self:set_value()
    self:set_size()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        return press
    end
end

UI.List = UI.Cls(UI.VBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
        command=function() end,image=nil,items={},sep=4,max=4,sel=1})
UI.List.type = 'list'
function UI.List:new(o)
    self.deffrm = self.frmclr
    self.variable = self.variable or {val=''}
    self.txt = nil
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,fnt=self.fnt,fntclr=self.fntclr,
                            image=self.image}
    end

    self.border = UI.VBox{frame=2, sep=2, frmclr=self.frmclr,mode=self.mode}
    -- set init size
    if #self.items>self.max then self.max=#self.items end
    if #self.items==0 and self.max~=0 then
        self.items = {'Selector1','Selector2','Selector3','Selector4'}
    end
    self:add(unpack(self.items))
    -- defaul size
    local initlen = #self.items
    if initlen<self.max then
        for i=initlen+1,self.max do self:add('Selector'..i) end
    end
    self:select(self.sel)
    self.frame = 0
    self.items = {self.txt,self.border}
    self:set_hide(self.hide)
    self:setup()
    -- default size
    if initlen<self.max then
        for i=self.max,initlen+1,-1 do self:delete(i) end
    end
    UI.Manager.add(self)
end

function UI.List:add(...)
    local fargs = {...}
    for i=1,#fargs do
    if type(fargs[i])=='table' then
            self.border:add(UI.Selector{text=fargs[i][1],
                            fnt=self.fnt,fntclr=self.fntclr,
                            variable=self.variable,
                            command=self.command,image=fargs[i][2]})
        else
            self.border:add(UI.Selector{text=fargs[i],fnt=self.fnt,
                            fntclr=self.fntclr,
                            variable=self.variable, command=self.command})
        end
    end
end

function UI.List:get_items()
    return self.border:get('items')
end

function UI.List:index(text)
    local items = self:get_items()
    for i=1, #items do if items[i]:get('text')==text then return i end end
end

function UI.List:select(index)
    local item = self:get_items()[index]
    if item then
        self.variable.val = item:get('text')
        item.command()
    end
end

function UI.List:delete(index)
    self.border:get_items()[index]:remove()
    table.remove(self:get_items(),index)
end

function UI.List:clear()
    local items = self:get_items()
    for i=#items, 1,-1 do items[i]:remove() table.remove(items,i) end
end

function UI.List:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        local index = self:index(self.variable.val)
        local items = self:get_items()
        local _,ywheel = false, false
        if self:mouse_collide() then ywheel = self:wheel_move() end
        if (self:key_press('up') or
            (ywheel and ywheel>0)) and index>1 then
            self:select(index-1)
        end
        if (self:key_press('down') or
            (ywheel and ywheel<0)) and index<#items then
            self:select(index+1)
        end
        return press
    end
end

UI.FoldList = UI.Cls(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,
                        frmclr=FRMCLR,image=nil,items={},sel=1,focus=false})
UI.FoldList.type = 'foldlist'

function UI.FoldList:new(o)
    self.deffrm = self.frmclr
    self.variable = self.variable or {val=''}
    self.txt = nil
    -- set init size
    if #self.items==0 then
        self.items = {'Selector1'}
    end
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,fnt=self.fnt,fntclr=self.fntclr,
                            image=self.image}
    end

    local maxlen = 0
    local maxtext
    for i=1,#self.items do
        local len=#self.items[i]
        local text=self.items[i]
        if type(self.items[i])=='table' then
            len=#self.items[i][1] text=self.items[i][1]
        end
        if len>maxlen then maxlen = len maxtext = text end
    end

    self.display = UI.Label{text=maxtext,
                    fnt=self.fnt, fntclr=self.fntclr, variable=self.variable,
                    frame=2, frmclr=self.frmclr,
                    mode=self.mode}

    self:select(1)
    if self.sel<=#self.items then
        self:select(self.sel)
    end

    self.folditems=self.items
    self.fold = UI.Button{text='...', fnt=self.fnt, fntclr=self.fntclr,
                command=function()
                    local hei = self.display:get('hei')
                    local frame = self.display:get('frame')

                    self.list = UI.List{x=self.display:get('rect_posx'),
                            y=self.display:get('rect_posy')+hei+frame*2,
                            anchor = 'nw',fnt=self.FNT,fntclr=self.FNTCLR,
                            frame=2,frmclr=self.FRMCLR,mode='fill',
                            variable=self.variable,
                            command=function()
                                    self.display:set({text=self.variable.val})
                                end,
                            items=self.folditems,max=0,
                            sel=self:index(self.variable.val)}
                    UI.Manager.focus(false)
                    local listitems = self.list:get_items()
                    for i=1,#listitems do listitems[i]:set_focus(true) end
                    self.list:set_focus(true)
                    self.display:set_focus(true)
                    self:set_focus(true)
                    end, frame=2, frmclr=self.frmclr,mode=self.mode}

    self.frame=0
    self.items = {self.txt,self.display,self.fold}
    self:set_hide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.FoldList:add(...)
    local fargs = {...}
    for i=1,#fargs do self.folditems[#self.folditems+1]=fargs[i] end
end

function UI.FoldList:get_items()
    return self.folditems
end

function UI.FoldList:index(text)
    for i=1, #self.folditems do
        if type(self.folditems[i])=='table' then
            if self.folditems[i][1]==text then return i end
        else
            if self.folditems[i]==text then return i end
        end
    end
end

function UI.FoldList:select(index)
    local item = self.folditems or self.items
    local val = item[index]
    if type(val)=='table' then self.variable.val = val[1]
    else self.variable.val = val end
end

function UI.FoldList:delete(index) table.remove(self.folditems,index) end

function UI.FoldList:clear()
    self.folditems = {}
    self.variable.val = ''
end

function UI.FoldList:close()
    UI.Manager.focus(true)
    self:set_focus(false)
    self.list:remove()
end

function UI.FoldList:update(dt)
    dt=dt or UI.get_dt()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouse_colpress(1)
        if (self:mouse_press(1) and not
                self:mouse_collide() and not
                self.list:mouse_collide()) then
            self:close()
        end

        if self.list:mouse_colpress(1) then
            self:close()
        end
        return press
    end
end
return UI
