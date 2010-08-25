local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Health Bar"))
end
local L = Gladius.L
local LSM

local HealthBar = Gladius:NewModule("HealthBar", "AceEvent-3.0")
Gladius:SetModule(HealthBar, "HealthBar", true, {
   healthBarAttachTo = "Frame",
   
   healthBarHeight = 40,
   healthBarAdjustWidth = true,
   healthBarWidth = 200,
   
   healthBarInverse = false,
   healthBarColor = { r = 1, g = 1, b = 1, a = 1 },
   healthBarClassColor = true,
   healthBarTexture = "Armory",      
   
   healthText = true,
   shortHealthText = true,
   healthTextPercentage = true,
   healthTextFont = "Friz Quadrata TT",
   healthTextSize = 11,
   healthTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   healthTextAlign = "RIGHT",
   healthTextAnchor = "RIGHT",
   healthTextOffsetX = 0,
   healthTextOffsetY = 0,
         
   maxHealthText = true,
   shortMaxHealthText = true,
   
   healthInfoTextRace = false,
   healthInfoTextSpec = false,
   healthInfoTextClass = false,
   healthInfoTextName = true,
   healthInfoTextFont = "Friz Quadrata TT",
   healthInfoTextSize = 11,
   healthInfoTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   healthInfoTextAlign = "LEFT",
   healthInfoTextAnchor = "LEFT",
   healthInfoTextOffsetX = 0,
   healthInfoTextOffsetY = 0,
})

function HealthBar:OnEnable()   
   self:RegisterEvent("UNIT_HEALTH")
   self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
   
   LSM = Gladius.LSM
   
   self.frame = {}
end

function HealthBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:Hide()
   end
end

function HealthBar:GetAttachTo()
   return Gladius.db.healthBarAttachTo
end

function HealthBar:GetFrame(unit)
   return self.frame[unit]
end

function HealthBar:UNIT_HEALTH(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
   local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
   self:UpdateHealth(unit, health, maxHealth)
end

function HealthBar:UpdateHealth(unit, health, maxHealth)
   if (not self.frame[unit]) then
      if (not Gladius.buttons[unit]) then
         Gladius:UpdateUnit(unit)
      else
         self:Update(unit)
      end
   end
  
   -- update min max values
   self.frame[unit]:SetMinMaxValues(0, maxHealth)

   -- inverse bar
   if (Gladius.db.healthBarInverse) then
      self.frame[unit]:SetValue(maxHealth - health)
   else
      self.frame[unit]:SetValue(health)
   end
   
   -- set health text
   local healthText = ""
   
   if (Gladius.db.healthText) then
      -- customize text
      if (Gladius.db.shortHealthText and health > 9999) then
         healthText = format("%.1fk", (health / 1000))
      else
         healthText = health
      end
   end
   
   -- set max health
   if (Gladius.db.maxHealthText) then
      -- customize text
      local maxHealthText
      if (Gladius.db.shortMaxHealthText and maxHealth > 9999) then
         maxHealthText = format("%.1fk", (maxHealth / 1000))
      else
         maxHealthText = maxHealth
      end
      
      if (Gladius.db.healthText) then
         healthText = format("%s/%s", healthText, maxHealthText)
      else
         healthText = maxHealthText
      end
   end
   
   -- set health percentage text
   if (Gladius.db.healthTextPercentage) then
      healthText = format("%s (%s%%)", healthText, format("%.1f", (health / maxHealth * 100)))
   end
   
   self.frame[unit].text:SetText(healthText)
end

function HealthBar:CreateBar(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "Gladius" .. self.name .. unit, button) 
   self.frame[unit].text = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "Text" .. unit, "OVERLAY")
   self.frame[unit].infoText = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "InfoText" .. unit, "OVERLAY")
end

