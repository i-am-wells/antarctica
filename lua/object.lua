
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
        self,
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

    self.facing = options.facing or 's'

    if options.bbox then
        self:setBoundingBox(options.bbox)
    end
end


function Object:setBoundingBox(box)
    ant.object.setBoundingBox(
        self._object,
        box.x, box.y, box.w, box.h
    )
end


-- TODO remove
function Object:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    ant.object.moveRelative(self._tilemap, self._object, dx, dy)
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
    self:getLocation()
    ant.object.moveAbsolute(self._tilemap, self._object, x or self.x, y or self.y)
end


function Object:setSprite(tx, ty, animation_count, animation_period, offX, offY)
    tx = tx or 0
    ty = ty or 0
    animation_count = animation_count or 1
    animation_period = animation_period or 1
    offX = offX or 0
    offY = offY or 0
    ant.object.setSprite(self._object, tx, ty, animation_count, animation_period, offX, offY)
end

function Object:getLocation()
    local x, y = ant.object.getLocation(self._object)
    self.x = x
    self.y = y
end

function Object:getTileLocation()
    local px, py = ant.object.getLocation(self._object)
    return (px // self.image.tw), (py // self.image.th)
end


function Object:on(handlers)
    for k, v in pairs(handlers) do
        if type(v) == 'function' then
            self['on'..k] = v
        else
            error('expected function for "'..k..'" but got '..type(v))
        end
    end
end

function Object:remove()
    ant.object.removeSelf(self._object)
end

return Object

