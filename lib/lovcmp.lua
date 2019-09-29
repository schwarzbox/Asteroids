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

-- old lovcmp

if arg[1] then print('0.2 LOVCMP Game Components (love2d)', arg[1]) end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local CMP = {DT=0.017,EPSILON=2^-31,GRAVITY={x=0,y=9.83},METER=1,TILESIZE=1}
function CMP.setObject(obj,data)
    data = data or obj.imgdata
    local wid,hei = data:getDimensions()
    obj.pivx = obj.pivx or wid/2
    obj.pivy = obj.pivy or hei/2
    obj.wid = wid*obj.scale
    obj.hei = hei*obj.scale
    obj.radius = math.min(obj.wid, obj.hei)/2

    obj.setImage = function(self,image)
                        self.image=image
                        self.image:setFilter('nearest', 'linear')
                    end
    obj.setImage(obj,love.graphics.newImage(data))

    obj.quad = love.graphics.newQuad(0,0,wid,hei,wid,hei)
    obj.rect = CMP.getRect(obj)

    obj.particles = {}

    -- matrix collision
    obj.tilex = math.floor(obj.x/CMP.TILESIZE+(obj.x/CMP.TILESIZE)%1)
    obj.tiley = math.floor(obj.y/CMP.TILESIZE+(obj.y/CMP.TILESIZE)%1)

    -- physics
    obj.mass = (obj.wid*obj.hei/(CMP.METER*CMP.METER))
    obj.speed=obj.speed or 10
    obj.torque=obj.torque or 1
    obj.restitution = 0.1
    -- obj.friction = 0.5
    -- obj.inertion = 0.5
    obj.flying=false

    obj.body = obj.body or 'dynamic'
    if obj.bounce==nil then obj.bounce = false end
    obj.collider = obj.collider or 'rectangle'
    obj.lastcoll = {}
    obj.collide = false

    obj.tag = obj.tag or 'tag'
    obj.dead = false
    obj.hp = obj.hp or 1
    obj.damage = obj.damage or 1

    obj.weapon = obj.weapon or {type=nil, side='center',offset={0,0}}
    obj.setWeapon = function(self,type_,side,offset)
                        self.weapon.type = type_ or self.weapon.type
                        self.weapon.side = side or self.weapon.side
                        self.weapon.offset = offset or self.weapon.offset
                    end

    obj.updateXY = function(self,dt) dt = dt or CMP.DT
        self.x = self.x+(self.dx*CMP.METER*dt)
        self.y = self.y+(self.dy*CMP.METER*dt)
    end
    obj.updateAngle=function(self,dt) dt = dt or CMP.DT
        self.angle = self.angle+(self.da*CMP.METER*dt)
    end
    obj.updateRect = function(self) self.rect = CMP.getRect(self) end

    obj.setXY = function(self,x,y) self.x=x self.y=y end
    -- fixed speed
    obj.setDX = function(self,dx) dx=dx or 0 self.dx=dx end
    obj.setDY = function(self,dy) dy=dy or 0 self.dy=dy end
    obj.setAngle = function(self,a) self.angle=a end
    obj.setDA = function(self,da) da=da or 0 self.da=da end
end

function CMP.getRect(obj)
    local cosx,siny = CMP.getCosSin(obj.angle)
    local wid,hei = obj.imgdata:getDimensions()
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

function CMP.getRectOffset(sidex,sidey,angle,offset)
    offset = offset or {0,0}
    local cosx,siny = CMP.getCosSin(angle)
    local horx = cosx*offset[1]
    local hory = siny*offset[1]
    local verx = cosx*offset[2]
    local very = siny*offset[2]
    local x,y
    x = sidex+horx-very
    y = sidey+hory+verx
    return x,y
end

function CMP.getRandOffsetXY(x,y,widscr,heiscr,side)
    if x and y then
        x,y = x,y
    else
        x = love.math.random(0,widscr)
        y = love.math.random(0,heiscr)
        if side=='rand' then
            local randside = love.math.random(0,1)
            if randside==0 then
                local randx = love.math.random(0,1)
                x = widscr
                if randx==0 then x = 0 end
            else
                local randy = love.math.random(0,1)
                y = heiscr
                if randy==0 then y = 0 end
            end
        elseif side=='top' then y = 0
        elseif side=='bot' then y = heiscr
        elseif side=='left' then x = 0
        elseif side=='right' then x = widscr
        else x,y = x,y end
    end
    return x,y
