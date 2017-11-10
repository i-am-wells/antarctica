local class = require("class")
local Common = require("common")

local EventReceiver = class.deriving(Common)

EventReceiver.init = function(self)
    self.listeners = {}
end


EventReceiver.addEventListener = function(self, key, handler)
    local handlerList = self.listeners[key] or []
    handlerList[(#handlerList) + 1] = handler
    self[key] = handlerList
end


EventReceiver.removeEventListener = function(self, key, handler)
    local handlerList = self.listeners[key]
    if handlerList == nil then
        return
    end

    -- Overwrite and shift down
    local found = false
    for i, handlerFromList in ipairs(handlerList) do
        if found then
            handlerList[i - 1] = handlerFromList
        else
            if handlerFromList == handler then
                found = true
            end
        end
    end
    if found then
        handlerList[#handlerList] = nil
    end
end


EventReceiver.trigger = function(self, key, params)
    local handlerList = self.listeners[key]
    if handlerList == nil then
        return
    end

    for i, handler in ipairs(handlerList) do
        handler(params)
    end
end


