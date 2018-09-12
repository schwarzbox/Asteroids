#!/usr/bin/env love
-- LOVCMP
-- 0.2
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

-- check sin cos for speed
-- improve weight and inertion with weight
-- 0.3
-- per pixel collision masksb
-- add particle option rotation
-- 0.4
-- rectangle rotation
-- circle rotation hill
-- fall bricks after center
-- walk in hill
-- 0.5
-- border problem collide when out screen
-- 1.0
-- upgrade to rectangle2d physics

if arg[1] then print('0.2 LOVCMP Game Components (love2d)', arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local CMP = {DT = 0.017,EPSILON = 2^-31,GRAVITY = {x=0, y=1},TILESIZE=1}
function CMP.set_obj(obj,data)
    data = data or obj.img_data
    local wid,hei = data:getDimensions()
    obj.cenx = wid/2
    obj.ceny = hei/2
    obj.wid = wid*obj.scale
    obj.hei = hei*obj.scale
    obj.radius = math.min(obj.wid, obj.hei)/2

    obj.hp = obj.hp or 1
    -- collision & matrix collision
    obj.xtile=math.floor(obj.x/CMP.TILESIZE+(obj.x/CMP.TILESIZE)%1)
    obj.ytile=math.floor(obj.y/CMP.TILESIZE+(obj.y/CMP.TILESIZE)%1)
    -- use 7.86 for steel(rect) (not real weight just example)
    obj.weight = (obj.wid*obj.hei*0.001)*7.86
    if obj.weight<1 then obj.weight=1.5 end
    obj.body = obj.body or 'dynamic'
    if obj.bounce==nil then obj.bounce = false end
    obj.collider = obj.collider or 'rectangle'
    obj.last_collision = {}
    obj.particle = {}

    local image = love.graphics.newImage(data)
    image:setFilter('nearest', 'linear')
    obj.image = image
    obj.quad = love.graphics.newQuad(0,0,wid,hei,wid,hei)
    obj.rect = CMP.get_rect(obj)
end

function CMP.set_sprites(obj,data,tilex,tiley,numx,numy)
    obj.sprites = {}
    obj.sprites.default = love.graphics.newImage(data)
    obj.sprites.tiles = obj.sprites.default
    obj.sprites.tiles:setFilter('nearest', 'linear')
    obj.sprites.quads = {}
    local sx = obj.sprites.tiles:getWidth()
    local sy = obj.sprites.tiles:getHeight()
    for y=0,numy-1 do
        for x=0,numx-1 do
            obj.sprites.quads[#obj.sprites.quads+1]=love.graphics.newQuad(
                                tilex*x,tiley*y,tilex,tiley,sx,sy)
        end
    end

    obj.get_sprites = function(self) return self.sprites end
end

function CMP.sprite_animation(obj,start,fin,total)
    total=total or 1
    fin=fin+1
    local animation={start=start,fin=fin,total=total,speed=1,elapsed=0}
    animation.upd=function(dt)
            animation.elapsed=animation.elapsed+dt
            if animation.elapsed>=(animation.total/animation.speed) then
                animation.elapsed=0
            end
            local pass=animation.elapsed/(animation.total/animation.speed)
            local index=start+math.floor(pass*(fin-start))
            obj.quad=obj.sprites.quads[index]
            end
    animation.set_image=function(image)
                            image = image or obj.sprites.default
                            obj.sprites.tiles=image
                            obj.image=obj.sprites.tiles
                        end
    animation.set_speed=function(speed) animation.speed=speed end
    animation.set_image()
    return animation
end

function CMP.set_world(obj,meter,gravx,gravy)
    meter = meter or 64
    gravx = gravx or CMP.GRAVITY.x
    gravy = gravy or CMP.GRAVITY.y

    love.physics.setMeter(meter)
    obj.world = love.physics.newWorld(gravx,gravy, true)
    obj.world:setCallbacks(obj.begin_contact, obj.end_contact,
                         obj.pre_solve, obj.post_solve)

    obj.get_world = function(self) return self.world end
end

function CMP.set_body(obj,mass,density,collider,vertex)
    density = density or 4
    mass = mass or 128
    collider = collider or obj.collider
    vertex = vertex or {-40,20,0,0,-40,-20}
    obj.body=love.physics.newBody(obj.model.world, obj.x,obj.y,obj.body)
    if collider=='circle' then
        obj.shape = love.physics.newCircleShape(obj.radius)
    elseif collider=='rectangle' then
        obj.shape = love.physics.newRectangleShape(obj.wid,obj.hei)
    else
        obj.shape=love.physics.newPolygonShape(vertex)
    end
    obj.body:setMass(mass)

    obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)
    obj.fixture:setUserData(obj)

    obj.get_body = function(self) return self.body end
    obj.get_shape = function(self) return self.shape end
    obj.get_fixture = function(self) return self.body end
