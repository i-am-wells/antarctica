
local Class = require 'class'

local ant = require 'antarctica'

local Engine = Class()

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
    textediting     = 0x302,
    textinput       = 0x303,

    mousemotion     = 0x400,
    mousebuttondown = 0x401,
    mousebuttonup   = 0x402,
    mousewheel      = 0x403
}
Engine.eventkeymap = eventkeymap
-- TODO define in c side
local _lshift, _rshift, _lctrl, _rctrl, _lalt, _ralt = 0x1, 0x2, 0x40, 0x80, 0x100, 0x200
Engine.keymod = {
    lShift = _lshift,
    rShift = _rshift,
    shift = _lshift | _rshift,
    lCtrl = _lctrl,
    rCtrl = _rctrl,
    ctrl = _lctrl | _rctrl,
    lAlt = _lalt,
    rAlt = _ralt,
    alt = _lalt | _ralt
}

-- TODO define in c side
-- see SDL_mouse.h
Engine.mousebutton = {
    left = 1,
    middle = 2,
    right = 3,
    x1 = 4,
    x2 = 5
}

-- Engine constructor
function Engine:init(...)
    self._engine = ant.engine.create(...)
    if not self._engine then
        return 'failed to create engine'
    end

    self.callbackHeap = {}
end

local heap_push = function(heap, entry)
    table.insert(heap, entry)
    local entryidx = #heap

    while true do
        -- TODO check parent index!
        local parentidx = ((entryidx - 1) // 2) + 1
        local parent = heap[parentidx]
        if (entry == parent) or (entry.time >= parent.time) then
            return
        else
            heap[parentidx] = entry
            heap[entryidx] = parent
            entryidx = parentidx
        end
    end
end


local heap_pop = function(heap)
    heap[1] = heap[#heap]
    heap[#heap] = nil

    local entryidx = 1
    while true do
        local entry = heap[entryidx]
        local lchildidx = entryidx * 2
        local lchild = heap[lchildidx]
        if not lchild then
            -- leaf
            return
        else
            local rchildidx = lchildidx + 1
            local rchild = heap[rchildidx]
            if rchild then
                if (lchild.time < rchild.time) and (lchild.time < entry.time) then
                    heap[entryidx] = lchild
                    heap[lchildidx] = entry
                    entryidx = lchildidx
                elseif (rchild.time < lchild.time) and (rchild.time < entry.time) then
                    heap[entryidx] = rchild
                    heap[rchildidx] = entry
                    entryidx = rchildidx
                else
                    return
                end
            else
                if entry.time >= lchild.time then
                    -- swap
                    heap[entryidx] = lchild
                    heap[lchildidx] = entry
                    entryidx = lchildidx
                else
                    return
                end
            end
        end
        
    end
end


function Engine:setTimeout(timeout, callback, _self)
    local timeout = {
        time = ant.engine.msSinceStart() + timeout,
        wait = interval,
        repeating = true,
        callback = callback,
        _self = _self
    }
    heap_push(self.callbackHeap, timeout)
    return timeout
end


function Engine:setInterval(interval, callback, _self)
    local interval = {
        time = ant.engine.msSinceStart() + interval,
        wait = interval,
        repeating = true,
        callback = callback,
        _self = _self
    }
    heap_push(self.callbackHeap, interval)
    return interval
end


function Engine:runCallbacks()
    local now, entry
    repeat
        entry = self.callbackHeap[1]
        if not entry then
            break
        end
        now = ant.engine.msSinceStart()

        if now >= entry.time then
            -- Run the callback
            if type(entry.callback) == 'function' then
                entry.callback(entry._self)
            end
            heap_pop(self)

            -- If repeating, add the entry back into the heap
            if entry.repeating then
                entry.time = ant.engine.msSinceStart() + entry.wait
                heap_push(self, entry)
            end
        end

    until now < entry.time 
end


function Engine:on(tbl)
    for key, value in pairs(tbl) do
        if type(value) == 'function' then
            local sdlevent_type = eventkeymap[key]
            if sdlevent_type then
                ant.engine.setHandler(self._engine, sdlevent_type, value);
            elseif key == 'redraw' then
                ant.engine.setRedraw(self._engine, value);
            else
                error('unknown event type "'..key..'"')
            end

            self['on'..key] = value
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


function Engine:drawPoint(x, y)
    ant.engine.drawPoint(self._engine, x, y)
end


function Engine:drawLine(x0, y0, x1, y1)
    ant.engine.drawLine(self._engine, x0, y0, x1, y1)
end


function Engine:drawRect(x, y, w, h)
    ant.engine.drawRect(self._engine, x, y, w, h)
end

function Engine:fillRect(x, y, w, h)
    ant.engine.fillRect(self._engine, x, y, w, h)
end


function Engine:clear()
    ant.engine.clear(self._engine)
end


function Engine:setColor(r, g, b, a)
    ant.engine.setColor(self._engine, r, g, b, a)
end

function Engine:getColor()
    return ant.engine.getColor(self._engine)
end

function Engine:setLogicalSize(w, h)
    ant.engine.setLogicalSize(self._engine, w, h)
end

function Engine:getLogicalSize()
    return ant.engine.getLogicalSize(self._engine)
end

function Engine:getSize()
    return ant.engine.getSize(self._engine)
end

function Engine:setScale(scaleX, scaleY)
    ant.engine.setScale(self._engine, scaleX or 1, scaleY or 1)
end

return Engine

