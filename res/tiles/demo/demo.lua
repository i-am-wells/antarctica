local filename = 'res/tiles/demo/demo.png'

local TileInfo = require 'tilemap'.TileInfo
local Info16 = require 'class'(TileInfo)
function Info16:init(arg)
  arg.w = 16
  arg.h = 16
  arg.name = filename
  TileInfo.init(self, arg)
end

return {
  sand = Info16{
    sx = 0
  },
  deepWater = Info16{
    sx = 16
  },
  water = Info16{
    sx = 32
  },
  wetSand = Info16{
    sx = 48
  }
}
