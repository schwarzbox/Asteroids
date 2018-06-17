#!/usr/bin/env love
-- LOVFL
-- 0.1
-- Files Function (love2d)
-- lovfl.lua

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

-- 0.2
-- lfs system

local unpack = table.unpack or unpack
local lfs = love.filesystem
local FL={}

function FL.load_all(dir,...)
    local extensions={...}
    local files = lfs.getDirectoryItems(dir)
    local arr = {}
    for i=1,#files do
        local path = dir .. '/' .. files[i]
        local ext = path:match('[^.]+$')
        local base = path:match('([^/]+)[%.]')
        for e=1,#extensions do
            if (lfs.getInfo(path).type=='file' and ext==extensions[e]) then
                arr[base] = path
            end
        end
    end
    return arr
end

function FL.tree(dir,arr,verbose)
    dir = dir or ''
    arr = arr or {}
    local files = lfs.getDirectoryItems(dir)
    if verbose then print('dir', dir) end
    for i=1, #files do
        local path = dir..'/'..files[i]
        if lfs.getInfo(path).type=='file' then
            arr[#arr+1] = path
            if verbose then print(#arr,path) end
        elseif lfs.getInfo(path).type=='directory' then
            FL.tree(path,arr,verbose)
        end
    end
    return arr
end

function FL.load_file(path)
    local file = io.open(path,'r')
    local content = file:read('*a')
    file:close()
    return content
end

function FL.save_file(path,datastr)
    local file = io.open(path,'w')
    file:write(datastr)
    file:close()
end

function FL.copy_file(path,dir)
    local newpath = dir..'/'..path:match('[^/]+$')
    local datastr = FL.load_file(path)
    FL.save_file(newpath,datastr)
end

function FL.copy_love(file,dir)
    if not lfs.getInfo(dir) then
        lfs.createDirectory(dir)
    end
    FL.copy_file(file:getFilename(),
                 lfs.getSaveDirectory()..'/'..dir)
    love.system.openURL('file://'..lfs.getSaveDirectory())
end

function FL.save_love(path,datastr)
    local file = lfs.newFile(path,'w')
    file:write(datastr)
    file:close()
end

function FL.load_love(path)
    local chunk, err = lfs.load(path)
    if not err then return chunk() end
end

return FL
