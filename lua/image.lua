local Class = require 'class'

local ant = require 'antarctica'

local Image = Class()

function Image:init(opt)
  local tilew = opt.tilew or 16
  local tileh = opt.tileh or 16
  local keepSurface = opt.keepSurface or false
  if opt.file then
    self._image = ant.image.load(opt.engine, opt.file, tilew, tileh, keepSurface)
    if not self._image then
      return nil, 'failed to load image'
    end
  elseif opt.w and opt.h then
    self._image = ant.image.createBlank(opt.engine, opt.w, opt.h, tilew, tileh)
    if not self._image then
      return nil, 'failed to create image'
    end
  end

  self.engine = opt.engine
  ant.image.get(self._image, self)

  self.tw = tilew
  self.th = tileh

  self.file = opt.file
end

function Image:colorMod(r, g, b)
  ant.image.colorMod(self._image, r, g, b)
end

function Image:alphaMod(a)
  ant.image.alphaMod(self._image, a)
end

function Image:draw(sx, sy, sw, sh, dx, dy, dw, dh)
  ant.image.draw(self._image, sx, sy, sw, sh, dx, dy, dw, dh)
end


function Image:drawWhole(dx, dy)
  ant.image.drawWhole(self._image, dx, dy)
end


function Image:drawTile(tilex, tiley, dx, dy)
  ant.image.drawTile(self._image, tilex, tiley, dx, dy)
end


function Image:drawText(text, x, y, wrapwidth)
  ant.image.drawText(self._image, text, x, y, wrapwidth)
end

function Image:scale(scale)
  ant.image.scale(self._image, scale)
  ant.image.get(self._image, self)
end


function Image:targetImage(other)
  local otherptr = nil
  if other then
    otherptr = other._image
  end
  ant.image.targetImage(self._image, otherptr)
end


function Image:drawCentered()
  local x = (self.engine.vw // 2) - (self.w // 2)
  local y = (self.engine.vh // 2) - (self.h // 2)
  self:draw(0, 0, self.w, self.h, x, y, self.w, self.h)
end

function Image:getPixels()
  return ant.image.getPixels(self._image)
end

function Image:getPixel(x, y)
  return ant.image.getPixel(self._image, x, y)
end

function Image:destroy()
  ant.image.destroy(self._image)
end

return Image

