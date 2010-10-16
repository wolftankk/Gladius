local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Class Icon"))
end
local L = Gladius.L
local LSM

local ClassIcon = Gladius:NewModule("ClassIcon", "AceEvent-3.0")
Gladius:SetModule(ClassIcon, "ClassIcon", false, true, {
   classIconAttachTo = "Frame",
   classIconAnchor = "TOPRIGHT",
   classIconRelativePoint = "TOPLEFT",
   classIconAdjustHeight = true,
   classIconHeight = 40,
   classIconAdjustWidth = true,
   classIconWidth = 40,
   classIconOffsetX = 0,
   classIconOffsetY = 0,
   classIconFrameLevel = 2,
   classIconGloss = true,
   classIconGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   classIconImportantAuras = true,
})

function ClassIcon:OnEnable()   
   self:RegisterEvent("UNIT_AURA")
   
   LSM = Gladius.LSM   
   
   if (not self.frame) then
      self.frame = {}
   end
end

function ClassIcon:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function ClassIcon:GetAttachTo()
   return Gladius.db.classIconAttachTo
end

function ClassIcon:GetFrame(unit)
   return self.frame[unit]
end

function ClassIcon:UNIT_AURA(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end   
   
   -- important auras
   self:UpdateAura(unit)
end

function ClassIcon:UpdateAura(unit)  
   if (not self.frame[unit] or not Gladius.db.classIconImportantAuras or not Gladius:GetModule("Auras"):IsEnabled()) then return end
   
   local aura   
   local index = 1
   
   -- debuffs
   while (true) do
      local name, _, icon, _, _, _, duration, _, _ = UnitAura(unit, index, "HARMFUL")
      if (not name) then break end  
      
      if (Gladius.db.aurasFrameAuras[name] and Gladius.db.aurasFrameAuras[name] >= self.frame[unit].priority) then
         aura = name         
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration - GetTime()
         self.frame[unit].priority = Gladius.db.aurasFrameAuras[name]
      end
      
      index = index + 1     
   end
   
   -- buffs
   index = 1
   
   while (true) do
      local name, _, icon, _, _, _, duration, _, _ = UnitAura(unit, index, "HELPFUL")
      if (not name) then break end  
      
      if (Gladius.db.aurasFrameAuras[name] and Gladius.db.aurasFrameAuras[name] >= self.frame[unit].priority) then
         aura = name
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration - GetTime()
         self.frame[unit].priority = Gladius.db.aurasFrameAuras[name]
      end
      
      index = index + 1     
   end
   
   if (aura and aura ~= self.frame[unit].aura) then
      -- display aura
      self.frame[unit].active = true
      self.frame[unit].aura = aura
   
      self.frame[unit].texture:SetTexture(self.frame[unit].icon)
      self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)      
      
      self.frame[unit].cooldown:SetCooldown(GetTime(), self.frame[unit].timeleft)
   elseif (not aura and self.frame[unit].active) then
      -- reset
      self.frame[unit].active = false
      self.frame[unit].aura = nil
      self.frame[unit].icon = nil
      self.frame[unit].priority = 0
      self.frame[unit].timeleft = 0     
      
      self.frame[unit].cooldown:SetCooldown(GetTime(), 0)
      self:SetClassIcon(unit)
   end
end

function ClassIcon:SetClassIcon(unit)
   if (not self.frame[unit]) then return end

   -- get unit class
   local class
   if (not Gladius.test) then
      class = select(2, UnitClass(unit))
   else
      class = Gladius.testing[unit].unitClass
   end

   self.frame[unit].texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   
   local left, right, top, bottom = unpack(CLASS_BUTTONS[class])
   -- zoom class icon
   left = left + (right - left) * 0.07
   right = right - (right - left) * 0.07
   
   top = top + (bottom - top) * 0.07
   bottom = bottom - (bottom - top) * 0.07
   
   self.frame[unit].texture:SetTexCoord(left, right, top, bottom)
end

