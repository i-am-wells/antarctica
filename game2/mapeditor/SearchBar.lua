local ant = require 'antarctica'
local Context = require 'ui.Context'
local InputHandler = require 'ui.InputHandler'
local Class = require 'class'
local Util = require 'Util'
local Trie = require 'Trie'
local VerticalContainer = require 'ui.elements.VerticalContainer'
local CursorText = require 'ui.elements.CursorText'
local HighlightableText = require 'game2.HighlightableText'
local ListMenu = require 'game2.ListMenu'
local RgbaColor = require 'RgbaColor'

local SearchBar = Class(Context)

local tileInfoModules = {
  'res.tiles.waves',
  'res.tiles.demo.demo',
}

local fontPath = __rootdir .. '/res/text-5x9.png'

local padX, padY = 8, 8

function SearchBar:init(arg)
  self.engine = engine or arg.engine
  if __dbg then
    assert(self.engine)
    assert(arg.imageCache)
  end
 
  self.imageCache = arg.imageCache
  self.font = self.imageCache:get{
    file = fontPath,
    engine = self.engine,
    tilew = 5,
    tileh = 9
  }
  assert(self.font)

  self:buildTrie(tileInfoModules)

  Util.using({context = self, engine = self.engine}, function()
    self.searchBar = CursorText{
      font = self.font,
      width = 300,
      onUpdate = self:bind(self.updateMatchList),
    }
    self.matchList = VerticalContainer{}
    self.matchListMenu = ListMenu{
      x = padX,
      y = 25,
      container = self.matchList,
    }

    Context.init(self, {
      engine = self.engine,
      draw = self:bind(self.draw),
      inputHandler = InputHandler{
        textInput = self:bind(self.onTextInput),
        textEditing = self:bind(self.onTextEditing),
        actions = {
          backspace = self:bind(self.backspace),
          moveCursorRight = self:bind(self.moveCursorRight),
          moveCursorLeft = self:bind(self.moveCursorLeft),
          moveCursorHome = self:bind(self.moveCursorHome),
          moveCursorEnd = self:bind(self.moveCursorEnd),
          autocomplete = self:bind(self.autocomplete),
          prevChoice = self:bind(self.prevChoice),
          nextChoice = self:bind(self.nextChoice),
          choose = self:bind(self.choose),
          banish = self:bind(self.banish),
        },
        -- TODO split out text input?
        keys = {
          Backspace = 'backspace',
          Right = 'moveCursorRight',
          Left = 'moveCursorLeft',
          Up = 'prevChoice',
          Down = 'nextChoice',
          Tab = 'autocomplete',
          Home = 'moveCursorHome',
          End = 'moveCursorEnd',
          Return = 'choose',
          Escape = 'banish'
        },
        allowKeyRepeat = true,
      }
    })
    self:updateMatchList('')
  end)
end

function SearchBar:bind(method)
  return Util.bind(method, self)
end

local makeInfoName = function(moduleName, key)
  return string.format('%s#%s', moduleName, key)
end

local splitInfoName = function(infoName)
  local _, __, moduleName, key = string.find(infoName, '^(.*)#(.*)$')
  return moduleName, key
end

function SearchBar:buildTrie(modules)
  self.trie = Trie()

  for _, moduleName in ipairs(modules) do
    local module = require(moduleName)
    for key, info in pairs(module) do
      -- TODO load image here?
      self.trie:set(makeInfoName(moduleName, key), info)
    end
  end
end

function SearchBar:backspace(keyState)
  if keyState == 'down' then
    self.searchBar:deleteBeforeCursor()
  end
end

function SearchBar:moveCursorRight(keyState)
  if keyState == 'down' then
    self.searchBar:moveCursor(1)
  end
end

function SearchBar:moveCursorLeft(keyState)
  if keyState == 'down' then
    self.searchBar:moveCursor(-1)
  end
end

function SearchBar:moveCursorHome(keyState)
  if keyState == 'down' then
    self.searchBar:setCursorPosition(0)
  end
end

function SearchBar:moveCursorEnd(keyState)
  if keyState == 'down' then
    self.searchBar:setCursorPosition(#self.searchBar.text)
  end
end

function SearchBar:autocomplete(keyState)
  if keyState == 'down' then
    if not self.searchBar:isCursorAtEnd() then
      return
    end

    local subtrie = self.trie:getNode(self.searchBar.text)
    if not subtrie then
      return
    end

    local commonPrefix = subtrie:getCommonPrefix()
    if commonPrefix ~= '' then
      self.searchBar:insertAtCursor(commonPrefix)
    end
  end
end

function SearchBar:prevChoice(keyState)
  if keyState == 'down' then
    self.matchListMenu:prev()
  end
end

function SearchBar:nextChoice(keyState)
  if keyState == 'down' then
    self.matchListMenu:next()
  end
end

function SearchBar:choose(keyState)
  if keyState == 'down' then
    self.matchListMenu:choose()
  end
end

function SearchBar:chooseTile(name, tileInfo)
  -- TODO replace this
  print('chose '..name..':')
  for k, v in pairs(tileInfo) do
    print(k, v)
  end
end

function SearchBar:banish(keyState)
  if keyState == 'down' then
    ant.engine.stopTextInput()
    self:returnControlToParent()
  end
end

function SearchBar:takeControlFrom(parent)
  print('open search bar')
  ant.engine.startTextInput()
  Context.takeControlFrom(self, parent)
end

local textColor = RgbaColor(0, 0, 0)
local highlightColor = RgbaColor(0xc0, 0xc0, 0xc0)

function SearchBar:makeHighlightableText(text, action)
  return HighlightableText{
    font = self.font,
    width = 300,
    text = text,
    action = action,
    color = textColor,
    highlight = highlightColor,
    blink = false,
    context = self
  }
end

function SearchBar:updateMatchList(query)
  -- update list of suggestions
  self.matchList:clearChildren()
  local subtrie = self.trie:getNode(query)
  if not subtrie then
    return
  end
  self.results = subtrie:getKeysAndValues()

  for key, tile in pairs(self.results) do
    self.matchList:addChild(self:makeHighlightableText(
      --[[text=]]key,
      --[[action=]]Util.bind(self.chooseTile, self, key, tile)))
  end
  self.matchList:sort(function(a, b) return a.text < b.text end)
  self.matchListMenu:setChoice(0)
end

function SearchBar:onTextInput(input)
  if self.text == '' and input == '/' then
    return
  end
  self.searchBar:insertAtCursor(input)
end

function SearchBar:draw()
  if self.parentContext then
    self.parentContext:draw()
  end

  self.searchBar:draw(padX, padY)
  self.matchListMenu:draw()
end


return SearchBar
