local log = require 'log'
local Image = require 'image'
local ImageCache = require 'class'()

function ImageCache:init()
  self.cache = {}
end

function ImageCache:get(arg)
  local cachedImage = self.cache[arg.file]
  if cachedImage then
    return cachedImage
  end

  local image, err = Image(arg)
  if not image then
    log.error('failed to load image %s: %s', arg.file, err)
    return nil
  end

  self.cache[arg.file] = image
  return image
end

function ImageCache:forEach(callback)
  for key, image in pairs(self.cache) do
    callback(key, image)
  end
end

return ImageCache