function ClassIcon:CreateFrame(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create frame   
   self.frame[unit] = CreateFrame("CheckButton", "Gladius" .. self.name .. "Frame" .. unit, button, "ActionButtonTemplate")
   self.frame[unit]:EnableMouse(false)
   self.frame[unit]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
   self.frame[unit].texture = _G[self.frame[unit]:GetName().."Icon"]
   self.frame[unit].normalTexture = _G[self.frame[unit]:GetName().."NormalTexture"]
   self.frame[unit].cooldown = _G[self.frame[unit]:GetName().."Cooldown"]
   self.frame[unit].cooldown:SetReverse(false)
end

function ClassIcon:Update(unit)
   -- create frame
   if (not self.frame[unit]) then 
      self:CreateFrame(unit)
   end
      
   -- update frame   
   self.frame[unit]:ClearAllPoints()
    
   local parent = Gladius:GetParent(unit, Gladius.db.classIconAttachTo)     
   self.frame[unit]:SetPoint(Gladius.db.classIconAnchor, parent, Gladius.db.classIconRelativePoint, Gladius.db.classIconOffsetX, Gladius.db.classIconOffsetY)
   
   -- frame level
   self.frame[unit]:SetFrameLevel(Gladius.db.classIconFrameLevel)
   
   if (Gladius.db.classIconAdjustHeight) then
      local height = true
      for _, module in pairs(Gladius.modules) do
         if (module:GetAttachTo() == self.name) then
            height = false
         end
      end
   
      if (height) then
         if (Gladius.db.classIconAdjustWidth) then
            self.frame[unit]:SetWidth(Gladius.buttons[unit].height) 
         else
            self.frame[unit]:SetWidth(Gladius.db.classIconWidth)
         end
 
         self.frame[unit]:SetHeight(Gladius.buttons[unit].height)   
      else
         if (Gladius.db.classIconAdjustWidth) then
            self.frame[unit]:SetWidth(Gladius.buttons[unit].frameHeight) 
         else
            self.frame[unit]:SetWidth(Gladius.db.classIconWidth)
         end
 
         self.frame[unit]:SetHeight(Gladius.buttons[unit].frameHeight)   
      end 
   else
      if (Gladius.db.classIconAdjustWidth) then
         self.frame[unit]:SetWidth(Gladius.db.classIconHeight) 
      else
         self.frame[unit]:SetWidth(Gladius.db.classIconWidth)
      end
        
      self.frame[unit]:SetHeight(Gladius.db.classIconHeight)  
   end  
   
   self.frame[unit].texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   
   -- set frame mouse-interactable area
   if (self:GetAttachTo() == "Frame") then
      local left, right, top, bottom = Gladius.buttons[unit]:GetHitRectInsets()
      
      if (Gladius.db.classIconRelativePoint:find("LEFT")) then
         left = -self.frame[unit]:GetWidth()
      else
         right = -self.frame[unit]:GetWidth()
      end
      
      -- search for an attached frame
      for _, module in pairs(Gladius.modules) do
         if (module.attachTo and module:GetAttachTo() == self.name and module.frame and module.frame[unit]) then
            local attachedPoint = module.frame[unit]:GetPoint()
            
            if (Gladius.db.classIconRelativePoint:find("LEFT") and (not attachedPoint or (attachedPoint and attachedPoint:find("RIGHT")))) then
               left = left - module.frame[unit]:GetWidth()
            elseif (Gladius.db.classIconRelativePoint:find("LEFT") and (not attachedPoint or (attachedPoint and attachedPoint:find("LEFT")))) then
               right = right - module.frame[unit]:GetWidth()
            end
         end
      end
      
      -- top / bottom
      if (self.frame[unit]:GetHeight() > Gladius.buttons[unit]:GetHeight()) then
         bottom = -(self.frame[unit]:GetHeight() - Gladius.buttons[unit]:GetHeight())
      end

      Gladius.buttons[unit]:SetHitRectInsets(left, right, top, bottom) 
      Gladius.buttons[unit].secure:SetHitRectInsets(left, right, top, bottom) 
   end
   
   -- style action button   
   self.frame[unit].normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
	self.frame[unit].normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
	
	self.frame[unit].normalTexture:ClearAllPoints()
	self.frame[unit].normalTexture:SetPoint("CENTER", 0, 0)
	self.frame[unit]:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
	
	self.frame[unit].texture:ClearAllPoints()
	self.frame[unit].texture:SetPoint("TOPLEFT", self.frame[unit], "TOPLEFT")
	self.frame[unit].texture:SetPoint("BOTTOMRIGHT", self.frame[unit], "BOTTOMRIGHT")
	
	self.frame[unit].normalTexture:SetVertexColor(Gladius.db.classIconGlossColor.r, Gladius.db.classIconGlossColor.g, 
      Gladius.db.classIconGlossColor.b, Gladius.db.classIconGloss and Gladius.db.classIconGlossColor.a or 0)
   
   -- hide
   self.frame[unit]:SetAlpha(0)
end

function ClassIcon:Show(unit)
   local testing = Gladius.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)
   
   -- set class icon
   self:SetClassIcon(unit)
