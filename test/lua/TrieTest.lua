local Trie = require 'Trie'
local TrieTest = require 'class'(require 'test.TestBase')

function TrieTest:testGetAndSet()
  local trie = Trie()
  self:expectEquals(nil, trie:get('something'))
  
  -- set/get
  trie:set('test', 42)
  self:expectEquals(42, trie:get('test'))
end

function TrieTest:testGetNode()
  local trie = Trie()
  trie:set('test', 42)
  trie:set('tea', 1)

  local subtrie = trie:getNode('te')
  self:assertEquals('table', type(subtrie))
  self:expectEquals(1, subtrie:get('a'))
  self:expectEquals(42, subtrie:get('st'))
end

function TrieTest:testGetKeysAndValuesForPrefix()
  local values = {
    swagger = 100,
    swole = 1000,
    stealth = 2,
    rectangle = 3,
  }
  local trie = Trie()
  for k, v in pairs(values) do
    trie:set(k, v)
  end

  -- no prefix
  local resultAll = trie:getKeysAndValues()
  for k, v in pairs(values) do
    self:expectEquals(v, resultAll[k])
  end

  -- prefix
  local subtrie = trie:getNode('sw')
  self:assertEquals('table', type(subtrie))
  local result_sw = subtrie:getKeysAndValues()
  self:expectEquals(100, result_sw.swagger)
  self:expectEquals(1000, result_sw.swole)
  self:expectEquals(nil, result_sw.stealth)
end

function TrieTest:testGetCommonPrefix()
  local trie = Trie()
  trie:set('abcdefgh xyz', 100)
  trie:set('abcd xyz', 200)
  self:expectEquals('abcd', trie:getCommonPrefix())

  trie:set('xxx', 300)
  self:expectEquals('', trie:getCommonPrefix())
end

return TrieTest
