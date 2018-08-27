#!/usr/bin/env love
-- LOVIMD
-- 0.2
-- Image Functions (love2d)
-- lovimd.lua

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

-- 0.3
-- blend modes
-- improve splash

if arg[1] then print('0.2 LOVIMG Image Functions (love2d)', arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local EMPTY = {1,1,1,0}
local WHITE = {1,1,1,1}

local IMD = {}
function IMD.matrix_imd(matrix, color, scale)
    scale = scale or 1
    local sx = #matrix[1]
    local sy = #matrix
    local data = love.image.newImageData(sx, sy)
    for y=1,sy do
        for x=1,sx do
            if matrix[y][x] and matrix[y][x]~=0 then
                data:setPixel((x-1),(y-1), unpack(color))
            end
        end
    end
    if scale~=1 then data = IMD.resize_imd(data, scale) end
    return data
end

function IMD.resize_imd(image_data, scale)
    scale = scale or 1
    local sx, sy = image_data:getDimensions()
    local data = love.image.newImageData(math.ceil(sx*scale),
                                          math.ceil(sy*scale))
    for x=1, sx do
        for y=1, sy do
            local r,g,b,a = image_data:getPixel(x-1, y-1)
            local initx = math.floor((x-1)*scale)
            local inity = math.floor((y-1)*scale)
            data:setPixel(initx,inity, r,g,b,a )
            for dx=0,scale-1 do
                for dy=0,scale-1 do
                    data:setPixel(initx+dx,inity+dy, r,g,b,a)
                end
            end
        end
    end
    return data
end

function IMD.imgdata_mat(image_data)
    local mat={}
    local sx, sy=image_data:getDimensions()
    for y=1, sy do
        local row={}
        for x=1, sx do
            local _,_,_,a = image_data:getPixel(x-1, y-1)
            if a==0 then row[x]=0 else row[x] = 1 end
        end
        mat[y] = row
    end
    return mat
end

function IMD.mask_imd(image_data,...)
    local colors = {...}
    if #colors==0 then colors={{0,0,0,1}} end
    local color = colors[1]
    local sx, sy = image_data:getDimensions()
    local data = love.image.newImageData(sx,sy)
    for x=1, sx do
        for y=1, sy do
            local _,_,_,a = image_data:getPixel(x-1, y-1)
            if a~=0 then
                if #colors>1 then
                    color = colors[love.math.random(#colors)]
                    color = {color[1],color[2],color[3],love.math.random()}
                end
                data:setPixel(x-1,y-1,unpack(color))
            end
        end
    end
    return data
end

function IMD.text_imd(text,size,color,fnt)
    text = text or ' '
    size = size or 16
    color = color or WHITE
    local font
    if fnt then font = love.graphics.newFont(fnt,size)
    else font = love.graphics.newFont(size) end

    local sx,sy = font:getWidth(text),font:getHeight()
    local canvas = love.graphics.newCanvas(sx,sy)
    love.graphics.setCanvas(canvas)
    love.graphics.setFont(font)
    love.graphics.setColor(color)
    love.graphics.setBlendMode('alpha')
    love.graphics.print(text)
    love.graphics.setColor(WHITE)
    love.graphics.setCanvas()
    local data = canvas:newImageData()
    return data
end

function IMD.merge_imd(image_data1,image_data2,x,y,blend)
    x = x or 0
    y = y or 0
    blend = blend or 'alpha'
    local sx, sy = image_data1:getDimensions()
    local canvas = love.graphics.newCanvas(sx,sy)
    love.graphics.setCanvas(canvas)
    love.graphics.setBlendMode(blend)
    love.graphics.draw(love.graphics.newImage(image_data1))
    love.graphics.draw(love.graphics.newImage(image_data2),x,y)
    love.graphics.setBlendMode('alpha')
    love.graphics.setCanvas()
    local data = canvas:newImageData()
    return data
end

function IMD.splash_imd(image_data,num,radius,maincolor,borcolor)
    local sx, sy = image_data:getDimensions()
    local data = love.image.newImageData(sx,sy)
    data:paste(image_data,0,0,0,0,sx,sy)
    num = num or 5
    radius = radius or 10
    radius = math.floor(math.min(radius,math.min(sx/2,sy/2)))-2
    maincolor = maincolor or {0,0,0,0}
    borcolor = borcolor or {0,0,0,1}
    local mod = {{1,1},{-1,1},{1,-1},{-1,-1}}
    for _=1,num do
        local rand_radius=love.math.random(radius)
        -- print(rand_radius)
        local all_dots=IMD.circle_allpx(rand_radius)
        local dots=IMD.circle_px(rand_radius)
        local cenx=love.math.random(radius+2,sx-radius-2)
        local ceny=love.math.random(radius+2,sy-radius-2)

        for i=1, #all_dots do
            if i%rand_radius==0 then
                data:setPixel(cenx+all_dots[i][1],
                              ceny+all_dots[i][2],maincolor)
            end
        end
        for i=1,#dots do
            local _,_,_,a = image_data:getPixel(cenx+dots[i][1],
                                                ceny+dots[i][2])
            if a>0  then
                if i%rand_radius==0 then
                    for m=1, #mod do
                        data:setPixel(cenx+mod[m][1]+dots[i][1],
                                  ceny+mod[m][2]+dots[i][2],
                                {borcolor[1],borcolor[2],borcolor[3],
                                love.math.random()})
                    end
                end
            end
        end
        for _=1,#dots/4 do
            local coords=all_dots[love.math.random(#all_dots)]
            for m=1,#mod do
                data:setPixel(cenx+mod[m][1]+coords[1],
                              ceny+mod[m][2]+coords[2],maincolor)
            end
        end
    end
    return data
end

function IMD.random_imd(sx,sy,num,blend,...)
    local colors = {...}
    if #colors==0 then colors={{1,1,1,1}} end
    local canvas = love.graphics.newCanvas(sx,sy)
    num = num or 10
    blend = blend or 'alpha'
    love.graphics.setCanvas(canvas)
    love.graphics.setBlendMode(blend)
    for color=1, #colors do
        local points = {}
        for i=1,num do
            -- 0.5 offset
            local x = love.math.random(sx)+0.5
            local y = love.math.random(sy)+0.5
            points[i]={x,y,unpack(colors[color])}
        end
        love.graphics.points(points)
    end
    love.graphics.setBlendMode('alpha')
    love.graphics.setCanvas()
    local data = canvas:newImageData()
    return data
end

function IMD.rotate_imd(image_data, side)
    local sx, sy = image_data:getDimensions()
    local data
    if side=='CW' or side=='CCW' then
        data = love.image.newImageData(sy,sx)
    else
        data = love.image.newImageData(sx,sy)
    end
    local initx
    local inity
    for x=1,sx do
        for y=1,sy do
            local r,g,b,a = image_data:getPixel(x-1, y-1)
            if side=='CW' then
                initx = sy-y
                inity = x-1
            elseif side=='CCW' then
                initx = y-1
                inity = sx-x
            elseif side=='HFLIP' then
                initx = sx-x
                inity = y-1
            elseif side=='VFLIP' then
                initx = x-1
                inity = sy-y
            else
                initx = x-1
                inity = sy-y
            end
            data:setPixel(initx,inity, r,g,b,a )
        end
    end
    return data
end

function IMD.slice_imd(image_data,tilex,tiley,numx,numy)
    numx=numx or 1
    numy=numy or 1
    local sx, sy = image_data:getDimensions()
    local arr = {}
    for y=0,numy-1 do
        for x=0,numx-1 do
            local data = love.image.newImageData(tilex,tiley)
            -- source, destx, desty, sourcex, sourcey, source wid, source hei
            data:paste(image_data,0,0,x*tilex, y*tiley,sx,sy)
            arr[#arr+1] = data
        end
    end
    return arr
end

function IMD.circle_allpx(radius)
    local  arr = {}
    for i=1,radius do
        local tmp = IMD.circle_px(i)
        for j=1, #tmp do
            arr[#arr+1] = tmp[j]
        end
    end
    return arr
end

function IMD.circle_px(radius)
    local  arr = {}
    for grad=0,359 do
        grad = math.rad(grad)
        local xdot = radius * math.cos(grad)
        local ydot = radius * math.sin(grad)
        arr[#arr+1] = {xdot, ydot}
    end
    return arr
end

return IMD
