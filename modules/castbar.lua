local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Cast Bar"))
end
local L = Gladius.L
local LSM

local CastBar = Gladius:NewModule("CastBar", "AceEvent-3.0")
Gladius:SetModule(CastBar, "CastBar", true, {
   castBarAttachTo = "ClassIcon",
   
   castBarAdjustHeight = true,
   castBarHeight = 40,
   castBarAdjustWidth = false,
   castBarWidth = 300,
   
   castBarOffsetX = 0,
   castBarOffsetY = 0,
   
   castBarPosition = "LEFT",
   
   castBarInverse = false,
   castBarColor = { r = 1, g = 1, b = 1, a = 1 },
   castBarTexture = "Minimalist",
   
   castIcon = true,
   castIconPosition = "LEFT",      
   
   castText = true,
   castTextFont = "Friz Quadrata TT",
   castTextSize = 11,
   castTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   castTextAlign = "LEFT",
   castTextAnchor = "LEFT",
   castTextOffsetX = 0,
   castTextOffsetY = 0,
   
   castTimeText = true,
   castTimeTextFont = "Friz Quadrata TT",
   castTimeTextSize = 11,
   castTimeTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   castTimeTextAlign = "RIGHT",
   castTimeTextAnchor = "RIGHT",
   castTimeTextOffsetX = 0,
   castTimeTextOffsetY = 0,
})

function CastBar:OnEnable()
   self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_STOP")
   
   LSM = Gladius.LSM
   
   self.frame = {}
   
   -- set frame type
   if (Gladius.db.castBarPosition ~= "CENTER") then
      self.isBar = false
   end
end

function CastBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:Hide()
   end
end

function CastBar:GetAttachTo()
   return Gladius.db.castBarAttachTo
end

function CastBar:GetFrame(unit)
   if (Gladius.db.castIcon and Gladius.db.castIconPosition == "LEFT") then
      return self.frame[unit].icon
   else
      return self.frame[unit]
   end
end

--Spell casts
local RESURRECTION_SPELLS = {
	[GetSpellInfo(48950)] = true,
	[GetSpellInfo(48171)] = true,
	[GetSpellInfo(49277)] = true,
	[GetSpellInfo(50763)] = true
}
function CastBar:UNIT_SPELLCAST_START(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
	if (spell) then
      self.frame[unit].isCasting = true
      self.frame[unit].value = (GetTime() - (startTime / 1000))
      self.frame[unit].maxValue = (endTime - startTime) / 1000
      self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
      self.frame[unit]:SetValue(self.frame[unit].value)
      self.frame[unit].timeText:SetText(self.frame[unit].maxValue)
      self.frame[unit].icon:SetTexture(icon)
		
		if( rank ~= "" ) then
			self.frame[unit].castText:SetFormattedText("%s (%s)", spell, rank)
		else
			self.frame[unit].castText:SetText(spell)
		end
	end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)	
	if (spell) then
		self.frame[unit].isChanneling = true
		self.frame[unit].value = ((endTime / 1000) - GetTime())
		self.frame[unit].maxValue = (endTime - startTime) / 1000
		self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
		self.frame[unit]:SetValue(self.frame[unit].value)
		self.frame[unit].timeText:SetText(self.frame[unit].maxValue)
		self.frame[unit].icon:SetTexture(icon)

		if( rank ~= "" ) then
			self.frame[unit].castText:SetFormattedText("%s (%s)", spell, rank)
		else
			self.frame[unit].castText:SetText(spell)
		end
	end	
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end   
   self:CastEnd(self.frame[unit])
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
   local spell, rank, displayName, icon, startTime, endTime, isTradeSkill
   if (event == "UNIT_SPELLCAST_DELAYED") then
      spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
   else
      spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
   end
   
   if (startTime == nil) then return end
   
   self.frame[unit].value = (GetTime() - (startTime / 1000))
   self.frame[unit].maxValue = (endTime - startTime) / 1000
   self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
end

