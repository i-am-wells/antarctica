local Class = require 'class'
local Tilemap = require 'tilemap'
local TilesetInfo = require 'maptools.TilesetInfo'

local IntermediateMap = Class()

function IntermediateMap:init(args)
  self.w = args.w or 0
  self.h = args.h or 0
  self.defaultGridValue = args.defaultGridValue or 1

  if self.w * self.h == 0 then
    error('IntermediateMap needs non-zero dimensions')
  end

  -- Set metamethods to avoid storing defaultGridValue
  local gridRowMt = {
    __index = function(row, k)
      -- TODO do we need bounds check?
      if k > 0 and k <= self.w then return self.defaultGridValue end
    end,
    __newindex = function(row, k, val)
      if val ~= self.defaultGridValue then
        rawset(row, k, val)
      end
    end
  }

  self.grid = {}
  for y = 1, self.h do
    self.grid[y] = setmetatable({}, gridRowMt)
    if not args.slim then
      for x = 1, self.w do
        self.grid[y][x] = self.defaultGridValue
      end
    end
  end
end

-- TODO give this a better name
function IntermediateMap:remap(remapFunction)
  self:map(function(k, x, y)
    self.grid[y][x] = remapFunction(k, x, y)
  end)
end

function IntermediateMap:map(f)
  for y = 1, self.h do
    for x = 1, self.w do
      f(self.grid[y][x], x, y)
    end
  end
end

function IntermediateMap:upsample(factor)
  local newW, newH = self.w*factor//1, self.h*factor//1
  local newMap = IntermediateMap{w=newW, h=newH}

  for y = 0, newH-1 do
    for x = 0, newW-1 do
      newMap:set(x+1, y+1, self:get(x // factor + 1, y // factor + 1))
    end
  end

  return newMap
end

function IntermediateMap:toBaseTilemap(tilesetInfo, nlayers)
  nlayers = nlayers or 1
  local tilemap = Tilemap{nlayers=nlayers, w=self.w, h=self.h}
  for y = 1, self.h do
    local row = self.grid[y]
    for x = 1, self.w do
      local key = row[x]
      if key then
        local tile = tilesetInfo:getTile(key)
        tilemap:setTile(0, x-1, y-1, tile.x, tile.y)

        -- TODO rethink?
        --[[
        if not tilesetInfo:isWalkable(key) then
          tilemap:setFlags(0, x-1, y-1, Tilemap.flags.bumpAll)
        end
        --]]
      else
        -- TODO: this should not happen now
        error(string.format("nil at (%d,%d)", x, y))
      end
    end
  end
  return tilemap
end

function IntermediateMap:get(x, y)
  if not self.grid[y] then return nil end
  return self.grid[y][x]
end

function IntermediateMap:set(x, y, key)
  if not self.grid[y] then return end
  self.grid[y][x] = key
end

function IntermediateMap:runMarchingSquares(key)
  local newMap = IntermediateMap{w=self.w//2, h=self.h//2}

  -- Intentionally start at zero rather than one so we'll be offset by 1
  for y = 0, self.h, 2 do
    for x = 0, self.w, 2 do
      -- 8, 4
      -- 2, 1
      local outKey = 0
      if self:get(x+1, y+1) == key then
        outKey = outKey + 1
      end
      if self:get(x, y+1) == key then
        outKey = outKey + 2
      end
      if self:get(x+1, y) == key then
        outKey = outKey + 4
      end
      if self:get(x, y) == key then
        outKey = outKey + 8
      end

      newMap:set(x//2, y//2, outKey)
    end
  end

  return newMap
end

function IntermediateMap:squareEquals(x, y, w, h, key)
  for yy = 0, h-1 do
    for xx = 0, w-1 do
      if self:get(x + xx, y + yy) ~= key then
        return false
      end
    end
  end
  return true
end

function IntermediateMap:layDownPatch(x, y, patch)
  for yy = 0, patch.h-1 do
    for xx = 0, patch.w-1 do
      self:set(x + xx, y + yy, TilesetInfo.getPointKey(patch, xx, yy))
    end
  end
end

return IntermediateMap
