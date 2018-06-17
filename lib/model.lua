-- Sun May 13 23:35:21 2018
-- (c) Alexander Veledzimovich
-- model ASTEROIDS

local Timer = require('lib/tmr')
local imd = require('lib/lovimd')
local fl = require('lib/lovfl')
local cmp = require('lib/lovcmp')
local obj = require('lib/obj')
local set = require('lib/set')

local Model = {}
Model.tag = 'model'
-- static cmp
Model.get_dist = cmp.get_dist
Model.get_randpos = cmp.get_randpos
-- particle
Model.local_particle=cmp.local_particle
function Model:new(view)
    self.view = view
    self.ships = {wasp=obj.Wasp,wing=obj.Wing}
    -- load data
    local olddata = fl.load_love(set.SAVE) or {1,0}
    self.lastscore = 0
    self.maxlevel = olddata[1]
    self.maxscore = olddata[2]
    -- radar
    self.radar = {x1=627,y1=set.HEI-164,x2=676,y2=set.HEI-131}
    self.radius = self.get_dist(self.radar.x1,self.radar.y1,
                                self.radar.x2,self.radar.y2)
    self.old_radarx,self.old_radary=self.radar.x2,self.radar.y2
    self.radar_min = 1
    self.radar_max = 360
    self.border = imd.circle_px(self.radius)
    self.all_dots = imd.circle_all_px(self.radius-20)

    self.tmr = Timer:new()
    -- sound bool
    self.audio = {bool=true}
    self.sfx = {bool=true}

    self:reset()
end

function Model:reset()
    self.particle ={}
    self.objects = {}
    self.avatar = nil
    self.level = {val=self.maxlevel}
    self.score = 0
    self.pause = false

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
    self.dust=self:local_particle(7, {set.WHITEFF,set.ORANGE,set.DARKGRAYF},
                                     'circle', {5,30}, {0.1,0.6},
                                     {-15,-15,15,15})

    self.grdust=self:local_particle(11, {set.WHITEFF,set.LIGHTGRAY,set.GRAYF},
                                     'circle', {5,40}, {0.1,0.4},
                                     {-10,-10,10,10})
    -- menu music
    set.AUD['intro']:setLooping(true)
    set.AUD['intro']:play()

    self.view:set_start_scr()
end

function Model:spawn(item) self.objects[item] = item end
function Model:destroy(item) self.objects[item] = nil end
function Model:getobj() return self.objects end

function Model:startgame()
    set.AUD['intro']:stop()
    self.avatar = self.ships[self.view.sel_ship.val]{model=self,
                                                   x=set.MIDWID,
                                                   y=set.MIDHEI}

    self.fog = self:local_particle({1}, {set.WHITEFF,set.WHITEF,set.WHITEFF},
                                     set.OBJ['cloud'], {6,15}, {0.1,15},
                                     {-1,-1, 1, 1})
    self.fog:setRotation(0.3, 1.5)
    self.fog:setEmitterLifetime(-1)
    self.fog:emit(1)

    set.AUD['loop']:setVolume(self.volume)
    set.AUD['loop']:setLooping(true)
    set.AUD['loop']:play()
    -- fade
    self.tmr:after(0.3, function () self.view:set_game_scr() end)
    self.tmr.sleep(0.3)
    set.AUD['fly']:play()

end

function Model:update(dt)
    if self.view.scr=='ui_scr' then
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
            set.AUD['rocket_destroy']:setVolume(set.BOOMV)
            set.AUD['bullet']:setVolume(set.BULV)
            set.AUD['shipboom']:setVolume(set.BOOMV)
            set.AUD['engine']:setVolume(set.ENGV)
            set.AUD['hit_ship']:setVolume(set.HITV)
            set.AUD['hit_aster']:setVolume(set.HITV)
        end
        self.old_radarx, self.old_radary = self.radar.x2, self.radar.y2
        self.radar.x2 = self.radar.x1+self.border[self.radar_min][1]
        self.radar.y2 = self.radar.y1+self.border[self.radar_min][2]
        self.radar_min = ((self.radar_min+1)%self.radar_max)+1
    end
    -- particle menu & game
    for particle in pairs(self.particle) do
        particle:update(dt)
        if particle:getCount()==0 then particle:reset() end
    end

    local randx,randy = self.get_randpos(nil,nil,set.WID,set.HEI,'rand')

    self.dust:emit(1)
    self.dust:setPosition(randx,randy)

    self.grdust:emit(1)
    self.grdust:setPosition(randx,randy)

    -- game
    if self.view.scr=='game_scr' then
        if self.pause then return end
        set.AUD['loop']:setVolume(self.volume)
        -- clouds
        self.fog:setEmissionRate(love.math.random(1,3))
        self.fog:setPosition(randx,randy)

        local num_aster = 0
        for object in pairs(self.objects) do
            if object.update then object:update(dt) end
            if object.tag=='aster' then num_aster = num_aster+1 end
        end
        -- new level
        if num_aster==0 then self.level.val = self.level.val+1
            self.fade=0.5
            self.volume=0
            self.tmr:tween(2, self, {fade=1,volume=set.LOOPV})
            set.AUD['level']:play()
            for _=1,self.level.val-1 do
                obj.Asteroid{model=self}
            end
        end
        -- fade
        if not self.avatar and not self.fin then
            self.fin = self.tmr:after(3, function()
                        self.tmr:tween(2, self, {fade=0,volume=0}, 'linear',
                                function () self:endgame() end) end)
        end
    end
    -- ui update
    for _, item in pairs(self.view.ui.Manager.items) do item:update(dt) end
end

function Model:endgame()
    set.AUD['loop']:stop()

    self.level.val = self.level.val-1
    local data = {self.level.val,self.score}
    local olddata = fl.load_love(set.SAVE)
    if olddata then
        if olddata[1]>data[1] then data[1] = olddata[1] end
        if olddata[2]>data[2] then data[2] = olddata[2] end
    end
    fl.save_love(set.SAVE,string.format('return {%i,%i}',data[1],data[2]))
    self.maxlevel, self.maxscore = data[1],data[2]
    self.lastscore = self.score
    self:reset()
end

return Model