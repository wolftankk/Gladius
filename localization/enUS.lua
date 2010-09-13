--[[local L = {}

-- options
L["LEFT"] = "Left"
L["CENTER"] = "Center"
L["RIGHT"] = "Right"
]]
local L = setmetatable({
   ["maxhealthTag"] = "Max Health",
   ["maxpower:shortTag"] = "Max Power (Short)",
   ["powerTag"] = "Power",
   ["health:shortTag"] = "Health (Short)",
   ["classTag"] = "Unit Class",
   ["power:percentageTag"] = "Power (Percentage)",
   ["power:shortTag"] = "Power (Short)",
   ["raceTag"] = "Unit Race",
   ["nameTag"] = "Unit Name",
   ["specTag"] = "Unit Spec",
   ["health:percentageTag"] = "Health (Percentage)",
   ["healthTag"] = "Health",
   ["maxhealth:shortTag"] = "Max Health (Short)",
   ["maxpowerTag"] = "Max Power",
}, {
   __index = function(t, index) return index end
})

Gladius.L = L