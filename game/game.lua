local ant = require 'antarctica'

local Class = require 'class'

local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'
local Sound = require 'sound'
local ResourceManager = require 'resourceManager'

local showFramerate = require 'showFramerate'

local GameState = require 'game.gameState'
local newGameState = require 'game.newGameState'
local resourceInfo = require 'game.resourceInfo'

local StatusText = require 'game.statusText'

-- TODO remove for release
local DevSession = require 'devtools.devSession'

local Game = Class()

function Game:init(opt)
  self.engine = opt.engine
  self.saveFileName = opt.saveFileName 
  self.resourceMan = opt.resourceMan

  self.isRunning = false

  self.font = self.resourceMan:get('res/textbold-9x15.png', Image, {
    engine = self.engine,
    file='res/textbold-9x15.png',
    tilew = 9, tileh = 15
  })

  self.state = newGameState
  if self.saveFileName then
    -- load save file
    --TODO wrong! should be a GameState
    self.state:read(self.saveFileName)
  end

  self.overlayStack = {}
  self.menuStack = {}

  -- load hero
  self.hero = Object.fromTable(self.state.hero, self.resourceMan)
  self.hero.controller = self
  self.hero:turn('south')

  self.hero:on{
    -- Door
    -- TODO consider moving this into its own class: dooruser.lua
    wallbump = function(hero, direction)
      local mx, my = hero:getTileLocation()
      local key = string.format('_%d_%d_', mx, my)
      local dest = nil
      if (direction & ant.tilemap.bumpnorthflag) then
        dest = resourceInfo.maps[self.mapName].warps[key..'n']
      end
      if (direction & ant.tilemap.bumpsouthflag) and not dest then
        dest = resourceInfo.maps[self.mapName].warps[key..'s']
      end
      if (direction & ant.tilemap.bumpeastflag) and not dest then
        dest = resourceInfo.maps[self.mapName].warps[key..'e']
      end
      if (direction & ant.tilemap.bumpwestflag) and not dest then
        dest = resourceInfo.maps[self.mapName].warps[key..'w']
      end

      if dest then
        -- make sure we stop updating objects on this map
        self.map:abortUpdateObjects()

        -- warp
        self:changeMap(dest.map, {
          x=dest.x*self.tileImage.tw, 
          y=dest.y*self.tileImage.th
        })
      end
    end
  }

  self.controlMap = opt.controlMap or self.state.controlMap or {
    D = 'goEast',
    W = 'goNorth',
    A = 'goWest',
    S = 'goSouth',
    Escape = 'quit',
    J = 'slide',
    K = 'interact',
    I = 'inventory'
  }
  self.controlMap.L = 'printLocation'

  -- Actions
  self.onkeydown = setmetatable({
    goEast = function()
      self.hero:pushDirection('east')
      self.hero:updateMovement()
    end,
    goNorth = function() 
      self.hero:pushDirection('north')
      self.hero:updateMovement()
    end,
    goWest = function() 
      self.hero:pushDirection('west')
      self.hero:updateMovement()
    end,
    goSouth = function() 
      self.hero:pushDirection('south')
      self.hero:updateMovement()
    end,

    slide = function()
      -- Do a belly slide
      if (self.hero.velx ~= 0) or (self.hero.vely ~= 0) then
        self.hero:slide()
      end
    end,

    interact = function()
      -- facing/touching interact target?
      local target = self.hero.interactTarget
      if target and self.hero:isFacing(target) then
        target:onInteract(self.hero)
      end
    end,

    inventory = function()
      if #self.menuStack == 0 then
        self.hero:stop()
        self.hero.inventory:open(self)
      end
    end,

    quit = function() 
      print('quitting...') 
      self.isRunning = false
      self.engine:stop() 
    end
  }, {
    __index = function(_, key) return function() end end
  })

  self.onkeyup = setmetatable({
    goEast = function()
      self.hero:popDirection('east')
      self.hero:setVelocity(0, nil)
      self.hero:updateMovement()
    end,
    goNorth = function()
      self.hero:popDirection('north')
      self.hero:setVelocity(nil, 0)
      self.hero:updateMovement()
    end,
    goWest = function() 
      self.hero:popDirection('west')
      self.hero:setVelocity(0, nil)
      self.hero:updateMovement()
    end,
    goSouth = function() 
      self.hero:popDirection('south')
      self.hero:setVelocity(nil, 0)
      self.hero:updateMovement()
    end,
    slide = function()
      -- TODO hide
      self.hero:stand()
      self.hero:updateMovement()
    end,
    printLocation = function()
      self.hero:getLocation()
      print(self.hero.x, self.hero.y)
    end
  },
  {
    __index = function() return function() end end
  }
  )

  -- TODO move the body of this function into a method of Game.
  self.redraw = function(time, elapsed, counter)
    self.engine:setColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, 255)
    self.engine:clear()

    -- Redraw
    self:redrawMap(counter)
    
    -- Draw menus
    for _, v in ipairs(self.menuStack) do
      v.menu:draw()
    end

    -- Draw/update overlays
    for i, o in ipairs(self.overlayStack) do
      o:draw(i)
      o:update()
    end

    -- Update object positions, run update callbacks
    -- TODO pass arguments through to object callbacks
    self.map:updateObjects()
  end

  -- load map
  self:changeMap(self.state.hero.mapName, {x=self.hero.x, y=self.hero.y})
end

