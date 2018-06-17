#!/usr/bin/env lua
-- LOVUI
-- 1.0
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

-- check widget hbox setup
-- move hbox and vbox drag ui ctrl
-- progress bar with images
-- hbox and vbox align

-- lovui 2.0
-- input utf support
-- improve input align
-- scrooled list with hbox

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local WHITE = {1,1,1,1}
local FNTCLR = {128/255,128/255,128/255,1}
local FRMCLR = {64/255,64/255,64/255,1}
local FNT = {nil,16}
local UI = {}

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

-- Manager collect UI
UI.Manager = {items={}}
function UI.Manager.len() return #UI.Manager.items end

function UI.Manager.clear() UI.Manager.items = {} end

function UI.Manager.add(item) UI.Manager.items[#UI.Manager.items+1] = item end

function UI.Manager.remove(item)
    for i=1, #UI.Manager.items do
        if UI.Manager.items[i]==item then UI.Manager.items[i] = nil end
    end
end

function UI.Manager.outfocus()
    for i=1, #UI.Manager.items do
        UI.Manager.items[i].focus = false
    end
end


UI.Base = UI.Cls({x=nil, y=nil, anchor='center', frame=0, frmclr=FRMCLR,
                 mode='line',wid=0, hei=0, corner={4,4,2}})
function UI.Base.set_place(itx,ity,itwid,ithei,side)
    local x,y
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

function UI.Base:set_widhei(wid,hei)
    if wid>self.wid then self.wid = wid end
    if hei>self.hei then self.hei = hei end
    self.wid = self.wid+self.wid%2
    self.hei = self.hei+self.hei%2
end

function UI.Base:draw_frame()
    love.graphics.setColor(self.frmclr)
    if self.frame>0 and self.wid>0 then
        love.graphics.rectangle(self.mode, self.rect_posx, self.rect_posy,
                                self.wid+self.frame*2, self.hei+self.frame*2,
                                unpack(self.corner))
    end
end

function UI.Base:remove() UI.Manager.remove(self) end



UI.HBox = UI.Cls(UI.Base,{sep=8})
UI.HBox.type = 'hbox'
function UI.HBox:new(o)
    self.items = {}
    self:setup()
    UI.Manager.add(self)
end

function UI.HBox:setup()
    local wid,hei = 0,0
    for _, item in pairs(self.items) do
        wid = wid+item.wid+item.frame*2
        if hei<item.hei+item.frame*2 then hei = item.hei+item.frame*2 end
    end

    wid = wid+self.sep*(#self.items-1)
    self:set_widhei(wid, hei)
    -- problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.set_place(self.x,
                                           self.y,
                                           self.wid+self.frame*2,
                                           self.hei+self.frame*2,
                                           self.anchor)

    self.conx = self.rect_posx+self.frame
    self.cony = self.rect_posy+self.frame
    local tot_wid = 0
    for _, item in pairs(self.items) do
        -- get w anchor
       item.x = self.conx+tot_wid
       item.y = self.cony+self.hei/2
       item.anchor = 'w'
       tot_wid = tot_wid+item.wid+item.frame*2+self.sep
    end
end

function UI.HBox:add(...)
    local args = {...}
    for i=1, #args do self.items[#self.items+1] = args[i] end
    self:setup()
end

function UI.HBox:draw()
    self:draw_frame()
    love.graphics.setColor(WHITE)
end

function UI.HBox:update() self:setup() end


UI.VBox = UI.Cls(UI.HBox)
UI.VBox.type = 'vbox'
function UI.VBox:setup()
    local wid,hei = 0,0
    for _, item in pairs(self.items) do
        hei = hei+item.hei+item.frame*2
        if wid<item.wid+item.frame*2 then wid = item.wid+item.frame*2 end
    end

    hei = hei+self.sep*(#self.items-1)
    self:set_widhei(wid, hei)
    -- problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rect_posx, self.rect_posy = self.set_place(self.x,
                                           self.y,
                                           self.wid+self.frame*2,
                                           self.hei+self.frame*2,
                                           self.anchor)

    self.conx = self.rect_posx+self.frame
    self.cony = self.rect_posy+self.frame
    local tot_hei = 0
    for _, item in pairs(self.items) do
        -- get n anchor
       item.x = self.conx+self.wid/2
       item.y = self.cony+tot_hei
       item.anchor = 'n'
       tot_hei = tot_hei+item.hei+item.frame*2+self.sep
    end
end


UI.Label = UI.Cls(UI.Base,{text='', fnt=FNT, fntclr=FNTCLR,
                    variable=nil, image=nil, rotate=0, rot_dt=nil,
                    scalex=1, scaley=1, pivot='nw', scewx=0, scewy=0})
UI.Label.type = 'label'
function UI.Label:new(o)
    if self.image then self.image = love.graphics.newImage(self.image) end
    self.rotate=math.rad(self.rotate)

    self.defclr = self.fntclr
    self.onclr = {self.fntclr[1]+0.5,self.fntclr[2]+0.5,self.fntclr[3]+0.5,1}

    self.deffrm = self.frmclr
    self.onfrm = {self.frmclr[1]+0.4,self.frmclr[2]+0.4,self.frmclr[3]+0.4,1}

    if self.fnt[1] then
        self.font = love.graphics.newFont(self.fnt[1], self.fnt[2])
    else
        self.font = love.graphics.newFont(self.fnt[2])
    end
    -- for pop-up
    self.tmpfont = self.font

    self:setup()
    UI.Manager.add(self)
end

function UI.Label:setup()
    local args
    if self.image then
        args = {self.image}
        self.pivot = 'center'
    else
        args = {self.font, self.text}
    end
    local wid,hei = self.set_size(unpack(args))
    self:set_widhei(wid, hei)
    -- problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end

    self.rect_posx, self.rect_posy = self.set_place(self.x, self.y,
                                           self.wid+self.frame*2,
                                           self.hei+self.frame*2,
                                           self.anchor)

    self.pivx, self.pivy = self.get_pivot(self.wid, self.hei, self.pivot)

    self.cenx = self.rect_posx+(self.wid+self.frame*2)/2
    self.ceny = self.rect_posy+(self.hei+self.frame*2)/2
    self.posx, self.posy = self.set_place(self.cenx, self.ceny,
                                           wid, hei, 'center')
end

function UI.Label:collide(x,y)
    return ((x>self.rect_posx and x<self.rect_posx+self.wid+self.frame*2) and
        (y>self.rect_posy and y<self.rect_posy+self.hei+self.frame*2))
end

function UI.Label:mouse_click(but)
    if love.mouse.isDown(but) and self:mouse_collide() then return true end
end

function UI.Label:mouse_collide()
    local x,y = love.mouse.getPosition()
    if self:collide(x,y) then return true end
end

function UI.Label.set_size(item,other)
    local wid,hei = item:getWidth(other),item:getHeight()
    wid = wid+wid%2
    hei = hei+hei%2
    return wid,hei
end

function UI.Label.get_pivot(itwid,ithei,pivot)
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

function UI.Label:rotate_image(dt)
    if self.rot_dt then self.rotate = self.rotate+self.rot_dt*dt end
end

function UI.Label:update(dt)
    self:rotate_image(dt)
    self:setup()
    --update text
    if self.variable then self.text = self.variable.val end
    local click = self:mouse_click(1)
    return click
end

function UI.Label:draw()
    self:draw_frame()
    love.graphics.setColor(self.defclr)
    if self.image then
        love.graphics.push()
        love.graphics.draw(self.image, self.cenx, self.ceny, self.rotate,
                           self.scalex, self.scaley, self.pivx, self.pivy,
                           self.scewx, self.scewy)
        love.graphics.pop()
    else
        love.graphics.setFont(self.font)
        love.graphics.print(self.text, self.posx, self.posy,self.rotate,
                            self.scalex, self.scaley, self.pivx, self.pivy,
                            self.scewx, self.scewy)
    end
    love.graphics.setColor(WHITE)
end


UI.Input = UI.Cls(UI.Label,{frame=1,chars=8, cursize=2,curmode='line'})
function UI.Input:new(o)
    local loveinput = love.textinput or function() end
    love.textinput = function(...)
        loveinput(...)
        self.textinput(self,...)
    end
    -- init size
    self.text = string.rep('0',self.chars)
    self.variable = {val=''}
    self.keyrep = 0.5
    self.rep = self.keyrep
    self.focus = false
    self.Super.new(self)
    -- cursor setup
    self.cursorx, self.cursory = self.set_size(self.font, '')
    self.curpos = 0
    self.curblink = 1
    self.blink=self.curblink
    self.wid, self.hei = self.set_size(self.font, self.text)
end

function UI.Input:setup()
    self.rect_posx, self.rect_posy = self.set_place(self.x, self.y,
                                           self.wid+self.frame*2,
                                           self.hei+self.frame*2,
                                           self.anchor)

    self.cenx = self.rect_posx+(self.wid+self.frame*2)/2
    self.ceny = self.rect_posy+(self.hei+self.frame*2)/2
    self.posx, self.posy = self.set_place(self.cenx, self.ceny,
                                           self.wid, self.hei, 'center')
end

function UI.Input:key_press(key)
    if love.keyboard.isDown(key) and self.rep<=0 then
        self.rep = self.keyrep
        return true
    end
end

function UI.Input:erase()
    local text = self.variable.val
    local last = utf8.offset(text:sub(1, self.curpos), -1)
    if last then
        text = text:sub(1,last-1)..self.variable.val:sub(self.curpos+1, #text)
        self.variable.val = text
        self.curpos = self.curpos-1
    end

end
function UI.Input:textinput(t)
    if self.focus then
        local text = self.variable.val
        text = text:sub(1,self.curpos)..t..text:sub(self.curpos+1, #text)
        self.variable.val = text
        self.curpos = self.curpos+1
    end
end

function UI.Input:draw()
    self:draw_frame()
    love.graphics.setColor(self.onfrm)
    -- cursor
    if self.focus and self.blink>self.curblink/2 then
        love.graphics.rectangle(self.curmode,
                                self.rect_posx+self.cursorx+self.frame*2,
                                self.rect_posy+self.frame*2,
                                self.cursize, self.cursory-self.frame*2)
        love.graphics.setFont(self.font)
    end
    love.graphics.setColor(self.defclr)
    love.graphics.print(self.text, self.posx, self.posy, self.rotate,
                            self.scalex, self.scaley, self.pivx, self.pivy,
                            self.scewx, self.scewy)
    love.graphics.setColor(WHITE)
end

function UI.Input:update(dt)
    if self.rep>0 then self.rep = self.rep-dt end
    if self.blink>0 then self.blink = self.blink-dt
    else self.blink = self.curblink end

    self:setup()
    -- erase text
    if self:key_press('backspace') then self:erase() end
    -- move cursor
    if self:key_press('left') then
        if self.curpos>=1 then self.curpos = self.curpos-1 end
    end
    if self:key_press('right') then
        if self.curpos<#self.variable.val then self.curpos = self.curpos+1 end
    end
    if self:key_press('return') then self.focus=false end
    --update text
    local wid, hei
    if self.variable then
        local text = self.variable.val
        wid, hei = self.set_size(self.font,text)
        while wid+self.cursize+self.frame*2>self.wid do
            text = text:sub(2,#text)
            wid, hei = self.set_size(self.font,text)
        end

        local dtxt = #self.variable.val-self.curpos
        if dtxt>#text then
            dtxt = #text
            text = self.variable.val:sub(self.curpos,self.curpos+#text)
        end
        self.text = text
        -- place cursor
        local curtext = text:sub(1,#text-dtxt)
        self.cursorx, self.cursory = self.set_size(self.font, curtext)
    end

    local click = self:mouse_click(1)

    if click and not self.focus then
        UI.Manager.outfocus()
        self.focus = true
    end

    return click
end


UI.CheckBox = UI.Cls(UI.Label,{mode='fill',command=function() end})
UI.CheckBox.type = 'checkbox'
function UI.CheckBox:new(o)
    self.Super.new(self)
    if self.variable.bool then self.defclr=self.onclr end
end

function UI.CheckBox:update(dt)
    self:rotate_image(dt)
    self:setup()
    local click = self:mouse_click(1)

    if self.press_button then
        self.command()
        self.press_button = false
    end
    if not self.variable.bool and click then
        if self.defclr~=self.onclr then self.press_button = true end
        self.defclr = self.onclr
    elseif self.defclr==self.onclr then
        self.variable.bool = true
    end
    if self.variable.bool and click then
        if self.defclr~=self.fntclr then self.press_button = true end
        self.defclr = self.fntclr

    elseif self.defclr==self.fntclr then
        self.variable.bool = false
    end
    return click
end


UI.PopUp = UI.Cls(UI.Label,{time=60, command=function() end})
UI.PopUp.type = 'popup'
function UI.PopUp:update(dt)
    self:rotate_image(dt)
    self:setup()

    if self.time<=0 then self.command() self:remove() return end
    self.time = self.time - 1
end


UI.Button = UI.Cls(UI.Label,{command=function() end})
UI.Button.type = 'button'
function UI.Button:update(dt)
    self:rotate_image(dt)
    self:setup()

    local click = self:mouse_click(1)

    if self.press_button then
        self.command()
        self.press_button = false
    elseif click then
        if self.defclr~=self.onclr then
            self.defclr = self.onclr
            self.press_button = true
        end
    else
        self.defclr = self.fntclr
    end

    if self:mouse_collide() then self.frmclr = self.onfrm
    else self.frmclr = self.deffrm
    end
    return click
end


UI.Selector = UI.Cls(UI.Label,{command=function() end})
UI.Selector.type = 'selector'
function UI.Selector:switch()
    if self.variable and self.variable.val==self.text then
        if self.defclr~=self.onclr then self.press_button = true end
        self.defclr = self.onclr
    else
        if self.defclr~=self.fntclr then self.press_button = true end
        self.defclr = self.fntclr
    end
end

function UI.Selector:setup()
    self:switch()
    self.Super.setup(self)
end

function UI.Selector:update(dt)
    self:rotate_image(dt)
    self:setup()
    local click = self:mouse_click(1)

    if self.press_button and click then
        self.command()
        self.press_button = false
    end
    if click then
        if self.variable then self.variable.val = self.text end
    end
    self:switch()
    return click
end


UI.Counter = UI.Cls(UI.HBox,{text='', fnt=FNT, fntclr=FNTCLR,
                        variable={val=0}, modifier=1, min=0, max=1000})
UI.Counter.type = 'counter'
function UI.Counter:new(o)
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1

    self.txt = nil
    if self.text:len()>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.right = UI.Button{text='>', fnt=self.fnt, fntclr=self.fntclr,
                command=function() self:add() end,
                frame=1, frmclr=self.frmclr}
    self.left = UI.Button{text='<', fnt=self.fnt, fntclr=self.fntclr,
                command=function() self:sub() end,
                frame=1, frmclr=self.frmclr}
    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr, variable=self.variable,
                    frame=1, frmclr=self.frmclr,
                    mode=self.mode,corner={0,0,0}}
    self.display.text = self.min

    self.items = {self.txt, self.left, self.display, self.right}
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


UI.Slider=UI.Cls(UI.HBox,{text='', fnt=FNT, fntclr=FNTCLR, variable={val=0},
                            image=nil, min=0, max=100, barmode='fill'})
UI.Slider.type = 'slider'
function UI.Slider:new(o)
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1
    self.onfrm = {self.frmclr[1]+0.4,self.frmclr[2]+0.4,self.frmclr[3]+0.4,1}

    self.txt=nil
    if self.text:len()>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{frame=1, frmclr=self.frmclr, mode=self.mode,
                        corner={0,0,0}}
    self.bar = UI.Label{fnt=self.fnt, fntclr=self.onfrm, image=self.image,
                        frame=1, frmclr=self.onfrm, mode=self.barmode,
                        corner={0,0,0}}
    -- setup cursor wid and max len
    self.bar.wid = self.bar.hei+self.bar.frame*2
    self.border.wid = self.max+self.bar.wid+self.border.frame*2
    self.border:add(self.bar)

    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr,
                    variable=self.variable,
                    frame=1, frmclr=self.frmclr,
                    mode=self.mode, corner={0,0,0}}

    self.items = {self.txt, self.border, self.display}
    self:setup()
    UI.Manager.add(self)
end

function UI.Slider:update()
    if self.bar:mouse_click(1) then self:set_value() end
    -- redefine HBox update to move slider
    self.border.update = function() end
end
function UI.Slider:set_value()
    local oldx = math.floor(self.bar.x)
    local x,y = love.mouse.getPosition()
    local newx = x-self.bar.wid/2

    if self.variable.val+newx-oldx>self.max then return end
    if self.variable.val+newx-oldx<self.min then return end
    self.bar.x = newx
    self.variable.val = self.variable.val+self.bar.x-oldx
end

UI.ProgBar=UI.Cls(UI.HBox,{text='', fnt=FNT, fntclr=FNTCLR, variable={val=0},
                    image=nil, barchar='*', barmode='fill', min=0, max=10})
UI.ProgBar.type = 'progbar'
function UI.ProgBar:new(o)
    local barfrm=0
    if self.barmode=='fill' then barfrm=1 self.barchar = ' ' end
    self.charbar = {val=string.rep(self.barchar, self.max)}
    self.onfrm = {self.frmclr[1]+0.4,self.frmclr[2]+0.4,self.frmclr[3]+0.4,1}

    self.txt = nil
    if self.text:len()>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{frame=1, frmclr=self.frmclr,
                            mode=self.mode, corner={0,0,0}}
    self.bar = UI.Label{text=self.charbar.val, fnt=self.fnt,
                        fntclr=self.onfrm, variable=self.charbar,
                        image=self.image, frame=barfrm,
                        frmclr=self.onfrm, mode=self.barmode, corner={0,0,0}}
    self.border:add(self.bar)

    self.items = {self.txt, self.border}
    self:setup()
    UI.Manager.add(self)
end

function UI.ProgBar:set_value()
    if self.variable.val<self.min then self.variable.val=self.min end
    if self.variable.val>self.max then self.variable.val=self.max end
    self.charbar.val = string.rep(self.barchar,self.variable.val)
end

function UI.ProgBar:set_size()
    local args
    if self.bar.image then
        args = {self.bar.image}
    else
        args = {self.bar.font, self.charbar.val}
    end
    self.bar.wid,self.bar.hei = self.bar.set_size(unpack(args))
end

function UI.ProgBar:update()
    self:set_value()
    self:set_size()
    self:setup()
end

return UI
