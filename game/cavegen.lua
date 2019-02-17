local math = require 'math'

local Class = require 'class'
local Tilemap = require 'tilemap'

local CaveGen = Class()

local randInt = function(min, max)
    return (min + math.random() * (max - min)) // 1
end


function CaveGen:init(opt)
    self.w = opt.w
    self.h = opt.h
    self.nlayers = opt.nlayers
    self.count = opt.count or 100

    self.nrooms = 5
    self.reachable = {}

    self.tx = 1
    self.ty = 3

    self.seed = opt.seed or os.time()
end

function CaveGen:generate()
    math.randomseed(self.seed)
    --local cX, cY = randInt(0, self.w), randInt(0, self.h)
    local cX, cY = self.w // 2, self.h // 2

    -- Create a map
    local map, err = Tilemap{
        w = self.w,
        h = self.h,
        nlayers = self.nlayers
    }

    if not map then
        error(err)
    end

    -- 1: choose points
    -- 2: make a room at each point
    -- 3: while (not all rooms connnected)
    --      make a hallway between a random pair of unconnected rooms
    --      -- or nearest room centers?
    -- 4: finish, populate, install doors

    self.points = {}
    self.edges = {}
    for i = 1, self.nrooms do
        local point = {
            x = randInt(self.w // 8, self.w * 7 // 8),
            y = randInt(self.h // 8, self.h * 7 // 8)
        }
        table.insert(self.points, point)
        self.edges[i] = {}

        -- Make a room
        self:makeRoom(map, point.x, point.y, self.count)
    end

    -- Carve hallways
    -- pick random starting point, cut hallway to nearest point that isn't already connected!
    -- check 

    self:widen(map)

    return map
end

function CaveGen:setTile(x, y)
    map:setTile(0, x, y, self.tx, self.ty)
    self.reachable[y * self.w + x] = true
end

function CaveGen:isReachable(x, y)
    return self.reachable[y * self.w + x]
end

function CaveGen:makeRoom(map, cX, cY, count)
    -- Tunnel around
    for i = 1, count do
        map:setTile(0, cX, cY, self.tx, self.ty)

        local d = 1

        local dir = randInt(0, 4)
        if dir == 0 and cX < self.w - d then
            cX = cX + d
        elseif dir == 1 and cY > d - 1 then
            cY = cY - d
        elseif dir == 2 and cX > d - 1 then
            cX = cX - d
        elseif dir == 3 and cY < self.h - d then
            cY = cY + d
        end
    end
end

function CaveGen:widen(map)
    for y = 1, map.h - 1 do
        for x = 1, map.w - 1 do
            local tx, ty = map:getTile(0, x, y)
            if tx == self.tx and ty == self.ty then
                map:setTile(0, x - 1, y - 1, tx, ty)
            end
        end
    end
end

function CaveGen:makeHallway(map, point0, point1)
    local x0, y0, x1, y1 = point0.x, point0.y, point1.x, point1.y

    while x0 ~= x1 or y0 ~= y1 do
        -- Advance from one point to the other with jitter
        local diffX, diffY = point1.x - point0.x, point1.y - point0.y
        local rise, run = math.abs(diffY), math.abs(diffX)
        local signX, signY = diffX / run, diffY / rise

        -- Move one space
        local roll = math.random()
        if rise == 0 then
            if roll < 0.25 then 
                y0 = y0 + 1
            elseif roll < 0.75 then
                y0 = y0 - 1
            elseif diffX > 0 then
                x0 = x0 + 1
            else
                x0 = x0 - 1
            end
        elseif run == 0 then
            if roll < 0.25 then 
                x0 = x0 + 1
            elseif roll < 0.75 then
                x0 = x0 - 1
            elseif diffY > 0 then
                y0 = y0 + 1
            else
                y0 = y0 - 1
            end
        else
            if roll < (rise / (rise + run)) then
                y0 = (y0 + signY) // 1
            else
                x0 = (x0 + signX) // 1
            end
        end

        -- Draw
        map:setTile(0, x0, y0, self.tx, self.ty)
    end
end

return CaveGen
