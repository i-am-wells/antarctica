local Class = require 'class'
local Tilemap = require 'tilemap'
local TilesetInfo = require 'maptools.TilesetInfo'

local IntermediateMap = Class()

function IntermediateMap:init(args)
  self.w = args.w or 0
  self.h = args.h or 0
  self.initial = args.initial or 1

  if self.w * self.h == 0 then
    error('IntermediateMap needs non-zero dimensions')
  end

  self.grid = {}
  for y = 1, self.h do
    self.grid[y] = {}
    for x = 1, self.w do
      self.grid[y][x] = self.initial
    end
  end
end

function IntermediateMap:remap(remapFunction)
  for y = 1, self.y do
    for x = 1, self.x do
      self.grid[y][x] = remapFunction(self.grid[y][x])
    end
  end
end

function IntermediateMap:toTilemap(tilesetInfo)
  local tilemap = Tilemap{nlayers=1, w=self.w, h=self.h}
  for y = 1, self.h do
    for x = 1, self.w do
      local tile = tilesetInfo:getTile(self.grid[y][x])
      tilemap:setTile(0, x-1, y-1, tile.x, tile.y)
    end
  end
  return tilemap
end

function IntermediateMap:get(x, y)
  return self.grid[y][x]
end

function IntermediateMap:set(x, y, key)
  if not self.grid[y] then return end
  self.grid[y][x] = key
end

return IntermediateMap
