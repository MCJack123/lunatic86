band = {}
bor = {}
bxor = {}
bnot = {}
blshift = {}
brshift = {}

setmetatable(band, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.band(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bor, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.bor(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bxor, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.bxor(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(blshift, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.blshift(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(brshift, {__sub = function(lhs)
    local mt = {lhs, __sub = function(self, b) return bit.blogic_rshift(self[1], b) end}
    return setmetatable(mt, mt)
end})

setmetatable(bnot, {__sub = function(_, rhs) return bit.bnot(rhs) end})