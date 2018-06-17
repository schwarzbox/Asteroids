#!/usr/bin/env love
-- LOVCMP
-- 0.1
-- Game Components (love2d)
-- lovecmp.lua

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

-- gravity inertion static obj
-- improve bounce screen border
-- collison correction
-- 0.2
-- per pixel collision masksb
-- particle rotation
-- paritcle update

local CMP={}
local unpack = table.unpack or unpack

function CMP.set_obj(obj,data)
    local wid,hei = data:getDimensions()
    obj.cenx = wid/2
    obj.ceny = hei/2
    obj.wid = wid*obj.scale
    obj.hei = hei*obj.scale
    obj.midwid = obj.wid/2
    obj.midhei = obj.hei/2
    obj.radius = math.min(obj.wid, obj.hei)/2
    local rect = CMP.get_rect(obj)
    return love.graphics.newImage(data), rect
end

function CMP.move_upd(obj,dt)
    dt = dt or 1
    obj.x = obj.x+obj.dx*dt
    obj.y = obj.y+obj.dy*dt
    obj.rect = CMP.get_rect(obj)
end

function CMP.move(obj,dist)
    dist = dist or obj.speed
    local cosx,siny = CMP.get_cos_sin(obj.rot_ang)
    local dx,dy = obj.dx+cosx*dist,obj.dy+siny*dist

    if obj.maxspeed then
        if math.abs(dx)+math.abs(dy)<obj.maxspeed then
            obj.dx = dx
            obj.dy = dy
        end
    else
        obj.dx = dx
        obj.dy = dy
    end
end

function CMP.rotate_upd(obj,dt)
    dt = dt or 1
    obj.rot_ang = obj.rot_ang+obj.rot_dt*dt
end

function CMP.rotate(obj,side)
    side = side or 0
    obj.rot_dt = obj.rot_dt+side*obj.rotspeed
    if obj.maxrotspeed then
        obj.rot_dt = math.min(math.max(obj.rot_dt,
                                       -obj.maxrotspeed), obj.maxrotspeed)
    end
end



function CMP.correction(obj1,obj2)
    local distance=CMP.get_dist(obj1.x,obj1.y,obj2.x,obj2.y)
    local radius=obj1.radius+obj2.radius
    local correction = distance-radius
    if obj1.body=='dynamic' then
        local cosx1,siny1 = CMP.get_cos_sin(obj1.rot_ang)
        local x1=cosx1*correction
        local y1=siny1*correction
        obj1.x = obj1.x+x1
        obj1.y = obj1.y+y1
    end
end

function CMP.bounce(obj1,obj2)
    if obj1~=obj2 then
        print('bounce')
        CMP.correction(obj1,obj2)

        local old1dx = obj1.dx
        local old1dy = obj1.dy
        local old2dx = obj2.dx
        local old2dy = obj2.dy

        local bounce=math.max(math.abs(obj1.dx),math.abs(obj1.dy))
        print(obj1.dx,obj1.dy)
        if obj1.body=='dynamic' then
            if bounce==old1dx then
                obj1.dx=-(old1dx+old2dx)/2
                obj1.dy=old1dy
            else
                obj1.dx=old1dx
                obj1.dy=-(old1dy+old2dy)/2
            end
        end
    end
end

function CMP.end_collision(obj1,obj2,func)
    if obj1~=obj2 then
        if not func(obj1, obj2) then
            obj1.start_collide = false
            obj2.start_collide = false
            return true
        end
    end
end

function CMP.dot_collision(obj1,obj2)
    if obj1~=obj2  then
        for _,v in pairs(obj1.rect) do
            local distance = CMP.get_dist(v[1], v[2], obj2.x, obj2.y)
            local radius = 1+obj2.radius
            if distance<radius then
                obj1.start_collide = true
                obj2.start_collide = true
                return true
            end
        end
    end
end

function CMP.box_collision(obj1,obj2)
    if obj1~=obj2 then
        local topx1 = obj1.x-obj1.midwid
        local topy1 = obj1.y-obj1.midhei
        local topx2 = obj2.x-obj2.midwid
        local topy2 = obj2.y-obj2.midhei
        local botx1 = obj1.x+obj1.midwid
        local boty1 = obj1.y+obj1.midhei
        local botx2 = obj2.x+obj2.midwid
        local boty2 = obj2.y+obj2.midhei
        if (topx1<botx2 and topy1<boty2 and topx2<botx1 and topy2<boty1) then
            obj1.start_collide = true
            obj2.start_collide = true
            return true
        end
    end
