local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Health Bar"))
end
local L = Gladius.L
local LSM

local HealthBar = Gladius:NewModule("HealthBar", "AceEvent-3.0")
Gladius:SetModule(HealthBar, "HealthBar", true, {
   healthBarAttachTo = "Frame",
   
   healthBarHeight = 25,
   healthBarAdjustWidth = true,
   healthBarWidth = 150,
   
   healthBarInverse = false,
   healthBarColor = { r = 1, g = 1, b = 1, a = 1 },
   healthBarClassColor = true,
   healthBarTexture = "Minimalist", 
   
   healthBarOffsetX = 0,
   healthBarOffsetY = 0,     
   
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
   
   if (not self.frame) then
      self.frame = {}
   end
end

function HealthBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
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
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("Gladius" .. self.name .. "Highlight" .. unit, "OVERLAY")
   self.frame[unit].text = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "Text" .. unit, "OVERLAY")
   self.frame[unit].infoText = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "InfoText" .. unit, "OVERLAY")
end

function HealthBar:Update(unit)
   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
   
   -- update health bar   
   self.frame[unit]:ClearAllPoints()
   
   local parent = Gladius:GetParent(unit, Gladius.db.healthBarAttachTo)  
   	
	if (Gladius.db.healthBarAttachTo == "Frame") then 
      self.frame[unit]:SetPoint("TOPLEFT", parent, "TOPLEFT", Gladius.db.healthBarOffsetX, Gladius.db.healthBarOffsetY)
   else
      self.frame[unit]:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", Gladius.db.healthBarOffsetX, Gladius.db.healthBarOffsetY)
	end
	   
	self.frame[unit]:SetWidth(Gladius.db.healthBarAdjustWidth and Gladius.db.barWidth or Gladius.db.healthBarWidth)
	self.frame[unit]:SetHeight(Gladius.db.healthBarHeight)	
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.healthBarTexture))
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)

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
	
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
	
	-- hide frame
	self.frame[unit]:SetAlpha(0)
end

function HealthBar:Show(unit)
   local testing = Gladius.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)
   
   -- get unit class
   local class
   if (not testing) then
      class = select(2, UnitClass(unit))
   else
      class = Gladius.testing[unit].unitClass
   end 
   
   -- set color
   if (not Gladius.db.healthBarClassColor) then
      local color = Gladius.db.healthBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      self.frame[unit]:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
   end

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
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function HealthBar:Test(unit)   
   -- set test values
   local maxHealth = Gladius.testing[unit].maxHealth
   local health = Gladius.testing[unit].health
   self:UpdateHealth(unit, health, maxHealth)
end

function HealthBar:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {
            healthBarAttachTo = {
               type="select",
               name=L["Health bar attach to"],
               desc=L["Attach health bar to the given frame"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            healthBarHeight = {
               type="range",
               name=L["Health bar height"],
               desc=L["Height of the health bar"],
               min=10, max=200, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            healthBarAdjustWidth = {
               type="toggle",
               name=L["Health bar adjust width"],
               desc=L["Adjust health bar width to the frame width"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            healthBarWidth = {
               type="range",
               name=L["Health bar width"],
               desc=L["Width of the health bar"],
               min=10, max=500, step=1,
               disabled=function() return Gladius.dbi.profile.healthBarAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            healthBarInverse = {
               type="toggle",
               name=L["Health bar inverse"],
               desc=L["Inverse the health bar"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=20,
            },
            healthBarColor = {
               type="color",
               name=L["Health bar color"],
               desc=L["Color of the health bar"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               disabled=function() return Gladius.dbi.profile.healthBarClassColor or not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            healthBarClassColor = {
               type="toggle",
               name=L["Health bar class color"],
               desc=L["Toggle health bar class color"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            healthBarOffsetX = {
               type="range",
               name=L["Health bar offset X"],
               desc=L["X offset of the health bar"],
               min=-100, max=100, step=1,
               disabled=function() return  not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            healthBarOffsetY = {
               type="range",
               name=L["Health bar offset Y"],
               desc=L["Y offset of the health bar"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=40,
            },  
            healthBarTexture = {
               type="select",
               name=L["Health bar texture"],
               desc=L["Texture of the health bar"],
               dialogControl = "LSM30_Statusbar",
               values = AceGUIWidgetLSMlists.statusbar,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=45,
            },   
         },
      },
      healthText = {  
         type="group",
         name=L["Health text"],
         order=2,
         args = {
            healthText = {
               type="toggle",
               name=L["Health text"],
               desc=L["Toggle health text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            shortHealthText = {
               type="toggle",
               name=L["Short health text"],
               desc=L["Toggle short health text"],
               disabled=function() return not Gladius.dbi.profile.healthText or not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },            
            maxHealthText = {
               type="toggle",
               name=L["Max health text"],
               desc=L["Toggle max health text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            shortMaxHealthText = {
               type="toggle",
               name=L["Short max health text"],
               desc=L["Toggle short max health text"],
               disabled=function() return not Gladius.dbi.profile.maxHealthText or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            healthTextPercentage = {
               type="toggle",
               name=L["Health text percentage"],
               desc=L["Toggle health text percentage"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=20,
            },
            healthTextFont = {
               type="select",
               name=L["Health text font"],
               desc=L["Font of the health text"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,					
            },
            healthTextSize = {
               type="range",
               name=L["Health text size"],
               desc=L["Text size of the health text"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            healthTextColor = {
               type="color",
               name=L["Health text color"],
               desc=L["Text color of the health text"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            healthTextAlign = {
               type="select",
               name=L["Health text align"],
               desc=L["Text align of the health text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            healthTextAnchor = {
               type="select",
               name=L["Health text anchor"],
               desc=L["Text anchor of the health text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            healthTextOffsetX = {
               type="range",
               name=L["Health text offset X"],
               desc=L["X offset of the health text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
            healthTextOffsetY = {
               type="range",
               name=L["Health text offset Y"],
               desc=L["Y offset of the health text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=55,
            },
         },
      },
      healthInfoText = {  
         type="group",
         name=L["Health info text"],
         order=3,
         args = {
            healthInfoTextName = {
               type="toggle",
               name=L["Health Info name text"],
               desc=L["Toggle health info name text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },            
            healthInfoTextRace = {
               type="toggle",
               name=L["Health info race text"],
               desc=L["Toggle health info race text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            healthInfoTextClass = {
               type="toggle",
               name=L["Health info class text"],
               desc=L["Toggle health info class text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            healthInfoTextSpec = {
               type="toggle",
               name=L["Health info spec text"],
               desc=L["Toggle health info spec text"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            healthInfoTextFont = {
               type="select",
               name=L["Health info text font"],
               desc=L["Text font of the health info text"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,					
            },
            healthInfoTextSize = {
               type="range",
               name=L["Health info text size"],
               desc=L["Text size of the health info text"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            healthInfoTextColor = {
               type="color",
               name=L["Health info text color"],
               desc=L["Text color of the health info text"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            healthInfoTextAlign = {
               type="select",
               name=L["Health info text align"],
               desc=L["Text align of the health info text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            healthInfoTextAnchor = {
               type="select",
               name=L["Health info text anchor"],
               desc=L["Text anchor of the health info text"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            healthInfoTextOffsetX = {
               type="range",
               name=L["Health info text offset X"],
               desc=L["X offset of the health info text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            healthInfoTextOffsetY = {
               type="range",
               name=L["Health info text offset Y"],
               desc=L["Y offset of the health info text"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=50,
            },
         },
      },
   }
end
