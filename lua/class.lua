
local Class = function(...)

    -- our class table
    local klass = {
        initSuper = {},
        isA = {}
    }

    -- copy things from parent classes
    for _, base in ipairs{...} do

        -- copy isA table
        klass.isA[klass] = true
        klass.isA[base] = true

        -- copy base class contents
        for k, v in pairs(base) do
            if k == "isA" then
                -- copy isA table
                for isAKey, isAValue in pairs(v) do
                    klass.isA[isAKey] = isAValue
                end
                --[[
            elseif k == "init" then
                -- keep base class constructor
                klass.initSuper[base] = v
                --]]
            else
                -- shallow copy base class data
                klass[k] = v
            end
        end
       
    end

    local klassMT = getmetatable(klass) or {}

    -- When klass is called, return new instance
    klassMT.__call = function(klassarg, ...)
        local that = {}
        setmetatable(that, {
            -- look up instance methods from klass
            __index = klass
        })

        local err = nil
        if that.init then
            _, err = that:init(...)
        end

        if err then
            return nil, err
        end
        return that, err
    end

    setmetatable(klass, klassMT)

    return klass
end


--[[
class.deriving = function(...)
    return Class(...)
end
class.base = function()
    return class.deriving()
end
--]]

return Class
