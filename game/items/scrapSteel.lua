local Class = require 'class'

local Item = require 'game.items.item'

local ScrapSteel = Class(Item)

ScrapSteel.name = 'scrap steel'
ScrapSteel.tx = 0

local tys = {0, 1, 2, 3}

function ScrapSteel:init(options)
  self.ty = tys[options.data.variety or 1]

  Item.init(self, options)
end

return ScrapSteel

