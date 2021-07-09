local fapi = require(script.Parent.firestore.FireStoreWrapper2ElectricBoogalo)

local foo = fapi.new('foo', 'foo', 'foo', 'foo')
local bar = foo:getCollection('foo')
print(bar:getAllDocuments())