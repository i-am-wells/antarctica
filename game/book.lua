local Class = require 'class'
local Image = require 'image'

local Menu = require 'game.menu'

local Book = Class(Menu)

local menuShadow = 'res/menuShadow.png'
local imageFile = 'res/book.png'
Book.pagesW = 292
Book.pagesH = 207


Book.fontBigFile = 'res/text-6x12.png'
Book.fontSmallFile = 'res/text-5x9.png'

-- default content: one empty page
-- replace with table of page-drawing methods
Book.pages = {function(_book) end}

function Book:init(options)
    local engine = options.resourceMan:get('engine')

    -- need: background image
    self.bgImage = options.bgImage
    if not options.bgImage then
        self.bgImage = options.resourceMan:get(imageFile, Image, {
            engine = engine,
            file = imageFile
        })
    end
    
    self.menuShadow = options.resourceMan:get(menuShadow, Image, {
        engine = engine,
        file = menuShadow
    })

    -- need: fonts
    self.fontBig = options.resourceMan:get(self.fontBigFile, Image, {
        engine = engine,
        file = self.fontBigFile,
        tilew = 6,
        tileh = 12
    })
    
    self.fontSmall = options.resourceMan:get(self.fontSmallFile, Image, {
        engine = engine,
        file = self.fontSmallFile,
        tilew = 5,
        tileh = 9
    })

    -- Find page corner
    self.contentX = (engine.vw - self.pagesW) // 2
    self.contentY = (engine.vh - self.pagesH) // 2

    -- set up menu behavior
    self.choices = self.pages
    Menu.init(self, options)
end


function Book:open(controller)
    -- TODO set up book-open animation

    -- take control
    Menu.open(self, controller)
end


function Book:close()
    -- give up controls
    Menu.close(self)
    
    -- TODO set up book-close animation
    --
    
end


-- like ordinary menu choices, but don't cycle
function Book:incChosen()
    if self.idx < #self.choices then
        self.idx = self.idx + 1
    end
end

function Book:decChosen()
    if self.idx > 1 then
        self.idx = self.idx - 1
    end
end


function Book:draw()
    -- Book background image
    self.menuShadow:drawCentered()
    self.bgImage:drawCentered()

    -- Draw content
    local drawFn = self.pages[self.idx]
    if drawFn then
        drawFn(self)
    end

    -- Update animation
    -- TODO animation handling here
    if self.animCounter ~= nil then
        self.animCounter = self.animCounter + 1
    end
end


return Book

