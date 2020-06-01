local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local Class = require 'class'
local Util = require 'Util'
local bind = Util.bind
local Object = require 'object'
local Engine = require 'engine'

local Model = require 'game2.mapeditor.Model'
local SearchBar = require 'game2.mapeditor.SearchBar'
local Eyedropper = require 'game2.mapeditor.editmodes.Eyedropper'

local MapEditorContext = Class(Context)

MapEditorContext.tileInfoModules = {
  'res.tiles.waves',
  'res.tiles.demo.demo',
}

local minScale, maxScale = 0.125, 4

function MapEditorContext:init(arg)
  if __dbg then
    assert(arg.engine)
    assert(arg.font)
    assert(arg.map)
  end

  self.engine = arg.engine
  self.imageCache = arg.imageCache
  self.map = arg.map

  self.font = self.imageCache:get{
    file = __rootdir .. '/res/textbold-9x15.png',
    engine = self.engine,
    tilew = 9,
    tileh = 15,
  }
  self.smallFont = self.imageCache:get{
    file = __rootdir .. '/res/text-5x9.png',
    engine = self.engine,
    tilew = 5,
    tileh = 9
  }

  self.model = Model{map=arg.map}
  self.editLayer = 0
  self.isEyedropperActive = false

  self.stepSizeX = arg.map.tw
  self.stepSizeY = arg.map.th

  self.mouseX = 0
  self.mouseY = 0
  self:updateMouseMapCoords()

  Util.using({engine=arg.engine, context=self}, function()
    Context.init(self, {
      draw = bind(self.draw, self),
      inputHandler = InputHandler{
        actions = {
          goNorth = bind(self.goNorth, self),
          goWest = bind(self.goWest, self),
          goSouth = bind(self.goSouth, self),
          goEast = bind(self.goEast, self),
          undo = bind(self.undo, self),
          redo = bind(self.redo, self),
          quit = bind(self.quit, self),
          focusSearchBar = bind(self.focusSearchBar, self),
          eyedropper = bind(self.eyedropper, self),
          floodFill = bind(self.floodFill, self),
        },
        keys = {
          W = 'goNorth',
          A = 'goWest',
          S = 'goSouth',
          D = 'goEast',
          Z = 'undo',
          Y = 'redo',
          F = 'floodFill',
          Escape = 'quit',
          ['/'] = 'focusSearchBar',
          ['Left Ctrl'] = 'eyedropper',
          ['Right Ctrl'] = 'eyedropper',
        },
        allowKeyRepeat = true,
        mouseDown = bind(self.mouseDown, self),
        mouseUp = bind(self.mouseUp, self),
        mouseMotion = bind(self.mouseMotion, self),
        mouseWheel = bind(self.mouseWheel, self),
      }
    })

    self.searchBar = SearchBar{
      mapEditor = self,
      imageCache = self.imageCache
    }
  end)
end

function MapEditorContext:floodFill(keyState)
  if keyState == 'down' then
    if self.editMode then
      self.editMode.isFloodFill = true
    end
  elseif keyState == 'up' then
    if self.editMode then
      self.editMode.isFloodFill = false
    end
  end
end

function MapEditorContext:eyedropper(keyState)
  -- Activate eyedropper mode when eyedropper key is held
  if keyState == 'down' and not self.isEyedropperActive then
    self.isEyedropperActive = true
    self.editMode = Eyedropper{mapEditor = self}
  elseif keyState == 'up' and self.isEyedropperActive then
    self.isEyedropperActive = false
    self.editMode = self.editMode:getFinalEditMode()
  end
end

function MapEditorContext:goNorth(keyState)
  if keyState == 'down' then
    self.camera:move(0, -self.stepSizeY)
    self:updateMouseMapCoords()
  end
end
function MapEditorContext:goWest(keyState)
  if keyState == 'down' then
    self.camera:move(-self.stepSizeX, 0)
    self:updateMouseMapCoords()
  end
end
function MapEditorContext:goSouth(keyState)
  if keyState == 'down' then
    self.camera:move(0, self.stepSizeY)
    self:updateMouseMapCoords()
  end
end
function MapEditorContext:goEast(keyState)
  if keyState == 'down' then
    self.camera:move(self.stepSizeX, 0)
    self:updateMouseMapCoords()
  end
end

