
local ant = require 'antarctica'

local class = require 'class'

local Object = class.base()

function Object:init(options)
    self.x = options.x
    self.y = options.y
    -- takes an image, a location, and sprite info
    --
    -- TODO create C object_t
    --
    self._object = ant.object.create(
        options.image._image,
        options.x,
        options.y,
        options.layer,
        options.tx,
        options.ty,
        options.tw,
        options.th,
        options.animation_count,
        options.animation_period
    )
end


function Object:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    ant.object.move_relative(self._tilemap, self._object, dx, dy)
end


function Object:warp(x, y)
    --self.x = x
    --self.y = y
    ant.object.move_absolute(self._object, x, y)
end


function Object:setsprite(tx, ty, animation_count, animation_period)
    tx = tx or 0
    ty = ty or 0
    animation_count = animation_count or 1
    animation_period = animation_period or 1
    ant.object.set_sprite(self._object, tx, ty, animation_count, animation_period)
end

return Object

