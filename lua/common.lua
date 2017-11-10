local class = require("class")

local common = {}

Common = class.base()

Common.init = function(self)
    -- TODO anything here?
end


Common.get = function(self, key)
    return self[key]
end


Common.set = function(self, settable)
    for k, v in pairs(settable) do
        self[k] = v
    end
end

