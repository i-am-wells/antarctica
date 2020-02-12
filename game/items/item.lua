local Class = require 'class'
local Object = require 'object'
local Image = require 'image'

local Item = Class(Object)

Item.imageFile = 'res/itemSprites.png'
Item.tw = 16
Item.th = 16
Item.tx = 0
Item.ty = 0

Item.offX = 0
Item.offY = 0

Item.bbox = {x=0, y=0, w=Item.tw, h=Item.th}

-- child class should provide this
Item.name = '???'

function Item:init(options)
  options.image = options.resourceMan:get(self.imageFile, Image, {
    engine = options.resourceMan:get('engine'),
    file = self.imageFile,
    tilew = 16,
    tileh = 16
  })

  options.tx = options.tx or self.tx
  options.ty = options.ty or self.ty
  options.tw = options.tw or self.tw
  options.th = options.th or self.th
  options.bbox = options.bbox or self.bbox
  Object.init(self, options)

  self:setSprite(
  self.tx, self.ty, self.tw, self.th, 
  1, 1, 
  self.offX, self.offY
  )
end


function Item:onInteract(other)
  -- "other" picks up item and adds to inventory
  other.controller:status('Picked up '..self.name..'.')
  other.inventory:addItem(self)
end


function Item:onUse(inventory, idx)
  -- TODO something else
  print("can't use this item!!")
end


return Item

