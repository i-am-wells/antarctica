local Class = require 'class'
local Image = require 'image'

local SpeechBubble = Class()

SpeechBubble.fontFile = 'res/text-6x12.png'
SpeechBubble.fontSmallFile = 'res/text-5x9.png'
SpeechBubble.imageFile = 'res/speechbubble.png'

SpeechBubble.sprites = {
    main = {x=0, y=0, w=100, h=74},
    sw = {x=100, y=0, w=15, h=16},
    se = {x=100, y=16, w=15, h=16},
    ne = {x=100, y=32, w=15, h=16},
    nw = {x=100, y=48, w=15, h=16},
}

function SpeechBubble:init(args)
    self.text = args.text
    self.bg = args.bg or {r=255, g=255, b=255}
    self.border = args.border or {r=0, g=0, b=0}
    self.margin = args.margin or 5

    self.engine = args.resourceMan:get('engine')

    self.font = args.font or args.resourceMan:get(self.fontSmallFile, Image, {
        file = self.fontSmallFile,
        engine = self.engine,
        tilew = 5,
        tileh = 9
    })
    self.font:colorMod(20, 0, 40)

    self.bgImage = args.resourceMan:get(self.imageFile, Image, {
        file = self.imageFile,
        engine = self.engine,
    })

    self.sx = args.sx or 1000
    self.sy = args.sy or 1000

    self.dy = self.sy - 2 * self.margin - self.sprites.nw.h

    if self.sx < self.engine.vw / 2 then
        self.dx = self.sx - self.sprites.main.w - 2 * self.sprites.nw.w
        self.stem = self.sprites.nw
    else
        self.dx = self.sx + 2 * self.sprites.ne.w
        self.stem = self.sprites.ne
    end
end


function SpeechBubble:draw()
    local bg, border = self.bg, self.border

    -- TODO just draw an image here
    local main, stem = self.sprites.main, self.stem
    self.bgImage:draw(main.x, main.y, main.w, main.h, self.dx, self.dy, main.w, main.h)
    if self.stem == self.sprites.nw then
        self.bgImage:draw(stem.x, stem.y, stem.w, stem.h, self.dx+main.w-1, self.dy+self.margin+1, stem.w, stem.h)
    else
        self.bgImage:draw(stem.x, stem.y, stem.w, stem.h, self.dx-stem.w+1, self.dy+self.margin+1, stem.w, stem.h)
    end

    -- Text
    self.font:drawText(
        self.text, 
        self.dx + self.margin, 
        self.dy + self.margin,
        main.w
    )

end


function SpeechBubble:updatePosition(newSx, newSy)
    local diffX, diffY = newSx - self.sx, newSy - self.sy
    self.dx = self.dx + diffX
    self.dy = self.dy + diffY
    self.sx = newSx
    self.sy = newSy
end


return SpeechBubble

