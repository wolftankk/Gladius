local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Tags"))
end
local L = Gladius.L
local LSM

local Tags = Gladius:NewModule("Tags", "AceEvent-3.0")
Gladius:SetModule(Tags, "Tags", false, {
   tagsTexts = {
      ["Health Bar Left Text"] = {
         attachTo = "HealthBar",
         position = "LEFT",
         offsetX = 2,
         offsetY = 0,
         
         text = "[name]",
         events = "UNIT_NAME_UPDATE",
      },
      ["Health Bar Right Text"] = {
         attachTo = "HealthBar",
         position = "RIGHT",
         offsetX = -2,
         offsetY = 0,
         
         text = "[health:short] / [maxhealth:short] ([health:percentage])",
         events = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      },
      ["Power Bar Left Text"] = {
         attachTo = "PowerBar",
         position = "LEFT",
         offsetX = 2,
         offsetY = 0,
         
         text = "[race] [class] [spec]",
         events = "UNIT_NAME_UPDATE",
      },
      ["Power Bar Right Text"] = {
         attachTo = "PowerBar",
         position = "RIGHT",
         offsetX = -2,
         offsetY = 0,
         
         text = "[power:short] / [maxpower:short] ([power:percentage])",
         events = "UNIT_POWER UNIT_MAXPOWER UNIT_MANA UNIT_RAGE UNIT_ENERGY UNIT_FOCUS UNIT_RUNIC_POWER UNIT_MAXMANA UNIT_MAXRAGE UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXRUNIC_POWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
      },
   },
})

function Tags:OnEnable()   
   LSM = Gladius.LSM   
   
   -- frame
   if (not self.frame) then
      self.frame = {}
   end
   
   -- tags
   if (not self.tags) then
      self.tags = self:GetTags()
   end
   
   -- gather events
   self.events = {}
   
   for k,v in pairs(Gladius.db.tagsTexts) do
      for event in v.events:gmatch("%S+") do
         if (not self.events[event]) then
            self.events[event] = {}
         end
         
         self.events[event][k] = true
      end
   end
   
   -- register events
   for event in pairs(self.events) do
      self:RegisterEvent(event, "OnEvent")
   end
end

function Tags:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function Tags:GetAttachTo()
   return ""
end

function Tags:GetFrame(unit)
   return ""
end

function Tags:OnEvent(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
   if (self.events[event]) then
      -- update texts
      for text, _ in pairs(self.events[event]) do
         self:UpdateText(unit, text)
      end
   end
end

function Tags:CreateFrame(unit, text)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create frame
   self.frame[unit][text] = button:CreateFontString("Gladius" .. self.name .. unit .. text, "OVERLAY")
end

function Tags:UpdateText(unit, text)
   if (not self.frame[unit][text]) then return end

   -- update tag
   local tagText = Gladius.db.tagsTexts[text].text
   
   for tag in Gladius.db.tagsTexts[text].text:gmatch("%[(.-)%]") do
      if (self.tags[tag]) then
         local escapedText
         
         -- clear the tag, if unit does not exist
         if (not Gladius.test and not UnitName(unit)) then
            escapedText = ""
         else
            escapedText = string.gsub(self.tags[tag](unit) or "", "%%", "%%%%")
         end
         
         tagText = string.gsub(tagText, "%[" .. tag .. "%]", escapedText)
      end
   end
   
   self.frame[unit][text]:SetText(tagText or "")
end

function Tags:Update(unit) 
   if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
   
   for text, _ in pairs(Gladius.db.tagsTexts) do
      -- create frame
      if (not self.frame[unit][text]) then 
         self:CreateFrame(unit, text)
      end
      
      -- update frame   
      self.frame[unit][text]:ClearAllPoints()
      self.frame[unit][text]:SetPoint(Gladius.db.tagsTexts[text].position, Gladius:GetModule(Gladius.db.tagsTexts[text].attachTo).frame[unit], Gladius.db.tagsTexts[text].position, 
         Gladius.db.tagsTexts[text].offsetX, Gladius.db.tagsTexts[text].offsetY)
         
      self.frame[unit][text]:SetParent(Gladius:GetModule(Gladius.db.tagsTexts[text].attachTo).frame[unit])
      
      self.frame[unit][text]:SetFont(LSM:Fetch(LSM.MediaType.FONT, "Friz Quadrata TT"), 11)
      self.frame[unit][text]:SetTextColor(1, 1, 1, 1)
      
      self.frame[unit][text]:SetShadowOffset(1, -1)
      self.frame[unit][text]:SetShadowColor(0, 0, 0, 1)
      
      -- update text
      self:UpdateText(unit, text)
      
      -- hide
      self.frame[unit][text]:SetAlpha(0)
   end
end

function Tags:Show(unit)
   if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
   
   -- update text
   for text, _ in pairs(Gladius.db.tagsTexts) do      
      self:UpdateText(unit, text)
   end
   
   -- show
   for _, text in pairs(self.frame[unit]) do
      text:SetAlpha(1)
   end
end

function Tags:Reset(unit)   
	if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
    
   -- hide
   for _, text in pairs(self.frame[unit]) do
      text:SetAlpha(0)
   end
end

function Tags:Test(unit)   
   -- test
end

function Tags:GetOptions()
   -- tags
   if (not self.tags) then
      self.tags = self:GetTags()
   end

   return {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {

         },
      },
   }
