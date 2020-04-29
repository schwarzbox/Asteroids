-- Sun May 13 23:35:21 2018
-- (c) Alexander Veledzimovich
-- view ASTEROIDS

local Tmr = require('lib/tmr')
local ui = require('lib/lovui')
local set = require('lib/set')

local View = {}

function View:new()
    ui.load()
    self.ui = ui
    self.scr = nil
    self.avatar = {val='wasp'}
    self.bg = love.graphics.newImage(set.IMG['bg'])
    self.bg_ui = love.graphics.newImage(set.IMG['uibg'])
    self.menu_ui = love.graphics.newImage(set.IMG['uifg'])
    self.radar = love.graphics.newImage(set.IMG['radar'])
    self.blink = true
    self.blink_time = 0.5
    self.tmr = Tmr:new()
    self.tmr:every(self.blink_time, function() self.blink=not self.blink end)
end

function View:get_scr() return self.scr end
function View:get_ui() return self.ui end
function View:get_avatar() return self.avatar.val end

function View:set_start_scr()
    self.scr='ui_scr'
    ui.Manager.clear()
    -- menu
    ui.Selector{x=310, y=set.HEI-93, text='wasp', var=self.avatar,
                    image=set.IMG['waspb'],
                    com=function() set.AUD['click']:play() end}
    ui.Selector{x=490, y=set.HEI-93, text='wing', var=self.avatar,
                    image=set.IMG['wingb'],
                    com=function() set.AUD['click']:play() end}

    ui.Button{x=400, y=set.HEI-93, image=set.IMG['start'],frm=0,
             com=function() set.AUD['click']:play()
                                Model:startgame() end}
    -- select level
    ui.Label{x=604, y=set.HEI-90, fnt=set.GAMEFNT,fntclr=set.DISPGREEN,
                var=Model.level, scewy=0.2}
    ui.Button{x=584, y=set.HEI-92, image=set.IMG['levleft'],frm=0,
        com=function() set.AUD['click']:play()
                if Model.level.val>1 then
                    Model.level.val=Model.level.val-1 end
                end}
    ui.Button{x=624, y=set.HEI-84,image=set.IMG['levright'],frm=0,
        com=function() set.AUD['click']:play()
                if Model.level.val<Model.maxlevel then
                    Model.level.val=Model.level.val+1 end
                end}
    -- score
    ui.Label{x=175, y=set.HEI-234, text=Model.lastscore,
                fnt=set.MENUFNT, fntclr=set.DISPGREEN, scewy=0.05}
    ui.Label{x=175, y=set.HEI-164, text=Model.maxscore,
                fnt=set.MENUFNT, fntclr=set.DISPGREEN, scewy=-0.05}
    -- aud
    ui.CheckBox{x=79,y=set.HEI-82,frm=0,
                image=set.IMG['sfx'], var=Model.sfx,
                com=function() set.AUD['click']:play() end}
    ui.CheckBox{x=146,y=set.HEI-91,frm=0,
                image=set.IMG['music'], var=Model.audio,
                com=function() set.AUD['click']:play() end}
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
        local fade = Model:get_fade()
        love.graphics.setColor({fade,fade,fade,fade})

        love.graphics.draw(self.bg)

        for item in pairs(Model:get_objects()) do
            if item.draw then item:draw() end
        end
    end
    -- particle menu & game
    for particle in pairs(Model:get_particles()) do
        love.graphics.draw(particle)
    end

    if self.scr=='ui_scr' then
        love.graphics.draw(self.menu_ui)
        -- show aster
        love.graphics.setColor(set.DISPYELLOW)

        if self.blink then
            for i=1,Model.level.val do
                love.graphics.circle('fill',Model.aster_coords[i][1],
                                        Model.aster_coords[i][2], 2)
            end
            -- asteroids blink
            love.graphics.setColor(set.DISPBLACK)
            love.graphics.rectangle('fill',180,set.HEI-524,440,55)
        end
        -- show radar line
        love.graphics.setColor(set.DISPGREEN)
        love.graphics.line(Model.radar.x1, Model.radar.y1,
                           Model.radar.x2, Model.radar.y2)
        love.graphics.setLineWidth(7)
        love.graphics.setColor({set.DISPGREEN[1], set.DISPGREEN[2],
                               set.DISPGREEN[3], 0.2})
        love.graphics.line(Model.radar.x1, Model.radar.y1,
                           Model.old_radarx, Model.old_radary)
        love.graphics.setLineWidth(1)
        -- center dot
        love.graphics.circle('fill',Model.radar.x1,Model.radar.y1,4)
        love.graphics.setColor(set.WHITE)
        -- radar cover
        love.graphics.draw(self.radar, 533, set.HEI-228)
    end

    ui.Manager.draw()
end

return View
