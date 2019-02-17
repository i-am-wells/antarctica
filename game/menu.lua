local Class = require 'class'

local Menu = Class()

-- Subclasses might implement drawing, key input, other
Menu.controlMap = {
    D = 'right',
    W = 'up',
    A = 'left',
    S = 'down',
    Escape = 'back',
    J = 'back',
    K = 'choose',
    Space = 'choose'
}


function Menu:init(options)
    -- TODO inherit default behavior from controller!
    --
    self.onkeydown = setmetatable({
        right = function()
            self:onRight()
        end,
        up = function()
            self:onUp()
        end,
        left = function()
            self:onLeft()
        end,
        down = function()
            self:onDown()
        end,
        back = function()
            self:onBack()
        end,
        choose = function()
            self:onChoose()
        end
    }, 
    {
        __index = function(_, key) return function() end end
    })

    self.onkeyup = setmetatable({}, {__index=function(_, key) return function() end end})
    
    -- there should always be at least one choice
    self.choices = self.choices or options.choices or {{label='okay'}}
    self.idx = 1

    self.isOpen = false
end


function Menu:open(controller)
    print('menu open: '..tostring(self))

    -- controller is the root game object calling engine:run
    self.controller = controller

    -- push inventory, save game controls
    table.insert(controller.menuStack, {
        onkeydown = controller.onkeydown,
        onkeyup = controller.onkeyup,
        controlMap = controller.controlMap,
        menu = self,
    })

    -- use own controls
    controller.onkeydown = setmetatable(self.onkeydown or {}, {__index=controller.onkeydown})
    controller.onkeyup = setmetatable(self.onkeyup or {}, {__index=controller.onkeyup})
    controller.controlMap = setmetatable(self.controlMap or {}, {__index=controller.controlMap})

    self.isOpen = true
end


function Menu:close()
    local controller = self.controller

    -- when the menu is closed, restore original controls
    local top = table.remove(controller.menuStack)
    controller.onkeydown = top.onkeydown
    controller.onkeyup = top.onkeyup
    controller.controlMap = top.controlMap

    self.isOpen = false
end

-- Children should implement drawing


-- Default behavior
function Menu:onRight()
    self:incChosen()
end

function Menu:onUp()
    self:decChosen()
end

function Menu:onDown()
    self:incChosen()
end

function Menu:onLeft()
    self:decChosen()
end

function Menu:onBack()
    self:close()
end

function Menu:onChoose()
    -- Make choice?
    local choice = self.choices[self.idx]
    if choice and choice.action then
        choice.action()
    end
end


-- choices are one-indexed
function Menu:incChosen()
    self.idx = (self.idx % #self.choices) + 1
end

function Menu:decChosen()
    self.idx = ((self.idx - 2) % #self.choices) + 1
end

return Menu