function Game:redrawMap(counter)
  local image, vw, vh = self.tileImage, self.engine.vw, self.engine.vh
  self.map:drawLayerAtCameraObject(image, 0, vw, vh, counter)
  self.map:drawObjectsAtCameraObject(image, 1, vw, vh, counter)
  --self.map:drawLayerAtCameraObject(image, 1, vw, vh, counter)
    
  -- TODO map overlays should draw here
end

--- Creates a StatusText to be drawn on over the map.
--
-- @param text string Text to be rendered and shown
-- @see game.statustext.StatusText
function Game:status(text)
  StatusText{
    text = text,
    expiry = 240,
    overlayStack = self.overlayStack,
    resourceMan = self.resourceMan
  }
end

--- Loads a new map and places the hero on it.
--
-- @param newMapName (string) Name of the new map for lookup in resourceInfo.
-- @param heroPos {int x, int y} Position of the hero on the new map.
function Game:changeMap(newMapName, heroPos)
  if self.mapName ~= newMapName then

    -- Fade out
    self:fadeOut(32)

    local mapInfo = resourceInfo.maps[newMapName]
    local mapDir = resourceInfo.mapdir or ""
    local newMapFilename = mapDir..mapInfo.file

    if self.map then
      -- remove hero
      if self.hero then
        self.map:removeObject(self.hero)
      end

      -- freeze map objects
      self.state.objects[self.map.name] = self.map:dumpObjects()
    end

    if not newMapName then
      print('no new map')
      -- no new map; we're done after unloading the old one
      return
    end

    -- Load the map from the file (if map is already loaded, no need to populate)
    if not self.resourceMan:has(newMapName) then
      print('loading map for the first time; populating')
      -- load and populate
      self.map = self.resourceMan:get(newMapName, Tilemap, {
        file = newMapFilename,
        objects = self.state.objects[newMapName],
        resourceMan = self.resourceMan
      })

    else
      print('map has been loaded before, no need to populate')
      self.map = self.resourceMan:get(newMapName)
    end
    self.mapName = newMapName

    -- get tile texture if necessary
    self.tileImage = self.resourceMan:get(mapInfo.tileImage, Image, {
      engine = self.engine,
      file = mapInfo.tileImage,
      tilew = mapInfo.tileW,
      tileh = mapInfo.tileH
    })

    -- now map is loaded and populated: we can place the hero
    self.map:addObject(self.hero)
    self.map:setCameraObject(self.hero)

    self.bgColor = mapInfo.background
    self.engine:setColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a or 255)
  end

  self.hero:warp(heroPos.x, heroPos.y)
  self:fadeIn(32)
end

--- Run a simple fade-in or fade-out effect.
--
-- Does ordinary redraw but targets an image instead of the screen. That image
-- is then drawn to the screen over a background color with opacity changing 
-- from startAlpha to endAlpha linearly over the specified frame count.
--
-- @param startAlpha (int) Starting opacity value in [0, 255]
-- @param endAlpha   (int) Ending opacity value in [0, 255]
-- @param frames     (int) Duration of fade as number of frames
--
-- @see Game:fadeIn
-- @see Game:fadeOut
function Game:fade(startAlpha, endAlpha, frames)
  -- TODO do this better
  if not self.tileImage then
    return
  end

  -- Render the map and objects once to blank texture
  local dummy = Image{engine=self.engine, w=self.engine.vw, h=self.engine.vh}

  self.tileImage:targetImage(dummy)

  self.engine:setColor(20, 12, 28, 255)
  self.engine:clear()

  self:redrawMap(0)

  self.tileImage:targetImage(nil)

  -- Do fade
  local frame = 0
  self.engine:run{
    redraw = function()
      if frame == frames then
        self.engine:stop()
        return
      end

      self.engine:clear()
      local alpha = frame / frames * (endAlpha - startAlpha) + startAlpha
      dummy:alphaMod(alpha // 1)
      dummy:drawWhole()

      frame = frame + 1
    end
  }
end

--- Fade in from the background color to full picture.
--
-- @param frames (int) Duration of fade in frames.
--
-- @see Game:fade
function Game:fadeIn(frames)
  self:fade(0, 255, frames)
end

--- Fade out from full picture to the background color.
--
-- @param frames (int) Duration of fade in frames.
--
-- @see Game:fade
function Game:fadeOut(frames)
  self:fade(255, 0, frames)
end

--- Stops everything, causing Game:run() to return.
function Game:quit()
  self.isRunning = false
  self.engine:stop()
end

--- Run the game loop.
--
-- Takes input, runs game logic, and redraws until the window is closed or an
-- event handler calls Game:quit().
function Game:run()
  -- Outer loop allowing the engine to start and stop for other running modes
  -- (fades/transitions, etc.)
  self.isRunning = true
  while self.isRunning do
    -- Install handlers and run
    self.engine:run{
      redraw = self.redraw,

      keydown = function(key, mod, isrepeat)
        if isrepeat == 0 then
          self.onkeydown[self.controlMap[key]]()

          -- TODO remove for release
          if (mod & self.engine.keymod.ctrl) and (mod & self.engine.keymod.shift) and key == 'O' then
            if self.devSession then
              self.devSession:close()
              self.devSession = nil
              print('Closed dev tools')
            else
              self.devSession = DevSession{game = self}
              print('Opened dev tools')
            end
          end
        end
      end,

      keyup = function(key)
        self.onkeyup[self.controlMap[key]]()
      end,

      quit = function()
        print('received quit')
        self:quit()
      end
    }
  end
end

return Game