end

function CMP.rect_upd(obj)
    obj.rect = CMP.get_rect(obj)
end

function CMP.dxdy_upd(obj,dt)
    dt = dt or CMP.DT
    obj.x = obj.x+obj.dx*dt
    obj.y = obj.y+obj.dy*dt
end

function CMP.angle_upd(obj,dt)
    dt = dt or CMP.DT
    obj.angle = obj.angle+obj.da*dt
end

function CMP.move(obj,dist)
    dist = dist or obj.speed
    local cosx,siny = CMP.get_cos_sin(obj.angle)
    local dx,dy = obj.dx+cosx*dist,obj.dy+siny*dist

    if obj.maxspeed then
        if math.abs(dx)+math.abs(dy)<obj.maxspeed then
            obj.dx,obj.dy = dx,dy
        end
    else
        obj.dx,obj.dy = dx,dy
    end
end

function CMP.rotate(obj,side)
    side = side or 0
    obj.da = obj.da+side*obj.torque
    if obj.maxtorque then
        obj.da = math.min(math.max(obj.da,-obj.maxtorque), obj.maxtorque)
    end
end

function CMP.walk(obj,side,dt)
    dt = dt or CMP.DT
    local walk
    if obj.collide then
        walk = CMP.dots_collision(obj,obj.collide,
                                  {{obj.rect.botright[1],
                                 obj.rect.botright[2]+1},
                                 {obj.rect.botleft[1],
                                obj.rect.botleft[2]+1}},dt)
        if walk then
            obj.jump_=false
        end
    end

    obj.y = obj.y-CMP.GRAVITY.y*obj.weight*dt
    if not obj.jump_ then
        if side=='right' then obj:move(obj.speed) end
        if side=='left' then obj:move(-obj.speed) end
    end

end

function CMP.jump(obj,hei)
    hei = hei or 200
    if not obj.jump_ then
        obj.dy = obj.dy-10*hei/obj.weight
        obj.jump_=true
    end
end

function CMP.stop(obj,rotate)
    if rotate=='rotate' then obj.da = 0
    else
        obj.dx,obj.dy = 0,0
    end
end

function CMP.velocity(obj,x,y)
    x = x or 0
    y = y or 0
    obj.dx = obj.dx + x
    obj.dy = obj.dy + y
end

function CMP.friction(obj,dt)
    dt = dt or CMP.DT
    obj.dx = obj.dx-obj.dx*dt
    obj.dy = obj.dy-obj.dy*dt
end

function CMP.angle_friction(obj,dt)
    dt = dt or CMP.DT
    obj.da = obj.da-obj.da*dt
end