end

function Tags:GetTags()
   return {
      ["name"] = function(unit)
         return UnitName(unit) or unit
      end, 
      ["class"] = function(unit)
         return not Gladius.test and UnitClass(unit) or LOCALIZED_CLASS_NAMES_MALE[Gladius.testing[unit].unitClass]
      end, 
      ["race"] = function(unit)
         return not Gladius.test and UnitRace(unit) or Gladius.testing[unit].unitRace
      end, 
      ["spec"] = function(unit)
         return Gladius.test and Gladius.testing[unit].unitSpec or Gladius.buttons[unit].spec
      end, 
           
      ["health"] = function(unit)
         return not Gladius.test and UnitHealth(unit) or Gladius.testing[unit].health
      end,
      ["maxhealth"] = function(unit)
         return not Gladius.test and UnitHealthMax(unit) or Gladius.testing[unit].maxHealth
      end,
      ["health:short"] = function(unit)
         local health = not Gladius.test and UnitHealth(unit) or Gladius.testing[unit].health
      
         if (health > 999) then
            return string.format("%.1fk", (health / 1000))
         else
            return health
         end
      end,
      ["maxhealth:short"] = function(unit)
         local health = not Gladius.test and UnitHealthMax(unit) or Gladius.testing[unit].maxHealth
      
         if (health > 999) then
            return string.format("%.1fk", (health / 1000))
         else
            return health
         end
      end,
      ["health:percentage"] = function(unit)
         local health = not Gladius.test and UnitHealth(unit) or Gladius.testing[unit].health
         local maxHealth = not Gladius.test and UnitHealthMax(unit) or Gladius.testing[unit].maxHealth
         
         return string.format("%.1f%%", (health / maxHealth * 100))
      end,
      
      ["power"] = function(unit)
         return not Gladius.test and UnitPower(unit) or Gladius.testing[unit].power
      end,
      ["maxpower"] = function(unit)
         return not Gladius.test and UnitPowerMax(unit) or Gladius.testing[unit].maxPower
      end,
      ["power:short"] = function(unit)
         local power = not Gladius.test and UnitPower(unit) or Gladius.testing[unit].power
      
         if (power > 999) then
            return string.format("%.1fk", (power / 1000))
         else
            return power
         end
      end,
      ["maxpower:short"] = function(unit)
         local power = not Gladius.test and UnitPowerMax(unit) or Gladius.testing[unit].maxPower
      
         if (power > 999) then
            return string.format("%.1fk", (power / 1000))
         else
            return power
         end
      end,
      ["power:percentage"] = function(unit)
         local power = not Gladius.test and UnitPower(unit) or Gladius.testing[unit].power
         local maxPower = not Gladius.test and UnitPowerMax(unit) or Gladius.testing[unit].maxPower
         
         return string.format("%.1f%%", (power / maxPower * 100))
      end,
   }
end
