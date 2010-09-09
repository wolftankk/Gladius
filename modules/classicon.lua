local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Class Icon"))
end
local L = Gladius.L
local LSM

local ClassIcon = Gladius:NewModule("ClassIcon", "AceEvent-3.0")
Gladius:SetModule(ClassIcon, "ClassIcon", false, {
   classIconAttachTo = "Frame",
   classIconPosition = "LEFT",
   classIconAnchor = "TOP",
   classIconAdjustHeight = true,
   classIconHeight = 40,
   classIconAdjustWidth = true,
   classIconWidth = 40,
   classIconOffsetX = 0,
   classIconOffsetY = 0,
   classIconFrameLevel = 2,
   
   classIconFrameAuras = nil,
})

function ClassIcon:OnEnable()   
   self:RegisterEvent("UNIT_AURA")
   
   LSM = Gladius.LSM   
   
   if (not self.frame) then
      self.frame = {}
   end
   
   -- set auras
   if (not Gladius.db.classIconFrameAuras) then
      Gladius.db.classIconFrameAuras = self:GetAuraList()
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
   self:UpdateAura(unit)
end

function ClassIcon:UpdateAura(unit)  
   if (not self.frame[unit]) then return end
   
   -- set auras
   if (not Gladius.db.classIconFrameAuras) then
      Gladius.db.classIconFrameAuras = self:GetAuraList()
   end
   
   local aura   
   local index = 1
   
   -- debuffs
   while (true) do
      local name, _, icon, _, _, _, duration, _, _ = UnitAura(unit, index, "HARMFUL")
      if (not name) then break end  
      
      if (Gladius.db.classIconFrameAuras[name] and Gladius.db.classIconFrameAuras[name] >= self.frame[unit].priority) then
         aura = name         
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration - GetTime()
         self.frame[unit].priority = Gladius.db.classIconFrameAuras[name]
      end
      
      index = index + 1     
   end
   
   -- buffs
   index = 1
   
   while (true) do
      local name, _, icon, _, _, _, duration, _, _ = UnitAura(unit, index, "HELPFUL")
      if (not name) then break end  
      
      if (Gladius.db.classIconFrameAuras[name] and Gladius.db.classIconFrameAuras[name] >= self.frame[unit].priority) then
         aura = name
         
         self.frame[unit].icon = icon
         self.frame[unit].timeleft = duration - GetTime()
         self.frame[unit].priority = Gladius.db.classIconFrameAuras[name]
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
         self.frame[unit]:SetWidth(Gladius.buttons[unit].height)   
         self.frame[unit]:SetHeight(Gladius.buttons[unit].height)   
      else
         self.frame[unit]:SetWidth(Gladius.buttons[unit].frameHeight)   
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
      
      if (Gladius.db.classIconPosition == "LEFT") then
         left = -self.frame[unit]:GetWidth()
      else
         right = -self.frame[unit]:GetWidth()
      end
      
      -- search for an attached frame
      for _, module in pairs(Gladius.modules) do
         if (module:GetAttachTo() == self.name and module.frame[unit]) then
            local attachedPoint = module.frame[unit]:GetPoint()
            
            if (Gladius.db.classIconPosition == "LEFT" and (not attachedPoint or (attachedPoint and attachedPoint:find("RIGHT")))) then
               left = left - module.frame[unit]:GetWidth()
            elseif (Gladius.db.classIconPosition == "RIGHT" and (not attachedPoint or (attachedPoint and attachedPoint:find("LEFT")))) then
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

local function setAura(info, value)
	if (info[#(info)] == "name") then   
      -- create new aura
      Gladius.options.args["ClassIcon"].args.auraList.args[value] = ClassIcon:SetupAura(value, Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]])
		Gladius.dbi.profile.classIconFrameAuras[value] = Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]]
		
		-- delete old aura
		Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]] = nil 
		Gladius.options.args["ClassIcon"].args.auraList.args = {}
		
		for aura, priority in pairs(Gladius.dbi.profile.classIconFrameAuras) do
         Gladius.options.args["ClassIcon"].args.auraList.args[aura] = ClassIcon:SetupAura(aura, priority)
      end
   else
      Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]] = value
	end
end

