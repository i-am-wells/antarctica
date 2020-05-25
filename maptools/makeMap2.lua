local TilemapUtils = require 'maptools.TilemapUtils'

local map = TilemapUtils.createTilemapFromImage{
  imagePath = __rootdir..'/maptools/demo/demo-map.png',
  colorToTileinfo = require 'maptools.demo.colorToTile',
  layers = 2,
  tw = 16,
  th = 16,
}

map:write(__rootdir..'/maptools/demo/demo-out.map')