function CastBar:CastEnd(bar)
	bar.isCasting = nil
	bar.isChanneling = nil
	bar.timeText:SetText("")
	bar.castText:SetText("")
	bar.icon:SetTexture("")
	bar:SetValue(0)
end

function CastBar:CreateBar(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end      
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "Gladius" .. self.name .. unit, button) 
   self.frame[unit].castText = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "CastText" .. unit, "OVERLAY")
   self.frame[unit].timeText = self.frame[unit]:CreateFontString("Gladius" .. self.name .. "TimeText" .. unit, "OVERLAY")
   self.frame[unit].icon = self.frame[unit]:CreateTexture("Gladius" .. self.name .. "IconFrame" .. unit, "ARTWORK") 
end

local function CastUpdate(self, elapsed)
   if (Gladius.test) then return end

	if (self.isCasting) then
		if (self.value >= self.maxValue) then
			self:SetValue(self.maxValue)
			CastBar:CastEnd(self)
			return
		end
		self.value = self.value + elapsed
		self:SetValue(Gladius.db.castBarInverse and (self.maxValue - self.value) or self.value)
		self.timeText:SetFormattedText("%.1f", self.maxValue-self.value)
	elseif (self.isChanneling) then
		if (self.value <= 0) then
			CastBar:CastEnd(self)
			return
		end
		self.value = self.value - elapsed
		self:SetValue(Gladius.db.castBarInverse and (self.maxValue - self.value) or self.value)
		self.timeText:SetFormattedText("%.1f", self.value)
	end
end

function CastBar:Update(unit)
   local testing = Gladius.test
   
   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
      
   -- update power bar   
   self.frame[unit]:ClearAllPoints()

   local width = Gladius.db.castBarAdjustWidth and Gladius.db.barWidth or Gladius.db.castBarWidth
   if (Gladius.db.castIcon) then
       width = width - Gladius.db.castBarHeight
	end
	
	-- add width of the indicator if attached to an indicator
	if (Gladius.db.castBarAttachTo ~= "Frame" and Gladius.db.castBarAdjustWidth and self.isBar) then
      if (not Gladius:GetModule(Gladius.db.castBarAttachTo).frame[unit]) then
         Gladius:GetModule(Gladius.db.castBarAttachTo):Update(unit)
      end
      
      width = width + Gladius:GetModule(Gladius.db.castBarAttachTo).frame[unit]:GetWidth()
	end
	
	if (not self.isBar and Gladius.db.castBarAdjustHeight) then
      self.frame[unit]:SetWidth(width)   
      self.frame[unit]:SetHeight(Gladius.buttons[unit].frameHeight)   
   else
      self.frame[unit]:SetWidth(width)   
      self.frame[unit]:SetHeight(Gladius.db.castBarHeight)  
   end  
	
	local parent, point, relativePoint, offsetX
	if (not self.isBar) then
      parent = Gladius:GetParent(unit, Gladius.db.castBarAttachTo)     
      point = Gladius.db.castBarPosition == "LEFT" and "RIGHT" or "LEFT" 
      relativePoint = Gladius.db.castBarPosition      
      
      if (Gladius.db.castBarPosition == "RIGHT") then
         offsetX = Gladius.db.castIcon and Gladius.db.castIconPosition == "LEFT" and self.frame[unit]:GetHeight() or 0
      elseif (Gladius.db.castBarPosition == "LEFT") then
         offsetX = Gladius.db.castIcon and Gladius.db.castIconPosition == "RIGHT" and -self.frame[unit]:GetHeight() or 0
      end
   else
      parent = Gladius:GetParent(unit, Gladius.db.castBarAttachTo)  
      relativePoint = "BOTTOMLEFT"
      point = "TOPLEFT"	
      if (Gladius.db.castBarAttachTo == "Frame") then relativePoint = point end
      
      offsetX = Gladius.db.castIcon and Gladius.db.castIconPosition == "LEFT" and self.frame[unit]:GetHeight() or 0
	end
	
	self.frame[unit]:SetPoint(point, parent, relativePoint, Gladius.db.castBarOffsetX + (offsetX or 0), Gladius.db.castBarOffsetY)	
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(0)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.castBarTexture))
	
	-- updating
	self.frame[unit]:SetScript("OnUpdate", CastUpdate)
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
	
	-- set color
   local color = Gladius.db.castBarColor
   self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   
   -- update cast text   
	self.frame[unit].castText:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.castTextFont), Gladius.db.castTextSize)
	
	local color = Gladius.db.castTextColor
	self.frame[unit].castText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].castText:SetShadowOffset(1, -1)
	self.frame[unit].castText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].castText:SetJustifyH(Gladius.db.castTextAlign)
	self.frame[unit].castText:SetPoint(Gladius.db.castTextAnchor, Gladius.db.castTextOffsetX, Gladius.db.castTextOffsetY)
	
	-- update cast time text   
	self.frame[unit].timeText:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.castTimeTextFont), Gladius.db.castTimeTextSize)
	
	local color = Gladius.db.castTimeTextColor
	self.frame[unit].timeText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].timeText:SetShadowOffset(1, -1)
	self.frame[unit].timeText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].timeText:SetJustifyH(Gladius.db.castTimeTextAlign)
	self.frame[unit].timeText:SetPoint(Gladius.db.castTimeTextAnchor, Gladius.db.castTimeTextOffsetX, Gladius.db.castTimeTextOffsetY)    
	
	-- update icon
	self.frame[unit].icon:ClearAllPoints()
	self.frame[unit].icon:SetPoint(Gladius.db.castIconPosition == "LEFT" and "RIGHT" or "LEFT", self.frame[unit], Gladius.db.castIconPosition)
	
	self.frame[unit].icon:SetWidth(self.frame[unit]:GetHeight())
	self.frame[unit].icon:SetHeight(self.frame[unit]:GetHeight())
	
	-- hide
	self.frame[unit]:SetAlpha(0)