end

function ClassIcon:Reset(unit)
   -- reset frame
   self.frame[unit].active = false
   self.frame[unit].aura = nil
   self.frame[unit].priority = 0
   
   self.frame[unit]:SetScript("OnUpdate", nil)
   
   -- reset cooldown
   self.frame[unit].cooldown:SetCooldown(GetTime(), 0)
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function ClassIcon:Test(unit)     
   -- test
end

function ClassIcon:GetOptions()
   return {
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
                  classIconImportantAuras = {
                     type="toggle",
                     name=L["Class Icon Important Auras"],
                     desc=L["Show important auras instead of the class icon"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  classIconGloss = {
                     type="toggle",
                     name=L["Class Icon Gloss"],
                     desc=L["Toggle gloss on the class icon"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=10,
                  },
                  classIconGlossColor = {
                     type="color",
                     name=L["Class Icon Gloss Color"],
                     desc=L["Color of the class icon gloss"],
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                     hasAlpha=true,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=15,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=17,
                  },
                  classIconFrameLevel = {
                     type="range",
                     name=L["Class Icon Frame Level"],
                     desc=L["Frame level of the class icon"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     min=1, max=5, step=1,
                     width="double",
                     order=20,
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
                  classIconAdjustWidth = {
                     type="toggle",
                     name=L["Class Icon Adjust Width"],
                     desc=L["Adjust class icon width to the frame width"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  classIconAdjustHeight = {
                     type="toggle",
                     name=L["Class Icon Adjust Height"],
                     desc=L["Adjust class icon height to the frame height"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  classIconWidth = {
                     type="range",
                     name=L["Class Icon Width"],
                     desc=L["Width of the class icon"],
                     min=10, max=100, step=1,
                     disabled=function() return Gladius.dbi.profile.classIconAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  classIconHeight = {
                     type="range",
                     name=L["Class Icon Height"],
                     desc=L["Height of the class icon"],
                     min=10, max=100, step=1,
                     disabled=function() return Gladius.dbi.profile.classIconAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
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
                  classIconAttachTo = {
                     type="select",
                     name=L["Class Icon Attach To"],
                     desc=L["Attach class icon to given frame"],
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
                  classIconAnchor = {
                     type="select",
                     name=L["Class Icon Anchor"],
                     desc=L["Anchor of the class icon"],
                     values=function() return Gladius:GetPositions() end,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  classIconRelativePoint = {
                     type="select",
                     name=L["Class Icon Relative Point"],
                     desc=L["Relative point of the class icon"],
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
                  classIconOffsetX = {
                     type="range",
                     name=L["Class Icon Offset X"],
                     desc=L["X offset of the class icon"],
                     min=-100, max=100, step=1,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  classIconOffsetY = {
                     type="range",
                     name=L["Class Icon Offset Y"],
                     desc=L["Y offset of the class icon"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     min=-50, max=50, step=1,
                     order=25,
                  },
               },
            },            
         },
      },      
   }
end
