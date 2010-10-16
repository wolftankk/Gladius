local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Auras"))
end
local L = Gladius.L
local LSM

local Auras = Gladius:NewModule("Auras", "AceEvent-3.0")
Gladius:SetModule(Auras, "Auras", false, true, {
   aurasBuffsAttachTo = "CastBar",
   aurasBuffsAnchor = "TOPLEFT",
   aurasBuffsRelativePoint = "BOTTOMLEFT",
   aurasBuffs = true,
   aurasBuffsGrow = "DOWNRIGHT",
   aurasBuffsSpacingX = 0,
   aurasBuffsSpacingY = 0,
   aurasBuffsPerColumn = 10,
   aurasBuffsMax = 20,
   aurasBuffsHeight = 16,
   aurasBuffsWidth = 16,
   aurasBuffsOffsetX = 0,
   aurasBuffsOffsetY = 0,
   aurasBuffsGloss = false,
   aurasBuffsGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   
   aurasDebuffsAttachTo = "ClassIcon",
   aurasDebuffsAnchor = "BOTTOMLEFT",
   aurasDebuffsRelativePoint = "TOPLEFT",
   aurasDebuffs = true,
   aurasDebuffsGrow = "UPRIGHT",
   aurasDebuffsSpacingX = 0,
   aurasDebuffsSpacingY = 0,
   aurasDebuffsPerColumn = 10,
   aurasDebuffsMax = 20,
   aurasDebuffsHeight = 16,
   aurasDebuffsWidth = 16,
   aurasDebuffsOffsetX = 0,
   aurasDebuffsOffsetY = 0,
   aurasDebuffsGloss = false,
   aurasDebuffsGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   
   aurasImportantAuras = true,
   aurasFrameAuras = nil,
})

function Auras:OnEnable()   
   self:RegisterEvent("UNIT_AURA")
   
   LSM = Gladius.LSM   
   
   self.buffFrame = self.buffFrame or {}
   self.debuffFrame = self.debuffFrame or {}
   
   -- set auras
   Gladius.db.aurasFrameAuras = Gladius.db.aurasFrameAuras or self:GetAuraList()
end

function Auras:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.buffFrame) do
      self.buffFrame[unit]:SetAlpha(0)
   end
end

function Auras:GetAttachTo()
   return Gladius.db.aurasAttachTo
end

function Auras:GetFrame(unit)
   return self.buffFrame[unit]
end

function Auras:GetIndicatorHeight()
   local height = 0
   
   if (Gladius.db.aurasBuffs) then
      height = height + Gladius.db.aurasBuffsHeight * ceil(Gladius.db.aurasBuffsMax / Gladius.db.aurasBuffsPerColumn)
   end
   
   if (Gladius.db.aurasDebuffs) then
      height = height + Gladius.db.aurasDebuffsHeight * ceil(Gladius.db.aurasDebuffsMax / Gladius.db.aurasDebuffsPerColumn)
   end
   
   return height
end

