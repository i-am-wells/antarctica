local math = require 'math'

local Class = require 'class'
local Image = require 'image'

local Penguin = require 'game.penguin'
local Inventory = require 'game.inventory'
local FightMenu = require 'game.fightMenu'

local Hero = Class(Penguin)


function Hero:init(options)
    local engine = options.resourceMan:get('engine')
    self.engine = engine

    self.controller = options.controller

    self.data = options.data
    
    Penguin.init(self, options)

    -- load inventory
    self.inventory = Inventory{
        resourceMan = options.resourceMan,
        items = self.data.inventoryItems
    }

    -- TODO fix
    self.hp = 10
    self.maxHp = 10

    -- TODO remove
    self:setMass(9)

    self.moveDirectionStack = {}
end


-- for saving state
function Hero:toTable()
    local objtable = Object.toTable(self)
    -- TODO
end


function Hero:pushDirection(direction)
    table.insert(self.moveDirectionStack, direction)
end


function Hero:popDirection(direction)
    for i = (#self.moveDirectionStack), 1, -1 do
        if self.moveDirectionStack[i] == direction then
            table.remove(self.moveDirectionStack, i)
            return
        end
    end
end


-- Which way should the hero move?
function Hero:moveDirection()
    local directionEW, directionNS = nil, nil

    for i = (#self.moveDirectionStack), 1, -1 do
        local d = self.moveDirectionStack[i]
        if d == 'east' or d == 'west' then
            directionEW = d
        elseif d == 'north' or d == 'south' then
            directionNS = d
        end

        if directionEW and directionNS then
            break
        end
    end

    return directionEW, directionNS
end


function Hero:updateMovement() 
    local dEW, dNS = self:moveDirection()

    local velX, velY = nil, nil
    if dEW == 'east' then
        velX = self.stepsize
    elseif dEW == 'west' then
        velX = -self.stepsize
    end

        if dNS == 'north' then
        velY = -self.stepsize
    elseif dNS == 'south' then
        velY = self.stepsize
    end

    self:setVelocity(velX, velY)
    self:updateDirection()
    
    if self.movement ~= 'slide' then
        self:stand()
    end
end


function Hero:stop()
    -- force stop
    self.moveDirectionStack = {}
    self:setVelocity(0, 0)
    self:stand()
end


function Hero:oncollision(other)
    if self:isFacing(other) then
        self.interactTarget = other
    end
end


function Hero:fight()
    if (not self.fightMenu) and self.interactTarget and self:isFacing(self.interactTarget) then
        -- load fight menu
        self.fightMenu = FightMenu{resourceMan = self.resourceMan}
        self.fightMenu:open(self.controller)
    end
end


function Hero:drawHealthBar()
    -- draw it on the right side
    self.engine:setColor(20, 12, 28, 255)
    self.engine:drawRect(self.engine.vw - 11, 1, 10, self.engine.vh - 2)
    
    local barHeight = self.engine.vh - 6
    local fillHeight = math.ceil(self.hp / self.maxHp * barHeight)

    self.engine:setColor(106, 190, 48, 255)
    self.engine:fillRect(self.engine.vw - 9, 3 + barHeight - fillHeight, 6, fillHeight)
end


function Hero:strike()
    self:peck()
end


return Hero

