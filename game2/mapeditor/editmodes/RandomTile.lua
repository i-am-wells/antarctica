local math = require 'math'
local RawTile = require 'game2.mapeditor.editmodes.RawTile'
local RandomTile = require 'class'(RawTile)

function RandomTile:init(tiles)
  self.tiles = tiles
end

function RandomTile:getTileToDraw()
  local tile = self.tiles[#self.tiles * math.random() // 1 + 1]
  return tile.x, tile.y, tile.flags
end

return RandomTile
