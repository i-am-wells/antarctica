
local Class = require 'class'
local Object = require 'object'
local Image = require 'image'

local AnimatedObject = Class(Object)


function AnimatedObject:init(options)

    if not options.image then
        -- get image
        options.image = options.resourceMan:get(self.imageFile, Image, {
            engine = options.resourceMan:get('engine'),
            file = self.imageFile,
        })
    end

    -- load info from sprites table
    local spinfo = self.sprites[self.movement][self.direction][1]
    options.tx = options.tx or spinfo.tx
    options.ty = options.ty or spinfo.ty
    options.tw = options.tw or spinfo.tw
    options.th = options.th or spinfo.th
    options.bbox = options.bbox or spinfo.bbox
    
    options.animation_count = options.animation_count or 1
    options.animation_period = options.animation_period or 1   
    Object.init(self, options)

    self:setSprite(
        spinfo.tx, spinfo.ty, spinfo.tw, spinfo.th, 
        1, 1, 
        spinfo.offX, spinfo.offY
    )

    self.updateCounter = 0
end


function AnimatedObject:updateSprite()
    local timing = self.sprites[self.movement].timing
    self.frameNumber = (self.updateCounter // timing.div) % timing.mod
    local frame = timing[self.frameNumber]
    if frame then
        -- set sprite info
        local spriteInfo = self.sprites[self.movement][self.direction][frame]
        self:setSprite(
            spriteInfo.tx, spriteInfo.ty, spriteInfo.tw, spriteInfo.th,
            1, 1,
            spriteInfo.offX, spriteInfo.offY
        )
        self:setBoundingBox(spriteInfo.bbox)
    end

    self.updateCounter = (self.updateCounter + 1) % 256
end


function AnimatedObject:getBbox(movement, direction)
    local timing = self.sprites[movement].timing
    local frame = timing[(self.updateCounter // timing.div) % timing.mod]
    if frame then
        return self.sprites[movement][direction][frame].bbox
    else
        return self.bbox
    end
end


return AnimatedObject

