
local ant = require 'antarctica'
--local SoundChannels = require 'soundChannels'
local AudioSource = require 'audioSource'
local Class = require 'class'

local Object = require 'object'

-- TODO make a wrapper class for tilemap + soundchannels
--local Tilemap = Class(SoundChannels)
local Tilemap = Class()

-- Keep in sync with flags in tilemap.h
local flags = {
  bumpSouth = 0x100,
  bumpWest = 0x200,
  bumpNorth = 0x400,
  bumpEast = 0x800,
}
flags.bumpAll = flags.bumpSouth | flags.bumpWest | flags.bumpNorth | flags.bumpEast
Tilemap.flags = flags

function Tilemap:init(options)
    if options.file then
        self:read(options.file)
    elseif options.nlayers and options.w and options.h then
        self:createEmpty(options.nlayers, options.w, options.h)
    else
        return nil, 'provide either a file name or empty map dimensions (nlayers, w, h)'
    end

    self.interactCallbacks = {}
    self.objects = {}

    self.name = options.file

    -- Set up sound channels
    --SoundChannels.init(self, options)

    if options.objects then
        self:populate(options.objects, options.resourceMan)
    end
end

function Tilemap:populate(objects, resourceMan)
    for _, frozenObject in ipairs(objects) do
        local newObject = Object.fromTable(frozenObject, resourceMan)

        self:addObject(newObject)
    end
end

function Tilemap:dumpObjects()
    local frozenObjects = {}
    for _, o in pairs(self.objects) do
        table.insert(frozenObjects, o:toTable())
    end

    return frozenObjects
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

function Tilemap:createEmpty(nlayers, w, h)
    self._tilemap = ant.tilemap.createEmpty(nlayers, w, h)
    self.nlayers = nlayers
    self.w = w
    self.h = h
end

function Tilemap:clean(cleanX, cleanY)
    for l = 0, self.nlayers - 1 do
        for y = 0, self.h - 1 do
            for x = 0, self.w - 1 do
                self:setTile(l, x, y, cleanX, cleanY)
            end
        end
    end
end

function Tilemap:drawLayer(image, layer, px, py, pw, ph, counter)
    ant.tilemap.drawLayer(self._tilemap, image._image, layer, px, py, pw, ph, counter, false)
end

function Tilemap:drawLayerFlags(image, layer, px, py, pw, ph)
    ant.tilemap.drawLayerFlags(self._tilemap, image._image, layer, px, py, pw, ph, counter, true)
end

function Tilemap:drawLayerObjects(layer, px, py, pw, ph, counter)
    ant.tilemap.drawLayerObjects(self._tilemap, layer, px, py, pw, ph, counter)
end

function Tilemap:getTile(layer, x, y)
    return ant.tilemap.getTile(self._tilemap, layer, x, y)
end

function Tilemap:setTile(layer, x, y, tilex, tiley)
    ant.tilemap.setTile(self._tilemap, layer, x, y, tilex, tiley)
end

function Tilemap:getFlags(layer, x, y)
    return ant.tilemap.getFlags(self._tilemap, layer, x, y)
end

function Tilemap:setFlags(layer, x, y, mask)
    ant.tilemap.setFlags(self._tilemap, layer, x, y, mask)
end

function Tilemap:clearFlags(layer, x, y, mask)
    ant.tilemap.clearFlags(self._tilemap, layer, x, y, mask)
end

function Tilemap:overwriteFlags(layer, x, y, mask)
    ant.tilemap.overwriteFlags(self._tilemap, layer, x, y, mask)
end

function Tilemap:export(rect)
    return ant.tilemap.exportSlice(self._tilemap, rect.x, rect.y, rect.w, rect.h)
end

function Tilemap:patch(data, rect)
    ant.tilemap.patch(self._tilemap, data, rect.x, rect.y, rect.w, rect.h)
end


function Tilemap:addObject(object)
    ant.tilemap.addObject(self._tilemap, object._object)
    object._tilemap = self._tilemap
    object.map = self

    self.objects[object] = object

    --[[
    if object.isA[AudioSource] then
        self:addSource(object)
    end
    --]]
end

function Tilemap:removeObject(object)
    ant.tilemap.removeObject(self._tilemap, object._object)
    object._tilemap = nil
    object.map = nil

    self.objects[object] = nil

    --[[
    if object.isA[AudioSource] then
        self:removeSource(object)
    end
    --]]
end


function Tilemap:updateObjects()
    -- reallocate sound channels
    --self:reallocateChannels()
    
    ant.tilemap.updateObjects(self._tilemap)
end


function Tilemap:setCameraObject(object)
    ant.tilemap.setCameraObject(self._tilemap, object._object)
end

function Tilemap:drawLayerAtCameraObject(image, layer, pw, ph, counter, draw_flags)
    ant.tilemap.drawLayerAtCameraObject(self._tilemap, image._image, layer, pw, ph, counter, draw_flags or false)
end

function Tilemap:drawObjectsAtCameraObject(img, layer, pw, ph, counter, draw_flags)
    ant.tilemap.drawObjectsAtCameraObject(self._tilemap, img._image, layer, pw, ph, counter, draw_flags or false)
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

function Tilemap:abortUpdateObjects()
    ant.tilemap.abortUpdateObjects(self._tilemap)
end

function Tilemap:setSparseLayer(layer, isSparse)
  ant.tilemap.setSparseLayer(self._tilemap, layer, isSparse)
end

function Tilemap:print(selX, selY)
    local layer = 0

    local selX, selY = 0 or selX, 0 or selY

    for y = 0, self.h - 1 do
        local row = ""
        for x = 0, self.w - 1 do
            local tx, ty = self:getTile(layer, x, y)
            if tx == selX and ty == selY then
                row = row + "#"
            else
                row = row + "."
            end
            print(row)
        end
    end
end

return Tilemap

