-- Sun May 13 23:35:21 2018
-- (c) Alexander Veledzimovich
-- view ASTEROIDS

local Timer = require('lib/tmr')
local ui = require('lib/lovui')
local set = require('lib/set')

local View = {}

function View:new(model)
    self.model = model
    self.ui = ui
    self.scr = nil
    self.sel_ship = {val='wasp'}
    self.bg = love.graphics.newImage(set.OBJ['bg'])
    self.bg_ui = love.graphics.newImage(set.OBJ['bg_ui'])
    self.menu_ui = love.graphics.newImage(set.OBJ['menu_ui'])
    self.radar = love.graphics.newImage(set.OBJ['radar'])
    self.blink = true
    self.blink_time = 0.5
    self.tmr = Timer:new()
    self.tmr:every(self.blink_time, function() self.blink=not self.blink end)
    return self
end

function View:set_start_scr()
    self.scr='ui_scr'
    ui.Manager.clear()
    -- menu
    ui.Selector{x=310, y=set.HEI-93, text='wasp', variable=self.sel_ship,
                    image=set.OBJ['waspb'],
                    command=function() set.AUD['click']:play() end}
    ui.Selector{x=490, y=set.HEI-93, text='wing', variable=self.sel_ship,
                    image=set.OBJ['wingb'],
                    command=function() set.AUD['click']:play() end}

    ui.Button{x=400, y=set.HEI-93, image=set.OBJ['start'],
             command=function() set.AUD['click']:play()
                                self.model:startgame() end}
    -- select level
    ui.Label{x=604, y=set.HEI-90, fnt=set.GAMEFNT,fntclr=set.DISPGREEN,
                variable=self.model.level, scewy=0.2}
    ui.Button{x=584, y=set.HEI-92, image=set.OBJ['levleft'],
        command=function() set.AUD['click']:play()
                if self.model.level.val>1 then
                    self.model.level.val=self.model.level.val-1 end
                end}
    ui.Button{x=624, y=set.HEI-84,image=set.OBJ['levright'],
        command=function() set.AUD['click']:play()
                if self.model.level.val<self.model.maxlevel then
                    self.model.level.val=self.model.level.val+1 end
                end}
    -- score
    ui.Label{x=175, y=set.HEI-234, text=self.model.lastscore,
                fnt=set.MENUFNT, fntclr=set.DISPGREEN, scewy=0.05}
    ui.Label{x=175, y=set.HEI-164, text=self.model.maxscore,
                fnt=set.MENUFNT, fntclr=set.DISPGREEN, scewy=-0.05}
    -- aud
    ui.CheckBox{x=79,y=set.HEI-82, mode='line',
                image=set.OBJ['sfx'], variable=self.model.sfx,
                command=function() set.AUD['click']:play() end}
    ui.CheckBox{x=146,y=set.HEI-91, mode='line',
                image=set.OBJ['music'], variable=self.model.audio,
                command=function() set.AUD['click']:play() end}
end

function View:set_game_scr()
    self.scr='game_scr'
    ui.Manager.clear()
end

function View:set_label(text,bool)
    local x = set.MIDWID
    local y = set.MIDHEI
    if self.label then self.label:remove() end
    if bool then
        self.label=ui.Label{x=x,y=y,text=text, fnt=set.MENUFNT,
                                    fntclr=set.DARKRED, anchor='s'}
    end
end

function View:draw()
    if self.scr=='ui_scr' then
        love.graphics.draw(self.bg_ui)
    end

    if self.scr=='game_scr' then
        love.graphics.setColor({self.model.fade,self.model.fade,
                               self.model.fade,self.model.fade})
        love.graphics.draw(self.bg)

        for item in pairs(self.model.objects) do
            if item.draw then item:draw() end
        end
    end
    -- particle menu & game
    for particle in pairs(self.model.particle) do
        love.graphics.draw(particle)
    end

    if self.scr=='ui_scr' then
        love.graphics.draw(self.menu_ui)
        -- show aster
        love.graphics.setColor(set.DISPYELLOW)

        if self.blink then
            for i=1,self.model.level.val do
                love.graphics.circle('fill',self.model.aster_coords[i][1],
                                        self.model.aster_coords[i][2], 2)
            end
            -- asteroids blink
            love.graphics.setColor(set.DISPBLACK)
            love.graphics.rectangle('fill',180,set.HEI-524,440,55)
        end
        -- show radar line
        love.graphics.setColor(set.DISPGREEN)
        love.graphics.line(self.model.radar.x1, self.model.radar.y1,
                           self.model.radar.x2, self.model.radar.y2)
        love.graphics.setLineWidth(7)
        love.graphics.setColor({set.DISPGREEN[1], set.DISPGREEN[2],
                               set.DISPGREEN[3], 0.2})
        love.graphics.line(self.model.radar.x1, self.model.radar.y1,
                           self.model.old_radarx, self.model.old_radary)
        love.graphics.setLineWidth(1)
        -- center dot
        love.graphics.circle('fill',self.model.radar.x1,self.model.radar.y1,4)
        love.graphics.setColor({self.model.fade, self.model.fade,
                               self.model.fade, self.model.fade})
        -- radar cover
        love.graphics.draw(self.radar, 533, set.HEI-228)
    end

    for _, item in pairs(ui.Manager.items) do item:draw() end
end

return View
