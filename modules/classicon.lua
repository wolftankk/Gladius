local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Class Icon"))
end
local L = Gladius.L
local LSM

local ClassIcon = Gladius:NewModule("ClassIcon", "AceEvent-3.0")
Gladius:SetModule(ClassIcon, "ClassIcon", false, {
   classIconAttachTo = "HealthBar",
   classIconPosition = "LEFT",
   classIconAnchor = "TOP",
   classIconAdjustHeight = true,
   classIconHeight = 80,
   classIconOffsetX = 0,
   classIconOffsetY = 0,
   classIconFrameLevel = 2,
})

function ClassIcon:OnEnable()   
   self:RegisterEvent("UNIT_AURA")
   
   LSM = Gladius.LSM   
   self.frame = {}
   
   self.auras = self:GetAuraList()
end

function ClassIcon:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:Hide()
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
   self:UpdateAura(unit)
end

function ClassIcon:UpdateAura(unit)  
   if (not self.frame[unit]) then return end

   local aura   
   local index = 1
   
   -- debuffs
   while (true) do
      local name, _, icon, _, _, duration, _, _, _ = UnitAura(unit, index, "HARMFUL")
      if (not name) then break end  
      
      if (self.auras[name] and (not self.frame[unit].priority or (self.frame[unit].priority and self.auras[name] > self.frame[unit].priority))) then
         aura = name         
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration
         self.frame[unit].priority = self.auras[name]
      end
      
      index = index + 1     
   end
   
   -- buffs
   index = 1
   
   while (true) do
      local name, _, icon, _, _, duration, _, _, _ = UnitAura(unit, index, "HELPFUL")
      if (not name) then break end  
      
      if (self.auras[name] and (not self.frame[unit].priority or (self.frame[unit].priority and self.auras[name] > self.frame[unit].priority))) then
         aura = name
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration
         self.frame[unit].priority = self.auras[name]
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
      self.frame[unit].priority = nil 
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
   -- zoom the class icon
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
   self.frame[unit]:SetNormalTexture("")
   self.frame[unit].texture = _G[self.frame[unit]:GetName().."Icon"]
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
   local point = Gladius.db.classIconPosition == "LEFT" and "RIGHT" or "LEFT" 
   local relativePoint = Gladius.db.classIconPosition
   
   if (Gladius.db.classIconAnchor ~= "CENTER") then
       -- switch anchor on growup
      local anchor = Gladius.db.classIconAnchor      
      point, relativePoint = anchor .. point, anchor .. relativePoint
   end
	
   self.frame[unit]:SetPoint(point, parent, relativePoint, Gladius.db.classIconOffsetX, Gladius.db.classIconOffsetY)
   
   if (Gladius.db.classIconAdjustHeight) then
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
      self.frame[unit]:SetWidth(Gladius.db.classIconHeight)   
      self.frame[unit]:SetHeight(Gladius.db.classIconHeight)  
   end  
   
   self.frame[unit].texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   
   -- hide
   self.frame[unit]:SetAlpha(0)
end

function ClassIcon:Show(unit)
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
   
   local left, right, top, bottom = unpack(CLASS_BUTTONS[class])
   -- zoom the class icon
   left = left + (right - left) * 0.07
   right = right - (right - left) * 0.07
   
   top = top + (bottom - top) * 0.07
   bottom = bottom - (bottom - top) * 0.07
   
   self.frame[unit].texture:SetTexCoord(left, right, top, bottom)
end

function ClassIcon:Reset(unit)
   -- reset frame
   self.frame[unit].active = false
   self.frame[unit].aura = nil
   self.frame[unit].priority = nil
   
   self.frame[unit]:SetScript("OnUpdate", nil)
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function ClassIcon:Test(unit)   
   -- update frame
   self:Update(unit)
   
   -- set test values   
   self:UpdateAura(unit)
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

