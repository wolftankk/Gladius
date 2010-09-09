local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Trinket"))
end
local L = Gladius.L
local LSM

local Trinket = Gladius:NewModule("Trinket", "AceEvent-3.0")
Gladius:SetModule(Trinket, "Trinket", false, {
   trinketAttachTo = "Frame",
   trinketPosition = "RIGHT",
   trinketAnchor = "TOP",
   trinketGridStyleIcon = false,
   trinketGridStyleIconColor = { r = 0, g = 1, b = 0, a = 1 },
   trinketAdjustHeight = true,
   trinketHeight = 52,
   trinketAdjustWidth = true,
   trinketWidth = 52,
   trinketOffsetX = 0,
   trinketOffsetY = 0,
   trinketFrameLevel = 2,
})

function Trinket:OnEnable()   
   self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
   
   LSM = Gladius.LSM   
   
   if (not self.frame) then
      self.frame = {}
   end
end

function Trinket:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function Trinket:GetAttachTo()
   return Gladius.db.trinketAttachTo
end

function Trinket:GetFrame(unit)
   return self.frame[unit]
end

function Trinket:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank)
   if (not unit:find("arena") or unit:find("pet")) then return end
   
   -- pvp trinket
   if (spell == GetSpellInfo(59752) or spell == GetSpellInfo(42292)) then
      self:UpdateTrinket(unit, 120)
   end

   -- wotf
   if (spell == GetSpellInfo(7744)) then	
      self:UpdateTrinket(unit, 45)
   end
end

function Trinket:UpdateTrinket(unit, duration)
   if (Gladius.db.trinketGridStyleIcon) then
      self.frame[unit]:SetAlpha(0)
      
      self.frame[unit].timeleft = duration
      self.frame[unit]:SetScript("OnUpdate", function(f, elapsed)
         self.frame[unit].timeleft = self.frame[unit].timeleft - elapsed
         if (self.frame[unit].timeleft <= 0) then
            self.frame[unit]:SetAlpha(1)
         end
      end)
   else
      self.frame[unit].cooldown:SetCooldown(GetTime(), duration)
   end
end

function Trinket:CreateFrame(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create frame
   self.frame[unit] = CreateFrame("CheckButton", "Gladius" .. self.name .. "Frame" .. unit, button, "ActionButtonTemplate")
   self.frame[unit]:EnableMouse(false)
   self.frame[unit]:SetNormalTexture("")
   self.frame[unit].texture = _G[self.frame[unit]:GetName().."Icon"]
   self.frame[unit].cooldown = _G[self.frame[unit]:GetName().."Cooldown"]
   self.frame[unit].cooldown:SetReverse(false)
end

function Trinket:Update(unit)   
   -- create frame
   if (not self.frame[unit]) then 
      self:CreateFrame(unit)
   end
   
   -- update frame   
   self.frame[unit]:ClearAllPoints()
   
   -- anchor point 
   local parent = Gladius:GetParent(unit, Gladius.db.trinketAttachTo)     
   local point = Gladius.db.trinketPosition == "LEFT" and "RIGHT" or "LEFT" 
   local relativePoint = Gladius.db.trinketPosition
   
   if (Gladius.db.trinketAnchor ~= "CENTER") then
      local anchor = Gladius.db.trinketAnchor       
      point, relativePoint = anchor .. point, anchor .. relativePoint      
   end
	
   self.frame[unit]:SetPoint(point, parent, relativePoint, Gladius.db.trinketOffsetX, Gladius.db.trinketOffsetY)
   
   -- frame level
   self.frame[unit]:SetFrameLevel(Gladius.db.trinketFrameLevel)
   
   if (Gladius.db.trinketAdjustHeight) then
      if (self:GetAttachTo() == "Frame") then   
         local height = true
         for _, module in pairs(Gladius.modules) do
            if (module:GetAttachTo() == self.name) then
               height = false
            end
         end
      
         if (height) then
            self.frame[unit]:SetWidth(Gladius.buttons[unit].height)   
            self.frame[unit]:SetHeight(Gladius.buttons[unit].height)   
         else
            self.frame[unit]:SetWidth(Gladius.buttons[unit].frameHeight)   
            self.frame[unit]:SetHeight(Gladius.buttons[unit].frameHeight)   
         end
      else
         self.frame[unit]:SetWidth(Gladius:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1)   
         self.frame[unit]:SetHeight(Gladius:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1) 
      end
   else
      if (Gladius.db.trinketAdjustWidth) then
         self.frame[unit]:SetWidth(Gladius.db.trinketHeight) 
      else
         self.frame[unit]:SetWidth(Gladius.db.trinketWidth)
      end
        
      self.frame[unit]:SetHeight(Gladius.db.trinketHeight)  
   end 
   
   -- set frame mouse-interactable area
   if (self:GetAttachTo() == "Frame") then
      local left, right, top, bottom = Gladius.buttons[unit]:GetHitRectInsets()
      
      if (Gladius.db.trinketPosition == "LEFT") then
         left = -self.frame[unit]:GetWidth()
      else
         right = -self.frame[unit]:GetWidth()
      end
      
      -- search for an attached frame
      for _, module in pairs(Gladius.modules) do
         if (module:GetAttachTo() == self.name and module.frame[unit]) then
            local attachedPoint = module.frame[unit]:GetPoint()
            
            if (Gladius.db.trinketPosition == "LEFT" and (not attachedPoint or (attachedPoint and attachedPoint:find("RIGHT")))) then
               left = left - module.frame[unit]:GetWidth()
            elseif (Gladius.db.trinketPosition == "RIGHT" and (not attachedPoint or (attachedPoint and attachedPoint:find("LEFT")))) then
               right = right - module.frame[unit]:GetWidth()
            end
         end
      end

      Gladius.buttons[unit]:SetHitRectInsets(left, right, top, bottom) 
      Gladius.buttons[unit].secure:SetHitRectInsets(left, right, top, bottom) 
   end
   
   -- hide
   self.frame[unit]:SetAlpha(0)
end

function Trinket:Show(unit)
   local testing = Gladius.test
      
   -- show frame
   self.frame[unit]:SetAlpha(1)
   
   if (Gladius.db.trinketGridStyleIcon) then
      self.frame[unit].texture:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "Minimalist"))
      self.frame[unit].texture:SetVertexColor(Gladius.db.trinketGridStyleIconColor.r, Gladius.db.trinketGridStyleIconColor.g, Gladius.db.trinketGridStyleIconColor.b, Gladius.db.trinketGridStyleIconColor.a)
   else
      if (not testing) then
         if (UnitFactionGroup(unit) == "Horde") then
            trinketIcon = UnitLevel(unit) == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_38" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
         else
            trinketIcon = UnitLevel(unit) == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_37" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
         end
      else
         if (UnitFactionGroup("player") == "Horde") then
            trinketIcon = "Interface\\Icons\\INV_Jewelry_Necklace_38"
         else
            trinketIcon = "Interface\\Icons\\INV_Jewelry_Necklace_37"
         end
      end
      
      self.frame[unit].texture:SetTexture(trinketIcon)
      self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      self.frame[unit].texture:SetVertexColor(1, 1, 1, 1)
   end