end

function CMP.setSprite(obj,data,tilex,tiley,numx,numy)
    obj.sprite = {}
    obj.sprite.default = love.graphics.newImage(data)
    obj.sprite.atlas = obj.sprite.default
    obj.sprite.atlas:setFilter('nearest', 'linear')
    obj.sprite.quads = {}
    local sx = obj.sprite.atlas:getWidth()
    local sy = obj.sprite.atlas:getHeight()
    for y=0,numy-1 do
        for x=0,numx-1 do
            obj.sprite.quads[#obj.sprite.quads+1]=love.graphics.newQuad(
                                tilex*x,tiley*y,tilex,tiley,sx,sy)
        end
    end

    obj.getSprite = function(self) return self.sprite end
end

function CMP.animateSprite(obj,start,fin,total)
    total = total or 1
    fin = fin+1
    local animation = {start=start,fin=fin,total=total,speed=1,elapsed=0}
    animation.update = function(dt)
            animation.elapsed=animation.elapsed+dt
            if animation.elapsed>=(animation.total/animation.speed) then
                animation.elapsed=0
            end
            local pass = animation.elapsed/(animation.total/animation.speed)
            local index = start+math.floor(pass*(fin-start))
            obj.quad = obj.sprite.quads[index]
        end
    animation.setAtlas = function(atlas)
                            obj.sprite.atlas = atlas or obj.sprite.default
                            obj.image = obj.sprite.atlas
                        end
    animation.setSpeed = function(speed) animation.speed=speed end
    animation.setAtlas()
    obj.quad = obj.sprite.quads[1]
    return animation
end

function CMP.move(obj,dist)
    dist = dist or obj.speed
    local cosx,siny = CMP.getCosSin(obj.angle)
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

function CMP.addForce(obj,x,y)
    x = x or 0 y = y or 0
    obj.dx=obj.dx+(x/obj.mass)
    obj.dy=obj.dy+(y/obj.mass)
end

function CMP.addTorque(obj,a)
    a = a or 0
    obj.da=obj.da+(a/obj.mass)
end

function CMP.linearImpulse(obj,x,y)
    x = x or 0 y = y or 0
    obj.dx = obj.dx+(x/obj.mass)*60
    obj.dy = obj.dy+(y/obj.mass)*60
end

function CMP.angularImpulse(obj,a)
    obj.da=obj.da+(a/obj.mass)*60
end

function CMP.linearDamping(obj,dt)
    dt = dt or CMP.DT
    obj.dx = obj.dx-obj.dx*dt
    obj.dy = obj.dy-obj.dy*dt
end

function CMP.angularDamping(obj,dt)
    dt = dt or CMP.DT
    obj.da = obj.da-obj.da*dt
end

function CMP.shot(obj)
    if obj.weapon.type  then
        local side = obj.weapon.side
        local offset = obj.weapon.offset
        local kick = obj.weapon.type.kick or 0
        local x,y = CMP.getRectOffset(obj.rect[side][1],obj.rect[side][2],
                                                         obj.angle, offset)
        local shot = obj.weapon.type{node=obj.node, x=x,y=y,
                        dx=obj.dx, dy=obj.dy,
                        angle=obj.angle, da=0, scale=obj.scale}

        if obj.move then obj:move(kick) end
        return shot
    end
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

