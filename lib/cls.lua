#!/usr/bin/env lua
-- CLS
-- 1.0
-- OOP (lua)
-- cls.lua

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

-- 2.0
-- convert table to class

if arg[0] then print('1.0 CLS OOP (lua)', arg[0]) end
if arg[1] then print('1.0 CLS OOP (lua)',arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local CLS = {}
function CLS.Cls(Super,class)
    Super = Super or {}
    class = class or {}
    class.Super = Super
    class.total = 0
    local meta = {__index=Super}

    meta.__call = function(self,o) o = o or {} self.__index = self
                    self = setmetatable(o, self)
                    if self.new then self.new(self, o) end
                    return self
                end
    -- merge class
    meta.__add = function (self, oth)
                    local New = CLS.Cls(self)
                    for k,v in pairs(oth) do New[k] = v  end
                    return New
                end
    -- copy metamethods
    for k,v in pairs(Super) do
        if rawget(Super,k) and k:match('^__') and type(v)=='function' then
            class[k] = v
        end
    end
    return setmetatable(class, meta)
end

return CLS
