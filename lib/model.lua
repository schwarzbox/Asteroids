-- Sun May 13 23:35:21 2018
-- (c) Aliaksandr Veledzimovich
-- model ASTEROIDS

local Tmr = require('lib/tmr')
local imd = require('lib/lovimd')
local fl = require('lib/lovfl')
local cmp = require('lib/lovcmp')
local obj = require('lib/obj')
local set = require('lib/set')

local Model = {}
Model.tag = 'model'
-- static cmp
Model.getHypot = cmp.getHypot
Model.getRandOffsetXY = cmp.getRandOffsetXY
-- particle
Model.objectParticle = cmp.objectParticle
function Model:new()
    self.ships = {wasp=obj.Wasp,wing=obj.Wing}
    -- load data
    local olddata = fl.loadLove(set.SAVE) or {1,0}
    self.lastscore = 0
    self.maxlevel = olddata[1]
    self.maxscore = olddata[2]
    -- radar
    self.radar = {x1=627,y1=set.HEI-164,x2=676,y2=set.HEI-131}
    self.radius = self.getHypot(self.radar.x1,self.radar.y1,
                                self.radar.x2,self.radar.y2)
    self.old_radarx,self.old_radary=self.radar.x2,self.radar.y2
    self.radar_min = 1
    self.radar_max = 360
    self.border = imd.circlePixels(self.radius)
    self.all_dots = imd.circleAllPixels(self.radius-20)

    self.tmr = Tmr:new()
    -- sound bool
    self.audio = {bool=true}
    self.sfx = {bool=true}

    self:reset()
end

