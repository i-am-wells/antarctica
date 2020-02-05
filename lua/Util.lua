local string = require 'string'

local fmt = function(p)
  return function(fmt, ...) p(string.format(fmt, ...)) end
end

return {
  printf = fmt(print),
  errorf = fmt(error)
}
