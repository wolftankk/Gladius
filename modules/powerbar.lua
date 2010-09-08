local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Power Bar"))
end
local L = Gladius.L
local LSM

local PowerBar = Gladius:NewModule("PowerBar", "AceEvent-3.0")
Gladius:SetModule(PowerBar, "PowerBar", true, {
   powerBarAttachTo = "HealthBar",
   
   powerBarHeight = 15,
   powerBarAdjustWidth = true,
   powerBarWidth = 150,
   
   powerBarInverse = false,
   powerBarColor = { r = 1, g = 1, b = 1, a = 1 },
   powerBarDefaultColor = true,
   powerBarTexture = "Minimalist",   
   
   powerBarOffsetX = 0,
   powerBarOffsetY = 0,   
   
   powerText = true,
   shortPowerText = true,
   powerTextPercentage = true,
   powerTextFont = "Friz Quadrata TT",
   powerTextSize = 11,
   powerTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   powerTextAlign = "RIGHT",
   powerTextAnchor = "RIGHT",
   powerTextOffsetX = 0,
   powerTextOffsetY = 0,
   
   maxPowerText = true,
   shortMaxPowerText = true,
   
   powerInfoTextRace = true,
   powerInfoTextSpec = false,
   powerInfoTextClass = true,
   powerInfoTextName = false,
   powerInfoTextFont = "Friz Quadrata TT",
   powerInfoTextSize = 11,
   powerInfoTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   powerInfoTextAlign = "LEFT",
   powerInfoTextAnchor = "LEFT",
   powerInfoTextOffsetX = 0,
   powerInfoTextOffsetY = 0,
   
   powerBarUseDefaultColorMana = false,
   powerBarDefaultColorMana = {r = .18, g = .44, b = .75, a = 1},
   powerBarUseDefaultColorRage = false,
   powerBarDefaultColorRage = {r = 1, g = 0, b = 0, a = 1},
   powerBarUseDefaultColorFocus = false,
   powerBarDefaultColorFocus = PowerBarColor[2],
   powerBarUseDefaultColorEnergy = false,
   powerBarDefaultColorEnergy = {r = 1, g = 1, b = 0, a = 1},
   powerBarUseDefaultColorRunicPower = false,
   powerBarDefaultColorRunicPower = {r = 0, g = 0.82, b = 1, a = 1},
})

function PowerBar:OnEnable()
   self:RegisterEvent("UNIT_POWER")
   self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER")
   
   self:RegisterEvent("UNIT_MANA")
   self:RegisterEvent("UNIT_MAXMANA", "UNIT_POWER")
   self:RegisterEvent("UNIT_ENERGY", "UNIT_POWER")
   self:RegisterEvent("UNIT_FOCUS", "UNIT_POWER")
   self:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXMANA", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXRAGE", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXENERGY", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXFOCUS", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_POWER")
   self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_POWER")
   
   LSM = Gladius.LSM
   
   if (not self.frame) then
      self.frame = {}
   end
end

function PowerBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function PowerBar:GetAttachTo()
   return Gladius.db.powerBarAttachTo
end

function PowerBar:GetFrame(unit)
   return self.frame[unit]
end

