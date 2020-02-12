local Class = require 'class'
local Object = require 'object'

local Menu = require 'game.menu'
local objectPaths = require 'game.objectPaths'

local ObjectEditor = Class()

ObjectEditor.defaultFile = 'objectEditorOut.state'

function ObjectEditor:init(opt)
  self.devSession = opt.devSession
  self.game = opt.devSession.game
  self.engine = self.game.engine
  self.resourceMan = self.game.resourceMan

  -- TODO set up object editor state things!!
  --

  -- TODO inherit directional controls from owning game
  --      add save-state key
  --      add undo/redo
  --

  self.onkeydown = setmetatable({
    quitEditor = function()
      self.devSession:close()
    end
  }, {
    __index = self.game.onkeydown
  })
  self.onkeyup = setmetatable({
    -- TODO is there anything here?
  }, {
    __index = self.game.onkeyup
  })
  self.controlMap = setmetatable({
    Escape = 'quitEditor'
  }, {
    __index = self.game.controlMap
  })


  self.mouseState = {x=0, y=0, click=false}

  -- Make object list
  self.objects = {}
  for _, path in ipairs(objectPaths) do
    table.insert(self.objects, {name=path, class=require(path)})
  end

  if #self.objects < 1 then
    error('Need at least one object class defined in game/objectPaths.lua.')
  end

  self.objectIdx = 1
  self:createNewCandidateObject()

end


function ObjectEditor:createNewCandidateObject()
  -- Create new object to be placed
  self.newObject = self.objects[1].class{
    resourceMan = self.resourceMan,
    x = 0,
    y = 0,
    layer = 1
  }
end


function ObjectEditor:launch()
  -- install own event handlers
  self.game.engine:on{
    redraw = function(time, elapsed, counter)
      -- first draw all game things
      self.game.redraw(time, elapsed, counter)

      -- TODO get tile dimensions from map?
      -- draw editor things
      self.engine:setColor(0,0,0,255)
      self.engine:drawRect(
      self.mouseState.x - self.mouseState.x % 16,
      self.mouseState.y - self.mouseState.y % 16,
      16,
      16
      )
      self.newObject:draw(self.mouseState.x, self.mouseState.y)
    end,

    keydown = function(key, mod, isRepeat)
      if isRepeat == 0 then
        self.onkeydown[self.controlMap[key]]()
      end
    end,
    keyup = function(key, mod, isRepeat)
      self.onkeyup[self.controlMap[key]]()
    end,
    mousebuttondown = function(x, y, button)
      self.mouseState = {x=x, y=y, click=self.mouseState.click}
    end,

    mousebuttonup = function(x, y, button)
      self.mouseState = {x=x, y=y, click=true}

      local wx, wy = self.devSession:screenToWorld(x, y)
      -- TODO check if we've hit an existing object! if so, bring up menu
      -- to modify/delete, otherwise we place a new object.

      self:placeObject(wx, wy)
    end,

    mousemotion = function(x, y, dx, dy)
      local wx, wy = self.devSession:screenToWorld(x, y)

      self.mouseState.x = x
      self.mouseState.y = y
    end,
  }
end


function ObjectEditor:placeObject(wx, wy)
  -- Add candidateObject to the map, create new object
  self.devSession.game.map:addObject(self.newObject)
  self.newObject:warp(wx, wy)

  self:createNewCandidateObject()
end


return ObjectEditor

