
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

    --ant.image.get(self._image, self)

    self.tw = tilew
    self.th = tileh
end


function Image:draw(sx, sy, sw, sh, dx, dy, dw, dh)
    ant.image.draw(self._image, sx, sy, sw, sh, dx, dy, dw, dh)
end


function Image:drawwhole(dx, dy)
    ant.image.drawwhole(self._image, dx, dy)
end


function Image:drawtile(tilenum, dx, dy)
    ant.image.drawtile(self._image, tilenum, dx, dy)
end

return Image

