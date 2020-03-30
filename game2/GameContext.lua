local ant = require 'antarctica'

local RgbaColor = require 'RgbaColor'
local Util = require 'Util'
local bind = Util.bind
local Tilemap = require 'tilemap'
local Image = require 'image'
local Object = require 'object'
local Engine = require 'engine'
local Sound = require 'sound'
local ResourceManager = require 'resourceManager'

local showFramerate = require 'showFramerate'

local GameState = require 'game.gameState'
local newGameState = require 'game2.newGameState'
local resourceInfo = require 'game2.resourceInfo'

local StatusText = require 'game.statusText'

local FadeContext = require 'game2.FadeContext'

-- TODO remove for release
local DevSession = require 'devtools.devSession'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'

local GameContext = require 'class'(Context)

function GameContext:init(opt)
  Context.init(self, {
    engine = opt.engine,
    draw = bind(self.draw, self),
    inputHandler = InputHandler{
      actions = {
        goEast = bind(self.goEast, self),
        goNorth = bind(self.goNorth, self),
        goWest = bind(self.goWest, self),
        goSouth = bind(self.goSouth, self),
        quit = bind(self.quit, self),
        slide = bind(self.slide, self),
        interact = bind(self.interact, self),
        inventory = bind(self.inventory, self),

        -- TODO remove
        devtools = function()
          require 'game2.devtools.DevToolsMenuContext'{
            engine = opt.engine,
            font = opt.font,
          }:takeControlFrom(self)
        end
      },
      keys = {
        D = 'goEast',
        W = 'goNorth',
        A = 'goWest',
        S = 'goSouth',
        Escape = 'quit',
        J = 'slide',
        K = 'interact',
        I = 'inventory',

        -- TODO remove
        X = 'devtools'
      },
      allowKeyRepeat = false
    }
  })

  self.engine = opt.engine
  self.saveFileName = opt.saveFileName 
  self.resourceMan = ResourceManager(opt.resDirectory)

  self.font = opt.font
  self.bgColor = RgbaColor(0, 0, 0, 255)

  self.state = newGameState
  if self.saveFileName then
    -- load save file
    --TODO wrong! should be a GameState
    self.state:read(self.saveFileName)
  end

  self.overlayStack = {}
  self.menuStack = {}

  -- load hero
  self.resourceMan:set("engine", self.engine)
  self.hero = Object.fromTable(self.state.hero, self.resourceMan)
  self.hero.controller = self
  self.hero:turn('south')

  self.hero:on{
    -- Door
    -- TODO consider moving this into its own class: dooruser.lua
    wallbump = function(hero, direction)
      if hero.isAlreadyInWallBump then
        return
      end
      hero.isAlreadyInWallBump = true

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
        self.afterObjectUpdateHook = function()
          self.afterObjectUpdateHook = nil
          
          self:changeMap(dest.map, {
            x=dest.x*self.tileImage.tw, 
            y=dest.y*self.tileImage.th
          })

          hero.isAlreadyInWallBump = false
        end
      else
        hero.isAlreadyInWallBump = false
      end
    end
  }

  -- load map
  self:changeMap(self.state.hero.mapName, {x=self.hero.x, y=self.hero.y})
end

function GameContext:redrawMap(counter)
  local image, vw, vh = self.tileImage, self.engine.vw, self.engine.vh
  self.map:drawLayerAtCameraObject(image, 0, vw, vh, counter)
  self.map:drawObjectsAtCameraObject(image, 1, vw, vh, counter)

  -- TODO map overlays should draw here
end

--- Creates a StatusText to be drawn on over the map.
function GameContext:status(text)
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
function GameContext:changeMap(newMapName, heroPos)
  assert(newMapName)

  local dark = RgbaColor(20, 12, 28, 255)
  if self.mapName ~= newMapName then

    if self.mapName then
      -- Fade out
      FadeContext{
        engine = self.engine,
        stealInput = false,
        to = dark,
        frames = 32
      }:takeControlFrom(self)
    end

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

    -- Load the map from the file (if map is already loaded, no need to populate)
    if not self.resourceMan:has(newMapName) then
      -- load and populate
      self.map = self.resourceMan:get(newMapName, Tilemap, {
        file = newMapFilename,
        objects = self.state.objects[newMapName],
        resourceMan = self.resourceMan
      })

    else
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

  -- Fade in
  FadeContext{
    engine = self.engine,
    stealInput = false,
    from = dark,
    frames = 32
  }:takeControlFrom(self)
end

-- Actions
function GameContext:goEast(keyState)
  if keyState == 'down' then
    self.hero:pushDirection('east')
    self.hero:updateMovement()
  else
    self.hero:popDirection('east')
    self.hero:setVelocity(0, nil)
    self.hero:updateMovement()
  end
end

function GameContext:goNorth(keyState)
  if keyState == 'down' then
    self.hero:pushDirection('north')
    self.hero:updateMovement()
  else
    self.hero:popDirection('north')
    self.hero:setVelocity(nil, 0)
    self.hero:updateMovement()
  end
end

function GameContext:goWest(keyState)
  if keyState == 'down' then
    self.hero:pushDirection('west')
    self.hero:updateMovement()
  else
    self.hero:popDirection('west')
    self.hero:setVelocity(0, nil)
    self.hero:updateMovement()
  end
end

function GameContext:goSouth(keyState)
  if keyState == 'down' then
    self.hero:pushDirection('south')
    self.hero:updateMovement()
  else
    self.hero:popDirection('south')
    self.hero:setVelocity(nil, 0)
    self.hero:updateMovement()
  end
end

function GameContext:slide(keyState)
  if keyState == 'down' then
    -- Do a belly slide
    if (self.hero.velx ~= 0) or (self.hero.vely ~= 0) then
      self.hero:slide()
    end
  else
    -- TODO hide
    self.hero:stand()
    self.hero:updateMovement()
  end
end

function GameContext:interact(keyState)
  if keyState == 'down' then
    -- facing/touching interact target?
    local target = self.hero.interactTarget
    if target and self.hero:isFacing(target) then
      target:onInteract(self.hero)
    end
  end
end

function GameContext:inventory(keyState)
  if keyState == 'down' then
    if #self.menuStack == 0 then
      self.hero:stop()
      self.hero.inventory:open(self)
    end
  end
end

function GameContext:quit(keyState)
  if keyState == 'down' then    
    print('quitting...') 
    self:returnControlToParent() 
  end
end

function GameContext:draw(time, elapsed, counter)
  if self.parentContext then
    self.parentContext:draw()
  end

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

  -- TODO should this be a list?
  if self.afterObjectUpdateHook then
    self.afterObjectUpdateHook()
  end
end

-- TODO implement
function GameContext:shouldShowCredits()
  return false
end

function GameContext:shouldQuitToMenu()
  return false
end

function GameContext:shouldQuitToOs()
  return true
end

return GameContext
