
local ant = require 'antarctica'

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
    self._tilemap = ant.tilemap.read(filename)
    if self._tilemap == nil then
        error('failed loading tile map')
    end
    --ant.tilemap.get(self._tilemap, self)
end


function Tilemap:write(filename)
    return ant.tilemap.write(self._tilemap, filename)
end


function Tilemap:create_empty(nlayers, w, h)
    self._tilemap = ant.tilemap.create_empty(nlayers, w, h)
    --ant.tilemap.get(self._tilemap, self)
    self.nlayers = nlayers
    self.w = w
    self.h = h
    for k,v in pairs(self) do print(k,v) end
end


function Tilemap:draw_layer(image, layer, px, py, pw, ph)
    ant.tilemap.draw_layer(self._tilemap, image._image, layer, px, py, pw, ph)
end

--[[
-- TODO

function Tilemap:get_tile(layer, x, y)
    return ant.tilemap.get_tile(self._tilemap, layer, x, y)
end
--]]

function Tilemap:set_tile(layer, x, y, tilex, tiley)
    ant.tilemap.set_tile(self._tilemap, layer, x, y, tilex, tiley)
end


function Tilemap:export(rect)
    return ant.tilemap.export_slice(self._tilemap, rect.x, rect.y, rect.w, rect.h)
end

function Tilemap:patch(data, rect)
    ant.tilemap.patch(self._tilemap, data, rect.x, rect.y, rect.w, rect.h)
end

return Tilemap

