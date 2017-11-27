
local class = require 'class'

local ant = require 'antarctica'

-- TODO define these in C library loader since we're trying to hide SDL details
local eventkeymap = {
    quit            = 0x100,
    
    window          = 0x200,
    windowshown     = 0x201,
    windowhidden    = 0x202,
    windowexposed   = 0x203,
    windowmoved     = 0x204,
    windowresized   = 0x205,
    windowsizechanged = 0x206,
    windowminimized = 0x207,
    windowmaximized = 0x208,
    windowrestored  = 0x209,
    windowenter     = 0x20a,
    windowleave     = 0x20b,
    windowfocusgained = 0x20c,
    windowfocuslost = 0x20d,
    windowclose     = 0x20e,

    keydown         = 0x300,
    keyup           = 0x301,

    mousemotion     = 0x400,
    mousebuttondown = 0x401,
    mousebuttonup   = 0x402,
    mousewheel      = 0x403
}

local Engine = class.base()


-- Engine constructor
function Engine:init(...)
    self._engine = ant.engine.create(...)
    if not self._engine then
        return 'failed to create engine'
    end
end


function Engine:on(tbl)
    for key, value in pairs(tbl) do
        if type(value) == 'function' then
            local sdlevent_type = eventkeymap[key]
            if sdlevent_type then
                ant.engine.sethandler(self._engine, sdlevent_type, value);
            elseif key == 'redraw' then
                ant.engine.setredraw(self._engine, value);
            else
                error('unknown event type "'..key..'"')
            end
        else
            error('handler for "'..key..'" is not a function')
        end
    end
end


function Engine:run(logic)
    if logic then
        self:on(logic)
    end

    ant.engine.run(self._engine)
end


function Engine:stop()
    ant.engine.stop(self._engine)
end


function Engine:drawpoint(x, y)
    ant.engine.drawpoint(self._engine, x, y)
end


function Engine:drawline(x0, y0, x1, y1)
    ant.engine.drawline(self._engine, x0, y0, x1, y1)
end


function Engine:drawrect(x, y, w, h)
    ant.engine.drawrect(self._engine, x, y, w, h)
end

function Engine:fillrect(x, y, w, h)
    ant.engine.fillrect(self._engine, x, y, w, h)
end


function Engine:clear()
    ant.engine.clear(self._engine)
end


function Engine:setcolor(r, g, b, a)
    ant.engine.setcolor(self._engine, r, g, b, a)
end

function Engine:getcolor()
    return ant.engine.getcolor(self._engine)
end

function Engine:setlogicalsize(w, h)
    ant.engine.setlogicalsize(self._engine, w, h)
end

return Engine

