
local class = require 'class'

local acc = require 'accursed'


local Image = class.base()

function Image:init(opt)
    local tilew = opt.tilew or 16
    local tileh = opt.tileh or 16
    self._image = acc.image.load(opt.engine, opt.file, tilew, tileh)
    if not self._image then
        return nil, 'failed to load image'
    end

    --acc.image.get(self._image, self)

    self.tw = tilew
    self.th = tileh
end


function Image:draw(sx, sy, sw, sh, dx, dy, dw, dh)
    acc.image.draw(self._image, sx, sy, sw, sh, dx, dy, dw, dh)
end


function Image:drawwhole(dx, dy)
    acc.image.drawwhole(self._image, dx, dy)
end


function Image:drawtile(tilenum, dx, dy)
    acc.image.drawtile(self._image, tilenum, dx, dy)
end

return Image

