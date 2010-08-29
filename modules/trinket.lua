local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Trinket"))
end
local L = Gladius.L
local LSM

local Trinket = Gladius:NewModule("Trinket", "AceEvent-3.0")
Gladius:SetModule(Trinket, "Trinket", false, {
   trinketAttachTo = "HealthBar",
   trinketPosition = "RIGHT",
   trinketAnchor = "TOP",
   trinketGridStyleIcon = false,
   trinketGridStyleIconColor = { r = 0, g = 1, b = 0, a = 1 },
   trinketAdjustHeight = true,
   trinketHeight = 80,
   trinketAdjustWidth = true,
   trinketWidth = 80,
   trinketOffsetX = 0,
   trinketOffsetY = 0,
   trinketFrameLevel = 2,
})

function Trinket:OnEnable()   
   self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
   
   LSM = Gladius.LSM   
   self.frame = {}
end

function Trinket:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:Hide()
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
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function Trinket:Test(unit)   
   -- update frame
   self:Update(unit)
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

function Trinket:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         inline=true,
         order=1,
         args = {
            trinketAttachTo = {
               type="select",
               name=L["trinketAttachTo"],
               desc=L["trinketAttachToDesc"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            trinketPosition = {
               type="select",
               name=L["trinketPosition"],
               desc=L["trinketPositionDesc"],
               values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            trinketAnchor = {
               type="select",
               name=L["trinketAnchor"],
               desc=L["trinketAnchorDesc"],
               values={ ["TOP"] = L["TOP"], ["CENTER"] = L["CENTER"], ["BOTTOM"] = L["BOTTOM"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=10,               
            },
            trinketGridStyleIcon = {
               type="toggle",
               name=L["trinketGridStyleIcon"],
               desc=L["trinketGridStyleIconDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=13,
            },
            trinketGridStyleIconColor = {
               type="color",
               name=L["trinketGridStyleIconColor"],
               desc=L["trinketGridStyleIconColorDesc"],
               hasAlpha=true,
               get=getColorOption,
               set=setColorOption,
               disabled=function() return not Gladius.dbi.profile.trinketGridStyleIcon or not Gladius.dbi.profile.modules[self.name] end,
               order=14,
            },            
            trinketAdjustHeight = {
               type="toggle",
               name=L["trinketAdjustHeight"],
               desc=L["trinketAdjustHeightDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            trinketHeight = {
               type="range",
               name=L["trinketHeight"],
               desc=L["trinketHeightDesc"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.trinketAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            trinketAdjustWidth = {
               type="toggle",
               name=L["trinketAdjustWidth"],
               desc=L["trinketAdjustWidthDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=21,
            },
            trinketWidth = {
               type="range",
               name=L["trinketWidth"],
               desc=L["trinketWidthDesc"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.trinketAdjustHeight or Gladius.dbi.profile.trinketAdjustWidth or not Gladius.dbi.profile.modules[self.name] end,
               order=22,
            },
            trinketOffsetX = {
               type="range",
               name=L["trinketOffsetX"],
               desc=L["trinketOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            trinketOffsetY = {
               type="range",
               name=L["trinketOffsetY"],
               desc=L["trinketOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-50, max=50, step=1,
               order=30,
            },
            trinketFrameLevel = {
               type="range",
               name=L["trinketFrameLevel"],
               desc=L["trinketFrameLevelDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=1, max=5, step=1,
               width="double",
               order=35,
            },
         },
      },
   }
end
