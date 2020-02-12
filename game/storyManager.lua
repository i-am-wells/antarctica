local Class = require 'class'

local StoryManager = Class()

function StoryManager:init()
  self.events = {}
end


function StoryManager:registerEvent(key, fn)
  -- Store the event handler
  self.events[key] = fn
end

function StoryManager:registerEvents(tbl)
  for k, v in pairs(tbl) do
    self:registerEvent(k, v)
  end
end

function StoryManager:run(key, state)
  local fn = self.events[key]
  if fn then
    fn(key, state)
  end
end

return StoryManager

