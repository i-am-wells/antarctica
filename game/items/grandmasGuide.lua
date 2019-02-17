local Class = require 'class'
local Image = require 'image'

local Item = require 'game.items.item'
local Book = require 'game.book'

local GrandmasGuide = Class(Item, Book)



-- Item properties
GrandmasGuide.name = "Grandma's guide"
GrandmasGuide.tx = 0
GrandmasGuide.ty = 4

local p0 = [[
Despite those automatic conversions, strings and numbers are different things. A comparison like 10 == "10" is always false, because 10 is a number and "10" is a string.
]]


-- Book properties
GrandmasGuide.pageColor = {r=241, g=255, b=125, a=255}
GrandmasGuide.margin = 5
GrandmasGuide.pages = {
    -- map page
    function(_self)
        _self.mapImage:drawWhole(_self.contentX, _self.contentY)
    end,

    -- text page
    function(_self)
        _self.fontSmall:colorMod(0, 0, 0)
        _self.fontSmall:drawText(p0, _self.contentX + _self.margin, _self.contentY + _self.margin, _self.pagesW // 2 - 2 * _self.margin)
    end
}

local mapImageFile = 'res/mapsmall.png'

function GrandmasGuide:init(options)
    self.resourceMan = options.resourceMan

    Item.init(self, options)
    Book.init(self, options)
end


function GrandmasGuide:onUse(inv, invIdx)

    self.mapImage = self.resourceMan:get(mapImageFile, Image, {
        engine = self.resourceMan:get('engine'),
        file = mapImageFile
    })

    self:open(inv.controller)
end

return GrandmasGuide

