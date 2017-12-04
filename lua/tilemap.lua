
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

    self.interactCallbacks = {}
end


function Tilemap:read(filename)
    self._tilemap = ant.tilemap.read(filename)
    if self._tilemap == nil then
        error('failed loading tile map')
    end
    -- set own properties
    ant.tilemap.get(self._tilemap, self)
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


function Tilemap:draw_layer(image, layer, px, py, pw, ph, counter)
    ant.tilemap.draw_layer(self._tilemap, image._image, layer, px, py, pw, ph, counter)
end

function Tilemap:draw_layer_flags(image, layer, px, py, pw, ph)
    ant.tilemap.draw_layer_flags(self._tilemap, image._image, layer, px, py, pw, ph)
end

function Tilemap:draw_layer_objects(layer, px, py, pw, ph)
    ant.tilemap.draw_layer_objects(self._tilemap, layer, px, py, pw, ph)
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

function Tilemap:get_flags(layer, x, y)
    return ant.tilemap.get_flags(self._tilemap, layer, x, y)
end

function Tilemap:set_flags(layer, x, y, mask)
    ant.tilemap.set_flags(self._tilemap, layer, x, y, mask)
end

function Tilemap:clear_flags(layer, x, y, mask)
    ant.tilemap.clear_flags(self._tilemap, layer, x, y, mask)
end

function Tilemap:overwrite_flags(layer, x, y, mask)
    ant.tilemap.overwrite_flags(self._tilemap, layer, x, y, mask)
end

function Tilemap:export(rect)
    return ant.tilemap.export_slice(self._tilemap, rect.x, rect.y, rect.w, rect.h)
end

function Tilemap:patch(data, rect)
    ant.tilemap.patch(self._tilemap, data, rect.x, rect.y, rect.w, rect.h)
end


function Tilemap:addObject(object)
    ant.tilemap.addobject(self._tilemap, object._object)
    object._tilemap = self._tilemap
end

function Tilemap:removeObject(object)
    ant.tilemap.removeobject(self._tilemap, object._object)
    object._tilemap = nil
end

function Tilemap:updateObjects()
    ant.tilemap.updateobjects(self._tilemap)
end


function Tilemap:setCameraObject(object)
    ant.tilemap.setCameraObject(self._tilemap, object._object)
end

function Tilemap:drawLayerAtCameraObject(image, layer, pw, ph, counter)
    ant.tilemap.drawLayerAtCameraObject(self._tilemap, image._image, layer, pw, ph, counter)
end

function Tilemap:drawObjectsAtCameraObject(layer, pw, ph)
    ant.tilemap.drawObjectsAtCameraObject(self._tilemap, layer, pw, ph)
end


function Tilemap:getTileAnimationInfo(layer, x, y)
    return ant.tilemap.getTileAnimationInfo(self._tilemap, layer, x, y)
end


function Tilemap:setTileAnimationInfo(layer, x, y, period, count)
    if period == nil then period = -1 end
    if count == nil then count = -1 end
    ant.tilemap.setTileAnimationInfo(self._tilemap, layer, x, y, period, count)
end


function Tilemap:getTileIndex(layer, mapx, mapy)
    return (layer * self.w * self.h) + (mapy * self.w) + mapx
end

function Tilemap:setInteractCallback(layer, mapx, mapy, cb)
    local index = self:getTileIndex(layer, mapx, mapy)
    self.interactCallbacks[index] = cb
end

function Tilemap:clearInteractCallback(layer, mapx, mapy)
    local index = self:getTileIndex(layer, mapx, mapy)
    self.interactCallbacks[index] = nil
end

function Tilemap:runInteractCallback(layer, mapx, mapy, object)
    local index = self:getTileIndex(layer, mapx, mapy)
    local cb = self.interactCallbacks[index]
    if type(cb) == 'function' then
        cb(object)
    end
end

return Tilemap