end

function CastBar:Show(unit)
   -- show frame
   self.frame[unit]:SetAlpha(1)
end

function CastBar:Reset(unit)
   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(0)

   -- reset text
   if (self.frame[unit].castText:GetFont()) then
      self.frame[unit].castText:SetText("")
   end
   
   if (self.frame[unit].timeText:GetFont()) then
      self.frame[unit].timeText:SetText("")
   end
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function CastBar:Test(unit)   
   -- update bar
   self:Update(unit)

   self.frame[unit].isCasting = true
   self.frame[unit].value = 1
   self.frame[unit].maxValue = 1
   self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
   self.frame[unit]:SetValue(self.frame[unit].value)
   self.frame[unit].timeText:SetFormattedText("%.1f", self.frame[unit].maxValue - self.frame[unit].value)
   
   local texture = select(3, GetSpellInfo(1))
   self.frame[unit].icon:SetTexture(texture)
   
   self.frame[unit].castText:SetText(L["Example Spell Name"])
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

function CastBar:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         inline=true,
         order=1,
         args = {       
            castBarAttachTo = {
               type="select",
               name=L["castBarAttachTo"],
               desc=L["castBarAttachToDesc"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            castBarPosition = {
               type="select",
               name=L["castBarPosition"],
               desc=L["castBarPositionDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               set=function(info, value)
                  local key = info.arg or info[#info]
                  Gladius.dbi.profile[key] = value
                  
                  -- set frame type
                  if (value == "CENTER") then
                     self.isBar = true
                  else
                     self.isBar = false
                  end
                  
                  Gladius:UpdateFrame()
               end,
               order=2,
            },
            castBarAdjustHeight = {
               type="toggle",
               name=L["castBarAdjustHeight"],
               desc=L["castBarAdjustHeightDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=4,
            },
            castBarHeight = {
               type="range",
               name=L["castBarHeight"],
               desc=L["castBarHeightDesc"],
               min=10, max=200, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] or (Gladius.dbi.profile.castBarPosition ~= "CENTER" and Gladius.dbi.profile.castBarAdjustHeight) end,
               order=5,
            },
            castBarAdjustWidth = {
               type="toggle",
               name=L["castBarAdjustWidth"],
               desc=L["castBarAdjustWidthDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=6,
            },
            castBarWidth = {
               type="range",
               name=L["castBarWidth"],
               desc=L["castBarWidthDesc"],
               min=10, max=500, step=1,
               disabled=function() return Gladius.dbi.profile.castBarAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=7,
            },
            castIcon = {
               type="toggle",
               name=L["castIcon"],
               desc=L["castIconDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=10,
            },
            castIconPosition = {
               type="select",
               name=L["castIconPosition"],
               desc=L["castIconPositionDesc"],
               values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.castIcon or not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },                        
            castBarInverse = {
               type="toggle",
               name=L["castBarInverse"],
               desc=L["castBarInverseDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            castBarColor = {
               type="color",
               name=L["castBarColor"],
               desc=L["castBarColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            castBarOffsetX = {
               type="range",
               name=L["castBarOffsetX"],
               desc=L["castBarOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return  not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            castBarOffsetY = {
               type="range",
               name=L["castBarOffsetY"],
               desc=L["castBarOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=35,
            },            
            castBarTexture = {
               type="select",
               name=L["castBarTexture"],
               desc=L["castBarTextureDesc"],
               dialogControl = "LSM30_Statusbar",
               values = AceGUIWidgetLSMlists.statusbar,
               width="double",
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
         },
      },
      castText = {  
         type="group",
         name=L["castText"],
         inline=true,
         order=2,
         args = {       
            castText = {
               type="toggle",
               name=L["castText"],
               desc=L["castTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=30,
            },
            castTextFont = {
               type="select",
               name=L["castTextFont"],
               desc=L["castTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            castTextSize = {
               type="range",
               name=L["castTextSize"],
               desc=L["castTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            castTextColor = {
               type="color",
               name=L["castTextColor"],
               desc=L["castTextColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               width="double",
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            castTextAlign = {
               type="select",
               name=L["castTextAlign"],
               desc=L["castTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            castTextAnchor = {
               type="select",
               name=L["castTextAnchor"],
               desc=L["castTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            castTextOffsetX = {
               type="range",
               name=L["castTextOffsetX"],
               desc=L["castTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            castTextOffsetY = {
               type="range",
               name=L["castTextOffsetY"],
               desc=L["castTextOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=90,
            },
         },
      },
      castTimeText = {  
         type="group",
         name=L["castTimeText"],
         inline=true,
         order=3,
         args = {       
            castTimeText = {
               type="toggle",
               name=L["castTimeText"],
               desc=L["castTimeTextDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=30,
            },
            castTimeTextFont = {
               type="select",
               name=L["castTimeTextFont"],
               desc=L["castTimeTextFontDesc"],
               dialogControl = "LSM30_Font",
               values = AceGUIWidgetLSMlists.font,
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=60,					
            },
            castTimeTextSize = {
               type="range",
               name=L["castTimeTextSize"],
               desc=L["castTimeTextSize"],
               min=1, max=20, step=1,
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=65,
            },
            castTimeTextColor = {
               type="color",
               name=L["castTimeTextColor"],
               desc=L["castTimeTextColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               width="double",
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=70,
            },
            castTimeTextAlign = {
               type="select",
               name=L["castTimeTextAlign"],
               desc=L["castTimeTextAlignDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=75,
            },
            castTimeTextAnchor = {
               type="select",
               name=L["castTimeTextAnchor"],
               desc=L["castTimeTextAnchorDesc"],
               values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=80,
            },
            castTimeTextOffsetX = {
               type="range",
               name=L["castTimeTextOffsetX"],
               desc=L["castTimeTextOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               order=85,
            },
            castTimeTextOffsetY = {
               type="range",
               name=L["castTimeTextOffsetY"],
               desc=L["castTimeTextOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.castTimeText or not Gladius.dbi.profile.modules[self.name] end,
               min=-100, max=100, step=1,
               order=90,
            },
         },
      },
   }
end
