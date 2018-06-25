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

-- circle collision box
-- box rotation
-- circle rotation
-- move on the hill
-- inertion
-- border problem

-- 0.4
-- per pixel collision masksb
-- particle rotation
-- paritcle update
-- 0.5

-- improve speed perfomance for colliders

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local DT = 0.016
local EPSILON = 2^-31
local CMP={}

function CMP.set_obj(obj,data)
    local wid,hei = data:getDimensions()
    obj.cenx = wid/2
    obj.ceny = hei/2
    obj.wid = wid*obj.scale
    obj.hei = hei*obj.scale
    obj.midwid = obj.wid/2
    obj.midhei = obj.hei/2
    obj.radius = math.min(obj.wid, obj.hei)/2
    -- use 7.86 for steel(rect) (not real weight just example)
    obj.weight = (obj.wid*obj.hei*0.001)*7.86
    if obj.weight<1 then obj.weight=1.5 end
    obj.body = obj.body or 'dynamic'
    obj.collider = obj.collider or 'box'
    obj.particle = {}
    obj.last_collision = {}
    local rect = CMP.get_rect(obj)
    return love.graphics.newImage(data), rect
end

function CMP.move_upd(obj,dt)
    dt = dt or DT
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
            obj.dx,obj.dy = dx,dy
        end
    else
        obj.dx,obj.dy = dx,dy
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

function CMP.circle_view(obj,x,y)
    x=x or obj.x
    y=y or obj.y
    local maxview = obj.viewrange or obj.radius
    love.graphics.circle('line',obj.x,obj.y,maxview)
    if CMP.get_dotincircle(x,y,{obj.x,obj.y},maxview) then
        return true
    end
end

function CMP.sector_view(obj,x,y)
    x=x or obj.x
    y=y or obj.y
    local cenx,ceny = obj.x, obj.y
    local maxview = obj.viewrange or obj.radius*2
    local angle = obj.viewangle or math.rad(45)
    local cosx_up,siny_up = CMP.get_cos_sin(obj.rot_ang-angle)
    local cosx_down,siny_down = CMP.get_cos_sin(obj.rot_ang+angle)

    local x1,y1,x2,y2
    x1 = cenx+maxview*cosx_up
    y1 = ceny+maxview*siny_up
    x2 = cenx+maxview*cosx_down
    y2 = ceny+maxview*siny_down

    local sides = {{{cenx,ceny},{x1,y1}},
                        {{x1,y1},{x2,y2}},
                            {{x2,y2},{cenx,ceny}}}
    local sq_view = CMP.get_vec2mul({x1,y1},{x2,y2})/2
    local sq_tri = 0
    for i=1, #sides do
        local s = sides[i]
        sq_tri = sq_tri+CMP.get_vec2mul(s[1],s[2],{x,y})/2
    end
    if sq_tri<=sq_view and CMP.circle_view(obj,x,y) then
        return {x1,y1},{x2,y2}
    end
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

function CMP.collision(obj1,obj2,dt)
    dt = dt or DT

    if obj1~=obj2 and obj1.body=='dynamic' then
        if obj1.collider=='box' then
            return CMP.box_collision(obj1,obj2,dt)
        end
        if obj1.collider=='circle' then
            return CMP.circle_collision(obj1,obj2,dt)
        end
        -- dot collider
        local dots = {}
        for i=1, #obj1.collider do
            if obj1.rect[obj1.collider[i]] then
                dots[#dots+1] = obj1.rect[obj1.collider[i]]
            end
        end
        if dots then return CMP.dots_collision(obj1,obj2,dt,dots) end
    end
end

function CMP.base_box_collision(obj1,obj2,dots,dt)
    local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}

    local sq_box=obj2.wid*obj2.hei
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        local sq_tri=0
        local delta,dst,dot
        for i=1,#sides do
            local s = sides[i]
            sq_tri = sq_tri+CMP.get_vec2mul(s[1],s[2],{newx,newy})/2
            local inter = CMP.get_dot_lines({newx,newy},d,s[1],s[2])
            if inter then
                delta,dst,dot=CMP.base_correction(inter,delta,dst,d)
            end
        end

        if sq_tri<=sq_box+1 then
            if delta and (obj1.dx>obj1.weight or obj1.dy>obj1.weight) then
                obj1.x = delta[1]+obj1.x-dot[1]
                obj1.y = delta[2]+obj1.y-dot[2]
            end
            return true
        end
    end
end

