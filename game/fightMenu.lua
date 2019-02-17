local math = require 'math'

local Class = require 'class'
local Image = require 'image'

local Menu = require 'game.menu'

local FightMenu = Class(Menu)

local fontFile = 'res/text-5x9.png'
local fontW, fontH = 5, 9

FightMenu.imageFile = 'res/fightmenu.png'
FightMenu.sprites = {
    heart = {x=0, y=0, w=13, h=11},
    sword = {x=0, y=16, w=12, h=11},
    speech = {x=0, y=32, w=12, h=11},
    slide = {x=0, y=48, w=22, h=11},
    bag = {x=16, y=0, w=12, h=12}
}


-- for trying to talk rather than fight
FightMenu.phrases = {
    'Hey now, hey now!',
    "Hold up, let's talk!",
    "Don't hurt me!"
}


-- TODO fighting controls


FightMenu.keyGuide = {
    {key = 'U', icon = 'sword'},
    {key = 'I', icon = 'bag'},
    {key = 'J', icon = 'slide'},
    {key = 'K', icon = 'speech'}
}


function FightMenu:init(opt)
    self.resourceMan = opt.resourceMan
    self.engine = opt.resourceMan:get('engine')

    self.font = opt.resourceMan:get(fontFile, Image, {
        engine = self.engine,
        file = fontFile, tilew = fontW, tileH = fontH
    })

    self.image = opt.resourceMan:get(self.imageFile, Image, {
        engine = self.engine,
        file = self.imageFile
    })

    Menu.init(self, opt)

    
    self.controlMap = {
        U = 'attack',
        I = 'bag',
        J = 'slide',
        K = 'talk'
    }
    self.onkeydown = {
        attack = function()
            self.controller.hero:strike()
        end
    }

    self.talkPhrase = self:getRandomPhrase()
end


function FightMenu:draw()
    -- Draw hero health bar
    self.controller.hero:drawHealthBar()
    local heart = self.sprites.heart
    self.image:draw(
        heart.x, heart.y, heart.w, heart.h,
        self.engine.vw - 12 - heart.w,
        3,
        heart.w,
        heart.h
    )

    -- Draw control guide
    local baseX, baseY = (self.engine.vw // 2 + 20), 40
    self.engine:setColor(20, 12, 18, 255)
    self.font:colorMod(255, 255, 255)
    for y = 0, 1 do
        for x = 0, 1 do
            local opt = self.keyGuide[y * 2 + x + 1]
            local cx, cy = (baseX + (x * 36)), (baseY + (y * 14))

            local icon = self.sprites[opt.icon]

            -- Draw key
            self.engine:fillRect(cx, cy, 11, 11)
            self.font:drawText(opt.key, cx + 3, cy + 1, 100)
            self.image:draw(
                icon.x, icon.y, icon.w, icon.h,
                cx + 12, cy, icon.w, icon.h
            )

            if opt.icon == 'speech' then
                self.font:colorMod(48, 52, 109)
                self.font:drawText(self.talkPhrase, cx + 26, cy + 1, 100)
            end
        end
    end
end


function FightMenu:getRandomPhrase()
    return '"'..self.phrases[math.random() * #self.phrases // 1 + 1]..'"'
end

return FightMenu

