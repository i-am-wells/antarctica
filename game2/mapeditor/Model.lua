local Util = require 'Util'

local Stack = require 'Stack'
local Class = require 'class'


-- Edit needs:
--  apply, unapply

-- Types of edits:
-- map tile draws
--    list draw
--    rect draw
-- complex map feature
--    list add
--    list remove
--    list move
-- objects
--    list add
--    list remove
--    list move
--    list rotate?

local Model = Class()

Model.Edit = Class()
-- TODO Model.Edit should handle thing-map updates?

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

Model.TileEdit = Class(Model.Edit)
function Model.TileEdit:init(model)
  self.model = model
  self.tiles = {}
end
function Model.TileEdit:addTile(z, x, y, newIdx)
  local tile = {z=z, x=x, y=y, newIdx=newIdx}
  tile.origIdx = self.model.map:getTileInfoIdxForTile(z, x, y)
  self.tiles[#self.tiles+1] = tile

  self:applyTile(z, x, y, tile.newIdx)
end

function Model.TileEdit:isSameLocationAsLast(z, x, y)
  local top = self.tiles[#self.tiles]
  return top and top.z == z and top.x == x and top.y == y
end

function Model.TileEdit:applyTile(z, x, y, idx)
  self.model.map:setTileInfoIdxForTile(z, x, y, idx)
end

function Model.TileEdit:apply()
  for _, tile in ipairs(self.tiles) do
    self:applyTile(tile.z, tile.x, tile.y, tile.newIdx)
  end
end

function Model.TileEdit:unapply()
  for _, tile in ipairs(self.tiles) do
    self:applyTile(tile.z, tile.x, tile.y, tile.origIdx)
  end
end

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

function Model:init(arg)
  self.map = arg.map
  -- TODO thing-map

  self.undoStack = Stack()
  self.redoStack = Stack()
  
  if __dbg then
    assert(self.map)
  end
end

function Model:getTileToDraw()
  -- TODO
  return 2, 6, 0 -- penguin head in forest-16x16.png
end

function Model:makeTileEdit()
  return Model.TileEdit(self)
end

function Model:update(edit)
  -- TODO thing-map update
  self.undoStack:push(edit)
end

function Model:undo()
  local edit = self.undoStack:pop()
  if not edit then
    return
  end

  edit:unapply(self)
  self.redoStack:push(edit)
end

function Model:redo()
  local edit = self.redoStack:pop()
  if not edit then
    return
  end

  edit:apply(self)
  self.undoStack:push(edit)
end

return Model