function MapEditorContext:undo(keyState, key, mod)
  if keyState == 'down' and mod & Engine.keymod.ctrl then
    self.model:undo()
  end
end

function MapEditorContext:redo(keyState, key, mod)
  if keyState == 'down' and mod & Engine.keymod.ctrl then
    self.model:redo()
  end
end

function MapEditorContext:quit(keyState)
  if keyState == 'down' then
    self:returnControlToParent()
  end
end

function MapEditorContext:takeControlFrom(parent)
  self.tileInfos = self.map:getAllTileInfos()
  self.origScreenW, self.origScreenH = self.engine:getLogicalSize()
  self.scale = 1

  -- TODO parent should implement getCameraObject or something
  self.originalCameraObject = parent.hero
  if not self.camera then
    self.camera = Object(parent.hero)
    self.camera:setVisible(false)
    self.map:addObject(self.camera)
  end
  self.map:setCameraObject(self.camera)
  Context.takeControlFrom(self, parent)
end

function MapEditorContext:returnControlToParent()
  self:zoom(1)
  self.map:removeObject(self.camera)
  self.map:setCameraObject(self.originalCameraObject)
  Context.returnControlToParent(self)
end

function MapEditorContext:getTileInfoIdx(tileName)
  for i, info in ipairs(self.tileInfos) do
    if info.name == tileName then
      return i - 1
    end
  end
  return nil
end

function MapEditorContext:addTileInfo(info)
  if not info.image then
    info.image = self.imageCache:get{
      engine = self.engine,
      file = info.imagePath,
    }
  end

  self.map:addTileInfo(info)
  self.tileInfos[#self.tileInfos + 1] = info
end

function MapEditorContext:setEditMode(editMode)
  self.editMode = editMode
end

function MapEditorContext:focusSearchBar()
  self.searchBar:takeControlFrom(self)
end

function MapEditorContext:screenToMap(x, y)
  local screenW, screenH = self.engine:getLogicalSize()
  local cornerX, cornerY = self.map:getCameraDrawLocation(screenW, screenH)
  return (x + cornerX) // self.map.tw, (y + cornerY) // self.map.th
end

function MapEditorContext:mapToScreen(x, y)
  local screenW, screenH = self.engine:getLogicalSize()
  local cornerX, cornerY = self.map:getCameraDrawLocation(screenW, screenH)
  return (x * self.map.tw) - cornerX, (y * self.map.th) - cornerY
end

function MapEditorContext:zoom(scale)
  self.scale = scale
  -- Scale images
  -- TODO skip UI images, if any
  --self.imageCache:forEach(function(key, image)
  --  image:scale(scale)
  --end)
  local newScreenW, newScreenH = self.origScreenW * scale, self.origScreenH * scale
  self.engine:setLogicalSize(newScreenW, newScreenH)
  self.map:setScreenSize(newScreenW, newScreenH)
end

function MapEditorContext:mouseDown(x, y, button)
  -- TODO pass mouse down to UI

  local mapX, mapY = self:screenToMap(x, y)
  if self.editMode then
    self.editMode:mouseDown(mapX, mapY, x, y, button)
  end
end

function MapEditorContext:mouseUp(x, y, button)
  local mapX, mapY = self:screenToMap(x, y)
  if self.editMode then
    self.editMode:mouseUp(mapX, mapY, x, y, button)
  end
end

function MapEditorContext:updateMouseMapCoords()
  self.mouseMapX, self.mouseMapY = self:screenToMap(self.mouseX, self.mouseY)
end

function MapEditorContext:mouseMotion(x, y, dx, dy)
  self.mouseX = x
  self.mouseY = y
  self:updateMouseMapCoords()

  if self.editMode then
    self.editMode:mouseMotion(self.mouseMapX, self.mouseMapY, x, y, dx, dy)
  end
end

function MapEditorContext:mouseWheel(wheelX, wheelY)
  -- Zoom in or out
  if wheelY < 0 then
    self.scale = self.scale / 2
    if self.scale < minScale then
      self.scale = minScale
    end
  elseif wheelY > 0 then
    self.scale = self.scale * 2
    if self.scale > maxScale then
      self.scale = maxScale
    end
  end
  self:zoom(self.scale)
end

function MapEditorContext:draw()
  if self.parentContext then
    self.parentContext:draw()
  end

  if self.editMode then
    self.editMode:draw()
  end
end

return MapEditorContext
