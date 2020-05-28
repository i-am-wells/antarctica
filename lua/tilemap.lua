
local ant = require 'antarctica'
--local SoundChannels = require 'soundChannels'
local AudioSource = require 'audioSource'
local Class = require 'class'

local Object = require 'object'

local tablecopy = function(t)
  local copy = {}
  for k, v in pairs(t) do copy[k] = v end
  return copy
end

-- TODO make a wrapper class for tilemap + soundchannels
--local Tilemap = Class(SoundChannels)
local Tilemap = Class()

local AnimationFrame = Class()
Tilemap.AnimationFrame = AnimationFrame

function AnimationFrame:init(arg)
  self.tileX = arg.tileX or 0
  self.duration = arg.duration or -1
end

local TileInfo = Class()
Tilemap.TileInfo = TileInfo

function TileInfo:init(arg)
  self.image = arg.image
  self.name = arg.name
  self.flags = arg.flags or 0
  self.w = arg.w
  self.h = arg.h
  self.sx = arg.sx or 0
  self.sy = arg.sy or 0
  self.dx = arg.dx or 0
  self.dy = arg.dy or 0
  self.frames = tablecopy(arg.frames or {})
end

function Tilemap:init(options)
  if options.file then
    self:read(options.file)
  elseif options.nlayers and options.w and options.h then
    self:createEmpty(options.nlayers, options.w, options.h, options.tw, options.th)
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
  self._tilemap = ant.tilemap.read(filename, self)
  if self._tilemap == nil then
    error('failed loading tile map')
  end
end

function Tilemap:write(filename)
  return ant.tilemap.write(self._tilemap, filename)
end

function Tilemap:createEmpty(nlayers, w, h, tw, th)
  self._tilemap = ant.tilemap.createEmpty(nlayers, w, h, tw, th)
  self.nlayers = nlayers
  self.w = w
  self.h = h
  self.tw = tw
  self.th = th
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

function Tilemap:drawLayer(layer, px, py)
  ant.tilemap.drawLayer(self._tilemap, layer, px, py)
end

function Tilemap:drawLayerObjects(layer, px, py)
  ant.tilemap.drawLayerObjects(self._tilemap, layer, px, py)
end

function Tilemap:setTileInfoIdxForTile(layer, x, y, idx)
  ant.tilemap.setTileInfoIdxForTile(self._tilemap, layer, x, y, idx)
end

function Tilemap:getTileInfoIdxForTile(layer, x, y)
  return ant.tilemap.getTileInfoIdxForTile(self._tilemap, layer, x, y)
end

function Tilemap:getTileInfo(layer, x, y)
  local info, flags = ant.tilemap.getTileInfo(self._tilemap, layer, x, y)
  for i = 1, #info.frames do
    info.frames[i] = AnimationFrame(info.frames[i])
  end
  return info, flags
end

function Tilemap:setScreenSize(screenW, screenH)
  ant.tilemap.setScreenSize(self._tilemap, screenW, screenH)
end

-- TODO maybe move this to engine
function Tilemap:advanceClock()
  ant.tilemap.advanceClock(self._tilemap)
end

function Tilemap:getAllTileInfos()
  return ant.tilemap.getAllTileInfos(self._tilemap)
end

function Tilemap:setTileInfo(idx, tileInfo)
  ant.tilemap.setTileInfo(self._tilemap, idx, tileInfo)
end

function Tilemap:addTileInfo(tileInfo)
  ant.tilemap.addTileInfo(self._tilemap, tileInfo)
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

function Tilemap:getCameraDrawLocation()
  return ant.tilemap.getCameraDrawLocation(self._tilemap)
end

function Tilemap:drawLayerAtCameraObject(layer)
  ant.tilemap.drawLayerAtCameraObject(self._tilemap, layer)
end

function Tilemap:drawObjectsAtCameraObject(layer)
  ant.tilemap.drawObjectsAtCameraObject(self._tilemap, layer)
end

-- TODO what was this for?
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

