-- Sun May 13 23:35:21 2018
-- (c) Alexander Veledzimovich
-- obj ASTEROIDS

local imd = require('lib/lovimd')
local cmp = require('lib/lovcmp')
local cls = require('lib/cls')
local set = require('lib/set')

local O={}
O.Base = cls.Cls({x=nil,y=nil, dx=0, dy=0, angle=0, da=0,
                 scale=set.SCALE, body='dynamic',collider='circle',
                 particle={}})
-- cmp
O.Base.set_obj = cmp.set_obj
O.Base.rect_upd = cmp.rect_upd
O.Base.borders = cmp.endless_scr
O.Base.dxdy_upd = cmp.dxdy_upd
O.Base.move = cmp.move
O.Base.rotate = cmp.rotate
O.Base.angle_upd = cmp.angle_upd
O.Base.friction = cmp.friction
O.Base.angle_friction = cmp.angle_friction
O.Base.collision = cmp.collision
O.Base.hit = cmp.hit
-- particle
O.Base.destroy_particle = cmp.destroy_particle
O.Base.boom = cmp.global_particle
O.Base.local_particle = cmp.local_particle
function O.Base:__tostring() return self.tag end

function O.Base:draw()
    love.graphics.draw(self.image,self.quad, self.x, self.y, self.angle,
                       self.scale, self.scale, self.cenx, self.ceny)
    for particle in pairs(self.particle) do love.graphics.draw(particle) end
end

function O.Base:update(dt)
    self:angle_upd(dt)
    self:dxdy_upd(dt)
    self:rect_upd()
    self:borders(set.WID,set.HEI)

    for i=1, #self.last_collision do
        local obj = self.last_collision[i]

        if obj.tag=='aster' and self.tag~='aster' then
            if obj:hit(self.damage,self) then obj:destroy() end
            if self:hit(obj.damage,obj) then self:destroy() return end
        end
    end
end

function O.Base:stop_rotate(dt)
    if self.auto_stop then
        if self.da>self.torque then
            self:rotate(-0.5)
        elseif self.da<-self.torque then
            self:rotate(0.5)
        else
            self:angle_friction(dt)
        end
    end
end

function O.Base:destroy()
    self.model.avatar = nil
    -- fire
    self:boom(self.x, self.y, 25, {1},
              {set.WHITEFF, set.WHITE, set.GRAYF}, set.OBJ['fire'],
                                                        {0.7,1.2},{1,0.1})
    -- smoke
    self:boom(self.x ,self.y, 40, {self.wid/10,self.wid/8,self.wid/6},
                       {set.DARKGRAY,set.GRAY,set.DARKGRAYF})
    -- fire
    self:boom(self.x, self.y, 80, {self.wid/16,self.wid/24},
              nil, nil, nil, nil,8000)
    self:destroy_particle()
    set.AUD['shipboom']:play()

    for particle in pairs(self.particle) do particle:reset() end

    self.model:destroy(self)
end

O.Wasp = cls.Cls(O.Base,{tag='wasp'})
-- const
O.Wasp.img_data = set.OBJ[O.Wasp.tag]
O.Wasp.speed = 3
O.Wasp.maxspeed = 160
O.Wasp.torque = math.rad(2)
O.Wasp.maxtorque = math.rad(100)
O.Wasp.hp = 4
-- cmp
O.Wasp.shot = cmp.shot
function O.Wasp:new(o)
    self.model=Model
    self:set_obj(self.img_data)
    self.destroy_data = imd.splash_imd(self.img_data, 50, 30)

    self.weapon = O.Bullet
    self.weapon_side = 'right'
    self.weapon_offset = {0,7}

    -- init engine particle
    self.engine1 = self:local_particle(5, {set.ORANGE,set.LIGHTGRAY,
                                    set.DARKGRAYF}, nil, nil, {1,0.1})
    self.engine2 = self:local_particle(5, {set.ORANGE, set.LIGHTGRAY,
                                   set.DARKGRAYF}, nil, nil, {1,0.1})
    self.engine3 = self:local_particle(5)
    self.engine4 = self:local_particle(5)

    self.wounded1 = self:local_particle(10, {set.ORANGE,set.DARKGRAYF,
                                   set.DARKGRAYF})
    self.wounded2 = self:local_particle(8, {set.YELLOW,set.ORANGE,
                                   set.DARKGRAYF})
    self.wounded3 = self:local_particle(8, {set.DARKGRAY,set.GRAY,
                                   set.DARKGRAYF})
    self.wound1 = {love.math.random(-18,-12), love.math.random(-45,45)}
    self.wound2 = {love.math.random(-30,9), love.math.random(-7,7)}
    self.wound3 = {love.math.random(-18,-12), love.math.random(-45,45)}

    self.model:spawn(self)
