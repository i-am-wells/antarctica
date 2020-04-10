local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local Class = require 'class'
local Util = require 'Util'
local bind = Util.bind
local Object = require 'object'
local Engine = require 'engine'

local Model = require 'game2.mapeditor.Model'

local MapEditorContext = Class(Context)

function MapEditorContext:init(arg)
  if __dbg then
    assert(arg.engine)
    assert(arg.font)
    assert(arg.map)
    assert(arg.tileset)
  end

  self.engine = arg.engine
  self.font = arg.font
  self.map = arg.map
  self.tileset = arg.tileset

  self.model = Model{map=arg.map}
  self.editLayer = 1

  self.stepSizeX = arg.tileset.tw
  self.stepSizeY = arg.tileset.th

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
          quit = bind(self.returnControlToParent, self),
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

    -- TODO implement search bar
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

function MapEditorContext:takeControlFrom(parent)
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
  return (x + cornerX) // self.tileset.tw, (y + cornerY) // self.tileset.th
end

function MapEditorContext:mapToScreen(x, y)
  local screenW, screenH = self.engine:getLogicalSize()
  local cornerX, cornerY = self.map:getCameraDrawLocation(screenW, screenH)
  return (x * self.tileset.tw) - cornerX, (y * self.tileset.th) - cornerY
end

function MapEditorContext:mouseDown(x, y, button)
  if __dbg then
    assert(self.tileEditInProgress == nil)
  end
  self.tileEditInProgress = self.model:makeTileEdit()

  local tx, ty, flags = self.model:getTileToDraw()
  local mapX, mapY = self:screenToMap(x, y)
  self.tileEditInProgress:addTile(self.editLayer, mapX, mapY, tx, ty, flags)
end

function MapEditorContext:mouseUp(x, y, button)
  if self.tileEditInProgress then
    self.model:update(self.tileEditInProgress)
    self.tileEditInProgress = nil
  end
end

function MapEditorContext:updateMouseMapCoords()
  self.mouseMapX, self.mouseMapY = self:screenToMap(self.mouseX, self.mouseY)
end

function MapEditorContext:mouseMotion(x, y, dx, dy)
  if self.tileEditInProgress then
    local mapX, mapY = self:screenToMap(x, y)
    if not self.tileEditInProgress:isSameLocationAsLast(self.editLayer, mapX, mapY) then
      local tx, ty, flags = self.model:getTileToDraw()
      self.tileEditInProgress:addTile(self.editLayer, mapX, mapY, tx, ty, flags)
    end
  end

  self.mouseX = x
  self.mouseY = y
  self:updateMouseMapCoords()
end

function MapEditorContext:draw(...)
  if self.parentContext then
    self.parentContext:draw(...)
  end

  self.font:drawText('editing', 0, 0, 200)

  self.engine:setColor(0, 255, 0, 255)
  local rectX, rectY = self:mapToScreen(self.mouseMapX, self.mouseMapY)
  self.engine:drawRect(rectX, rectY, self.tileset.tw, self.tileset.th)
end

return MapEditorContext