function CMP.circle_view(obj,x,y)
    x=x or obj.x
    y=y or obj.y
    local maxview = obj.viewrange or obj.radius
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
    local cosx_up,siny_up = CMP.get_cos_sin(obj.angle-angle)
    local cosx_down,siny_down = CMP.get_cos_sin(obj.angle+angle)

    local x1,y1,x2,y2
    x1 = cenx+maxview*cosx_up
    y1 = ceny+maxview*siny_up
    x2 = cenx+maxview*cosx_down
    y2 = ceny+maxview*siny_down

    local sides = {{{cenx,ceny},{x1,y1}},
                        {{x1,y1},{x2,y2}},
                            {{x2,y2},{cenx,ceny}}}
    local sq_view = CMP.get_vec2mulvec({x1,y1},{x2,y2},{cenx,ceny})/2

    local sq_tri = 0
    for i=1, #sides do
        local s = sides[i]
        sq_tri = sq_tri+CMP.get_vec2mulvec(s[1],s[2],{x,y})/2
    end

    if sq_tri<=sq_view then
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


function CMP.target(obj,x,y,rotate)
    local tcosx,tsiny = CMP.get_direction(obj.x,obj.y,x,y)
    local dx,dy = tcosx*obj.speed,tsiny*obj.speed
    local side = 0
    if rotate then
        local ocosx,osiny = CMP.get_direction(obj.x,obj.y,
                                            obj.rect.right[1],
                                             obj.rect.right[2])
        local tarcos = tcosx-tcosx%0.1
        local objcos = ocosx-ocosx%0.1
        local tarsin = tsiny-tsiny%0.1
        local objsin = osiny-osiny%0.1

        if tarcos == objcos and tarsin == objsin then
            obj.da=0
            return dx,dy,side
        end

        local tacos = math.acos(tcosx)
        local oacos = math.acos(ocosx)

        if tarsin<0 then tacos = math.pi*2-tacos end
        if objsin<0 then oacos = math.pi*2-oacos end

        if tacos>=oacos then
            side=1
            if tacos-oacos > math.pi then side=-1 end
        else side=-1
            if oacos-tacos > math.pi then side=1 end
        end
    end
    return dx,dy,side
end

function CMP.shot(obj,side,weapon_offset,inertion)
    weapon_offset = weapon_offset or {0,0}
    inertion = inertion or 0
    local x,y = CMP.get_side(obj.rect[side][1],
                             obj.rect[side][2], obj.angle, weapon_offset)
    obj.weapon{x=x,y=y ,angle=obj.angle,
                dx=obj.dx, dy=obj.dy, da=0, scale=obj.scale}
    if obj.move then obj:move(inertion) end
end

function CMP.hit(obj,damage)
    damage = damage or 1
    if type(obj.hp)=='table' then
        obj.hp.val = obj.hp.val-damage
        return obj.hp.val<=0
    else
        obj.hp = obj.hp-damage
        return obj.hp<=0
    end
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

function CMP.global_particle(obj,x,y,en,shsize,clrs,shtype,time,ptsize,accel)
    obj.model.particle = obj.model.particle or {}
    x = x or obj.x
    y = y or obj.y
    en = en or 20
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
    local finaccel = {-love.math.random(accel/2,accel),
            -love.math.random(accel/2,accel),
            love.math.random(accel/2,accel),
            love.math.random(accel/2,accel)}

    for i=1, #shsize do
        local image = CMP.get_particle(shsize[i],shtype)
        local particle = love.graphics.newParticleSystem(image, 600)
        particle:setParticleLifetime(unpack(time))
        particle:setLinearAcceleration(unpack(finaccel))
        particle:setColors(unpack(grad))
        particle:setSizes(unpack(ptsize))
        particle:setPosition(x, y)
        particle:setSizeVariation(1)
        particle:setEmissionArea('uniform', 5, 5, 0)
        particle:setRotation(1, 8)
        particle:setSpin(1, 4)
        particle:emit(en)
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
    accel = accel or 40
    accel = {-love.math.random(accel/2,accel),
            -love.math.random(accel/2,accel),
            love.math.random(accel/2,accel),
            love.math.random(accel/2,accel)}

    local image = CMP.get_particle(shsize,shtype)
    local particle = love.graphics.newParticleSystem(image, 400)
    particle:setParticleLifetime(unpack(time))
    particle:setLinearAcceleration(unpack(accel))
    particle:setColors(unpack(grad))
    particle:setSizes(unpack(ptsize))
    particle:setEmissionArea('uniform', 1, 1, 0)
    particle:setRotation(0.5, 1)
    particle:setSpin(0.1, 0.5)
    obj.particle[particle] = particle

    local local_particle={['particle']=particle}
    function local_particle.upd(dt,side,offset,speed,angle)
        dt = dt or CMP.DT
        side = side or 'center'
        offset = offset or {0,0}
        speed = speed or 0
        angle = angle or obj.angle
        local x,y = CMP.get_side(obj.rect[side][1], obj.rect[side][2],
                                 obj.angle,offset)
        local_particle.particle:setPosition(x, y)
        local_particle.particle:setSpeed(speed/2,speed)
        local_particle.particle:setDirection(angle)
        local_particle.particle:update(dt)
    end
    return local_particle
