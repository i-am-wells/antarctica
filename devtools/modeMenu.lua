local Class = require 'class'

local Menu = require 'game.menu'


local modules = {
    {label='object editor', module = require 'devtools.objectEditor'}
}

local fontFile = 'res/text-6x12.png'


local ModeMenu = Class(Menu)

ModeMenu.margin = 6

function ModeMenu:init(opt)
    self.devSession = opt.devSession
    self.resourceMan = opt.devSession.game.resourceMan

    self.engine = self.resourceMan:get('engine')
    self.w = self.engine.vw // 2
    self.h = self.engine.vh // 2
    self.x = (self.engine.vw // 2) - (self.w // 2)
    self.y = (self.engine.vh // 2) - (self.h // 2)


    self.font = self.resourceMan:get(fontFile, Image, {
        engine = self.engine,
        file = fontFile,
        tilew = 6, tileh = 12
    })

    self.choices = {}
    for i, v in ipairs(modules) do
        self.choices[i] = {label=v.label, action=function() self:launch(v.module) end}
    end

    Menu.init(self, opt)
end


function ModeMenu:launch(module)
    self:close()

    local m = module{devSession = self.devSession}
    m:launch()
end


function ModeMenu:draw()
    -- draw background
    self.engine:setColor(0, 0, 0, 255)
    self.engine:fillRect(self.x, self.y, self.w, self.h)

    local line = 0

    -- draw title
    self.font:colorMod(255, 255, 255)
    self.font:drawText('Dev Tools', self.x + self.margin, self.y + self.margin + self.font.th * line, self.w - self.margin)
    line = line + 1

    -- draw options
    for i, v in ipairs(self.choices) do
        if i == self.idx then
            self.font:colorMod(0, 255, 0)
        else
            self.font:colorMod(0, 127, 0)
        end


        self.font:drawText(v.label, self.x + self.margin, self.y + self.margin + self.font.th * line, self.w - self.margin)
        line = line + 1
    end
end

return ModeMenu