function ClassIcon:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         inline=true,
         order=1,
         args = {
            classIconAttachTo = {
               type="select",
               name=L["classIconAttachTo"],
               desc=L["classIconAttachToDesc"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            classIconPosition = {
               type="select",
               name=L["classIconPosition"],
               desc=L["classIconPositionDesc"],
               values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            classIconAnchor = {
               type="select",
               name=L["classIconAnchor"],
               desc=L["classIconAnchorDesc"],
               values={ ["TOP"] = L["TOP"], ["CENTER"] = L["CENTER"], ["BOTTOM"] = L["BOTTOM"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=10,
            },
            classIconAdjustHeight = {
               type="toggle",
               name=L["classIconAdjustHeight"],
               desc=L["classIconAdjustHeightDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            classIconHeight = {
               type="range",
               name=L["classIconHeight"],
               desc=L["classIconHeightDesc"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.classIconAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            classIconOffsetX = {
               type="range",
               name=L["classIconOffsetX"],
               desc=L["classIconOffsetXDesc"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            classIconOffsetY = {
               type="range",
               name=L["classIconOffsetY"],
               desc=L["classIconOffsetYDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-50, max=50, step=1,
               order=30,
            },
            classIconFrameLevel = {
               type="range",
               name=L["classIconFrameLevel"],
               desc=L["classIconFrameLevelDesc"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=1, max=5, step=1,
               width="double",
               order=35,
            },
         },
      },
   }
end

function ClassIcon:GetAuraList()
	return {
		-- Spell Name			Priority (higher = more priority)
		-- Crowd control
		[GetSpellInfo(33786)] 	= 3, 	-- Cyclone
		[GetSpellInfo(18658)] 	= 3,	-- Hibernate
		[GetSpellInfo(14309)] 	= 3, 	-- Freezing Trap Effect
		[GetSpellInfo(60210)]	= 3,	-- Freezing arrow effect
		[GetSpellInfo(6770)]	= 3, 	-- Sap
		[GetSpellInfo(2094)]	= 3, 	-- Blind
		[GetSpellInfo(5782)]	= 3, 	-- Fear
		[GetSpellInfo(47860)]	= 3,	-- Death Coil Warlock
		[GetSpellInfo(6358)] 	= 3, 	-- Seduction
		[GetSpellInfo(5484)] 	= 3, 	-- Howl of Terror
		[GetSpellInfo(5246)] 	= 3, 	-- Intimidating Shout
		[GetSpellInfo(8122)] 	= 3,	-- Psychic Scream
		[GetSpellInfo(12826)] 	= 3,	-- Polymorph
		[GetSpellInfo(28272)] 	= 3,	-- Polymorph pig
		[GetSpellInfo(28271)] 	= 3,	-- Polymorph turtle
		[GetSpellInfo(61305)] 	= 3,	-- Polymorph black cat
		[GetSpellInfo(61025)] 	= 3,	-- Polymorph serpent
		[GetSpellInfo(51514)]	= 3,	-- Hex
		[GetSpellInfo(18647)]	= 3,	-- Banish
		
		-- Roots
		[GetSpellInfo(53308)] 	= 3, 	-- Entangling Roots
		[GetSpellInfo(42917)]	= 3,	-- Frost Nova
		[GetSpellInfo(16979)] 	= 3, 	-- Feral Charge
		[GetSpellInfo(13809)] 	= 1, 	-- Frost Trap
		
		-- Stuns and incapacitates
		[GetSpellInfo(8983)] 	= 3, 	-- Bash
		[GetSpellInfo(1833)] 	= 3,	-- Cheap Shot
		[GetSpellInfo(8643)] 	= 3, 	-- Kidney Shot
		[GetSpellInfo(1776)]	= 3, 	-- Gouge
		[GetSpellInfo(44572)]	= 3, 	-- Deep Freeze
		[GetSpellInfo(49012)]	= 3, 	-- Wyvern Sting
		[GetSpellInfo(19503)] 	= 3, 	-- Scatter Shot
		[GetSpellInfo(49803)]	= 3, 	-- Pounce
		[GetSpellInfo(49802)]	= 3, 	-- Maim
		[GetSpellInfo(10308)]	= 3, 	-- Hammer of Justice
		[GetSpellInfo(20066)] 	= 3, 	-- Repentance
		[GetSpellInfo(46968)] 	= 3, 	-- Shockwave
		[GetSpellInfo(49203)] 	= 3,	-- Hungering Cold
		[GetSpellInfo(47481)]	= 3,	-- Gnaw (dk pet stun)
		
		-- Silences
		[GetSpellInfo(18469)] 	= 1,	-- Improved Counterspell
		[GetSpellInfo(15487)] 	= 1, 	-- Silence
		[GetSpellInfo(34490)] 	= 1, 	-- Silencing Shot	
		[GetSpellInfo(18425)]	= 1,	-- Improved Kick
		[GetSpellInfo(49916)]	= 1,	-- Strangulate
		
		-- Disarms
		[GetSpellInfo(676)] 	= 1, 	-- Disarm
		[GetSpellInfo(51722)] 	= 1,	-- Dismantle
		[GetSpellInfo(53359)] 	= 1,	-- Chimera Shot - Scorpid	
				
		-- Buffs
		[GetSpellInfo(1022)] 	= 1,	-- Blessing of Protection
		[GetSpellInfo(10278)] 	= 1,	-- Hand of Protection
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