end

function CMP.destroy_particle(obj,maxnum,time,accel)
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

function CMP.get_rect(obj)
    local cosx,siny = CMP.get_cos_sin(obj.angle)
    local wid,hei = obj.img_data:getDimensions()
    obj.wid = wid*obj.scale
    obj.hei = hei*obj.scale
    obj.radius = math.min(obj.wid, obj.hei)/2
    local midwid=obj.wid/2
    local midhei=obj.hei/2
    local horx = cosx*midwid
    local hory = siny*midwid
    local verx = cosx*midhei
    local very = siny*midhei

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

function CMP.get_side(sidex,sidey,angle,offset)
    local cosx,siny = CMP.get_cos_sin(angle)
    local horx = cosx*offset[1]
    local hory = siny*offset[1]
    local verx = cosx*offset[2]
    local very = siny*offset[2]
    local x,y
    x = sidex+horx-very
    y = sidey+hory+verx
    return x,y
end

function CMP.get_randxy(x,y,widscr,heiscr,side)
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

function CMP.get_goal(obj,matrix,oldgoal,viewrange,empty,target)
    local cells = {{-1,0},{1,0},{0,-1},{0,1},{-1,-1},{1,1},{1,-1},{-1,1}}
    local maxview = 0
    local goal = nil

    for i=1,#cells do
        local tmpview=0
        local tmpgoal = {}
        local xx,yy
        for view=1,viewrange do
            xx=obj.xtile+cells[i][1]*view
            yy=obj.ytile+cells[i][2]*view
            for tar=1,#target do
                if matrix[yy][xx] == target[tar] then return {xx,yy} end
            end
            if matrix[yy][xx] ~= empty then break end
            for old=1,#oldgoal do
                if xx==oldgoal[old][1] and yy==oldgoal[old][2] then
                    goto continue
                end
            end
            tmpview=tmpview+1
            tmpgoal = {xx,yy}
            ::continue::
        end
        if tmpview>maxview then
            maxview = tmpview
            goal=tmpgoal
        end
    end
    return goal
end