end

function O.Wasp:move(dist)
    self.Super.move(self,dist)
    self.engine1.particle:emit(1)
    self.engine2.particle:emit(1)
    if not dist then set.AUD['engine']:play() end
end

function O.Wasp:rotate(side)
    self.Super.rotate(self,side)
    self.Super.move(self,self.speed/10)
    if side>0 then self.engine3.particle:emit(1)
    else self.engine4.particle:emit(1) end
    set.AUD['side_engine']:play()
end

function O.Wasp:hit(damage)
    set.AUD['hit_ship']:play()
    return self.Super.hit(self,damage)
end

function O.Wasp:update(dt)
    self.Super.update(self,dt)
    self.engine1.upd(dt,'left' ,{-3,6}, -self.maxspeed/2)
    self.engine2.upd(dt, 'left', {-3,-6}, -self.maxspeed/2)
    self.engine3.upd(dt,'center', {-25,-25}, -self.maxspeed/3)
    self.engine4.upd(dt,'center', {-25,25}, -self.maxspeed/3)

    if self.hp<4 then
        self.wounded1.upd(dt,'center',self.wound1,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded1.particle:emit(1)
    end
    if self.hp<3 then
        self.wounded2.upd(dt,'center', self.wound2,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded2.particle:emit(1)
    end
    if self.hp<2 then
        self.wounded3.upd(dt,'center', self.wound3,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded3.particle:emit(1)
    end
    self:stop_rotate(dt)
end


O.Wing = cls.Cls(O.Base,{tag = 'wing'})
-- const
O.Wing.img_data = set.OBJ[O.Wing.tag]
O.Wing.speed = 2.5
O.Wing.maxspeed = 100
O.Wing.torque = math.rad(1.3)
O.Wing.maxtorque = math.rad(100)
O.Wing.hp = 5
-- cmp
O.Wing.shot=cmp.shot
function O.Wing:new(o)
    self.model=Model
    self:set_obj(self.img_data)
    self.destroy_data = imd.splash_imd(self.img_data,50,30)

    self.weapon = O.Rocket
    self.weapon_side = 'right'
    self.weapon_offset = {15,0}

    self.engine1 = self:local_particle(7, {set.ORANGE,set.LIGHTGRAY,
                                   set.DARKGRAYF}, nil, nil, {1,0.1})
    self.engine2 = self:local_particle(7, {set.ORANGE,set.LIGHTGRAY,
                                   set.DARKGRAYF}, nil, nil, {1,0.1})
    self.engine3 = self:local_particle(5)
    self.engine4 = self:local_particle(5)

    self.wounded1 = self:local_particle(10, {set.ORANGE,set.DARKGRAYF,
                                   set.DARKGRAYF})
    self.wounded2 = self:local_particle(8, {set.YELLOW,set.ORANGE,
                                   set.DARKGRAYF})
    self.wounded3 = self:local_particle(8, {set.DARKGRAY,set.GRAY,
                                   set.DARKGRAYF})

    self.wound1 = {love.math.random(0,10), love.math.random(-30,30)}
    self.wound2 = {love.math.random(-5,10), love.math.random(-20,20)}
    self.wound3 = {love.math.random(-37,37), love.math.random(-6,6)}
    self.wound4 = {love.math.random(-37,37), love.math.random(-7,7)}

    self.model:spawn(self)
end

function O.Wing:move(dist)
    self.Super.move(self, dist)
    self.engine1.particle:emit(1)
    self.engine2.particle:emit(1)
    if not dist then set.AUD['engine']:play() end
end

function O.Wing:rotate(side)
    self.Super.rotate(self, side)
    self.Super.move(self, self.speed/10)
    if side>0 then self.engine3.particle:emit(1)
    else self.engine4.particle:emit(1) end
    set.AUD['side_engine']:play()
end

function O.Wing:hit(damage)
    set.AUD['hit_ship']:play()
    return self.Super.hit(self, damage)
end

function O.Wing:update(dt)
    self.Super.update(self,dt)
    self.engine1.upd(dt, 'left', {-4,3}, -self.maxspeed/2)
    self.engine2.upd(dt, 'left', {-4,-3}, -self.maxspeed/2)
    self.engine3.upd(dt, 'left', {8,13}, -self.maxspeed/3)
    self.engine4.upd(dt, 'left', {8,-13}, -self.maxspeed/3)

    if self.hp<5 then
        self.wounded1.upd(dt,'center', self.wound1,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded1.particle:emit(1)
    end
    if self.hp<4 then
        self.wounded1.upd(dt,'center', self.wound2,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded1.particle:emit(1)
    end
    if self.hp<3 then
        self.wounded2.upd(dt,'center', self.wound3,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded2.particle:emit(1)
    end
    if self.hp<2 then
        self.wounded3.upd(dt,'center', self.wound4,
                          -math.abs(self.dx+self.dy)/2)
        self.wounded3.particle:emit(1)
    end

    self:stop_rotate(dt)
end


O.Bullet = cls.Cls(O.Base,{tag='bullet',collider={'left'}})
-- const
O.Bullet.img_data = set.OBJ[O.Bullet.tag]
O.Bullet.speed = 600
O.Bullet.maxspeed = 1200
O.Bullet.cooldown = 0.2
O.Bullet.lifetime = 1
O.Bullet.damage = 1
O.Bullet.kick = -5
O.Bullet.mistake = 45
--cmp
O.Bullet.borders = cmp.out_scr
function O.Bullet:new(o)
    self.model=Model
    self:set_obj(self.img_data)

    self.dx = self.dx+love.math.random(-self.mistake, self.mistake)
    self.dy = self.dy+love.math.random(-self.mistake, self.mistake)

    self:move()

    self:boom(self.x, self.y, 10, {12,8,6}, nil, nil, {0.02,0.06})
    set.AUD['bullet']:stop()
    set.AUD['bullet']:play()

    self.model:spawn(self)
end

function O.Bullet:update(dt)
    self.Super.update(self,dt)
    self:friction(dt)

    self.lifetime = self.lifetime-dt
    if self.lifetime<0.9 then self.bounce=true end
    if self.lifetime<0 then self:destroy() return end
    if self:borders(set.WID, set.HEI) then self.model:destroy(self) end

end

function O.Bullet:destroy()
    self:boom(self.x, self.y, 40, {self.wid,self.wid/2,self.wid/4},
                nil, nil, {0.1,0.4})
    set.AUD['bullet_destroy']:stop()
    set.AUD['bullet_destroy']:play()

    self.model:destroy(self)
end


O.Rocket = cls.Cls(O.Base,{tag='rocket',collider='rectangle'})
-- const
O.Rocket.img_data = set.OBJ[O.Rocket.tag]
O.Rocket.speed = 5
O.Rocket.maxspeed = 500
O.Rocket.cooldown = 0.9
O.Rocket.lifetime = 2.5
O.Rocket.damage = 3
O.Rocket.kick = -20
O.Rocket.mistake = 4
function O.Rocket:new(o)
    self.model=Model
    self:set_obj(self.img_data)
    self.destroy_data = imd.splash_imd(self.img_data, 5, 10)

    self.dx = self.dx+love.math.random(-self.mistake,self.mistake)
    self.dy = self.dy+love.math.random(-self.mistake,self.mistake)

    self.engine = self:local_particle(6, {set.ORANGE,set.GRAYF,set.DARKGRAYF},
                                        nil, {0.7,1.2}, {1,0.1})

    self:boom(self.rect.left[1], self.rect.left[2], 60, {8,6,4},
                            {set.WHITE,set.GRAY,set.GRAYF})
    set.AUD['rocket']:stop()
    set.AUD['rocket']:play()

    self.model:spawn(self)
end

function O.Rocket:update(dt)
    self.Super.update(self,dt)
    self:move()

    self.lifetime = self.lifetime-dt
    if self.lifetime<=2 then
        self.engine.upd(dt,'left', {0,0})
        self.engine.particle:emit(1)
    end
    if self.lifetime<0 then self:destroy() end
end

function O.Rocket:destroy()
    -- fire cloud
    self:boom(self.rect.right[1], self.rect.right[2], 10, {1},
              {set.WHITEFF,set.WHITE,set.GRAYF}, set.OBJ['fire'],nil,{1,0.1})
    -- smoke
    self:boom(self.x, self.y, 30, {self.wid/16,self.wid/8,self.wid/6},
                       {set.DARKGRAY,set.GRAY,set.DARKGRAYF})
    -- fire
    self:boom(self.x, self.y, 80, {self.wid/16},
                        nil, nil, nil, nil, 4000)

    self:destroy_particle({2,4}, {1,2.5}, 300)
    set.AUD['rocket_destroy']:stop()
    set.AUD['rocket_destroy']:play()

    for particle in pairs(self.particle) do particle:reset() end
    self.model:destroy(self)
end


O.Asteroid = cls.Cls(O.Base, {tag='aster', size=3})
-- const
O.Asteroid.aster_data = imd.slice_imd(set.OBJ['aster'], 250, 250, 3)
O.Asteroid.maxspeed = 90
O.Asteroid.torque = math.pi
-- static cmp
O.Asteroid.get_randxy = cmp.get_randxy
function O.Asteroid:new(o)
    self.model=Model
    self.x, self.y = self.get_randxy(self.x, self.y, set.WID, set.HEI,'rand')

    self.dx = love.math.random(-self.maxspeed, self.maxspeed)
    self.dy = love.math.random(-self.maxspeed, self.maxspeed)
    self.da = love.math.random(-self.torque, self.torque)

    self.scale = self.scale*self.size/4
    self.damage = self.size
    self.hp = self.size

    if self.size==3 then
        self.img_data = self.aster_data[1]
    else
        self.img_data = self.aster_data[love.math.random(#self.aster_data)]
    end
    self:set_obj(self.img_data)

    self.model:spawn(self)
end

function O.Asteroid:hit(damage,item)
    self:boom(item.x, item.y, 20, {self.wid/16,self.wid/8},
                       {set.BROWN,set.LIGHTBROWN,set.GRAYF},
                        nil, {0.2,0.5}, {0.3,0.6}, 500)
    return self.Super.hit(self,damage)
end

function O.Asteroid:destroy()
    -- dust cloud
    self:boom(self.x, self.y, 20, {1},
              {set.WHITEFF,set.GRAY,set.DARKGRAYF}, set.OBJ['dust'])
    self:boom(self.x, self.y,30, {self.wid/8,self.wid/10},
                       {set.LIGHTBROWN,set.BROWN, set.GRAYF})
    -- fire
    self:boom(self.x, self.y, 10, {self.wid/16},nil,nil,{0.8,2})

    self.model.score = self.model.score+1

    if self.size>1 then
        self.size = self.size-1
        for _=1, set.NUMASTER do
            O.Asteroid{x=self.x,y=self.y, size=self.size}
        end
    end
    self.model:destroy(self)
end

return O
