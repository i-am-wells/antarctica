local Class = require 'class'
local Object = require 'object'
local Image = require 'image'

local Menu = require 'game.menu'
local Item = require 'game.items.item'
local SpeechBubble = require 'game.speechBubble'

local Inventory = Class(Menu)

local imageFile = 'res/bag.png'
local menuShadow = 'res/menuShadow.png'

Inventory.fontSmallFile = 'res/text-5x9.png'
Inventory.rowLength = 12
Inventory.spacing = 4
Inventory.max = 60

Inventory.contentW = 240
Inventory.contentH = 100

function Inventory:init(options)

    -- copy in items from options?
    self.resourceMan = options.resourceMan

    self.engine = self.resourceMan:get('engine')

    Menu.init(self, options)

    self.menuShadow = options.resourceMan:get(menuShadow, Image, {
        engine = self.engine,
        file = menuShadow
    })

    self.font = options.font or options.resourceMan:get(self.fontSmallFile, Image, {
        file = self.fontSmallFile,
        engine = self.engine,
        tilew = 5,
        tileh = 9
    })

    self.bgImage = options.resourceMan:get(imageFile, Image, {
        engine = self.engine,
        file = imageFile
    })

    self.contentX = (self.engine.vw // 2) - (self.contentW // 2)
    self.contentY = (self.engine.vh // 2) - 20

    self.items = {}
    self.choices = {}


    -- populate
    for i, itemTable in ipairs(options.items) do
        local obj = Object.fromTable(itemTable, self.resourceMan)
        self:addItem(obj)
    end
    
    self.bubble = SpeechBubble{
        resourceMan = self.resourceMan
    }
end


function Inventory:addItem(item)
    item:remove()
    table.insert(self.items, item)

    local idx = #self.items
    
    table.insert(self.choices, {
        label = item.name,
        item = item,
        action = function()
            item:onUse(self, idx)
        end
    })
end


function Inventory:removeItem(idx)
    table.remove(self.items, idx)
    table.remove(self.choices, idx)

    if self.idx > #self.choices then
        self.idx = self.idx - 1
    end
end


function Inventory:dropItem(idx, map, x, y)
    local item = self.items[idx]
    if item then
        self:removeItem(idx)
        map:addObject(item)
        item:warp(x, y)
    end
end


function Inventory:draw()

    -- Draw background image
    self.menuShadow:drawCentered()
    self.bgImage:drawCentered()


    -- Draw items
    local w = self.rowLength
    local spacing = 16 + self.spacing
    for i, choice in ipairs(self.choices) do
        local ii = i - 1
        local x, y = (self.contentX + (spacing * (ii % w))), (self.contentY + (spacing * (ii // w)))

        if i == self.idx then
            self.engine:setColor(255, 0, 0, 255)
            self.engine:drawRect(x - 2, y - 2, 20, 20)
        end

        -- draw icon
        Item.draw(choice.item, x, y)

        -- label
        if i == self.idx then
            self.bubble.text = choice.label
            self.bubble:updatePosition(x, y)
            self.bubble:draw()
        end
    end
end

function Inventory:onRight()
    self:incChosen()
end

function Inventory:onUp()
    self.idx = (self.idx - 1 - self.rowLength) % #self.choices + 1
end

function Inventory:onLeft()
    self:decChosen()
end

function Inventory:onDown()
    self.idx = (self.idx - 1 + self.rowLength) % #self.choices + 1
end

function Inventory:onBack()
    self:close()
end

function Inventory:onChoose()
    local choice = self.choices[self.idx]
    if choice.action then
        choice.action()
    else
        -- TODO something else here
        print('no action for this item!')
    end
end


return Inventory