function HealthBar:Update(unit)
   local testing = Gladius.test
   
   -- get unit class
   local class
   if (not testing) then
      class = select(2, UnitClass(unit))
   else
      class = Gladius.testing[unit].unitClass
   end

   -- create health bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
   
   -- reset bar
   self:Reset(unit)
   
   -- update health bar   
   self.frame[unit]:ClearAllPoints()
   
   local parent = Gladius:GetParent(unit, Gladius.db.healthBarAttachTo)  
	local relativePoint = "BOTTOMLEFT"
	local point = "TOPLEFT"	
	if (Gladius.db.healthBarAttachTo == "Frame") then relativePoint = point end
	
   self.frame[unit]:SetPoint(point, parent, relativePoint)
	self.frame[unit]:SetWidth(Gladius.db.healthBarAdjustWidth and Gladius.db.barWidth or Gladius.db.healthBarWidth)
	self.frame[unit]:SetHeight(Gladius.db.healthBarHeight)	
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.healthBarTexture))
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
	
	-- set color
   if (not Gladius.db.healthBarClassColor) then
      local color = Gladius.db.healthBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      self.frame[unit]:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
   end
   
   -- update health text   
	self.frame[unit].text:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.healthTextFont), Gladius.db.healthTextSize)
	
	local color = Gladius.db.healthTextColor
	self.frame[unit].text:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].text:SetShadowOffset(1, -1)
	self.frame[unit].text:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].text:SetJustifyH(Gladius.db.healthTextAlign)
	self.frame[unit].text:SetPoint(Gladius.db.healthTextAnchor, self.frame[unit], Gladius.db.healthTextOffsetX, Gladius.db.healthTextOffsetY)
   
   -- update health info text   
	self.frame[unit].infoText:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.healthInfoTextFont), Gladius.db.healthInfoTextSize)
	
	local color = Gladius.db.healthInfoTextColor
	self.frame[unit].infoText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].infoText:SetShadowOffset(1, -1)
	self.frame[unit].infoText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].infoText:SetJustifyH(Gladius.db.healthInfoTextAlign)
	self.frame[unit].infoText:SetPoint(Gladius.db.healthInfoTextAnchor, self.frame[unit], Gladius.db.healthInfoTextOffsetX, Gladius.db.healthInfoTextOffsetY)
	
	-- set info text
   local healthInfoText = ""
   
   -- race
   if (Gladius.db.healthInfoTextRace) then
      local race = Gladius.test and Gladius.testing[unit].unitRace or UnitRace(unit)
      healthInfoText = race
   end
   
   -- spec
   if (Gladius.db.healthInfoTextSpec) then
      local spec = Gladius.test and Gladius.testing[unit].unitSpec or ""
      healthInfoText = healthInfoText .. " " .. spec
   end
   
   -- class
   if (Gladius.db.healthInfoTextClass) then
      local class = Gladius.test and LOCALIZED_CLASS_NAMES_MALE[Gladius.testing[unit].unitClass] or UnitClass(unit)
      healthInfoText = healthInfoText .. " " .. class
   end
   
   -- name
   if (Gladius.db.healthInfoTextName) then
      local name = Gladius.test and unit or UnitName(unit)
      healthInfoText = healthInfoText .. " " .. name
   end
   
   self.frame[unit].infoText:SetText(healthInfoText)
      
   -- update health if not testing
   if (not testing) then
      self:UNIT_HEALTH("UNIT_HEALTH", unit)
   end
end

function HealthBar:Reset(unit)
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
end

function HealthBar:Test(unit)   
   -- update bar
   self:Update(unit)
   
   -- set test values
   local maxHealth = 30000
   local health = maxHealth --random(0, maxHealth)
   self:UpdateHealth(unit, health, maxHealth)
end


