return require 'class'{
  init = function(self, arg)
    self.mapEditorContext = arg.mapEditor
    self.model = arg.mapEditor.model
  end,

  mouseDown = function(self, mapX, mapY, x, y, button)
  end,

  mouseUp = function(self, mapX, mapY, x, y, button)
  end,

  mouseMotion = function(self, mapX, mapY, x, y, dx, dy)
  end,

  draw = function(self)
  end,
}
