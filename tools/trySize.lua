local Engine = require 'engine'

local w = tonumber(arg[2])
local h = tonumber(arg[3])

local e = Engine{w=w*3, h=h*3}

e:setLogicalSize(w, h)
local counter = 0
e:run{
    redraw = function()
        counter = counter + 1
        print(counter)
        if counter == 1000 then
            e:stop()
        end
    end
}