function Model:reset()
    self.particles = {}
    self.objects = {}

    self.avatar = nil
    self.level = {val=self.maxlevel}
    self.score = 0
    self.pause = false
    self.next = true
    -- radar dots update
    self.aster_coords = {}
    for i=1, self.maxlevel do
        local coords = self.all_dots[love.math.random(#self.all_dots)]
        self.aster_coords[i] = {self.radar.x1+coords[1],
                                self.radar.y1+coords[2]}
    end
    -- fade var
    self.volume = 0
    self.fade = 64/255
    self.fin = false
    -- menu&game particles
    self.dust=self:objectParticle(7, {set.WHITEFF,set.ORANGE,set.DARKGRAYF},
                                     'circle', {5,10}, {0.1,0.6},25)

    self.grdust=self:objectParticle(11, {set.WHITEFF,set.LIGHTGRAY,set.GRAYF},
                                     'circle', {5,15}, {0.1,0.4},15)
    -- menu music
    set.AUD['intro']:setLooping(true)
    set.AUD['intro']:play()
    Ctrl:bind('space','start',function() self:startgame() end)
    View:set_start_scr()
end

function Model:spawn(item) self.objects[item] = item end
function Model:destroy(item) self.objects[item] = nil end
function Model:get_objects() return self.objects end
function Model:get_particles() return self.particles end
function Model:get_fade() return self.fade end

function Model:set_pause(pause)
    if View:get_scr()=='game_scr' then
        self.pause = pause or not self.pause
        View:set_label('PAUSE',self.pause)
    end
end

function Model:startgame()
    if not self.avatar then
        -- update bind for space
        Ctrl:unbind('space')
        Ctrl:bind('space','fire')

        set.AUD['intro']:stop()

        self.avatar = self.ships[View:get_avatar()]{x=set.MIDWID,
                                                       y=set.MIDHEI}

        self.fog = self:objectParticle({1},
                                       {set.WHITEFF,set.WHITEF,set.WHITEFF},
                            set.IMG['cloud'], {6,15}, {0.1,15},1,{0.1,0.3})
        self.fog.particle:setRotation(0.1, 0.3)
        self.fog.particle:setEmitterLifetime(-1)
        self.fog.particle:emit(1)

        set.AUD['loop']:setVolume(self.volume)
        set.AUD['loop']:setLooping(true)
        set.AUD['loop']:play()
        -- fade
        self.tmr:after(0.5, function () View:set_game_scr() end)

        set.AUD['fly']:play()
    end
end

function Model:update(dt)
    if View:get_scr()=='ui_scr' then
        -- on/off audio
        if self.audio.bool==false then
            set.AUD['loop']:setVolume(0)
            set.AUD['intro']:setVolume(0)
        else
            set.AUD['loop']:setVolume(self.volume)
            set.AUD['intro']:setVolume(1)
        end
        -- on/off sfx
        if self.sfx.bool==false then
            for k,_ in pairs(set.AUD) do
                if k~='loop' and k~='intro' then set.AUD[k]:setVolume(0) end
            end
        else
            for k,_ in pairs(set.AUD) do
                if k~='loop' and k~='intro' then set.AUD[k]:setVolume(1) end
            end
            set.AUD['rocketdestroy']:setVolume(set.BOOMV)
            set.AUD['bullet']:setVolume(set.BULV)
            set.AUD['shipboom']:setVolume(set.BOOMV)
            set.AUD['engine']:setVolume(set.ENGV)
            set.AUD['hitship']:setVolume(set.HITV)
            set.AUD['hitaster']:setVolume(set.HITV)
        end
        self.old_radarx, self.old_radary = self.radar.x2, self.radar.y2
        self.radar.x2 = self.radar.x1+self.border[self.radar_min][1]
        self.radar.y2 = self.radar.y1+self.border[self.radar_min][2]
        self.radar_min = ((self.radar_min+1)%self.radar_max)+1
    end


    local randx,randy = self.getRandOffsetXY(nil,nil,set.WID,set.HEI,'rand')

    self.dust.particle:emit(1)
    self.dust.particle:setPosition(randx,randy)

    self.grdust.particle:emit(1)
    self.grdust.particle:setPosition(randx,randy)

    -- game
    if View:get_scr()=='game_scr' then
        -- if self.pause then return end

        -- clouds
        self.fog.particle:setEmissionRate(love.math.random(1,2))
        self.fog.particle:setPosition(randx,randy)

        local num_aster = 0

        -- collision
        for object in pairs(self.objects) do
            object.lastcoll = {}
            for collider in pairs(self.objects) do
                object:collision(collider,dt)
            end
            if #object.lastcoll == 0 then
                object.collide=nil
            end
        end

         -- update objects
        for object in pairs(self.objects) do
            if object.update then object:update(dt) end
            if object.tag=='aster' then num_aster = num_aster+1 end
        end

        -- new level
        if num_aster==0 then
            self.level.val = self.level.val+1

            self.particles={[self.fog.particle]=self.fog.particle,
                            [self.dust.particle]=self.dust.particle,
                            [self.grdust.particle]=self.grdust.particle}

            self.fade = 0.5
            self.volume = 0
            if self.audio.bool then
                self.tmr:tween(2.5, self, {volume=set.LOOPV})
                self.tmr:during(2.5,function()
                            set.AUD['loop']:setVolume(self.volume) end)
            end
            self.tmr:tween(2.5, self, {fade=1},'linear')
            set.AUD['level']:play()

            for _=1,self.level.val-1 do
                obj.Asteroid()
            end
        end
        -- fade
        if not self.avatar and not self.fin then
            self.fin = self.tmr:after(2.5, function()
                        self.tmr:tween(1.5, self, {fade=0,volume=0}, 'linear',
                                function () self:endgame() end) end)
        end
    end

       -- particle menu & game
    for particle in pairs(self.particles) do
        particle:update(dt)
        if particle:getCount()==0 then
            particle:reset()
            self.particles[particle] = nil
        end
    end

    -- ui update
    View:get_ui().Manager.update(dt)
end

function Model:endgame()
    set.AUD['loop']:stop()

    self.level.val = self.level.val-1
    local data = {self.level.val,self.score}
    local olddata = fl.loadLove(set.SAVE)
    if olddata then
        if olddata[1]>data[1] then data[1] = olddata[1] end
        if olddata[2]>data[2] then data[2] = olddata[2] end
    end
    fl.saveLoveFile(set.SAVE,string.format('return {%i,%i}',data[1],data[2]))
    self.maxlevel, self.maxscore = data[1],data[2]
    self.lastscore = self.score
    self:reset()
end

return Model
