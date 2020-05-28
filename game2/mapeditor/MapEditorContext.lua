local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local Class = require 'class'
local Util = require 'Util'
local bind = Util.bind
local Object = require 'object'
local Engine = require 'engine'

local Model = require 'game2.mapeditor.Model'
local SearchBar = require 'game2.mapeditor.SearchBar'

-- TODO
local getTileInfos = function(map)
  local infos = map:getAllTileInfos()
end

local MapEditorContext = Class(Context)

MapEditorContext.tileInfoModules = {
  'res.tiles.waves',
  'res.tiles.demo.demo',
}

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
  -- TODO how should this be set?
  self.editLayer = 0

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
          focusSearchBar = bind(self.focusSearchBar, self)
        },
        keys = {
          W = 'goNorth',
          A = 'goWest',
          S = 'goSouth',
          D = 'goEast',
          Z = 'undo',
          Y = 'redo',
          Escape = 'quit',
          ['/'] = 'focusSearchBar',
        },
        mouseDown = bind(self.mouseDown, self),
        mouseUp = bind(self.mouseUp, self),
        mouseMotion = bind(self.mouseMotion, self),
      }
    })

    self.searchBar = SearchBar{imageCache = self.imageCache}
  end)
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
  print('open map editor')
  self.tileInfos = getTileInfos(self.map)

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
  self.map:removeObject(self.camera)
  self.map:setCameraObject(self.originalCameraObject)
  Context.returnControlToParent(self)
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
  if self.editMode then
    self.editMode:mouseMotion(x, y, dx, dy)
  end

  self.mouseX = x
  self.mouseY = y
  self:updateMouseMapCoords()
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
