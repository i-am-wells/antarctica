local string = require 'string'
local Rope = require 'class'()

function Rope:init(...)
  self:splice{...}
end

function Rope:splice(rope)
  for _, v in ipairs(rope) do
    self[#self+1] = v
  end
end

function Rope:add(str)
  self[#self+1] = str
end

function Rope:join()
  return string.format(string.rep('%s', #self), table.unpack(self))
end

return Rope