function CMP.target(obj,x,y,rotate)
    local tcosx,tsiny = CMP.getDirection(obj.x,obj.y,x,y)
    local dx,dy = tcosx*obj.speed,tsiny*obj.speed
    local side = 0
    if rotate then
        local ocosx,osiny = CMP.getDirection(obj.x,obj.y,
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

function CMP.circleView(obj,x,y)
    x=x or obj.x
    y=y or obj.y
    local maxview = obj.viewrange or obj.radius
    if CMP.getDotInCircle(x,y,{obj.x,obj.y},maxview) then
        return true
    end
end

function CMP.sectorView(obj,x,y)
    x=x or obj.x
    y=y or obj.y
    local cenx,ceny = obj.x, obj.y
    local maxview = obj.viewrange or obj.radius*2
    local angle = obj.viewangle or math.rad(45)
    local cosup,sinup = CMP.getCosSin(obj.angle-angle)
    local cosdown,sindown = CMP.getCosSin(obj.angle+angle)

    local x1,y1,x2,y2
    x1 = cenx+maxview*cosup
    y1 = ceny+maxview*sinup
    x2 = cenx+maxview*cosdown
    y2 = ceny+maxview*sindown

    local sides = {{{cenx,ceny},{x1,y1}},
                        {{x1,y1},{x2,y2}},
                            {{x2,y2},{cenx,ceny}}}
    local viewarea = CMP.getVec2mulvec({x1,y1},{x2,y2},{cenx,ceny})/2

    local triarea = 0
    for i=1, #sides do
        local s = sides[i]
        triarea = triarea+CMP.getVec2mulvec(s[1],s[2],{x,y})/2
    end

    if triarea<=viewarea then
        return {x1,y1},{x2,y2}
    end
end

function CMP.infinityScreen(obj,widscr,heiscr)
    if obj.x<0 then obj.x = obj.x+widscr return true end
    if obj.y<0 then obj.y = obj.y+heiscr return true end
    if obj.x>widscr then obj.x = obj.x-widscr return true end
    if obj.y>heiscr then obj.y = obj.y-heiscr return true end
end

function CMP.outScreen(obj,widscr,heiscr)
    return obj.x<0 or obj.y<0 or obj.x>widscr or obj.y>heiscr
end

function CMP.getParticle(fsize,form)
    local canvas
    if form=='circle' or form=='rectangle' then
        canvas = love.graphics.newCanvas(fsize, fsize)
        love.graphics.setCanvas(canvas)
        love.graphics.setColor(1,1,1,1)
        if form=='circle' then
            love.graphics.circle('fill', fsize/2, fsize/2,fsize/2)
        else
            love.graphics.rectangle('fill', 0, 0, fsize, fsize)
        end
        love.graphics.setCanvas()
    else canvas = love.graphics.newImage(form)
    end
    return canvas
end

function CMP.nodeParticle(obj,x,y,en,fsize,clrs,form,time,ptsize,accel,spin)
    obj.node.particles = obj.node.particles or {}
    x = x or obj.x
    y = y or obj.y
    en = en or 20
    fsize = fsize or {1}
    clrs = clrs or {{1,1,0,1}, {1,164/255,64/255,1}, {64/255,64/255,64/255,0}}
    local grad = {}
    for i=1, #clrs do
        for j=1, #clrs[i] do grad[#grad+1] = clrs[i][j] end
    end
    form = form or 'circle'
    time = time or {0.3,1}
    ptsize = ptsize or {0.5,1}
    accel = accel or 100
    local finaccel = {-love.math.random(accel/2,accel),
            -love.math.random(accel/2,accel),
            love.math.random(accel/2,accel),
            love.math.random(accel/2,accel)}
    spin = spin or {-5,5}
    for i=1, #fsize do
        local image = CMP.getParticle(fsize[i],form)
        local particle = love.graphics.newParticleSystem(image, 1000)
        particle:setParticleLifetime(unpack(time))
        particle:setLinearAcceleration(unpack(finaccel))
        particle:setColors(unpack(grad))
        particle:setSizes(unpack(ptsize))
        particle:setSizeVariation(1)
        particle:setPosition(x, y)
        particle:setEmissionArea('uniform', 5, 5, 0)
        particle:setRotation(0, math.pi*2)
        particle:setSpin(unpack(spin))
        particle:setSpinVariation(1)
        particle:emit(en)
        obj.node.particles[particle] = particle
    end
end

function CMP.objectParticle(obj,fsize,clrs,form,time,ptsize,accel,spin)
    obj.particles = obj.particles or {}
    fsize = fsize or 5
    clrs = clrs or {{1,1,1,200/255}, {1,1,1,100/255}, {1,1,1,0}}
    local grad = {}
    for i=1, #clrs do
        for j=1, #clrs[i] do grad[#grad+1] = clrs[i][j] end
    end
    form = form or 'circle'
    time = time or {0.5,1}
    ptsize = ptsize or {0.2,1}
    accel = accel or 40
    accel = {-love.math.random(accel/2,accel),
            -love.math.random(accel/2,accel),
            love.math.random(accel/2,accel),
            love.math.random(accel/2,accel)}
    spin = spin or {-0.5,0.5}

    local image = CMP.getParticle(fsize,form)
    local particle = love.graphics.newParticleSystem(image, 1000)
    particle:setParticleLifetime(unpack(time))
    particle:setLinearAcceleration(unpack(accel))
    particle:setColors(unpack(grad))
    particle:setSizes(unpack(ptsize))
    -- particle:setEmissionArea('uniform', 1, 1, 0)
    particle:setRotation(0, 1)
    particle:setSpin(unpack(spin))
    obj.particles[particle] = particle

    local objParticle={['particle']=particle}
    function objParticle.update(dt,side,offset,speed,angle)
        dt = dt or CMP.DT
        side = side or 'center'
        offset = offset or {0,0}
        speed = speed or 0
        angle = angle or obj.angle
        local x,y = CMP.getRectOffset(obj.rect[side][1], obj.rect[side][2],
                                      obj.angle,offset)
        objParticle.particle:setPosition(x, y)
        objParticle.particle:setSpeed(speed/2,speed)
        objParticle.particle:setDirection(angle)
        objParticle.particle:update(dt)
    end
    return objParticle
end

function CMP.destroyParticle(obj,maxnum,time,accel)
    maxnum = maxnum or {3,5}
    local nx,ny = unpack(maxnum)
    local numx = love.math.random(nx,ny)
    local numy = love.math.random(nx+1,ny+1)
    local dstdata = obj.dstdata or obj.imgdata
    local sx, sy = dstdata:getDimensions()

    local arr = {}
    local tilex,tiley = sx/numx,sy/numy
    time = time or {15,30}
    accel = accel or 40
    for i=0,numx-1 do
        for j=0,numy-1 do
            local data = love.image.newImageData(tilex,tiley)
            data:paste(dstdata, 0, 0, i*tilex, j*tiley, sx, sy)
            arr[#arr+1] = data
        end
    end
    for i=1,#arr do
        if love.math.random(0,1)==1 then
            local scale = {obj.scale, obj.scale+love.math.random(-1,1)*0.2}
            CMP.nodeParticle(obj, obj.x, obj.y, 1, nil,
                                {{1,1,1,1}, {1,1,1,0}},
                                arr[i], time, scale, accel)
        end
    end
end

function CMP.getMatrixGoal(obj,matrix,oldgoal,viewrange,empty,target)
    local cells = {{-1,0},{1,0},{0,-1},{0,1},{-1,-1},{1,1},{1,-1},{-1,1}}
    local maxview = 0
    local goal = nil

    for i=1,#cells do
        local tmpview = 0
        local tmpgoal = {}
        local x,y
        for view=1,viewrange do
            x = obj.tilex+cells[i][1]*view
            y = obj.tiley+cells[i][2]*view
            for tar=1,#target do
                if matrix[y][x]==target[tar] then return {x,y} end
            end
            if matrix[y][x]~=empty then break end
            for old=1,#oldgoal do
                if x==oldgoal[old][1] and y==oldgoal[old][2] then
                    goto continue
                end
            end
            tmpview = tmpview+1
            tmpgoal = {x,y}
            ::continue::
        end
        if tmpview>maxview then
            maxview = tmpview
            goal = tmpgoal
        end
    end
    return goal
end

function CMP.getEmptyTile(matrix,tile,wall)
    local tilex,tiley = tile[1],tile[2]
    local wid,hei=#matrix[1],#matrix
    local cells = {{1,0},{0,1},{-1,0},{0,-1}}
    local side = {'right','down','left','up'}
    local empty={}
    for i=1,#cells do
        local x = tilex+cells[i][1]
        local y = tiley+cells[i][2]
        if x>0 and x<=wid and y>0 and y<=hei then
            if matrix[y][x]~=wall then
                empty[#empty+1]=side[i]
            end
        end
    end
    return empty
end

function CMP.getMatrixPath(matrix,sign,last)
    local path = {last}
    local wid = #matrix[1]
    local hei = #matrix
    local cells = {{-1,0},{1,0},{0,-1},{0,1}}
    for s=sign,2,-1 do
        for c=1,#cells do
            local x = path[#path][1]+cells[c][1]
            local y = path[#path][2]+cells[c][2]
            if x>=1 and x<=wid and y>=1 and y<=hei then
                if matrix[y][x]==s-1 then
                    path[#path+1] = {x,y}
                    break
                end
            end
        end
    end
    return path
end

function CMP.getMatrixWave(matrix,wave,goal,empty,sign,target)
    local wid = #matrix[1]
    local hei = #matrix

    local freecell = 0
    for s=#wave,1,-1 do
        local wavex,wavey = wave[s][1],wave[s][2]
        local cells = {{-1,0},{1,0},{0,-1},{0,1}}
        for c=1,#cells do
            local x = wavex+cells[c][1]
            local y = wavey+cells[c][2]
            if x>=1 and x<=wid and y>=1 and y<=hei then
                local alltags = {empty,unpack(target)}
                for i=1,#alltags do
                    if matrix[y][x]==alltags[i] then
                        freecell=freecell+1
                        wave[#wave+1] = {x,y}
                        matrix[y][x] = sign
                    end
                end

                if x == goal[1] and y==goal[2] then
                    return matrix,sign,goal
                end
            end
        end
    end

    if freecell>0 then
        return CMP.getMatrixWave(matrix,wave,goal,empty,sign+1,target)
    else
        return matrix,sign,wave[#wave]
    end
end

function CMP.matrixPathfinder(obj,matrix,step,goal,empty,target)
    goal = goal or obj.goal or {obj.tilex,obj.tiley}

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

    local wavemat,sign,last = CMP.getMatrixWave(clone,step,goal,empty,1,target)
    local path = CMP.getMatrixPath(wavemat,sign,last)
    return path
end

function CMP.matrixCollision(obj,matrix,tilesize)
    tilesize = tilesize or CMP.TILESIZE
    local dx,dy=obj.dx,obj.dy
    dx=math.floor(dx/tilesize)
    dy=math.floor(dy/tilesize)
    if math.abs(obj.dx)<CMP.TILESIZE then dx=0 end
    if math.abs(obj.dy)<CMP.TILESIZE then dy=0 end

    local tile = matrix[obj.tiley+dy][obj.tilex+dx]
    obj.lastcoll[#obj.lastcoll+1]={tile=tile,dx=dx,dy=dy}
end

function CMP.collision(obj1,obj2,dt)
    dt = dt or CMP.DT
    if obj1~=obj2 and obj1.body=='dynamic' then
        if obj1.collider=='rectangle' then
            return CMP.rectangleCollision(obj1,obj2,dt)
        end
        if obj1.collider=='circle' then
            return CMP.circleCollision(obj1,obj2,dt)
        end

        local dots = {}
        for i=1, #obj1.collider do
            if obj1.rect[obj1.collider[i]] then
                dots[#dots+1] = obj1.rect[obj1.collider[i]]
            end
        end
        if dots then return CMP.dotsCollision(obj1,obj2,dots,dt) end
    end
end

function CMP.baseRectangleCollision(obj1,obj2,dots,dt)
    local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}

    local rectarea = obj2.wid*obj2.hei
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        local triarea=0

        for i=1,#sides do
            local s = sides[i]
            triarea = triarea+CMP.getVec2mulvec(s[1],s[2],{newx,newy})/2
        end

        if triarea<=rectarea+1 then
            local offset,dst,side
            for i=1,#sides do
                local s = sides[i]
                local inter = CMP.getDotInLines({newx,newy},d,s[1],s[2])
                if inter then
                    offset,dst,side=CMP.getRectCorrection(inter,offset,
                                                        dst,d,s,side)
                end
            end

            if offset and obj1.bounce then
                obj1.x = offset[1]+obj1.x-d[1]
                obj1.y = offset[2]+obj1.y-d[2]
            end

            if side and obj1.bounce then
                -- use for bounce
                local sidenorm = CMP.getVec2to90(CMP.getVec2dots(
                                side[1][1],side[1][2],side[2][1],side[2][2]))

                local vector = CMP.getVec2dots(d[1],d[2],newx,newy)
                local bounce = CMP.getVec2bounce(vector,sidenorm)
                CMP.setBounce(obj1,obj2,bounce)
            end

            obj1.lastcoll[#obj1.lastcoll+1]=obj2
            obj2.lastcoll[#obj2.lastcoll+1]=obj1
        end
    end
end

function CMP.baseCircleCollision(obj1,obj2,dots,dt)
    local cosx,siny = CMP.getDirection(obj1.x,obj1.y,obj2.x,obj2.y)

    local old1x = obj1.x
    local old1y = obj1.y
    -- circle correction
    if obj1.bounce then
        local doubleradius = obj1.radius+obj2.radius
        local distance = CMP.getHypot(obj1.x,obj1.y,obj2.x,obj2.y)
        if doubleradius>=distance then
            local correction = doubleradius-distance
            obj1.x=obj1.x+cosx*-correction
            obj1.y=obj1.y+siny*-correction
        end
    end
    for _,d in pairs(dots) do
        local newx = d[1]+obj1.dx*dt
        local newy = d[2]+obj1.dy*dt
        if CMP.getDotInCircle(newx,newy,{obj2.x,obj2.y},obj2.radius) then
            if obj1.bounce then
                local sidenorm = CMP.getVec2dots(old1x,old1y,obj2.x,obj2.y)

                local vector = CMP.getVec2dots(obj1.x,obj1.y,newx,newy)
                local bounce = CMP.getVec2bounce(vector,sidenorm)
                CMP.setBounce(obj1,obj2,bounce)
            end

            obj1.lastcoll[#obj1.lastcoll+1]=obj2
            obj2.lastcoll[#obj2.lastcoll+1]=obj1
        end
    end
end

function CMP.rectangleCollision(obj1,obj2,dt)
    local dots = obj1.rect
    if obj2.collider=='circle' then
        CMP.baseCircleCollision(obj1,obj2,dots,dt)
    elseif obj2.collider=='rectangle' then
       CMP.baseRectangleCollision(obj1,obj2,dots,dt)
    end
end

function CMP.circleCollision(obj1,obj2,dt)
    local cosx,siny = CMP.getDirection(obj1.x,obj1.y,obj2.x,obj2.y)
    local dots = {{obj1.x+cosx*obj1.radius, obj1.y+siny*obj1.radius}}
    if obj2.collider=='rectangle' then
        local sides = {{obj2.rect.topleft, obj2.rect.topright},
                    {obj2.rect.topright, obj2.rect.botright},
                    {obj2.rect.botright, obj2.rect.botleft},
                    {obj2.rect.botleft, obj2.rect.topleft}}
        for _,s in pairs(sides) do
            local vec = CMP.getVec2to90(CMP.getVec2dots(
                                        s[1][1],s[1][2],s[2][1],s[2][2]))
            cosx,siny = CMP.getDirection(0,0,vec[1],vec[2])

            dots[#dots+1] = {obj1.x+cosx*obj1.radius,
                                 obj1.y+siny*obj1.radius}
        end
        CMP.baseRectangleCollision(obj1,obj2,dots,dt)

    elseif obj2.collider=='circle' then
        CMP.baseCircleCollision(obj1,obj2,dots,dt)
    end
end

function CMP.dotsCollision(obj1,obj2,dots,dt)
    if obj2.collider=='rectangle'  then
        CMP.baseRectangleCollision(obj1,obj2,dots,dt)
    else
        CMP.baseCircleCollision(obj1,obj2,dots,dt)
    end
end

function CMP.getRectCorrection(inter,offset,dist,dot,s,side)
    local hypot = CMP.getHypot(dot[1],dot[2],inter[1],inter[2])
    if not dist or hypot < dist then
        dist = hypot
        offset = inter
        side = s
    end
    return offset,dist,side
end

function CMP.setBounce(obj1,obj2,bounce)
    local old1dx = obj1.dx
    local old1dy = obj1.dy

    obj1.dx=obj1.dx*obj1.restitution*bounce[1]
    obj1.dy=obj1.dy*obj1.restitution*bounce[2]

    if (obj2.body=='dynamic' and
        math.abs(old1dx+obj1.mass)>=obj2.mass) then
        obj2.dx = obj2.dx + old1dx/(1+obj2.mass)
    end
    if (obj2.body=='dynamic' and
        math.abs(old1dy+obj1.mass)>=obj2.mass) then
        obj2.dy = obj2.dy + old1dy/(1+obj2.mass)
    end
end

function CMP.getCosSin(angle)
    local cosx = math.cos(angle)
    local siny = math.sin(angle)
    return cosx,siny
end

function CMP.getDirection(x1,y1,x2,y2)
    local oldhyp = CMP.getHypot(x1,y1,x2,y2)
    return (x2-x1)/oldhyp,(y2-y1)/oldhyp
end

function CMP.getHypot(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function CMP.getVec2dots(x1,y1,x2,y2)
    return CMP.getVec2normalize({x2-x1,y2-y1})
end

function CMP.getVec2add(v1,v2)
    return {v1[1]+v2[1],v1[2]+v2[2]}
end

function CMP.getVec2mulnum(v,num)
    return {v[1]*num,v[2]*num}
end

function CMP.getVec2mulvec(v1,v2,offset)
    offset = offset or {0,0}
    local offset1 = {v1[1]-offset[1],v1[2]-offset[2]}
    local offset2 = {v2[1]-offset[1],v2[2]-offset[2]}
    return math.abs(offset1[1]*offset2[2]-offset1[2]*offset2[1])
end

function CMP.getVec2mulscal(v1,v2)
    return v1[1]*v2[1] + v1[2]*v2[2]
end

function CMP.getVec2to90(v)
    return CMP.getVec2normalize({v[2],-v[1]})
end

function CMP.getVec2normalize(v)
    local lenght = CMP.getHypot(0,0,v[1],v[2])
    return {v[1]/lenght,v[2]/lenght}
end

function CMP.getVec2bounce(v,n)
    -- r = v-2*(v*n)*n
    local vnum = -2*CMP.getVec2mulscal(v,n)
    local vmul = CMP.getVec2mulnum(n,vnum)
    return CMP.getVec2add(v,vmul)
end

function CMP.getTriangleArea(a,b,c)
    local p = (a+b+c)/2
    return (p*(p-a)*(p-b)*(p-c))^0.5
end

function CMP.getConeVolume(hei,angle)
    angle=(math.pi-angle)/2
    local hypot = hei/math.sin(angle)
    local radius=(hypot^2-hei^2)
    return math.pi*radius*hei/3
end

function CMP.getDotInLine(x,y,a1,a2)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local k = (yy1-y1)/(xx1-x1)
    if yy1-y1==0 or xx1-x1==0 then return true end
    return y-(k*(x-x1)+y1)<=CMP.EPSILON
end

function CMP.getDotInCircle(x,y,cen,radius,edge)
    edge=edge or false
    if edge then
        return radius-CMP.getHypot(x,y,cen[1],cen[2])<CMP.EPSILON end
    return CMP.getHypot(x,y,cen[1],cen[2])<=radius+CMP.EPSILON
end

function CMP.getDotInLines(a1,a2,b1,b2)
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

function CMP.getDotInLineAndCircle(a1,a2,cen,radius)
    local x1,y1 = unpack(a1)
    local xx1,yy1 = unpack(a2)
    local k = (yy1-y1)/(xx1-x1)

    if yy1-y1==0 and xx1-x1==0 then
        if CMP.getDotInCircle(x1,y1,cen,radius,true) then
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

    local d1,d2 = CMP.getSquareRoots(a,b,c)

    if d1 and d2 then
        return {{d1,k*d1+y1},{d2,k*d2+y1}}
    elseif d1 then
        return {{d1,k*d1+y1},{nil,nil}}
    else
        return {{nil,nil},{nil,nil}}
    end
end

function CMP.getSquareRoots(a,b,c)
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
