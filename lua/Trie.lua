local Stack = require 'Stack'
local Rope = require 'Rope'

local Trie
Trie = require 'class'{
  init = function(self)
    self.children = {}
    self.childrenCount = 0
  end,

  set = function(self, str, val)
    local node = self
    for i = 1, #str do
      local char = str:sub(i, i)
      local nextNode = node.children[char]
      if not nextNode then
        nextNode = Trie()
        node.children[char] = nextNode
        node.childrenCount = node.childrenCount + 1
      end
      node = nextNode
    end
    node.key = str
    node.val = val
  end,

  getNode = function(self, str)
    if str == '' then
      return self
    end

    local node = self
    for idx = 1, #str do
      local nextNode = node.children[str:sub(idx, idx)]
      if not nextNode then
        return nil
      end
      node = nextNode
    end
    return node
  end,

  get = function(self, str)
    local endNode = self:getNode(str)
    if endNode then
      return endNode.val
    end
    return nil
  end,

  getKeysAndValues = function(self)
    -- Search tree for values
    local stack, result = Stack(), {}
    stack:push(self)
    while not stack:empty() do
      local node = stack:pop()

      if node.key then
        result[node.key] = node.val
      end

      for _, child in pairs(node.children) do
        stack:push(child)
      end
    end

    return result
  end,

  getCommonPrefix = function(self)
    local node, result = self, Rope()
    while node.childrenCount == 1 do
      for k, v in pairs(node.children) do
        result:add(k)
        node = v
        break
      end
    end
    return result:join()
  end,
}

return Trie
