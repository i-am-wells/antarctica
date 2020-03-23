local string = require 'string'

local fmt = function(p)
  return function(fmt, ...) p(string.format(fmt, ...)) end
end

return {
  printf = fmt(print),
  errorf = fmt(error),

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