function CMP.base_circle_collision(obj1,obj2,dots,dt)
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        if CMP.get_dotincircle(newx,newy,{obj2.x,obj2.y},obj2.radius) then
            local dot_in = CMP.get_dot_line_circle({newx,newy},
                                {d[1],d[2]},{obj2.x,obj2.y},obj2.radius)

            local delta,dst,dot
            for _,inter in pairs(dot_in) do
                if inter[1] and inter[2] then
                    delta,dst,dot=CMP.base_correction(inter,delta,dst,d)
                end
            end
            print(obj1.x,obj1.y)
            if delta and (obj1.dx>obj1.weight or obj1.dy>obj1.weight) then
                obj1.x = delta[1]+obj1.x-dot[1]
                obj1.y = delta[2]+obj1.y-dot[2]
            end
            print(obj1.x,obj1.y)
            return true
        end
    end
end

function CMP.box_collision(obj1,obj2,dt)
    local dots = obj1.rect
    if obj2.collider=='circle' then
        if CMP.base_circle_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end
    elseif obj2.collider=='box' then
        if  CMP.base_box_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end
    end
end

function CMP.circle_collision(obj1,obj2,dt)
    if obj2.collider=='box' then
        local dots = {}
        local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}
        for _,s in pairs(sides) do
            local vec = CMP.get_vec2norm(s[1],s[2])
            local cosvx,sinvy = CMP.get_direction(0,0,vec[1],vec[2])

            dots[#dots+1] = {obj1.x+cosvx*obj1.radius,
                                 obj1.y+sinvy*obj1.radius}
        end
        if CMP.base_box_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end

    elseif obj2.collider=='circle' then
        local cosx,siny = CMP.get_direction(obj1.x,obj1.y,obj2.x,obj2.y)
        local dots = {{obj1.x+cosx*obj1.radius, obj1.y+siny*obj1.radius}}

        if CMP.base_circle_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end
    end
end

