local demoTiles = require 'res.tiles.demo.demo'

return require 'maptools.ColorMap'{
  [0xfee4b3] = demoTiles.sand,
  [0x007f7f] = demoTiles.deepWater,
  [0x42a9af] = demoTiles.water,
  [0xc1b17f] = demoTiles.wetSand
}
