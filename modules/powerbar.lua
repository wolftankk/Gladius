local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Power Bar"))
end
local L = Gladius.L
local LSM

local PowerBar = Gladius:NewModule("PowerBar", "AceEvent-3.0")
Gladius:SetModule(PowerBar, "PowerBar", true, {
   powerBarAttachTo = "HealthBar",
   
   powerBarHeight = 40,
   powerBarAdjustWidth = true,
   powerBarWidth = 200,
   
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
})

function PowerBar:OnEnable()
   self:RegisterEvent("UNIT_MANA")
   self:RegisterEvent("UNIT_RAGE", "UNIT_MANA")
   self:RegisterEvent("UNIT_ENERGY", "UNIT_MANA")
   self:RegisterEvent("UNIT_FOCUS", "UNIT_MANA")
   self:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_MANA")
   self:RegisterEvent("UNIT_MAXMANA", "UNIT_MANA")
   self:RegisterEvent("UNIT_MAXRAGE", "UNIT_MANA")
   self:RegisterEvent("UNIT_MAXENERGY", "UNIT_MANA")
   self:RegisterEvent("UNIT_MAXFOCUS", "UNIT_MANA")
   self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_MANA")
   self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_MANA")
   
   LSM = Gladius.LSM
   
   self.frame = {}
end

function PowerBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:Hide()
   end
end

function PowerBar:GetAttachTo()
   return Gladius.db.powerBarAttachTo
end

function PowerBar:GetFrame(unit)
   return self.frame[unit]
end

function PowerBar:UNIT_MANA(event, unit)
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
      self.frame[unit]:SetStatusBarColor(PowerBarColor[powerType].r, PowerBarColor[powerType].g, PowerBarColor[powerType].b)
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

function PowerBar:Show(unit)
   local testing = Gladius.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)

   -- get unit powerType
   local powerType
   if (not testing) then
      powerType = UnitPowerType(unit)
   else
      powerType = Gladius.testing[unit].powerType
   end

   -- set color
   if (not Gladius.db.powerBarDefaultColor) then
      local color = Gladius.db.powerBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      self.frame[unit]:SetStatusBarColor(PowerBarColor[powerType].r, PowerBarColor[powerType].g, PowerBarColor[powerType].b)
   end

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
         --inline=true,
         order=1,
         args = {       
            powerBarAttachTo = {
               type="select",
               name=L["powerBarAttachTo"],
               desc=L["powerBarAttachToDesc"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            powerBarHeight = {
               type="range",
               name=L["powerBarHeight"],
               desc=L["powerBarHeightDesc"],
               min=10, max=200, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            powerBarAdjustWidth = {
               type="toggle",
               name=L["powerBarAdjustWidth"],
               desc=L["powerBarAdjustWidthDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=6,
            },
            powerBarWidth = {
               type="range",
               name=L["powerBarWidth"],
               desc=L["powerBarWidthDesc"],
               min=10, max=500, step=1,
               disabled=function() return Gladius.dbi.profile.powerBarAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=7,
            },
            powerBarInverse = {
               type="toggle",
               name=L["powerBarInverse"],
               desc=L["powerBarInverseDesc"],
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            powerBarColor = {
               type="color",
               name=L["powerBarColor"],
               desc=L["powerBarColorDesc"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               disabled=function() return Gladius.dbi.profile.powerBarDefaultColor or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            powerBarDefaultColor = {
               type="toggle",
               name=L["powerBarDefaultColor"],
               desc=L["powerBarDefaultColorDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            powerBarOffsetX = {
               type="range",
               name=L["powerBarOffsetX"],
               desc=L["powerBarOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return  not Gladius.dbi.profile.modules[self.name] end,
               order=21,
            },
            powerBarOffsetY = {
               type="range",
               name=L["powerBarOffsetY"],
               desc=L["powerBarOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=22,
            },
            powerBarTexture = {
               type="select",
               name=L["powerBarTexture"],
               desc=L["powerBarTextureDesc"],
               dialogControl = "LSM30_Statusbar",
               values = AceGUIWidgetLSMlists.statusbar,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
         },
      },
      powerText = {  
         type="group",
         name=L["powerText"],
         --inline=true,
         order=2,
         args = {       
            powerText = {
               type="toggle",
               name=L["powerText"],
               desc=L["powerTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            shortPowerText = {
               type="toggle",
               name=L["shortPowerText"],
               desc=L["shortPowerTextDesc"],
               disabled=function() return not Gladius.dbi.profile.powerText or not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            maxPowerText = {
               type="toggle",
               name=L["maxPowerText"],
               desc=L["maxPowerTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            shortMaxPowerText = {
               type="toggle",
               name=L["shortMaxPowerText"],
               desc=L["shortMaxPowerTextDesc"],
               disabled=function() return not Gladius.dbi.profile.maxPowerText or not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            powerTextPercentage = {
               type="toggle",
               name=L["powerTextPercentage"],
               desc=L["powerTextPercentageDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=50,
            },
            powerTextFont = {
               type="select",
               name=L["powerTextFont"],
               desc=L["powerTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            powerTextSize = {
               type="range",
               name=L["powerTextSize"],
               desc=L["powerTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            powerTextColor = {
               type="color",
               name=L["powerTextColor"],
               desc=L["powerTextColorDesc"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            powerTextAlign = {
               type="select",
               name=L["powerTextAlign"],
               desc=L["powerTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            powerTextAnchor = {
               type="select",
               name=L["powerTextAnchor"],
               desc=L["powerTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            powerTextOffsetX = {
               type="range",
               name=L["powerTextOffsetX"],
               desc=L["powerTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            powerTextOffsetY = {
               type="range",
               name=L["powerTextOffsetY"],
               desc=L["powerTextOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=90,
            },
         },
      },
      powerInfoText = {  
         type="group",
         name=L["powerInfoText"],
         --inline=true,
         order=3,
         args = {
            powerInfoTextName = {
               type="toggle",
               name=L["powerInfoTextName"],
               desc=L["powerInfoTextNameDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },            
            powerInfoTextRace = {
               type="toggle",
               name=L["powerInfoTextRace"],
               desc=L["powerInfoTextRaceDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            powerInfoTextClass = {
               type="toggle",
               name=L["powerInfoTextClass"],
               desc=L["powerInfoTextClassDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            powerInfoTextSpec = {
               type="toggle",
               name=L["powerInfoTextSpec"],
               desc=L["powerInfoTextSpecDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
            powerInfoTextFont = {
               type="select",
               name=L["powerInfoTextFont"],
               desc=L["powerInfoTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            powerInfoTextSize = {
               type="range",
               name=L["powerInfoTextSize"],
               desc=L["powerInfoTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            powerInfoTextColor = {
               type="color",
               name=L["powerInfoTextColor"],
               desc=L["powerInfoTextColorDesc"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            powerInfoTextAlign = {
               type="select",
               name=L["powerInfoTextAlign"],
               desc=L["powerInfoTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            powerInfoTextAnchor = {
               type="select",
               name=L["powerInfoTextAnchor"],
               desc=L["powerInfoTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            powerInfoTextOffsetX = {
               type="range",
               name=L["powerInfoTextOffsetX"],
               desc=L["powerInfoTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            powerInfoTextOffsetY = {
               type="range",
               name=L["powerInfoTextOffsetY"],
               desc=L["powerInfoTextOffsetYDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=90,
            },
         },
      },
   }
end
