local TilemapUtils = require 'maptools.TilemapUtils'

local tileInfos = TilemapUtils.loadTileInfos{'res.tiles.demo.demo'}
local demoTiles = tileInfos['res.tiles.demo.demo']

for k, v in pairs(demoTiles) do print(k, v) end

return require 'maptools.ColorMap'{
  [0xfee4b3] = demoTiles.sand,
  [0x007f7f] = demoTiles.deepWater,
  [0x42a9af] = demoTiles.water,
  [0xc1b17f] = demoTiles.wetSand
}