end

function Trinket:Reset(unit)
   -- reset frame
   if (UnitFactionGroup("player") == "Horde") then
      trinketIcon = "Interface\\Icons\\INV_Jewelry_Necklace_38"
   else
      trinketIcon = "Interface\\Icons\\INV_Jewelry_Necklace_37"
   end
   
   self.frame[unit].texture:SetTexture(trinketIcon)
   self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
   
   self.frame[unit]:SetScript("OnUpdate", nil)
   
   -- reset cooldown
   self.frame[unit].cooldown:SetCooldown(GetTime(), 0)
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function Trinket:Test(unit)   
   -- test
end

function Trinket:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {
            trinketAttachTo = {
               type="select",
               name=L["Trinket attach to"],
               desc=L["Attach trinket to the given frame"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            trinketPosition = {
               type="select",
               name=L["Trinket position"],
               desc=L["Position of the trinket"],
               values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            trinketAnchor = {
               type="select",
               name=L["Trinket anchor"],
               desc=L["Anchor of the trinket"],
               values={ ["TOP"] = L["TOP"], ["CENTER"] = L["CENTER"], ["BOTTOM"] = L["BOTTOM"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=10,               
            },
            trinketGridStyleIcon = {
               type="toggle",
               name=L["Trinket grid style icon"],
               desc=L["Toggle trinket grid style icon"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            trinketGridStyleIconColor = {
               type="color",
               name=L["Trinket grid style icon color"],
               desc=L["Color of the trinket grid style icon"],
               hasAlpha=true,
               get=function(info) return Gladius:GetColorOption(info) end,
               set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
               disabled=function() return not Gladius.dbi.profile.trinketGridStyleIcon or not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },            
            trinketAdjustHeight = {
               type="toggle",
               name=L["Trinket adjust height"],
               desc=L["Adjust trinket height to the frame height"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            trinketHeight = {
               type="range",
               name=L["Trinket height"],
               desc=L["Height of the trinket"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.trinketAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            trinketAdjustWidth = {
               type="toggle",
               name=L["Trinket adjust width"],
               desc=L["Adjust trinket width to the frame width"],
               disabled=function() return Gladius.dbi.profile.trinketAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            trinketWidth = {
               type="range",
               name=L["Trinket width"],
               desc=L["Width of the trinket"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.trinketAdjustHeight or Gladius.dbi.profile.trinketAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=40,
            },
            trinketOffsetX = {
               type="range",
               name=L["Trinket offset X"],
               desc=L["X offset of the trinket"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=45,
            },
            trinketOffsetY = {
               type="range",
               name=L["Trinket offset Y"],
               desc=L["Y  offset of the trinket"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-50, max=50, step=1,
               order=50,
            },
            trinketFrameLevel = {
               type="range",
               name=L["Trinket frame level"],
               desc=L["Frame level of the trinket"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=1, max=5, step=1,
               width="double",
               order=55,
            },
         },
      },
   }
end