function CMP.get_emptytile(matrix,tile,wall)
    local xtile,ytile=tile[1],tile[2]
    local wid,hei=#matrix[1],#matrix
    local cells = {{1,0},{0,1},{-1,0},{0,-1}}
    local side = {'right','down','left','up'}
    local empty={}
    for i=1,#cells do
        local x=xtile+cells[i][1]
        local y=ytile+cells[i][2]
        if x>0 and x<=wid and y>0 and y<=hei then
            if matrix[y][x]~=wall then
                empty[#empty+1]=side[i]
            end
        end
    end
    return empty
end

function CMP.get_path(matrix,sign,last)
    local path = {last}
    local wid = #matrix[1]
    local hei = #matrix
    local cells = {{-1,0},{1,0},{0,-1},{0,1}}
    for s=sign,2,-1 do
        for c=1,#cells do
            local xx = path[#path][1]+cells[c][1]
            local yy = path[#path][2]+cells[c][2]
            if xx>=1 and xx<=wid and yy>=1 and yy<=hei then
                if matrix[yy][xx]==s-1 then
                    path[#path+1] = {xx,yy}
                    break
                end
            end
        end
    end
    return path
end

function CMP.get_wave(matrix,wave,goal,empty,sign,target)
    local wid = #matrix[1]
    local hei = #matrix

    local freecell = 0
    for s=#wave,1,-1 do
        local x,y=wave[s][1],wave[s][2]
        local cells = {{-1,0},{1,0},{0,-1},{0,1}}
        for c=1,#cells do
            local xx = x+cells[c][1]
            local yy = y+cells[c][2]
            if xx>=1 and xx<=wid and yy>=1 and yy<=hei then
                local alltags = {empty,unpack(target)}
                for i=1,#alltags do
                    if matrix[yy][xx]==alltags[i] then
                        freecell=freecell+1
                        wave[#wave+1] = {xx,yy}
                        matrix[yy][xx] = sign
                    end
                end

                if xx == goal[1] and yy==goal[2] then
                    return matrix,sign,goal
                end
            end
        end
    end

    if freecell>0 then
        return CMP.get_wave(matrix,wave,goal,empty,sign+1,target)
    else
        return matrix,sign,wave[#wave]
    end
end

function CMP.matrix_pathfinder(obj,matrix,step,goal,empty,target)
    goal = goal or obj.goal or {obj.xtile,obj.ytile}

    if step[1][1]==goal[1] and step[1][2]==goal[2] then
        obj.goal = nil
        return step
    end

    local clone = {}
    for row=1,#matrix do
        clone[row] = {}
        for col=1,#matrix[1] do
            clone[row][col]=matrix[row][col]
        end
    end

    local wavematrix,sign,last = CMP.get_wave(clone,step,goal,empty,1,target)
    local path = CMP.get_path(wavematrix,sign,last)
    return path
end

function CMP.matrix_collision(obj,matrix,tilesize)
    tilesize = tilesize or CMP.TILESIZE
    local dx,dy=obj.dx,obj.dy
    dx=math.floor(dx/tilesize)
    dy=math.floor(dy/tilesize)
    if math.abs(obj.dx)<CMP.TILESIZE then dx=0 end
    if math.abs(obj.dy)<CMP.TILESIZE then dy=0 end

    local tile = matrix[obj.ytile+dy][obj.xtile+dx]
    obj.last_collision[#obj.last_collision+1]={tile=tile,dx=dx,dy=dy}
end

function CMP.collision(obj1,obj2,dt)
    dt = dt or CMP.DT
    if obj1~=obj2 and obj1.body=='dynamic' then
        if obj1.collider=='rectangle' then
            return CMP.rectangle_collision(obj1,obj2,dt)
        end
        if obj1.collider=='circle' then
            return CMP.circle_collision(obj1,obj2,dt)
        end

        local dots = {}
        for i=1, #obj1.collider do
            if obj1.rect[obj1.collider[i]] then
                dots[#dots+1] = obj1.rect[obj1.collider[i]]
            end
        end
        if dots then return CMP.dots_collision(obj1,obj2,dots,dt) end
    end
end

function CMP.base_rectangle_collision(obj1,obj2,dots,dt)
    local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}

    local sq_rectangle=obj2.wid*obj2.hei
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        local sq_tri=0

        for i=1,#sides do
            local s = sides[i]
            sq_tri = sq_tri+CMP.get_vec2mulvec(s[1],s[2],{newx,newy})/2
        end

        if sq_tri<=sq_rectangle+1 then
            local offset,dst,side
            for i=1,#sides do
                local s = sides[i]
                local inter = CMP.get_dotlines({newx,newy},d,s[1],s[2])
                if inter then
                    offset,dst,side=CMP.get_correction(inter,offset,
                                                        dst,d,s,side)
                end
            end

            if offset and obj1.bounce then
                obj1.x = offset[1]+obj1.x-d[1]
                obj1.y = offset[2]+obj1.y-d[2]
            end

            if side and obj1.bounce then
                -- use for bounce
                local side_norm = CMP.get_vec2to90(CMP.get_vec2dots(
                                side[1][1],side[1][2],side[2][1],side[2][2]))

                local vector = CMP.get_vec2dots(d[1],d[2],newx,newy)
                local bounce = CMP.get_vec2bounce(vector,side_norm)
                CMP.set_bounce(obj1,obj2,bounce)
            end

            obj1.last_collision[#obj1.last_collision+1]=obj2
            obj2.last_collision[#obj2.last_collision+1]=obj1
        end
    end
end

function CMP.base_circle_collision(obj1,obj2,dots,dt)
    local cosx,siny = CMP.get_direction(obj1.x,obj1.y,obj2.x,obj2.y)

    local old1x = obj1.x
    local old1y = obj1.y
    -- circle correction
    if obj1.bounce then
        local doubleradius = obj1.radius+obj2.radius
        local distance = CMP.get_hypot(obj1.x,obj1.y,obj2.x,obj2.y)
        if doubleradius>=distance then
            local correction = doubleradius-distance
            obj1.x=obj1.x+cosx*-correction
            obj1.y=obj1.y+siny*-correction
        end
    end
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        if CMP.get_dotincircle(newx,newy,{obj2.x,obj2.y},obj2.radius) then
            if obj1.bounce then
                local side_norm = CMP.get_vec2dots(old1x,old1y,obj2.x,obj2.y)

                local vector = CMP.get_vec2dots(obj1.x,obj1.y,newx,newy)
                local bounce = CMP.get_vec2bounce(vector,side_norm)
                CMP.set_bounce(obj1,obj2,bounce)
            end

            obj1.last_collision[#obj1.last_collision+1]=obj2
            obj2.last_collision[#obj2.last_collision+1]=obj1
        end
    end
end

function CMP.rectangle_collision(obj1,obj2,dt)
    local dots = obj1.rect
    if obj2.collider=='circle' then
        CMP.base_circle_collision(obj1,obj2,dots,dt)
    elseif obj2.collider=='rectangle' then
       CMP.base_rectangle_collision(obj1,obj2,dots,dt)
    end
end

function CMP.circle_collision(obj1,obj2,dt)
    local cosx,siny = CMP.get_direction(obj1.x,obj1.y,obj2.x,obj2.y)
    local dots = {{obj1.x+cosx*obj1.radius, obj1.y+siny*obj1.radius}}
    if obj2.collider=='rectangle' then
        local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}
        for _,s in pairs(sides) do
            local vec = CMP.get_vec2to90(CMP.get_vec2dots(
                                        s[1][1],s[1][2],s[2][1],s[2][2]))
            cosx,siny = CMP.get_direction(0,0,vec[1],vec[2])

            dots[#dots+1] = {obj1.x+cosx*obj1.radius,
                                 obj1.y+siny*obj1.radius}
        end
        CMP.base_rectangle_collision(obj1,obj2,dots,dt)

    elseif obj2.collider=='circle' then
        CMP.base_circle_collision(obj1,obj2,dots,dt)
    end
end

function CMP.dots_collision(obj1,obj2,dots,dt)
    if obj2.collider=='rectangle'  then
        CMP.base_rectangle_collision(obj1,obj2,dots,dt)
    else
        CMP.base_circle_collision(obj1,obj2,dots,dt)
    end
end

function CMP.get_correction(inter,offset,dist,dot,s,side)
    local hypot = CMP.get_hypot(dot[1],dot[2],inter[1],inter[2])
    if not dist or hypot < dist then
        dist = hypot
        offset = inter
        side = s
    end
    return offset,dist,side
end

function CMP.set_bounce(obj1,obj2,bounce)
    local old1dx = obj1.dx
    local old1dy = obj1.dy

    local dist = CMP.get_hypot(0,0,obj1.dx/obj1.weight,obj1.dy/obj1.weight)

    obj1.dx=dist*bounce[1]
    obj1.dy=dist*bounce[2]

    local weightx, weighty = 1, 1
    if CMP.GRAVITY.x > 0 then weightx = CMP.GRAVITY.x end
    if CMP.GRAVITY.y > 0 then weighty = CMP.GRAVITY.y end

    local divw = weightx*obj2.weight/2
    if divw<=1 then divw=1.1 end

    if (obj2.body=='dynamic' and
        math.abs(old1dx)>=weightx*obj2.weight) then
        obj2.dx = old1dx/divw
    end
    if (obj2.body=='dynamic' and
        math.abs(old1dy)>=weighty*obj2.weight) then
        obj2.dy = old1dy/divw
    end
end

function CMP.get_cos_sin(angle)
    local cosx = math.cos(angle)
    local siny = math.sin(angle)
    return cosx,siny
end

function CMP.get_direction(x1,y1,x2,y2)
    local oldhyp = CMP.get_hypot(x1,y1,x2,y2)
    return (x2-x1)/oldhyp,(y2-y1)/oldhyp
end

function CMP.get_hypot(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function CMP.get_vec2dots(x1,y1,x2,y2)
    return CMP.get_vec2normalize({x2-x1,y2-y1})
end

function CMP.get_vec2add(v1,v2)
    return {v1[1]+v2[1],v1[2]+v2[2]}
end

function CMP.get_vec2mulnum(v,num)
    return {v[1]*num,v[2]*num}
end

function CMP.get_vec2mulvec(v1,v2,offset)
    offset = offset or {0,0}
    local offset_v1 = {v1[1]-offset[1],v1[2]-offset[2]}
    local offset_v2 = {v2[1]-offset[1],v2[2]-offset[2]}
    return math.abs(offset_v1[1]*offset_v2[2]-offset_v1[2]*offset_v2[1])
end

function CMP.get_vec2mulscal(v1,v2)
    return v1[1]*v2[1] + v1[2]*v2[2]
end

function CMP.get_vec2to90(v)
    return CMP.get_vec2normalize({v[2],-v[1]})
end

function CMP.get_vec2normalize(v)
    local lenght = CMP.get_hypot(0,0,v[1],v[2])
    return {v[1]/lenght,v[2]/lenght}
end

function CMP.get_vec2bounce(v,n)
    -- r = v-2*(v*n)*n
    local vnum = -2*CMP.get_vec2mulscal(v,n)
    local vmul = CMP.get_vec2mulnum(n,vnum)
    return CMP.get_vec2add(v,vmul)
end

function CMP.get_sqtri(a,b,c)
    local p = (a+b+c)/2
    return (p*(p-a)*(p-b)*(p-c))^0.5
end

function CMP.get_volcone(hei,angle)
    angle=(math.pi-angle)/2
    local hypot = hei/math.sin(angle)
    local radius=(hypot^2-hei^2)
    return math.pi*radius*hei/3
end

function CMP.get_dotinline(x,y,a1,a2)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local k = (yy1-y1)/(xx1-x1)
    if yy1-y1==0 or xx1-x1==0 then return true end
    return y-(k*(x-x1)+y1)<=CMP.EPSILON
end

function CMP.get_dotincircle(x,y,cen,radius,edge)
    edge=edge or false
    if edge then
        return radius-CMP.get_hypot(x,y,cen[1],cen[2])<CMP.EPSILON end
    return CMP.get_hypot(x,y,cen[1],cen[2])<=radius+CMP.EPSILON
end

function CMP.get_dotlines(a1,a2,b1,b2)
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

function CMP.get_dot_linecircle(a1,a2,cen,radius)
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

return CMP