function PowerBar:UNIT_POWER(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end

   local power, maxPower, powerType = UnitPower(unit), UnitPowerMax(unit), UnitPowerType(unit)
   self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:UpdatePower(unit, power, maxPower, powerType)
   local testing = Gladius.test
   
   if (not self.frame[unit]) then
      if (not Gladius.buttons[unit]) then
         Gladius:UpdateUnit(unit)
      else
         self:Update(unit)
      end
   end

   -- update min max values
   self.frame[unit]:SetMinMaxValues(0, maxPower)
   
   -- inverse bar
   if (Gladius.db.powerBarInverse) then
      self.frame[unit]:SetValue(maxPower - power)
   else
      self.frame[unit]:SetValue(power)
   end
   
   -- update bar color
   if (Gladius.db.powerBarDefaultColor) then		
      local color = self:GetBarColor(powerType)
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
   end
   
   -- set power text
   local powerText = ""
   
   if (Gladius.db.powerText) then
      -- customize text
      if (Gladius.db.shortPowerText and power > 9999) then
         powerText = format("%.1fk", (power / 1000))
      else
         powerText = power
      end
   end
   
   -- set max power
   if (Gladius.db.maxPowerText) then
      -- customize text
      local maxPowerText
      if (Gladius.db.shortMaxPowerText and maxPower > 9999) then
         maxPowerText = format("%.1fk", (maxPower / 1000))
      else
         maxPowerText = maxPower
      end
      
      if (Gladius.db.powerText) then
         powerText = format("%s/%s", powerText, maxPowerText)
      else
         powerText = maxPowerText
      end
   end
   
   -- set power percentage text
   if (Gladius.db.powerTextPercentage) then
      powerText = format("%s (%s%%)", powerText, format("%.1f", (power / maxPower * 100)))
   end
   
   self.frame[unit].text:SetText(powerText)
end

function PowerBar:CreateBar(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end      
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "Gladius" .. self.name .. unit, button) 
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("Gladius" .. self.name .. "Highlight" .. unit, "OVERLAY")
   self.frame[unit].text = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "Text" .. unit, "OVERLAY")
   self.frame[unit].infoText = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "InfoText" .. unit, "OVERLAY")
end

function PowerBar:Update(unit)
   -- get unit powerType
   local powerType
   if (not testing) then
      powerType = UnitPowerType(unit)
   else
      powerType = Gladius.testing[unit].powerType
   end

   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
     
   -- update power bar   
   self.frame[unit]:ClearAllPoints()
   
	local parent = Gladius:GetParent(unit, Gladius.db.powerBarAttachTo)  
	local relativePoint = "BOTTOMLEFT"
	local point = "TOPLEFT"	
	if (Gladius.db.powerBarAttachTo == "Frame") then relativePoint = point end
	   
	self.frame[unit]:SetPoint(point, parent, relativePoint, Gladius.db.powerBarOffsetX, Gladius.db.powerBarOffsetY)
	self.frame[unit]:SetWidth(Gladius.db.powerBarAdjustWidth and Gladius.db.barWidth or Gladius.db.powerBarWidth)
	self.frame[unit]:SetHeight(Gladius.db.powerBarHeight)	
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.powerBarTexture))
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
   
   -- set color
   if (not Gladius.db.powerBarDefaultColor) then
      local color = Gladius.db.powerBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      local color = self:GetBarColor(powerType)
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
   end
	
   -- update power text   
	self.frame[unit].text:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.powerTextFont), Gladius.db.powerTextSize)
	
	local color = Gladius.db.powerTextColor
	self.frame[unit].text:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].text:SetShadowOffset(1, -1)
	self.frame[unit].text:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].text:SetJustifyH(Gladius.db.powerTextAlign)
	self.frame[unit].text:SetPoint(Gladius.db.powerTextAnchor, Gladius.db.powerTextOffsetX, Gladius.db.powerTextOffsetY)  
   
   -- update power info text   
	self.frame[unit].infoText:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.powerInfoTextFont), Gladius.db.powerInfoTextSize)
	
	local color = Gladius.db.powerInfoTextColor
	self.frame[unit].infoText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].infoText:SetShadowOffset(1, -1)
	self.frame[unit].infoText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].infoText:SetJustifyH(Gladius.db.powerInfoTextAlign)
	self.frame[unit].infoText:SetPoint(Gladius.db.powerInfoTextAnchor, self.frame[unit], Gladius.db.powerInfoTextOffsetX, Gladius.db.powerInfoTextOffsetY)
		
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
   
	-- hide frame
   self.frame[unit]:SetAlpha(0)
end

function PowerBar:GetBarColor(powerType)
   if (powerType == 0 and not powerBarUseDefaultColorMana) then
      return Gladius.db.powerBarDefaultColorMana
   elseif (powerType == 1 and not powerBarUseDefaultColorRage) then
      return Gladius.db.powerBarDefaultColorRage
   elseif (powerType == 2 and not powerBarUseDefaultColorFocus) then
      return Gladius.db.powerBarDefaultColorFocus
   elseif (powerType == 3 and not powerBarUseDefaultColorEnergy) then
      return Gladius.db.powerBarDefaultColorEnergy
   elseif (powerType == 6 and not powerBarUseDefaultColorRunicPower) then
      return Gladius.db.powerBarDefaultColorRunicPower
   end
   
   return PowerBarColor[powerType]