local function getColorOption(info)
   local key = info.arg or info[#info]
   return Gladius.dbi.profile[key].r, Gladius.dbi.profile[key].g, Gladius.dbi.profile[key].b, Gladius.dbi.profile[key].a
end

local function setColorOption(info, r, g, b, a) 
   local key = info.arg or info[#info]
   Gladius.dbi.profile[key].r, Gladius.dbi.profile[key].g, Gladius.dbi.profile[key].b, Gladius.dbi.profile[key].a = r, g, b, a
   Gladius:UpdateFrame()
end

function HealthBar:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         inline=true,
         order=1,
         args = {
            healthBarAttachTo = {
               type="select",
               name=L["healthBarAttachTo"],
               desc=L["healthBarAttachToDesc"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            healthBarHeight = {
               type="range",
               name=L["healthBarHeight"],
               desc=L["healthBarHeightDesc"],
               min=10, max=200, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            healthBarAdjustWidth = {
               type="toggle",
               name=L["healthBarAdjustWidth"],
               desc=L["healthBarAdjustWidthDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=6,
            },
            healthBarWidth = {
               type="range",
               name=L["healthBarWidth"],
               desc=L["healthBarWidthDesc"],
               min=10, max=500, step=1,
               disabled=function() return Gladius.dbi.profile.healthBarAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=7,
            },
            healthBarInverse = {
               type="toggle",
               name=L["healthBarInverse"],
               desc=L["healthBarInverseDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=10,
            },
            healthBarColor = {
               type="color",
               name=L["healthBarColor"],
               desc=L["healthBarColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               disabled=function() return Gladius.dbi.profile.healthBarClassColor or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            healthBarClassColor = {
               type="toggle",
               name=L["healthBarClassColor"],
               desc=L["healthBarClassColorDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            healthBarTexture = {
               type="select",
               name=L["healthBarTexture"],
               desc=L["healthBarTextureDesc"],
               dialogControl = "LSM30_Statusbar",
               values = AceGUIWidgetLSMlists.statusbar,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=25,
            },   
         },
      },
      healthText = {  
         type="group",
         name=L["healthText"],
         inline=true,
         order=2,
         args = {
            healthText = {
               type="toggle",
               name=L["healthText"],
               desc=L["healthTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            shortHealthText = {
               type="toggle",
               name=L["shortHealthText"],
               desc=L["shortHealthTextDesc"],
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },            
            maxHealthText = {
               type="toggle",
               name=L["maxHealthText"],
               desc=L["maxHealthTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            shortMaxHealthText = {
               type="toggle",
               name=L["shortMaxHealthText"],
               desc=L["shortMaxHealthTextDesc"],
               disabled=function() return not Gladius.dbi.profile.maxHealthText or not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            healthTextPercentage = {
               type="toggle",
               name=L["healthTextPercentage"],
               desc=L["healthTextPercentageDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=50,
            },
            healthTextFont = {
               type="select",
               name=L["healthTextFont"],
               desc=L["healthTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            healthTextSize = {
               type="range",
               name=L["healthTextSize"],
               desc=L["healthTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            healthTextColor = {
               type="color",
               name=L["healthTextColor"],
               desc=L["healthTextColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               width="double",
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            healthTextAlign = {
               type="select",
               name=L["healthTextAlign"],
               desc=L["healthTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            healthTextAnchor = {
               type="select",
               name=L["healthTextAnchor"],
               desc=L["healthTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            healthTextOffsetX = {
               type="range",
               name=L["healthTextOffsetX"],
               desc=L["healthTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            healthTextOffsetY = {
               type="range",
               name=L["healthTextOffsetY"],
               desc=L["healthTextOffsetYDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=90,
            },
         },
      },
      healthInfoText = {  
         type="group",
         name=L["healthInfoText"],
         inline=true,
         order=3,
         args = {
            healthInfoTextName = {
               type="toggle",
               name=L["healthInfoTextName"],
               desc=L["healthInfoTextNameDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },            
            healthInfoTextRace = {
               type="toggle",
               name=L["healthInfoTextRace"],
               desc=L["healthInfoTextRaceDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            healthInfoTextClass = {
               type="toggle",
               name=L["healthInfoTextClass"],
               desc=L["healthInfoTextClassDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            healthInfoTextSpec = {
               type="toggle",
               name=L["healthInfoTextSpec"],
               desc=L["healthInfoTextSpecDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
            healthInfoTextFont = {
               type="select",
               name=L["healthInfoTextFont"],
               desc=L["healthInfoTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            healthInfoTextSize = {
               type="range",
               name=L["healthInfoTextSize"],
               desc=L["healthInfoTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            healthInfoTextColor = {
               type="color",
               name=L["healthInfoTextColor"],
               desc=L["healthInfoTextColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            healthInfoTextAlign = {
               type="select",
               name=L["healthInfoTextAlign"],
               desc=L["healthInfoTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            healthInfoTextAnchor = {
               type="select",
               name=L["healthInfoTextAnchor"],
               desc=L["healthInfoTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            healthInfoTextOffsetX = {
               type="range",
               name=L["healthInfoTextOffsetX"],
               desc=L["healthInfoTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            healthInfoTextOffsetY = {
               type="range",
               name=L["healthInfoTextOffsetY"],
               desc=L["healthInfoTextOffsetYDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=90,
            },
         },
      },
   }
end
