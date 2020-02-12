
local Class = require 'class'

local ResourceManager = Class()


function ResourceManager:init(resDir)
  self.resDir = resDir
  self.resources = {}
end

function ResourceManager:get(name, class, opt)
  local loadedRes = self.resources[name]
  if not loadedRes then
    loadedRes = class(opt)
    self.resources[name] = loadedRes
  end

  return loadedRes
end

function ResourceManager:set(key, val)
  self.resources[key] = val
end

function ResourceManager:has(name)
  return self.resources[name] ~= nil
end


function ResourceManager:forget(name)
  self.resources[name] = nil
end


return ResourceManager