end

function PowerBar:Show(unit)
   local testing = Gladius.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)

   -- set info text
   local powerInfoText = ""
   
   -- race
   if (Gladius.db.powerInfoTextRace) then
      local race = Gladius.test and Gladius.testing[unit].unitRace or UnitRace(unit)
      powerInfoText = race
   end
   
   -- spec
   if (Gladius.db.powerInfoTextSpec) then
      local spec = Gladius.test and Gladius.testing[unit].unitSpec or ""
      powerInfoText = powerInfoText .. " " .. spec
   end
   
   -- class
   if (Gladius.db.powerInfoTextClass) then
      local class = Gladius.test and LOCALIZED_CLASS_NAMES_MALE[Gladius.testing[unit].unitClass] or UnitClass(unit)
      powerInfoText = powerInfoText .. " " .. class
   end
   
   -- name
   if (Gladius.db.powerInfoTextName) then
      local name = Gladius.test and unit or UnitName(unit)
      powerInfoText = powerInfoText .. " " .. name
   end
   
   self.frame[unit].infoText:SetText(powerInfoText)
end

function PowerBar:Reset(unit)
   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(1)

   -- reset text
   if (self.frame[unit].text:GetFont()) then
      self.frame[unit].text:SetText("")
   end
   
   if (self.frame[unit].infoText:GetFont()) then
      self.frame[unit].infoText:SetText("")
   end
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function PowerBar:Test(unit)     
   -- set test values
   local maxPower, power
   
   -- power type
   local powerType = Gladius.testing[unit].powerType
   
   maxPower = Gladius.testing[unit].maxPower  
   power = Gladius.testing[unit].power
   
   self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],         
         order=1,
         args = {       
            powerBarAttachTo = {
               type="select",
               name=L["Power bar attach to"],
               desc=L["Attach power bar to the given frame"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            powerBarHeight = {
               type="range",
               name=L["Power bar height"],
               desc=L["Height of the power bar"],
               min=10, max=200, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            powerBarAdjustWidth = {
               type="toggle",
               name=L["Power bar adjust width"],
               desc=L["Adjust health bar width to the frame width"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            powerBarWidth = {
               type="range",
               name=L["Power bar width"],
               desc=L["Width of the power bar"],
               min=10, max=500, step=1,
               disabled=function() return Gladius.dbi.profile.powerBarAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            powerBarInverse = {
               type="toggle",
               name=L["Power bar inverse"],
               desc=L["Inverse the power bar"],
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            powerBarColor = {
               type="color",
               name=L["Power bar color"],
               desc=L["Color of the power bar"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               disabled=function() return Gladius.dbi.profile.powerBarDefaultColor or not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            powerBarDefaultColor = {
               type="toggle",
               name=L["Power bar default color"],
               desc=L["Toggle power bar default color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            powerBarOffsetX = {
               type="range",
               name=L["Power bar offset X"],
               desc=L["X offset of the power bar"],
               min=-100, max=100, step=1,
               disabled=function() return  not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            powerBarOffsetY = {
               type="range",
               name=L["Power bar offset X"],
               desc=L["X offset of the power bar"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=40,
            },
            powerBarTexture = {
               type="select",
               name=L["Power bar texture"],
               desc=L["Texture of the power bar"],
               dialogControl = "LSM30_Statusbar",
               values = AceGUIWidgetLSMlists.statusbar,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
         },
      },
      powerText = {  
         type="group",
         name=L["Power text"],
         order=2,
         args = {       
            powerText = {
               type="toggle",
               name=L["Power text"],
               desc=L["Toggle power text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            shortPowerText = {
               type="toggle",
               name=L["Short power text"],
               desc=L["Toggle short power text"],
               disabled=function() return not Gladius.dbi.profile.powerText or not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            maxPowerText = {
               type="toggle",
               name=L["Max power text"],
               desc=L["Toggle max power text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            shortMaxPowerText = {
               type="toggle",
               name=L["Short max power text"],
               desc=L["Toggle short max power text"],
               disabled=function() return not Gladius.dbi.profile.maxPowerText or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            powerTextPercentage = {
               type="toggle",
               name=L["Power text percentage"],
               desc=L["Toggle power text percentage"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=20,
            },
            powerTextFont = {
               type="select",
               name=L["Power text font"],
               desc=L["Font of the power text"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,					
            },
            powerTextSize = {
               type="range",
               name=L["Power text size"],
               desc=L["Text size of the power text"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            powerTextColor = {
               type="color",
               name=L["Power text color"],
               desc=L["Text color of the power text"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            powerTextAlign = {
               type="select",
               name=L["Power text align"],
               desc=L["Text align of the power text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            powerTextAnchor = {
               type="select",
               name=L["Power text anchor"],
               desc=L["Anchor of the power text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            powerTextOffsetX = {
               type="range",
               name=L["Power text offset X"],
               desc=L["X offset of the power text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
            powerTextOffsetY = {
               type="range",
               name=L["Power text offset Y"],
               desc=L["Y offset of the power text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=55,
            },
         },
      },
      powerInfoText = {  
         type="group",
         name=L["Power info text"],
         order=3,
         args = {
            powerInfoTextName = {
               type="toggle",
               name=L["Power info name text"],
               desc=L["Toggle power info name text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },            
            powerInfoTextRace = {
               type="toggle",
               name=L["Power info race text"],
               desc=L["Toggle power info race text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            powerInfoTextClass = {
               type="toggle",
               name=L["Power info class text"],
               desc=L["Toggle power info class text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            powerInfoTextSpec = {
               type="toggle",
               name=L["Power info spec text"],
               desc=L["Toggle power info spec text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            powerInfoTextFont = {
               type="select",
               name=L["Power info text font"],
               desc=L["Text font of the power info text"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,					
            },
            powerInfoTextSize = {
               type="range",
               name=L["Power info text size"],
               desc=L["Text size of the power info text"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            powerInfoTextColor = {
               type="color",
               name=L["Power info text color"],
               desc=L["Text color of the power info text"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            powerInfoTextAlign = {
               type="select",
               name=L["Power info text align"],
               desc=L["Text align of the power info text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            powerInfoTextAnchor = {
               type="select",
               name=L["Power info text anchor"],
               desc=L["Text anchor of the power info text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            powerInfoTextOffsetX = {
               type="range",
               name=L["Power info text offset X"],
               desc=L["X offset of the power info text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            powerInfoTextOffsetY = {
               type="range",
               name=L["Power info text offset Y"],
               desc=L["Y offset of the power info text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
         },
      },
      powerDefaultColors = {  
         type="group",
         name=L["Power colors"],
         order=4,
         args = {
            powerBarUseDefaultColorMana = {
               type="toggle",
               name=L["Default power mana color"],
               desc=L["Toggle default power mana color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            powerBarDefaultColorMana = {
               type="color",
               name=L["Default power mana color"],
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            powerBarUseDefaultColorRage = {
               type="toggle",
               name=L["Default power rage color"],
               desc=L["Toggle default power rage color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            powerBarDefaultColorRage = {
               type="color",
               name=L["Default power rage color"],
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            powerBarUseDefaultColorFocus = {
               type="toggle",
               name=L["Default power focus color"],
               desc=L["Toggle default power focus color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            powerBarDefaultColorFocus = {
               type="color",
               name=L["Default power focus color"],
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            powerBarUseDefaultColorEnergy = {
               type="toggle",
               name=L["Default power energy color"],
               desc=L["Toggle default power energy color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            powerBarDefaultColorEnergy = {
               type="color",
               name=L["Default power energy color"],
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            powerBarUseDefaultColorRunicPower = {
               type="toggle",
               name=L["Default power runic power color"],
               desc=L["Toggle default power runic power color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            powerBarDefaultColorRunicPower = {
               type="color",
               name=L["Default power runic power color"],
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
         },
      },
   }
end
