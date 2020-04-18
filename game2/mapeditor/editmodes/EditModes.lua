local RawTile = require 'game2.mapeditor.editmodes.RawTile'
local RandomTile = require 'game2.mapeditor.editmodes.RandomTile'

local tile = function(x, y, flags)
  return {x=x, y=y, flags=(flags or 0)}
end

return {
  beach = RandomTile{
    -- layer = 1,
    -- tile(0, 4), tile(1, 4), tile(2, 4)
  },
  plant = RawTile{},
  rock = RawTile{},

}
