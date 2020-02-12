
local Engine = require 'engine'
local Image = require 'image'

local engine = Engine{
  w=300*3, h=200*3
}
engine:setColor(255,255,255,255)
engine:setLogicalSize(300, 200)


-- load image
local file, tw, th, nframes = arg[2], arg[3], arg[4], arg[5]
local img = Image{
  engine=engine,
  file=file,
  tilew=tw,
  tileh=th
}


local counter, frame = 0, 0
engine:run{
  redraw = function()

    engine:clear()
    img:drawTile(0, frame, 0, 0)

    counter = (counter + 1) % 12
    if counter == 0 then
      frame = (frame + 1) % nframes
    end
  end
}


