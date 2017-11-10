
local acc = require 'accursed'

local class = require 'class'

local Tilemap = class.base()


function Tilemap:init(options)
    if options.file then
        self:read(options.file)
    elseif options.nlayers and options.w and options.h then
        self:create_empty(options.nlayers, options.w, options.h)
    else
        return nil, 'provide either a file name or empty map dimensions (nlayers, w, h)'
    end
end


function Tilemap:read(filename)
    self._tilemap = acc.tilemap.read(filename)
    if self._tilemap == nil then
        error('failed loading tile map')
    end
    --acc.tilemap.get(self._tilemap, self)
end


function Tilemap:write(filename)
    return acc.tilemap.write(self._tilemap, filename)
end


function Tilemap:create_empty(nlayers, w, h)
    self._tilemap = acc.tilemap.create_empty(nlayers, w, h)
    --acc.tilemap.get(self._tilemap, self)
    self.nlayers = nlayers
    self.w = w
    self.h = h
    for k,v in pairs(self) do print(k,v) end
end


function Tilemap:draw_layer(image, layer, px, py, pw, ph)
    acc.tilemap.draw_layer(self._tilemap, image._image, layer, px, py, pw, ph)
end

--[[
-- TODO

function Tilemap:get_tile(layer, x, y)
    return acc.tilemap.get_tile(self._tilemap, layer, x, y)
end
--]]

function Tilemap:set_tile(layer, x, y, tilex, tiley)
    acc.tilemap.set_tile(self._tilemap, layer, x, y, tilex, tiley)
end


function Tilemap:export(rect)
    return acc.tilemap.export_slice(self._tilemap, rect.x, rect.y, rect.w, rect.h)
end

function Tilemap:patch(data, rect)
    acc.tilemap.patch(self._tilemap, data, rect.x, rect.y, rect.w, rect.h)
end

return Tilemap