function Auras:UNIT_AURA(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
   -- buff frame
   for i=1, 40 do
      local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitBuff(unit, i)
      
      if (not self.buffFrame[unit][i]) then break end
      
      if (name) then       
         self.buffFrame[unit][i].texture:SetTexture(icon)
         CooldownFrame_SetTimer(self.buffFrame[unit][i].cooldown, GetTime(), duration and duration - GetTime() or 0, 1)    
         
         self.buffFrame[unit][i]:SetAlpha(1)
      else
         self.buffFrame[unit][i]:SetAlpha(0)
      end
   end
   
   -- debuff frame
   for i=1, 40 do
      local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitDebuff(unit, i)
      
      if (not self.debuffFrame[unit][i]) then break end
      
      if (name) then       
         self.debuffFrame[unit][i].texture:SetTexture(icon)
         CooldownFrame_SetTimer(self.debuffFrame[unit][i].cooldown, GetTime(), duration and duration - GetTime() or 0, 1)    
         
         self.debuffFrame[unit][i]:SetAlpha(1)
      else
         self.debuffFrame[unit][i]:SetAlpha(0)
      end
   end
end

local function updateTooltip(f, unit, index, filter)
   if (GameTooltip:IsOwned(f)) then
		GameTooltip:SetUnitAura(unit, index, filter)
	end
end

function Auras:CreateFrame(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create buff frame
   if (not self.buffFrame[unit] and Gladius.db.aurasBuffs) then
      self.buffFrame[unit] = CreateFrame("Frame", "Gladius" .. self.name .. "BuffFrame" .. unit, button)
      self.buffFrame[unit]:EnableMouse(false)
      
      for i=1, 40 do
         self.buffFrame[unit][i] = CreateFrame("CheckButton", "Gladius" .. self.name .. "BuffFrameIcon" .. i .. unit, button, "ActionButtonTemplate")
         self.buffFrame[unit][i]:SetScript("OnEnter", function(f) 
            GameTooltip:SetUnitAura(unit, i, "HELPFUL")
            f:SetScript("OnUpdate", function(f)
               updateTooltip(f, unit, i, "HELPFUL")
            end)
         end)
         self.buffFrame[unit][i]:SetScript("OnLeave", function(f)
            f:SetScript("OnUpdate", nil)
            GameTooltip:Hide()
         end)
         self.buffFrame[unit][i]:RegisterForClicks("RightButtonUp")
         self.buffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
         self.buffFrame[unit][i].texture = _G[self.buffFrame[unit][i]:GetName().."Icon"]
         self.buffFrame[unit][i].normalTexture = _G[self.buffFrame[unit][i]:GetName().."NormalTexture"]
         self.buffFrame[unit][i].cooldown = _G[self.buffFrame[unit][i]:GetName().."Cooldown"]
         self.buffFrame[unit][i].cooldown:SetReverse(false)
      end
   end
   
   -- create debuff frame
   if (not self.debuffFrame[unit] and Gladius.db.aurasDebuffs) then
      self.debuffFrame[unit] = CreateFrame("Frame", "Gladius" .. self.name .. "DebuffFrame" .. unit, button)
      self.debuffFrame[unit]:EnableMouse(false)
      
      for i=1, 40 do
         self.debuffFrame[unit][i] = CreateFrame("CheckButton", "Gladius" .. self.name .. "DebuffFrameIcon" .. i .. unit, button, "ActionButtonTemplate")
         self.debuffFrame[unit][i]:SetScript("OnEnter", function(f) 
            GameTooltip:SetUnitAura(unit, i, "HARMFUL")
            f:SetScript("OnUpdate", function(f)
               updateTooltip(f, unit, i, "HARMFUL")
            end)
         end)
         self.debuffFrame[unit][i]:SetScript("OnLeave", function(f)
            f:SetScript("OnUpdate", nil)
            GameTooltip:Hide()
         end)
         self.debuffFrame[unit][i]:RegisterForClicks("RightButtonUp")
         self.debuffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
         self.debuffFrame[unit][i].texture = _G[self.debuffFrame[unit][i]:GetName().."Icon"]
         self.debuffFrame[unit][i].normalTexture = _G[self.debuffFrame[unit][i]:GetName().."NormalTexture"]
         self.debuffFrame[unit][i].cooldown = _G[self.debuffFrame[unit][i]:GetName().."Cooldown"]
         self.debuffFrame[unit][i].cooldown:SetReverse(false)
      end
   end
   
   if (not Gladius.test) then
      self:UNIT_AURA(nil, unit)
   end
end

function Auras:Update(unit)   
   Gladius.db.aurasFrameAuras = Gladius.db.aurasFrameAuras or self:GetAuraList()

   -- create frame
   if (not self.buffFrame[unit] or not self.debuffFrame[unit]) then 
      self:CreateFrame(unit)
   end
   
   -- update buff frame 
   if (Gladius.db.aurasBuffs) then  
      self.buffFrame[unit]:ClearAllPoints()
      
      -- anchor point 
      local parent = Gladius:GetParent(unit, Gladius.db.aurasBuffsAttachTo)     
      self.buffFrame[unit]:SetPoint(Gladius.db.aurasBuffsAnchor, parent, Gladius.db.aurasBuffsRelativePoint, Gladius.db.aurasBuffsOffsetX, Gladius.db.aurasBuffsOffsetY)

      -- size
      self.buffFrame[unit]:SetWidth(1)
      self.buffFrame[unit]:SetHeight(1)
      
      -- icon points
      local anchor, parent, relativePoint, offsetX, offsetY
      local start, startAnchor = 1, self.buffFrame[unit]
      
      -- grow anchor
      local grow1, grow2, grow3
      if (Gladius.db.aurasBuffsGrow == "DOWNRIGHT") then
         grow1, grow2, grow3 = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT"      
      elseif (Gladius.db.aurasBuffsGrow == "DOWNLEFT") then
         grow1, grow2, grow3 = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT"
      elseif (Gladius.db.aurasBuffsGrow == "UPRIGHT") then
         grow1, grow2, grow3 = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT"
      elseif (Gladius.db.aurasBuffsGrow == "UPLEFT") then
         grow1, grow2, grow3 = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT"
      end
            
      for i=1, 40 do
         self.buffFrame[unit][i]:ClearAllPoints()
         
         if (Gladius.db.aurasBuffsMax >= i) then        
            if (start == 1) then
               anchor, parent, relativePoint, offsetX, offsetY = grow1, startAnchor, grow2, 0, Gladius.db.aurasBuffsGrow:find("DOWN") and -Gladius.db.aurasBuffsSpacingY or Gladius.db.aurasBuffsSpacingY                  
            else
               anchor, parent, relativePoint, offsetX, offsetY = grow1, self.buffFrame[unit][i-1], grow3, Gladius.db.aurasBuffsGrow:find("LEFT") and -Gladius.db.aurasBuffsSpacingX or Gladius.db.aurasBuffsSpacingX, 0                                
               
               if (start == Gladius.db.aurasBuffsPerColumn) then
                  start = 0
                  startAnchor = self.buffFrame[unit][i - Gladius.db.aurasBuffsPerColumn + 1]
               end
            end
            
            start = start + 1
         end
      
         self.buffFrame[unit][i]:SetPoint(anchor, parent, relativePoint, offsetX, offsetY)
         
         self.buffFrame[unit][i]:SetWidth(Gladius.db.aurasBuffsWidth)
         self.buffFrame[unit][i]:SetHeight(Gladius.db.aurasBuffsHeight)
         
         -- style action button   
         self.buffFrame[unit][i].normalTexture:SetHeight(self.buffFrame[unit][i]:GetHeight() + self.buffFrame[unit][i]:GetHeight() * 0.4)
         self.buffFrame[unit][i].normalTexture:SetWidth(self.buffFrame[unit][i]:GetWidth() + self.buffFrame[unit][i]:GetWidth() * 0.4)
         
         self.buffFrame[unit][i].normalTexture:ClearAllPoints()
         self.buffFrame[unit][i].normalTexture:SetPoint("CENTER", 0, 0)
         self.buffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
         
         self.buffFrame[unit][i].texture:ClearAllPoints()
         self.buffFrame[unit][i].texture:SetPoint("TOPLEFT", self.buffFrame[unit][i], "TOPLEFT")
         self.buffFrame[unit][i].texture:SetPoint("BOTTOMRIGHT", self.buffFrame[unit][i], "BOTTOMRIGHT")
         
         self.buffFrame[unit][i].normalTexture:SetVertexColor(Gladius.db.aurasBuffsGlossColor.r, Gladius.db.aurasBuffsGlossColor.g, 
            Gladius.db.aurasBuffsGlossColor.b, Gladius.db.aurasBuffsGloss and Gladius.db.aurasBuffsGlossColor.a or 0)
      end
   end

   -- hide
   self.buffFrame[unit]:SetAlpha(0)
   
   -- update debuff frame 
   if (Gladius.db.aurasDebuffs) then  
      self.debuffFrame[unit]:ClearAllPoints()
      
      -- anchor point 
      local parent = Gladius:GetParent(unit, Gladius.db.aurasDebuffsAttachTo)     
      self.debuffFrame[unit]:SetPoint(Gladius.db.aurasDebuffsAnchor, parent, Gladius.db.aurasDebuffsRelativePoint, Gladius.db.aurasDebuffsOffsetX, Gladius.db.aurasDebuffsOffsetY)

      -- size
      self.debuffFrame[unit]:SetWidth(1)
      self.debuffFrame[unit]:SetHeight(1)
      
      -- icon points
      local anchor, parent, relativePoint, offsetX, offsetY
      local start, startAnchor = 1, self.debuffFrame[unit]
      
      -- grow anchor
      local grow1, grow2, grow3
      if (Gladius.db.aurasDebuffsGrow == "DOWNRIGHT") then
         grow1, grow2, grow3 = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT"      
      elseif (Gladius.db.aurasDebuffsGrow == "DOWNLEFT") then
         grow1, grow2, grow3 = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT"
      elseif (Gladius.db.aurasDebuffsGrow == "UPRIGHT") then
         grow1, grow2, grow3 = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT"
      elseif (Gladius.db.aurasDebuffsGrow == "UPLEFT") then
         grow1, grow2, grow3 = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT"
      end
            
      for i=1, 40 do
         self.debuffFrame[unit][i]:ClearAllPoints()
         
         if (Gladius.db.aurasDebuffsMax >= i) then        
            if (start == 1) then
               anchor, parent, relativePoint, offsetX, offsetY = grow1, startAnchor, grow2, 0, Gladius.db.aurasDebuffsGrow:find("DOWN") and -Gladius.db.aurasDebuffsSpacingY or Gladius.db.aurasDebuffsSpacingY                  
            else
               anchor, parent, relativePoint, offsetX, offsetY = grow1, self.debuffFrame[unit][i-1], grow3, Gladius.db.aurasDebuffsGrow:find("LEFT") and -Gladius.db.aurasDebuffsSpacingX or Gladius.db.aurasDebuffsSpacingX, 0                                
               
               if (start == Gladius.db.aurasDebuffsPerColumn) then
                  start = 0
                  startAnchor = self.debuffFrame[unit][i - Gladius.db.aurasDebuffsPerColumn + 1]
               end
            end
            
            start = start + 1
         end
      
         self.debuffFrame[unit][i]:SetPoint(anchor, parent, relativePoint, offsetX, offsetY)
         
         self.debuffFrame[unit][i]:SetWidth(Gladius.db.aurasDebuffsWidth)
         self.debuffFrame[unit][i]:SetHeight(Gladius.db.aurasDebuffsHeight)
         
         -- style action button   
         self.debuffFrame[unit][i].normalTexture:SetHeight(self.debuffFrame[unit][i]:GetHeight() + self.debuffFrame[unit][i]:GetHeight() * 0.4)
         self.debuffFrame[unit][i].normalTexture:SetWidth(self.debuffFrame[unit][i]:GetWidth() + self.debuffFrame[unit][i]:GetWidth() * 0.4)
         
         self.debuffFrame[unit][i].normalTexture:ClearAllPoints()
         self.debuffFrame[unit][i].normalTexture:SetPoint("CENTER", 0, 0)
         self.debuffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
         
         self.debuffFrame[unit][i].texture:ClearAllPoints()
         self.debuffFrame[unit][i].texture:SetPoint("TOPLEFT", self.debuffFrame[unit][i], "TOPLEFT")
         self.debuffFrame[unit][i].texture:SetPoint("BOTTOMRIGHT", self.debuffFrame[unit][i], "BOTTOMRIGHT")
         
         self.debuffFrame[unit][i].normalTexture:SetVertexColor(Gladius.db.aurasDebuffsGlossColor.r, Gladius.db.aurasDebuffsGlossColor.g, 
            Gladius.db.aurasDebuffsGlossColor.b, Gladius.db.aurasDebuffsGloss and Gladius.db.aurasDebuffsGlossColor.a or 0)
      end
   end

   -- hide
   self.debuffFrame[unit]:SetAlpha(0)
end

function Auras:Show(unit)
   local testing = Gladius.test
      
   -- show buff frame
   self.buffFrame[unit]:SetAlpha(1)
   
   for i=1, Gladius.db.aurasBuffsMax do
      self.buffFrame[unit][i]:SetAlpha(1)
   end
   
   -- show debuff frame
   self.debuffFrame[unit]:SetAlpha(1)
   
   for i=1, Gladius.db.aurasDebuffsMax do
      self.debuffFrame[unit][i]:SetAlpha(1)
   end
end

function Auras:Reset(unit)   
   -- hide buff frame
	self.buffFrame[unit]:SetAlpha(0)
	
	for i=1, 40 do
      self.buffFrame[unit][i].texture:SetTexture()
      self.buffFrame[unit][i]:SetAlpha(0)
   end
   
   -- hide debuff frame
	self.buffFrame[unit]:SetAlpha(0)
	
	for i=1, 40 do
      self.debuffFrame[unit][i].texture:SetTexture()
      self.debuffFrame[unit][i]:SetAlpha(0)
   end
end

function Auras:Test(unit)   
   -- test buff frame
   for i=1, Gladius.db.aurasBuffsMax do
      self.buffFrame[unit][i].texture:SetTexture(GetSpellTexture("Power Word: Fortitude"))
   end
   
   -- test debuff frame
   for i=1, Gladius.db.aurasDebuffsMax do
      self.debuffFrame[unit][i].texture:SetTexture(GetSpellTexture("Shadow Word: Pain"))
   end
end

function Auras:GetOptions()
   Gladius.db.aurasFrameAuras = Gladius.db.aurasFrameAuras or self:GetAuraList()
   
   local options = {
      buffs = {  
         type="group",
         name=L["Buffs"],
         childGroups="tab",
         order=1,
         args = {
            general = {  
               type="group",
               name=L["General"],
               order=1,
               args = {
                  widget = {
                     type="group",
                     name=L["Widget"],
                     desc=L["Widget settings"],  
                     inline=true,                
                     order=1,
                     args = { 
                        aurasBuffs = {
                           type="toggle",
                           name=L["Auras Buffs"],
                           desc=L["Toggle aura buffs"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasBuffsGrow = {
                           type="select",
                           name=L["Auras Column Grow"],
                           desc=L["Grow direction of the auras"],
                           values=function() return {
                              ["UPLEFT"] = L["Up Left"],
                              ["UPRIGHT"] = L["Up Right"],
                              ["DOWNLEFT"] = L["Down Left"],
                              ["DOWNRIGHT"] = L["Down Right"],
                           }
                           end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        }, 
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },                        
                        aurasBuffsPerColumn = {
                           type="range",
                           name=L["Aura Icons Per Column"],
                           desc=L["Number of aura icons per column"],
                           min=1, max=50, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasBuffsMax = {
                           type="range",
                           name=L["Aura Icons Max"],
                           desc=L["Number of max buffs"],
                           min=1, max=40, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=20,
                        },  
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=23,
                        },   
                        aurasBuffsGloss = {
                           type="toggle",
                           name=L["Auras Gloss"],
                           desc=L["Toggle gloss on the auras icon"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           hidden=function() return not Gladius.db.advancedOptions end,
                           order=25,
                        },
                        aurasBuffsGlossColor = {
                           type="color",
                           name=L["Auras Gloss Color"],
                           desc=L["Color of the auras icon gloss"],
                           get=function(info) return Gladius:GetColorOption(info) end,
                           set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                           hasAlpha=true,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           hidden=function() return not Gladius.db.advancedOptions end,
                           order=30,
                        },
                     },
                  },
                  size = {
                     type="group",
                     name=L["Size"],
                     desc=L["Size settings"],  
                     inline=true,                
                     order=2,
                     args = {
                        aurasBuffsWidth = {
                           type="range",
                           name=L["Aura Icon Width"],
                           desc=L["Width of the aura icons"],
                           min=10, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasBuffsHeight = {
                           type="range",
                           name=L["Aura Icon Height"],
                           desc=L["Height of the aura icon"],
                           min=10, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        },   
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },
                        aurasBuffsSpacingY = {
                           type="range",
                           name=L["Auras Spacing Vertical"],
                           desc=L["Vertical spacing of the auras"],
                           min=0, max=30, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasBuffsSpacingX = {
                           type="range",
                           name=L["Auras Spacing Horizontal"],
                           desc=L["Horizontal spacing of the auras"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           min=0, max=30, step=1,
                           order=20,
                        },             
                     },
                  },
                  position = {
                     type="group",
                     name=L["Position"],
                     desc=L["Position settings"],  
                     inline=true,                
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=3,
                     args = {
                        aurasBuffsAttachTo = {
                           type="select",
                           name=L["Auras Attach To"],
                           desc=L["Attach auras to the given frame"],
                           values=function() return Gladius:GetModules(self.name) end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           width="double",
                           order=5,
                        },
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=7,
                        },
                        aurasBuffsAnchor = {
                           type="select",
                           name=L["Auras Anchor"],
                           desc=L["Anchor of the auras"],
                           values=function() return Gladius:GetPositions() end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        },
                        aurasBuffsRelativePoint = {
                           type="select",
                           name=L["Auras Relative Point"],
                           desc=L["Relative point of the auras"],
                           values=function() return Gladius:GetPositions() end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,               
                        },
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=17,
                        },
                        aurasBuffsOffsetX = {
                           type="range",
                           name=L["Auras Offset X"],
                           desc=L["X offset of the auras"],
                           min=-100, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=20,
                        },
                        aurasBuffsOffsetY = {
                           type="range",
                           name=L["Auras Offset Y"],
                           desc=L["Y  offset of the auras"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           min=-50, max=50, step=1,
                           order=25,
                        },
                     },
                  },
               },
            },
            --[[filter = {  
               type="group",
               name=L["Filter"],
               childGroups="tree",
               hidden=function() return not Gladius.db.advancedOptions end,
               order=2,
               args = {
                  whitelist = {  
                     type="group",
                     name=L["Whitelist"],
                     order=1,
                     args = {
                     },
                  },
                  blacklist = {  
                     type="group",
                     name=L["Blacklist"],
                     order=2,
                     args = {
                     },
                  },
                  filterFunction = {  
                     type="group",
                     name=L["Filter Function"],
                     order=3,
                     args = {
                     },
                  },
               },
            },]]
         },
      },
      debuffs = {  
         type="group",
         name=L["Debuffs"],
         childGroups="tab",
         order=2,
         args = {
            general = {  
               type="group",
               name=L["General"],
               order=1,
               args = {
                  widget = {
                     type="group",
                     name=L["Widget"],
                     desc=L["Widget settings"],  
                     inline=true,                
                     order=1,
                     args = { 
                        aurasDebuffs = {
                           type="toggle",
                           name=L["Auras Debuffs"],
                           desc=L["Toggle aura debuffs"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasDebuffsGrow = {
                           type="select",
                           name=L["Auras Column Grow"],
                           desc=L["Grow direction of the auras"],
                           values=function() return {
                              ["UPLEFT"] = L["Up Left"],
                              ["UPRIGHT"] = L["Up Right"],
                              ["DOWNLEFT"] = L["Down Left"],
                              ["DOWNRIGHT"] = L["Down Right"],
                           }
                           end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        }, 
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },                        
                        aurasDebuffsPerColumn = {
                           type="range",
                           name=L["Aura Icons Per Column"],
                           desc=L["Number of aura icons per column"],
                           min=1, max=50, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasDebuffsMax = {
                           type="range",
                           name=L["Aura Icons Max"],
                           desc=L["Number of max Debuffs"],
                           min=1, max=40, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=20,
                        },  
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=23,
                        },   
                        aurasDebuffsGloss = {
                           type="toggle",
                           name=L["Auras Gloss"],
                           desc=L["Toggle gloss on the auras icon"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           hidden=function() return not Gladius.db.advancedOptions end,
                           order=25,
                        },
                        aurasDebuffsGlossColor = {
                           type="color",
                           name=L["Auras Gloss Color"],
                           desc=L["Color of the auras icon gloss"],
                           get=function(info) return Gladius:GetColorOption(info) end,
                           set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                           hasAlpha=true,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           hidden=function() return not Gladius.db.advancedOptions end,
                           order=30,
                        },
                     },
                  },
                  size = {
                     type="group",
                     name=L["Size"],
                     desc=L["Size settings"],  
                     inline=true,                
                     order=2,
                     args = {
                        aurasDebuffsWidth = {
                           type="range",
                           name=L["Aura Icon Width"],
                           desc=L["Width of the aura icons"],
                           min=10, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasDebuffsHeight = {
                           type="range",
                           name=L["Aura Icon Height"],
                           desc=L["Height of the aura icon"],
                           min=10, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        },   
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },
                        aurasDebuffsSpacingY = {
                           type="range",
                           name=L["Auras Spacing Vertical"],
                           desc=L["Vertical spacing of the auras"],
                           min=0, max=30, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasDebuffsSpacingX = {
                           type="range",
                           name=L["Auras Spacing Horizontal"],
                           desc=L["Horizontal spacing of the auras"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           min=0, max=30, step=1,
                           order=20,
                        },             
                     },
                  },
                  position = {
                     type="group",
                     name=L["Position"],
                     desc=L["Position settings"],  
                     inline=true,                
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=3,
                     args = {
                        aurasDebuffsAttachTo = {
                           type="select",
                           name=L["Auras Attach To"],
                           desc=L["Attach auras to the given frame"],
                           values=function() return Gladius:GetModules(self.name) end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           width="double",
                           order=5,
                        },
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=7,
                        },
                        aurasDebuffsAnchor = {
                           type="select",
                           name=L["Auras Anchor"],
                           desc=L["Anchor of the auras"],
                           values=function() return Gladius:GetPositions() end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=10,
                        },
                        aurasDebuffsRelativePoint = {
                           type="select",
                           name=L["Auras Relative Point"],
                           desc=L["Relative point of the auras"],
                           values=function() return Gladius:GetPositions() end,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=15,               
                        },
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=17,
                        },
                        aurasDebuffsOffsetX = {
                           type="range",
                           name=L["Auras Offset X"],
                           desc=L["X offset of the auras"],
                           min=-100, max=100, step=1,
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           order=20,
                        },
                        aurasDebuffsOffsetY = {
                           type="range",
                           name=L["Auras Offset Y"],
                           desc=L["Y  offset of the auras"],
                           disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                           min=-50, max=50, step=1,
                           order=25,
                        },
                     },
                  },
               },
            },
            --[[filter = {  
               type="group",
               name=L["Filter"],
               childGroups="tree",
               hidden=function() return not Gladius.db.advancedOptions end,
               order=2,
               args = {
                  whitelist = {  
                     type="group",
                     name=L["Whitelist"],
                     order=1,
                     args = {
                     },
                  },
                  blacklist = {  
                     type="group",
                     name=L["Blacklist"],
                     order=2,
                     args = {
                     },
                  },
                  filterFunction = {  
                     type="group",
                     name=L["Filter Function"],
                     order=3,
                     args = {
                     },
                  },
               },
            },]]
         },
      },      
      auraList = {  
         type="group",
         name=L["Auras"],
         childGroups="tree",
         order=3,
         args = {      
            newAura = {
               type = "group",
               name = L["New Aura"],
               desc = L["New Aura"],
               inline=true,
               order = 1,
               args = {
                  name = {
                     type = "input",
                     name = L["Name"],
                     desc = L["Name of the aura"],
                     get=function() return Auras.newAuraName or "" end,
                     set=function(info, value) Auras.newAuraName = value end,
                     order=1,
                  },
                  priority = {
                     type= "range",
                     name = L["Priority"],
                     desc = L["Select what priority the aura should have - higher equals more priority"],
                     get=function() return Auras.newAuraPriority or "" end,
                     set=function(info, value) Auras.newAuraPriority = value end,
                     min=0,
                     max=5,
                     step=1,
                     order=2,
                  },
                  add = {
                     type = "execute",
                     name = L["Add new Aura"],
                     func = function(info)
                        Gladius.dbi.profile.aurasFrameAuras[Auras.newAuraName] = Auras.newAuraPriority 
                        Gladius.options.args[self.name].args.auraList.args[Auras.newAuraName] = Auras:SetupAura(Auras.newAuraName, Auras.newAuraPriority)
                     end,
                     order=3,
                  },
               },
            },
         },
      },
   }
   
   -- set auras
   if (not Gladius.db.aurasFrameAuras) then
      Gladius.db.aurasFrameAuras = self:GetAuraList()
   end
  
   for aura, priority in pairs(Gladius.db.aurasFrameAuras) do
      options.auraList.args[aura] = self:SetupAura(aura, priority)
   end
   
   return options
end

local function setAura(info, value)
	if (info[#(info)] == "name") then   
      -- create new aura
      Gladius.options.args["ClassIcon"].args.auraList.args[value] = ClassIcon:SetupAura(value, Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]])
		Gladius.dbi.profile.aurasFrameAuras[value] = Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]]
		
		-- delete old aura
		Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = nil 
		Gladius.options.args["ClassIcon"].args.auraList.args = {}
		
		for aura, priority in pairs(Gladius.dbi.profile.aurasFrameAuras) do
         Gladius.options.args["ClassIcon"].args.auraList.args[aura] = ClassIcon:SetupAura(aura, priority)
      end
   else
      Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = value
	end
end

local function getAura(info)
   if (info[#(info)] == "name") then
      return info[#(info) - 1]
   else      
      return Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]]
   end
end

function Auras:SetupAura(aura, priority)
   return {
      type = "group",
      name = aura,
      desc = aura,
      get = getAura,
      set = setAura,
      args = {
         name = {
            type = "input",
            name = L["Name"],
            desc = L["Name of the aura"],
            order=1,
         },
         priority = {
            type= "range",
            name = L["Priority"],
            desc = L["Select what priority the aura should have - higher equals more priority"],
            min=0,
            max=5,
            step=1,
            order=2,
         },
         delete = {
            type = "execute",
            name = L["Delete"],
            func = function(info)
               Gladius.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = nil 
               
               local newAura = Gladius.options.args["Auras"].args.auraList.args.newAura
               Gladius.options.args["Auras"].args.auraList.args = {
                  newAura = newAura,
               }
               
               for aura, priority in pairs(Gladius.dbi.profile.aurasFrameAuras) do
                  Gladius.options.args["Auras"].args.auraList.args[aura] = self:SetupAura(aura, priority)
               end
            end,
            order=3,
         },
      },
   }
end

function Auras:GetAuraList()
	return {
		-- Spell Name			Priority (higher = more priority)
		-- Crowd control
		[GetSpellInfo(33786)] 	= 3, 	-- Cyclone
		[GetSpellInfo(2637)] 	= 3,	-- Hibernate
		[GetSpellInfo(3355)] 	= 3, 	-- Freezing Trap Effect
		[GetSpellInfo(60210) or ""]	= 3,	-- Freezing arrow effect
		[GetSpellInfo(6770)]	= 3, 	-- Sap
		[GetSpellInfo(2094)]	= 3, 	-- Blind
		[GetSpellInfo(5782)]	= 3, 	-- Fear
		[GetSpellInfo(6789)]	= 3,	-- Death Coil Warlock
		[GetSpellInfo(6358)] 	= 3, 	-- Seduction
		[GetSpellInfo(5484)] 	= 3, 	-- Howl of Terror
		[GetSpellInfo(5246)] 	= 3, 	-- Intimidating Shout
		[GetSpellInfo(8122)] 	= 3,	-- Psychic Scream
		[GetSpellInfo(118)] 	= 3,	-- Polymorph
		[GetSpellInfo(28272)] 	= 3,	-- Polymorph pig
		[GetSpellInfo(28271)] 	= 3,	-- Polymorph turtle
		[GetSpellInfo(61305)] 	= 3,	-- Polymorph black cat
		[GetSpellInfo(61025)] 	= 3,	-- Polymorph serpent
		[GetSpellInfo(51514)]	= 3,	-- Hex
		[GetSpellInfo(710)]	= 3,	-- Banish
		
		-- Roots
		[GetSpellInfo(338) or ""] 	= 3, 	-- Entangling Roots
		[GetSpellInfo(112) or ""]	= 3,	-- Frost Nova
		[GetSpellInfo(16979)] 	= 3, 	-- Feral Charge
		[GetSpellInfo(13809)] 	= 1, 	-- Frost Trap
		
		-- Stuns and incapacitates
		[GetSpellInfo(5211)] 	= 3, 	-- Bash
		[GetSpellInfo(1833)] 	= 3,	-- Cheap Shot
		[GetSpellInfo(408)] 	= 3, 	-- Kidney Shot
		[GetSpellInfo(1776)]	= 3, 	-- Gouge
		[GetSpellInfo(44572)]	= 3, 	-- Deep Freeze
		[GetSpellInfo(49012) or ""]	= 3, 	-- Wyvern Sting
		[GetSpellInfo(19503)] 	= 3, 	-- Scatter Shot
		[GetSpellInfo(9005)]	= 3, 	-- Pounce
		[GetSpellInfo(49802) or ""]	= 3, 	-- Maim
		[GetSpellInfo(853)]	= 3, 	-- Hammer of Justice
		[GetSpellInfo(20066)] 	= 3, 	-- Repentance
		[GetSpellInfo(46968)] 	= 3, 	-- Shockwave
		[GetSpellInfo(49203)] 	= 3,	-- Hungering Cold
		[GetSpellInfo(47481)]	= 3,	-- Gnaw (dk pet stun)
		
		-- Silences
		[GetSpellInfo(18469)] 	= 1,	-- Improved Counterspell
		[GetSpellInfo(15487)] 	= 1, 	-- Silence
		[GetSpellInfo(34490)] 	= 1, 	-- Silencing Shot	
		[GetSpellInfo(18425)]	= 1,	-- Improved Kick
		[GetSpellInfo(49916) or ""]	= 1,	-- Strangulate
		
		-- Disarms
		[GetSpellInfo(676)] 	= 1, 	-- Disarm
		[GetSpellInfo(51722)] 	= 1,	-- Dismantle
		[GetSpellInfo(53359)] 	= 1,	-- Chimera Shot - Scorpid	
				
		-- Buffs
		[GetSpellInfo(10278) or GetSpellInfo(1022)] 	= 1,	-- Hand of Protection
		[GetSpellInfo(1044)] 	= 1, 	-- Blessing of Freedom
		[GetSpellInfo(2825)] 	= 1, 	-- Bloodlust
		[GetSpellInfo(32182)] 	= 1, 	-- Heroism
		[GetSpellInfo(33206)] 	= 1, 	-- Pain Suppression
		[GetSpellInfo(29166)] 	= 1,	-- Innervate
		[GetSpellInfo(18708)]  	= 1,	-- Fel Domination
		[GetSpellInfo(54428)]	= 1,	-- Divine Plea
		[GetSpellInfo(31821)]	= 1,	-- Aura mastery
		
		-- Turtling abilities
		[GetSpellInfo(871)]		= 1,	-- Shield Wall
		[GetSpellInfo(48707)]	= 1,	-- Anti-Magic Shell
		[GetSpellInfo(31224)]	= 1,	-- Cloak of Shadows
		[GetSpellInfo(19263)]	= 1,	-- Deterrence
		
		-- Immunities
		[GetSpellInfo(34692)] 	= 2, 	-- The Beast Within
		[GetSpellInfo(45438)] 	= 2, 	-- Ice Block
		[GetSpellInfo(642)] 	= 2,	-- Divine Shield
	}
end