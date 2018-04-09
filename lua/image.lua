
local class = require 'class'

local ant = require 'antarctica'


local Image = class.base()

function Image:init(opt)
    local tilew = opt.tilew or 16
    local tileh = opt.tileh or 16
    self._image = ant.image.load(opt.engine, opt.file, tilew, tileh)
    if not self._image then
        return nil, 'failed to load image'
    end

    ant.image.get(self._image, self)

    self.tw = tilew
    self.th = tileh
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

return Image

