
local ant = require 'antarctica'

local class = require 'class'

local Object = class.base()

function Object:init(options)
    self.x = options.x
    self.y = options.y
    self.layer = options.layer
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
    self.image = options.image

    self.velx = 0
    self.vely = 0
end


-- TODO remove
function Object:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    ant.object.move_relative(self._tilemap, self._object, dx, dy)
end

function Object:setVelocity(vx, vy)
    self.velx = vx or self.velx
    self.vely = vy or self.vely

    if vx == nil then
        if vy == nil then
            return
        else
            ant.object.setYVelocity(self._object, vy)
        end
    else
        if vy == nil then
            ant.object.setXVelocity(self._object, vx)
        else
            ant.object.setVelocity(self._object, vx, vy)
        end
    end
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

function Object:getTileLocation()
    local px, py = ant.object.getLocation(self._object)
    return (px // self.image.tw), (py // self.image.th)
end

return Object

