local EditMode = require 'game2.mapeditor.editmodes.EditMode'
local RawTile = require 'game2.mapeditor.editmodes.RawTile'

return require 'class'(EditMode, {
  init = function(self, arg)
    EditMode.init(self, arg)
    self.origEditMode = self.mapEditorContext.editMode
  end,

  mouseUp = function(self, mapX, mapY, x, y, button)
    self.idx = self.mapEditorContext.map:getTileInfoIdxForTile(
      self.mapEditorContext.editLayer, mapX, mapY)
  end,

  getFinalEditMode = function(self)
    if not self.idx then
      return self.origEditMode
    end

    return RawTile{
      mapEditor = self.mapEditorContext,
      idx = self.idx,
      tileInfo = self.mapEditorContext.tileInfos[self.idx],
    }
  end,
})
