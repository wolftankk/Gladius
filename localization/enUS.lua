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
   ["name:statusTag"] = "Unit Name/Status",  
   ["specTag"] = "Unit Spec",
   ["health:percentageTag"] = "Health (Percentage)",
   ["healthTag"] = "Health",
   ["maxhealth:shortTag"] = "Max Health (Short)",
   ["maxpowerTag"] = "Max Power",
   
   -- Specs, sup?
   ["Unholy:short"] = "Unh",
   ["Frost:short"] = "Frost",
   ["Blood:short"] = "Blood",  
   ["Fire:short"] = "Fire",
   ["Arcane:short"] = "Arcane",
   ["Marksmanship:short"] = "Marks",
   ["Survival:short"] = "Surv",
   ["Beast Mastery:short"] = "BM", 
   ["Elemental:short"] = "Ele",
   ["Enhancement:short"] = "Enh",
   ["Restoration:short"] = "Resto",
   ["Feral:short"] = "Feral",
   ["Balance:short"] = "Balance",  
   ["Demonology:short"] = "Demo",
   ["Destruction:short"] = "Destro",
   ["Affliction:short"] = "Affli",
   ["Subletly:short"] = "Sub",
   ["Combat:short"] = "Combat",
   ["Assassination:short"] = "Assa",
   ["Shadow:short"] = "Shadow",
   ["Discipline:short"] = "Disc",
   ["Holy:short"] = "Holy",   
   ["Retribution:short"] = "Ret",
   ["Protection:short"] = "Prot",
   ["Arms:short"] = "Arms",
   ["Fury:short"] = "Fury",
   
   ["Warrior:short"] = "Warr",
   ["Death Knight:short"] = "DK",
   ["Warlock:short"] = "Lock",
   ["Priest:short"] = "Priest",
   ["Hunter:short"] = "Hunter",
   ["Rogue:short"] = "Rogue",
   ["Shaman:short"] = "Shaman",
   ["Druid:short"] = "Druid",
   ["Paladin:short"] = "Pala",
   ["Mage:short"] = "Mage",         
}, {
   __index = function(t, index) return index end
})

Gladius.L = L