local Class = require 'class'
local Object = require 'object'
local Image = require 'image'

local TextBar = require 'game.textBar'

local Sign = Class(Object)

Sign.imageFile = 'res/spritesnew-16x16.png'
Sign.tx = 19
Sign.ty = 15
Sign.tw = 16
Sign.th = 32
Sign.bbox = {
    x = 0,
    y = 0,
    w = 16,
    h = 16
}
Sign.offX = 0
Sign.offY = -16

Sign.margin = 4
Sign.color = {r=133, g=149, b=161, a=255}
Sign.border = {r=78, g=74, b=78, a=255}

function Sign:init(options)
    self.resourceMan = options.resourceMan
    self.engine = self.resourceMan:get('engine')

    if not options.image then
        -- get image
        options.image = options.resourceMan:get(self.imageFile, Image, {
            engine = self.engine,
            file = self.imageFile
        })
    end


    options.tx = options.tx or self.tx
    options.ty = options.ty or self.ty
    options.tw = options.tw or self.tw
    options.th = options.th or self.th
    options.bbox = options.bbox or self.bbox

    options.animation_count = 1
    options.animation_period = 1

    Object.init(self, options)

    self:setSprite(self.tx, self.ty, self.tw, self.th, 1, 1, self.offX, self.offY)
    

    self.messageShown = false
    self:on{
        update = function(_self)
            if self.messageShown then
                if not self.interacter:isFacing(self) then
                    self:stopInteract()
                end
            end
        end
    }

    self.data = options.data
end


function Sign:onInteract(other)
    if not self.messageShown then
        self.messageShown = true
        self.interacter = other

        if other.moveDirectionStack then
            other.moveDirectionStack = {}
        end

        self.textBar = TextBar{
            resourceMan = self.resourceMan,
            text = self.data.says,
            name = self.data.name or 'sign'
        }

        self.textBar:open(other.controller)
    end
end


function Sign:stopInteract()
    self.messageShown = false
    self.interacter = nil
    if self.textBar.isOpen then
        self.textBar:close()
    end
    self.textBar = nil
end


return Sign

