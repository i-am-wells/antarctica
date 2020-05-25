local Penguin = require 'game.penguin'
-- Default new game state.

local tileW, tileH = 16, 16

return {
  hero = {
    mapName = 'demo',
    x = 32 * tileW,
    y = 32 * tileH,
    layer = 1,

    class = 'game.hero',
    channel = 0, -- TODO

    data = {
      -- TODO set name
      name = 'Vic',
      inventoryItems = {
        {class='game.items.scrapSteel', data={variety=3}}
      },
      accessory = Penguin.accessories.backpack
    },
  },

  objects = {}
}