function CMP.dots_collision(obj1,obj2,dt,dots)
    if obj2.collider=='circle'  then
        if CMP.base_circle_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end
    else
        if CMP.base_box_collision(obj1,obj2,dots,dt) then
            CMP.bounce(obj1,obj2,dt)
            obj1.last_collision[#obj1.last_collision+1]=obj2
            return true
        end
    end
end

function CMP.box_correction(obj1,obj2,dt,dot)

    if side then
        -- correct rotation
        local side_norm = CMP.get_vec2norm({side[1][1],side[1][2]},
                                               {side[2][1],side[2][2]})
        local cosv,sinv = CMP.get_direction(0,0,side_norm[1],side_norm[2])

        local next_dot = dot
        local dist_side = nil
        local sides_obj1 = {{obj1.rect.topleft, obj1.rect.topright},
                        {obj1.rect.topright, obj1.rect.botright},
                        {obj1.rect.botright, obj1.rect.botleft},
                        {obj1.rect.botleft, obj1.rect.topleft}}

        for i=1,#sides_obj1 do
            local s = sides_obj1[i]
            local d1,d2
            if dot==s[1] then
                d1 = CMP.get_hypot(s[2][1],s[2][2],
                                         s[2][1]*cosv,s[2][2]*sinv)
                if not dist_side then
                    dist_side=d1
                    next_dot = s[2]
                end
                if d1<dist_side then dist_side=d1 next_dot = s[2] end
            end
            if  dot==s[2] then
                d2 = CMP.get_hypot(s[1][1],s[1][2],
                                         s[2][1]*cosv,s[2][2]*sinv)
                if not dist_side then
                    dist_side=d2
                    next_dot = s[1]
                end
                if d2<dist_side then dist_side=d2 next_dot = s[1] end
            end
        end

        local dot_norm = CMP.get_vec2norm({dot[1],dot[2]},
                                          {next_dot[1],next_dot[2]})

        if math.abs(dot_norm[1])>1 and math.abs(dot_norm[2])>1 then
            -- print('rotate')
            -- print(dot_norm[1],dot_norm[2])

            if next_dot[1]<obj1.x then
                obj1.rot_dt=obj1.rot_dt+dt
            else
                obj1.rot_dt=obj1.rot_dt-dt
            end
        else
            -- print(obj1.rot_dt)
            obj1.rot_dt=0
        end
    end
end

function CMP.base_correction(inter,delta,dist,dot)
    local hypot = CMP.get_hypot(dot[1],dot[2],inter[1],inter[2])
    if not dist then
        dist = hypot
        delta = inter
    end
    if hypot<dist then
        dist = hypot
        delta = inter
    end
    return delta,dist,dot
end

function CMP.bounce(obj1,obj2,dt)
    local old1dx = obj1.dx
    local old1dy = obj1.dy
    local bounce = math.max(math.abs(obj1.dx),math.abs(obj1.dy))

    if bounce==math.abs(old1dx) then
        obj1.dx = -old1dx/obj1.weight
        obj1.dy = old1dy
        if obj2.body=='dynamic' and math.abs(old1dx)>obj2.weight then
            obj2.dx = old1dx/obj2.weight
        end
    else
        obj1.dx = old1dx
        obj1.dy = -old1dy/obj1.weight
        if obj2.body=='dynamic' and math.abs(old1dy)>obj2.weight then
            obj2.dy = old1dy/obj2.weight
        end
    end

    if math.abs(obj1.dx*dt)<0.5 then obj1.dx=0 end
    if math.abs(obj1.dy*dt)<0.5 then obj1.dy=0 end
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
    local horx = cosx*delta[1]
    local hory = siny*delta[1]
    local verx = cosx*delta[2]
    local very = siny*delta[2]
    local x,y
    x = sidex+horx-very
    y = sidey+hory+verx
    return x,y
end

function CMP.get_vec2mul(v1,v2,delta)
    delta = delta or {0,0}
    local delta_v1 = {v1[1]-delta[1],v1[2]-delta[2]}
    local delta_v2 = {v2[1]-delta[1],v2[2]-delta[2]}
    return math.abs(delta_v1[1]*delta_v2[2]-delta_v1[2]*delta_v2[1])
end

function CMP.get_vec2norm(v1,v2)
    local x1,y1 = unpack(v1)
    local xx1,yy1 = unpack(v2)
    return {y1-yy1,xx1-x1}
end

function CMP.get_sqtri(a,b,c)
    local p = (a+b+c)/2
    return (p*(p-a)*(p-b)*(p-c))^0.5
end

function CMP.get_dotinline(x,y,a1,a2)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local k = (yy1-y1)/(xx1-x1)
    if yy1-y1==0 or xx1-x1==0 then return true end
    return y-(k*(x-x1)+y1)<=EPSILON
end

function CMP.get_dotincircle(x,y,cen,radius,edge)
    edge=edge or false
    if edge then
        return radius-CMP.get_hypot(x,y,cen[1],cen[2])<EPSILON end
    return CMP.get_hypot(x,y,cen[1],cen[2])<=radius+EPSILON
end

function CMP.get_dot_lines(a1,a2,b1,b2)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local x2,y2 = unpack(b1)
    local xx2,yy2 = unpack(b2)
    local a, b, c, d, e, f = y1-yy1,xx1-x1,y2-yy2,xx2-x2,
                        -(x1*yy1-xx1*y1),-(x2*yy2-xx2*y2)
    local dbase = a*d-b*c
    if dbase~=0 then
        local dx = e*d-f*b
        local dy = a*f-c*e
        local x,y = dx/dbase,dy/dbase
        return {x,y}
    end
end

function CMP.get_dot_line_circle(a1,a2,cen,radius)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local k = (yy1-y1)/(xx1-x1)

    if yy1-y1==0 and xx1-x1==0 then
        if CMP.get_dotincircle(x1,y1,cen,radius,true) then
            return {{x1,y1},{nil,nil}}
        end
        return {{nil,nil},{nil,nil}}
    end

    if xx1-x1==0 then
        return {{cen[1],cen[2]+radius},{cen[1],cen[2]-radius}}
    end
    if yy1-y1==0 then
        return {{cen[1]+radius,cen[2]},{cen[1]-radius,cen[2]}}
    end

    local a,b,c
    a = 1+k^2
    b = - 2*cen[1] + 2*k*y1 - 2*cen[2]*k
    c = cen[1]^2 + y1^2 - 2*cen[2]*y1 + cen[2]^2 - radius^2

    local d1,d2 = CMP.get_root(a,b,c)

    if d1 and d2 then
        return {{d1,k*d1+y1},{d2,k*d2+y1}}
    elseif d1 then
        return {{d1,k*d1+y1},{nil,nil}}
    else
        return {{nil,nil},{nil,nil}}
    end
end


function CMP.get_root(a,b,c)
    local D = b^2-4*a*c
    if a then
        if D>0 then
            return (-b+D^0.5)/(2*a), (-b-D^0.5)/(2 * a)
        elseif D == 0 then
            return -b / (2 * a),nil
        end
    elseif b then
        return -c/b,nil
    else return nil,nil
    end
end

function CMP.get_direction(x1,y1,x2,y2)
    local oldhyp = CMP.get_hypot(x1,y1,x2,y2)
    return (x2-x1)/oldhyp,(y2-y1)/oldhyp
end

function CMP.get_hypot(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

return CMP