local function getAura(info)
   if (info[#(info)] == "name") then
      return info[#(info) - 1]
   else      
      return Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]]
   end
end

function ClassIcon:GetOptions()
   local options = {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {
            classIconAttachTo = {
               type="select",
               name=L["Class icon attach to"],
               desc=L["Attach class icon to given frame"],
               values=function() return Gladius:GetModules(self.name) end,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=0,
            },
            classIconPosition = {
               type="select",
               name=L["Class icon position"],
               desc=L["Position of the class icon"],
               values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=5,
            },
            classIconAnchor = {
               type="select",
               name=L["Class icon anchor"],
               desc=L["Anchor of the class icon"],
               values={ ["TOP"] = L["TOP"], ["CENTER"] = L["CENTER"], ["BOTTOM"] = L["BOTTOM"] },
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               width="double",
               order=10,
            },
            classIconAdjustHeight = {
               type="toggle",
               name=L["Class Icon adjust height"],
               desc=L["Adjust class icon height to the frame height"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=15,
            },
            classIconHeight = {
               type="range",
               name=L["Class icon height"],
               desc=L["Height of the class icon"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.classIconAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=20,
            },
            classIconAdjustWidth = {
               type="toggle",
               name=L["Class Icon adjust width"],
               desc=L["Adjust class icon width to the frame width"],
               disabled=function() return Gladius.dbi.profile.classIconAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=25,
            },
            classIconWidth = {
               type="range",
               name=L["Class icon width"],
               desc=L["Width of the class icon"],
               min=10, max=100, step=1,
               disabled=function() return Gladius.dbi.profile.classIconAdjustHeight or not Gladius.dbi.profile.modules[self.name] end,
               order=30,
            },
            classIconOffsetX = {
               type="range",
               name=L["Class icon offset X"],
               desc=L["X offset of the class icon"],
               min=-100, max=100, step=1,
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               order=35,
            },
            classIconOffsetY = {
               type="range",
               name=L["Class icon offset Y"],
               desc=L["Y offset of the class icon"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=-50, max=50, step=1,
               order=40,
            },
            classIconFrameLevel = {
               type="range",
               name=L["Class icon frame level"],
               desc=L["Frame level of the class icon"],
               disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
               min=1, max=5, step=1,
               width="double",
               order=45,
            },
         },
      },
      newAura = {
         type = "group",
         name = L["New Aura"],
         desc = L["New Aura"],
         order = 2,
         args = {
            name = {
               type = "input",
               name = L["Name"],
               desc = L["Name of the aura"],
               get=function() return ClassIcon.newAuraName or "" end,
               set=function(info, value) ClassIcon.newAuraName = value end,
               order=1,
            },
            priority = {
               type= "range",
               name = L["Priority"],
               desc = L["Select what priority the aura should have - higher equals more priority"],
               get=function() return ClassIcon.newAuraPriority or "" end,
               set=function(info, value) ClassIcon.newAuraPriority = value end,
               min=0,
               max=5,
               step=1,
               order=2,
            },
            add = {
               type = "execute",
               name = L["Add new Aura"],
               func = function(info)
                  Gladius.dbi.profile.classIconFrameAuras[ClassIcon.newAuraName] = ClassIcon.newAuraPriority 
                  Gladius.options.args[self.name].args.auraList.args[ClassIcon.newAuraName] = ClassIcon:SetupAura(ClassIcon.newAuraName, ClassIcon.newAuraPriority)
               end,
               order=3,
            },
         },
      },
      auraList = {  
         type="group",
         name=L["Auras"],
         childGroups="tree",
         order=3,
         args = {            
         },
      },
   }
   
   -- set auras
   if (not Gladius.db.classIconFrameAuras) then
      Gladius.db.classIconFrameAuras = self:GetAuraList()
   end
  
   for aura, priority in pairs(Gladius.db.classIconFrameAuras) do
      options.auraList.args[aura] = self:SetupAura(aura, priority)
   end
   
   return options
end

function ClassIcon:SetupAura(aura, priority)
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
               Gladius.dbi.profile.classIconFrameAuras[info[#(info) - 1]] = nil 
               Gladius.options.args["ClassIcon"].args.auraList.args = {}
               
               for aura, priority in pairs(Gladius.dbi.profile.classIconFrameAuras) do
                  Gladius.options.args["ClassIcon"].args.auraList.args[aura] = self:SetupAura(aura, priority)
               end
            end,
            order=3,
         },
      },
   }
end

function ClassIcon:GetAuraList()
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