end

function CMP.circle_collision(obj1,obj2)
    if obj1~=obj2  then
        local distance = CMP.get_dist(obj1.x, obj1.y, obj2.x, obj2.y)
        local radius = obj1.radius+obj2.radius
        if distance<radius then
            obj1.start_collide = true
            obj2.start_collide = true
            return true
        end
    end
end

function CMP.shot(obj,side,weapon_delta,inertion)
    weapon_delta = weapon_delta or {0,0}
    inertion = inertion or 0
    local x,y = CMP.get_side(obj.rect[side][1],
                             obj.rect[side][2], obj.rot_ang, weapon_delta)

    obj.weapon{model=obj.model, x=x,y=y, dx=obj.dx, dy=obj.dy,
                                                    rot_ang=obj.rot_ang}
    if obj.move then obj:move(inertion) end
end

function CMP.hit(obj,damage)
    obj.hp = obj.hp-damage
    return obj.hp<=0
end

function CMP.destroy_obj(obj,maxnum,time,accel)
    maxnum = maxnum or {3,5}
    local nx,ny = unpack(maxnum)
    local numx = love.math.random(nx,ny)
    local numy = love.math.random(nx+1,ny+1)
    local destroy_data = obj.destroy_data or obj.img_data
    local sx, sy = destroy_data:getDimensions()

    local arr = {}
    local tilex,tiley = sx/numx,sy/numy
    time = time or {15,30}
    accel = accel or 40
    for i=0,numx-1 do
        for j=0,numy-1 do
            local data = love.image.newImageData(tilex,tiley)
            data:paste(destroy_data, 0, 0, i*tilex, j*tiley, sx, sy)
            arr[#arr+1] = data
        end
    end
    for i=1,#arr do
        if love.math.random(0,1)==1 then
            local scale = {obj.scale, obj.scale+love.math.random(-1,1)*0.2}
            CMP.global_particle(obj, obj.x, obj.y, 1, nil,
                                {{1,1,1,1}, {1,1,1,0}},
                                arr[i], time, scale, accel)
        end
    end
end

function CMP.particle_upd(obj,dt,particle,side,delta,speed)
    side = side or 'center'
    delta = delta or {0,0}
    speed = speed or 0
    local x,y = CMP.get_side(obj.rect[side][1], obj.rect[side][2],
                             obj.rot_ang,delta)
    particle:setPosition(x, y)
    particle:setSpeed(speed)
    particle:setDirection(obj.rot_ang)
    particle:update(dt)
end

function CMP.get_particle(shsize,shtype)
    local canvas
    if shtype=='circle' or shtype=='rect' then
        canvas = love.graphics.newCanvas(shsize, shsize)
        love.graphics.setCanvas(canvas)
        love.graphics.setColor(1,1,1,1)
        if shtype=='circle' then
            love.graphics.circle('fill', shsize/2, shsize/2,shsize/2)
        else
            love.graphics.rectangle('fill', 0, 0, shsize, shsize)
        end
        love.graphics.setCanvas()
    else canvas = love.graphics.newImage(shtype)
    end
    return canvas
end


function CMP.global_particle(obj,x,y,num,shsize,clrs,shtype,time,ptsize,accel)
    obj.model.particle = obj.model.particle or {}
    x = x or obj.x
    y = y or obj.y
    num = num or 20
    shsize = shsize or {1}
    clrs = clrs or {{1,1,0,1}, {1,164/255,64/255,1}, {64/255,64/255,64/255,0}}
    local grad = {}
    for i=1, #clrs do
        for j=1, #clrs[i] do grad[#grad+1] = clrs[i][j] end
    end
    shtype = shtype or 'circle'
    time = time or {0.3,1}
    ptsize = ptsize or {0.5,1}
    accel = accel or 100
    accel = {-love.math.random(accel/2,accel),
            -love.math.random(accel/2,accel),
            love.math.random(accel/2,accel),
            love.math.random(accel/2,accel)}

    for i=1, #shsize do
        local image = CMP.get_particle(shsize[i],shtype)
        local particle = love.graphics.newParticleSystem(image, 100)
        particle:setParticleLifetime(unpack(time))
        particle:setLinearAcceleration(unpack(accel))
        particle:setColors(unpack(grad))
        particle:setSizes(unpack(ptsize))
        particle:setPosition(x, y)
        particle:setSizeVariation(1)
        particle:setEmissionArea('uniform', 5, 5, 0)
        particle:setRotation(1, 8)
        particle:setSpin(1, 4)
        particle:emit(num)
        obj.model.particle[particle] = particle
    end
end

function CMP.local_particle(obj,shsize,clrs,shtype,time,ptsize,accel)
    obj.particle = obj.particle or {}
    shsize = shsize or 5
    clrs = clrs or {{1,1,1,200/255}, {1,1,1,100/255}, {1,1,1,0}}
    local grad = {}
    for i=1, #clrs do
        for j=1, #clrs[i] do grad[#grad+1] = clrs[i][j] end
    end
    shtype = shtype or 'circle'
    time = time or {0.5,1}
    ptsize = ptsize or {0.2,1}
    accel = accel or {-40,-40,40,40}

    local image = CMP.get_particle(shsize,shtype)
    local particle = love.graphics.newParticleSystem(image, 100)
    particle:setParticleLifetime(unpack(time))
    particle:setLinearAcceleration(unpack(accel))
    particle:setColors(unpack(grad))
    particle:setSizes(unpack(ptsize))
    particle:setEmissionArea('uniform', 1, 1, 0)
    particle:setRotation(0.5, 1)
    particle:setSpin(0.1, 0.5)
    obj.particle[particle] = particle
    return particle
end

function CMP.endless_scr(obj,widscr,heiscr)
    if obj.x<0 then obj.x = obj.x+widscr return true end
    if obj.y<0 then obj.y = obj.y+heiscr return true end
    if obj.x>widscr then obj.x = obj.x-widscr return true end
    if obj.y>heiscr then obj.y = obj.y-heiscr return true end
end

function CMP.out_scr(obj,widscr,heiscr)
    return obj.x<0 or obj.y<0 or obj.x>widscr or obj.y>heiscr
end


function CMP.get_rect(obj)
    local cosx,siny = CMP.get_cos_sin(obj.rot_ang)
    local horx = cosx*obj.midwid
    local hory = siny*obj.midwid
    local verx = cosx*obj.midhei
    local very = siny*obj.midhei

    return {topleft = {obj.x-horx+very, obj.y-hory-verx},
            top = {obj.x+very, obj.y-verx},
            topright = {obj.x+horx+very, obj.y+hory-verx},
            right = {obj.x+horx, obj.y+hory},
            botright = {obj.x+horx-very, obj.y+hory+verx},
            bot = {obj.x-very, obj.y+verx},
            botleft = {obj.x-horx-very, obj.y-hory+verx},
            left = {obj.x-horx, obj.y-hory},
            center = {obj.x, obj.y}}
end

function CMP.get_randpos(x,y,widscr,heiscr,side)
    if x and y then
        x,y = x,y
    else
        x = love.math.random(0,widscr)
        y = love.math.random(0,heiscr)
        if side=='rand' then
            local get_side = love.math.random(0,1)
            if get_side==0 then
                local get_x = love.math.random(0,1)
                x=widscr
                if get_x==0 then x = 0 end
            else
                local get_y = love.math.random(0,1)
                y = heiscr
                if get_y==0 then y = 0 end
            end
        elseif side=='top' then y = 0
        elseif side=='bot' then y = heiscr
        elseif side=='left' then x = 0
        elseif side=='right' then x = widscr
        else x,y = x,y end
    end
    return x,y
end

function CMP.get_cos_sin(angle)
    local cosx = math.cos(angle)
    local cosy = math.sin(angle)
    return cosx,cosy
end

function CMP.get_side(sidex,sidey,angle,delta)
    local cosx,siny = CMP.get_cos_sin(angle)
    local x,y
    local horx = cosx*delta[1]
    local hory = siny*delta[1]
    local verx = cosx*delta[2]
    local very = siny*delta[2]

    x = sidex+horx-very
    y = sidey+hory+verx
    return x,y
end

function CMP.get_dist(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

return CMP
