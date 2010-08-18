--[[local L = {}

-- options
L["LEFT"] = "Left"
L["CENTER"] = "Center"
L["RIGHT"] = "Right"
]]
local L = setmetatable({}, {
   __index = function(t, index) return index end
})

Gladius.L = L