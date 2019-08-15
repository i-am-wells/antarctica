local math = require 'math'

local Tilemap = require 'tilemap'
local Class = require 'class'

local Square = Class()

function Square:init(_0, _1, _2, _3)
  self[0], self[1], self[2], self[3] = _0, _1, _2, _3
end

function Square:matchRight(other)
  return self[1] == other[0] and self[3] == other[2]
end

function Square:matchUp(other)
  return self[0] == other[2] and self[1] == other[3]
end

function Square:matchLeft(other)
  return self[0] == other[1] and self[2] == other[3]
end

function Square:matchDown(other)
  return self[2] == other[0] and self[3] == other[1]
end


-- Arguments: zero or more sets like this: {x=true, y=true}, {x=true}
-- Returns: a list of common values: {x}
local setIntersect = function(...)
  local sets, intersection = {...}, {}

  for i, set in ipairs(sets) do
    -- copy entire contents of first set into output
    if i == 1 then
      for idx, inSet in pairs(set) do
        if inSet then
          intersection[#intersection+1] = idx
        end
      end
    else
      -- Remove anything from the result that isn't in the current set.
      local newIntersection = {}
      for j, idx in ipairs(intersection) do
        if set[idx] then
          newIntersection[#newIntersection+1] = idx
        end
      end
      intersection = newIntersection
    end
  end

  return intersection
end

local MapGenerator = Class()

function MapGenerator:init(w, h)
  self.w = w
  self.h = h
  self.grid = {}
  for y = 0, h-1 do
    self.grid[y] = {}
  end

  local dotGrid = {}

  for _0 = 0, 1 do
    for _1 = 0, 1 do
      for _2 = 0, 1 do
        for _3 = 0, 1 do
          dotGrid[(_0 * 8) + (_1 * 4) + (_2 * 2) + _3] = Square(_0, _1, _2, _3)
        end
      end
    end
  end

  self.neighborsRight, self.neighborsUp, self.neighborsLeft, self.neighborsDown = {}, {}, {}, {}
  self.all16 = {}
  for i = 0, 15 do
    self.neighborsRight[i] = {}
    self.neighborsUp[i] = {}
    self.neighborsLeft[i] = {}
    self.neighborsDown[i] = {}
    for j = 0, 15 do
      if dotGrid[i]:matchRight(dotGrid[j]) then
        self.neighborsRight[i][j] = true
      end
      if dotGrid[i]:matchUp(dotGrid[j]) then
        self.neighborsUp[i][j] = true
      end
      if dotGrid[i]:matchLeft(dotGrid[j]) then
        self.neighborsLeft[i][j] = true
      end
      if dotGrid[i]:matchDown(dotGrid[j]) then
        self.neighborsDown[i][j] = true
      end
    end
    self.all16[i] = true
  end

end

function MapGenerator:getSquareIndex(x, y)
  if x < 0 or x > (self.w-1) or y < 0 or y > (self.h-1) then
    return 0
  end
  return self.grid[y][x]
end

function MapGenerator:setSquareIndex(x, y, idx)
  if self.grid[y] then
    self.grid[y][x] = idx
  end
end

function MapGenerator:fillIn()
  self:fillInWeighted(MapGenerator.make16Weights())
end

function MapGenerator:fillInSquare(weights, x, y)
  local gridRow = self.grid[y]

  -- Get a list of possible values for the square
  local right = self.neighborsLeft[self:getSquareIndex(x+1, y)] or self.all16
  local up = self.neighborsDown[self:getSquareIndex(x, y-1)] or self.all16
  local left = self.neighborsRight[self:getSquareIndex(x-1, y)] or self.all16
  local down = self.neighborsUp[self:getSquareIndex(x, y+1)] or self.all16

  local possibleIndices = setIntersect(right, up, down, left)

  local sum = 0
  for _, idx in ipairs(possibleIndices) do
    sum = sum + weights[idx+1]
  end

  if #possibleIndices > 0 then
    local rand = math.random() * sum
    -- Weighted random choice
    for i, idx in ipairs(possibleIndices) do
      local nextRand = rand - weights[idx+1]
      if nextRand < 0 then
        gridRow[x] = idx
        break
      end
      rand = nextRand
    end
  else
    print("Warning: couldn't fill ("..x..", "..y..")")
    gridRow[x] = 0
  end
end

--[[
-- For each nil square, determines the set of possible values and chooses one
-- randomly according to the distribution defined by |weights|.
--]]
function MapGenerator:fillInWeighted(weights)
  for y = 0, (self.h-1) do
    local gridRow = self.grid[y]
    for x = 0, (self.w-1) do
      if not self.grid[y][x] then self:fillInSquare(weights, x, y) end
    end
  end
end


-- TODO callbacks
function MapGenerator:fillInWeightedUsingStack(weights, startX, startY)
  local stackX, stackY, count = {startX}, {startY}, 1
  local stackPush = function(x, y)
    count = count + 1
    stackX[count], stackY[count] = x, y
  end
  local stackPop = function()
    local x, y = stackX[count], stackY[count]
    stackX[count], stackY[count], count = nil, nil, count-1
    return x, y
  end

  while count > 0 do
    -- Get a square
    local x, y = stackPop()

    local idx = self:getSquareIndex(x, y)
    if (idx == nil) or (idx == -1) then
      -- Choose a value for the square
      self:fillInSquare(weights, x, y)
    end

    if (idx == nil or idx == -1) and (self:getSquareIndex(x, y) ~= 0) then
      -- Push neighbors onto stack
      if x < (self.w-1) then stackPush(x+1, y) end
      if y > 0 then stackPush(x, y-1) end
      if x > 0 then stackPush(x-1, y) end
      if y < (self.h-1) then stackPush(x, y+1) end 
    end
  end
end

function MapGenerator:make16Mapping(cornerX, cornerY)
  local mapping = {}
  for y = 0, 3 do
    for x = 0, 3 do
      mapping[y * 4 + x] = {x=(cornerX+x), y=(cornerY+y)}
    end
  end
  return mapping
end

function MapGenerator:make16Weights(val)
  local weights, initialValue = {}, val or 1
  for i = 1, 16 do
    weights[i] = initialValue
  end
  return weights
end

function MapGenerator:createTilemap(mapping)
  local tilemap = Tilemap{nlayers=1, w=self.w, h=self.h}
  for y = 0, (self.h-1) do
    for x = 0, (self.w-1) do
      local tile = mapping[self:getSquareIndex(x, y)]
      if not tile then
        print(x, y, self:getSquareIndex(x, y))
      end
      tilemap:setTile(0, x, y, tile.x, tile.y)
    end
  end
  return tilemap
end

return MapGenerator
