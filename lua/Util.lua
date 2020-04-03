local string = require 'string'

local fmt = function(p)
  return function(fmt, ...) p(string.format(fmt, ...)) end
end

local printf, errorf = fmt(print), fmt(error)

local doNothing = function() end

local dlog = doNothing
if __dbg then
  dlog = printf
end

return {
  printf = printf,
  errorf = errorf,
  dlog = dlog,

  doNothing = doNothing,

  -- Temporarily set globals.
  using = function(dict, fn)
    local orig = {}
    for k, v in pairs(dict) do
      orig[k] = _G[k]
      _G[k] = v
    end
    local ret = fn()
    for k, v in pairs(dict) do
      _G[k] = orig[k]
    end
    return ret
  end,

  bind = function(fn, ...)
    local a = {...}
    return function(...)
      return fn(table.unpack(a), ...)
    end
  end,
}
