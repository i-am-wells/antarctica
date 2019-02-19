local math = require 'math'
local ant = require 'antarctica'

local Class = require 'class'
local Image = require 'image'

local Object = Class()


Object.fromTable = function(t, resourceMan)
    -- TODO why not include this?
    --[[
    local image = resourceMan:get(t.imageFile, Image, {
        engine = resourceMan:get('engine'),
        file = t.imageFile
    })
    if not image then
        error('failed to load image '..t.imageFile)
    end
    --]]
    
    
    local theClass = Object
    if t.class then
        theClass = require(t.class)
    end

    -- TODO no need to copy twice. This happens in the constructor
    local objData = {}
    for k, v in pairs(t.data or {}) do
        objData[k] = v
    end

    local obj = theClass{
        resourceMan = resourceMan,
        x = t.x,
        y = t.y,
        layer = t.layer,
        --image = image,
        tx = t.tx,
        ty = t.ty,
        tw = t.tw,
        th = t.th,
        animation_count = t.animation_count,
        animation_period = t.animation_period,
        velx = t.velx,
        vely = t.vely,
        facing = t.facing,
        bbox = t.bbox,
        data = objData
    }

    return obj
end


function Object:init(options)
    self.x = options.x
    self.y = options.y
    self.layer = options.layer

    self.resourceMan = options.resourceMan
    self._object = ant.object.create(
        self,
        options.image._image,
        options.x or 0,
        options.y or 0,
        options.layer or 1,
        options.tx,
        options.ty,
        options.tw,
        options.th,
        options.animation_count or 1,
        options.animation_period or 1
    )
    self.image = options.image

    self.tx = options.tx
    self.ty = options.ty
    self.tw = options.tw
    self.th = options.th
    self.animation_count = options.animation_count
    self.animation_period = options.animation_period

    self.velx = options.velx or 0
    self.vely = options.vely or 0

    self.facing = options.facing or 's'

    if options.bbox then
        self:setBoundingBox(options.bbox)
    end

    if options.data then
        self.data = {}
        for k, v in pairs(options.data) do
            self.data[k] = v
        end
    end
end


function Object:toTable()
    return {
        x = self.x,
        y = self.y,
        layer = self.layer,
        imageFile = self.image.file,
        tx = self.tx,
        ty = self.ty,
        tw = self.tw,
        th = self.th,
        animation_count = self.animation_count,
        animation_period = self.animation_period,
        velx = self.velx,
        vely = self.vely,
        facing = self.facing,
        bbox = {
            x = self.bbox.x,
            y = self.bbox.y,
            w = self.bbox.w,
            h = self.bbox.h
        },
        data = self.data
    }
end


function Object:setBoundingBox(box)
    ant.object.setBoundingBox(
        self._object,
        box.x, box.y, box.w, box.h
    )
    self.bbox = {
        x = box.x,
        y = box.y,
        w = box.w,
        h = box.h
    }
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


function Object:setSprite(tx, ty, tw, th, animation_count, animation_period, offX, offY)
    tx = tx or 0
    ty = ty or 0
    tw = tw or self.image.tw
    th = th or self.image.th
    animation_count = animation_count or 1
    animation_period = animation_period or 1
    offX = offX or 0
    offY = offY or 0
    self.offX = offX
    self.offY = offY
    ant.object.setSprite(self._object, tx, ty, tw, th, animation_count, animation_period, offX, offY)
end


function Object:setImage(image)
    ant.object.setImage(self._object, image._image)
    self.image = image
end


function Object:getLocation()
    local x, y = ant.object.getLocation(self._object)
    self.x = x
    self.y = y

    return x, y
end


function Object:getScreenLocation(pw, ph)
    -- Get object's location on the screen (based on position of camera object)
    local cx, cy = ant.tilemap.getCameraLocation(self._tilemap, pw, ph)
    if cx ~= nil and cy ~= nil then
        self:getLocation()
        return (self.x - cx), (self.y - cy)
    else
        return nil, nil
    end
end

function Object:getTileLocation()
    local px, py = ant.object.getLocation(self._object)
    return (px // self.image.tw), (py // self.image.th)
end


function Object:isTouching(other)
    self:getLocation()
    other:getLocation()
    local ax0, ay0 = self.x + self.bbox.x, self.y + self.bbox.y
    local ax1, ay1 = ax0 + self.bbox.w, ay0 + self.bbox.h
    local bx0, by0 = other.x + other.bbox.x, other.y + other.bbox.y
    local bx1, by1 = bx0 + other.bbox.w, by0 + other.bbox.h

    local xTouch = (ax1 == bx0) or (bx1 == ax0)
    local yTouch = (ay1 == by0) or (by1 == ay0)

    local xOverlap = ((ax0 < bx0) and (ax1 >= bx0)) or ((bx0 <= ax0) and (bx1 >= ax0))
    local yOverlap = ((ay0 < by0) and (ay1 >= by0)) or ((by0 <= ay0) and (by1 >= ay0))
    
    return (xTouch and yOverlap) or (yTouch and xOverlap)
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
    if self._tilemap then
        ant.object.removeSelf(self._object)
        
        self.map.objects[self] = nil
        self.map = nil
        self._tilemap = nil
    end
end


function Object:draw(x, y)
    if self.image then
        self.image:draw(
            self.tx * self.tw,
            self.ty * self.th,
            self.tw,
            self.th,
            x + self.offX,
            y + self.offY,
            self.tw,
            self.th
        )
    end
end

function Object:distanceTo(otherObject)
    local dx, dy = (otherObject.x - self.x), (otherObject.y - self.y)
    return math.sqrt(dx * dx, dy * dy)
end


return Object

