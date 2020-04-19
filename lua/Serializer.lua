local string = require 'string'
local Rope = require 'Rope'
local Serializer = require 'class'()

local escapes = setmetatable({
  ['\a'] = '\\a',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
  ['\v'] = '\\v',
  ['\\'] = '\\\\',
  ["'"] = "\\'",
}, {__index = function(_, s) return s end})

local quoteAndEscape = function(s)
  local rope = Rope("'")
  for i = 1, #s do
    rope:add(escapes[s:sub(i, i)])
  end

  rope:add("'")
  return rope:join()
end

local indent = string.rep(' ', 2)
local makeIndent = function(n)
  return string.rep(indent, n)
end

local serializeType, serializeTable

-- Recursively serialize a table as a Rope.
serializeTable = function(t, indent)
  local rope = Rope('{\n')
  indent = indent or 0
  for k, v in pairs(t) do
    local sKey
    if type(k) == 'table' then
      -- Table definition can't be a key, so just use tostring()
      sKey = quoteAndEscape(tostring(k))
    else
      sKey = serializeType[type(k)](k)
    end
    rope:add(string.format('%s[%s] = ', makeIndent(indent+1), sKey))

    local sVal
    if type(v) == 'table' then
      rope:splice(serializeTable(v, indent+1))
    else
      rope:add(serializeType[type(v)](v))
    end
    rope:add(',\n')
  end

  rope:add(makeIndent(indent)..'}')
  return rope
end

serializeType = setmetatable({string = quoteAndEscape},
  {__index = function() return tostring end})
  
function Serializer:serializeToString(t)
  if type(t) == 'table' then
    return serializeTable(t):join()
  elseif type(t) == 'string' then
    return quoteAndEscape(t)
  end
   return tostring(t)
end

function Serializer:serializeToFile(t, filename)
  local io = require 'io'
  local file = io.open(filename, 'w')
  if file == nil then
    error('failed to open '..file)
  end

  local _, err = file:write('return '..self:serializeToString(t))
  if err then
    error(err)
  end
end

return Serializer
