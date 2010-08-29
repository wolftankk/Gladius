Gladius = LibStub("AceAddon-3.0"):NewAddon("Gladius", "AceEvent-3.0")

local L

function Gladius:Call(handler, func, ...)
   -- save module function call
   if (type(handler[func]) == "function") then
      handler[func](handler, ...)
   end
end

function Gladius:Debug(...)
   print("Gladius:", ...)
end

function Gladius:SetModule(module, key, bar, defaults)
   if (not self.modules) then self.modules = {} end

   -- register module
   self.modules[key] = module
   module.name = key
   module.isBar = bar
   
   -- set db defaults
   self.defaults.profile.modules[key] = true
   
   for k,v in pairs(defaults) do
      self.defaults.profile[k] = v
   end
end

function Gladius:GetParent(unit, module)  
   -- get parent frame
   if (module == "Frame") then
      return self.buttons[unit]
   else
      -- get parent module frame
      local m = self:GetModule(module)
      
      -- update module, if frame doesn't exist
      local frame = m:GetFrame(unit)
      if (not frame) then
         self:Call(m, "Update", unit)
         frame = m:GetFrame(unit)
      end
      
      return frame
   end
end

function Gladius:GetModules(module)
   -- get module list for frame anchor
   local t = { ["Frame"] = L["Frame"] }
   for moduleName, m in pairs(self.modules) do
      if (moduleName ~= module and m:GetAttachTo() ~= module) then
         t[moduleName] = L[moduleName]
      end
   end
   
   return t
end

function Gladius:OnInitialize()
   -- setup db
   self.dbi = LibStub("AceDB-3.0"):New("Gladius2DB", self.defaults)
	self.dbi.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.dbi.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.dbi.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self.db = self.dbi.profile
	
	-- localization
	L = self.L
	
	-- libsharedmedia
	self.LSM = LibStub("LibSharedMedia-3.0")
	self.LSM:Register("statusbar", "Minimalist", "Interface\\Addons\\Gladius2\\images\\Minimalist")
		
	-- test environment
	self.test = false
	self.testing = setmetatable({
      ["arena1"] = { unitPowerType = 0, unitClass = "PRIEST", unitRace = "Draenei", unitSpec = "Discipline" },
      ["arena2"] = { unitPowerType = 1, unitClass = "HUNTER", unitRace = "Night Elf", unitSpec = "Marksmanship" },
      ["arena3"] = { unitPowerType = 3, unitClass = "ROGUE", unitRace = "Human", unitSpec = "Combat" },
      ["arena4"] = { unitPowerType = 6, unitClass = "DEATHKNIGHT", unitRace = "Dwarf", unitSpec = "Unholy" },
      ["arena5"] = { unitPowerType = 0, unitClass = "MAGE", unitRace = "Gnome", unitSpec = "Frost" },
	}, { 
      __index = function(t, k)
         return t["arena1"]
      end
	})
	
	-- buttons
   self.buttons = {}
end

function Gladius:OnEnable()
   -- setup options
   self:SetupOptions()

   -- register the appropriate events that fires when you enter an arena
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
		
	-- enable modules
	for moduleName, module in pairs(self.modules) do
      if (self.db.modules[moduleName]) then
         module:Enable()
      else
         module:Disable()
      end
   end
	
	-- see if we are already in arena
   if IsLoggedIn() then
		Gladius:ZONE_CHANGED_NEW_AREA()
	end
end

function Gladius:OnDisable()
   -- unregister events and disable modules
   self:UnregisterAllEvents()
   
   for _, module in pairs(self.modules) do
      module:Disable()
   end
end

function Gladius:OnProfileChanged(event, database, newProfileKey)
   -- update frame on profile change
   self.db = self.dbi.profile
   self:UpdateFrame()   
end

function Gladius:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	
	-- check if we are entering or leaving an arena 
	if (type == "arena") then
		self:JoinedArena()
	elseif (type ~= "arena" and self.instanceType == "arena") then
		self:LeftArena()
	end
	
	self.instanceType = type
end

function Gladius:JoinedArena()
   -- enemy events
	--self:RegisterEvent("UNIT_PET")

   -- special arena event
   self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")	
	self:RegisterEvent("UNIT_DIED")
	
	self:RegisterEvent("UNIT_HEALTH")	
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
		
	-- reset test
	self.test = false
	
   -- find out the current bracket size
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
		if (status == "active" and teamSize > 0) then
			self.currentBracket = teamSize
			break
		end
	end
	
	for i=1, self.currentBracket do
      self:UpdateUnit("arena" .. i)
	end
	
	self:HideFrame()
end

function Gladius:LeftArena()
   -- reset units
   for unit, _ in pairs(self.buttons) do
      self:ResetUnit(unit)
   end
   
   -- unregister combat events
   self:UnregisterAllEvents()
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

function Gladius:UNIT_NAME_UPDATE(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   self:ShowUnit(unit)
end

function Gladius:UNIT_DIED(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   self:ShowUnit(unit)
end

function Gladius:ARENA_OPPONENT_UPDATE(event, unit, type)
   -- enemy seen
   if (type == "seen" or type == "destroyed") then
      self:ShowUnit(unit)
   -- enemy stealth
   elseif (type == "unseen") then
      self:UpdateAlpha(unit, self.db.stealthAlpha)
   -- enemy left arena
   elseif (type == "cleared") then
      self:ResetUnit(unit)
   end
end

function Gladius:UpdateFrame()
   -- update units
   for unit, _ in pairs(self.buttons) do
      if (self.buttons[unit] and not self.buttons[unit]:IsVisible() and self.test) then return end
      
      -- update frame will only be called in the test environment
      self:UpdateUnit(unit)
      self:ShowUnit(unit, true)
      
      -- test environment
      if (self.test) then
         self:TestUnit(unit)
      end
   end
end

function Gladius:HideFrame()
   -- hide units
   for unit, _ in pairs(self.buttons) do
      self:ResetUnit(unit)
   end
end

function Gladius:UpdateUnit(unit)
   if (not unit:find("arena") or unit:find("pet")) then return end
   if (InCombatLockdown()) then return end
   
   -- create button 
   if (not self.buttons[unit]) then
      self:CreateButton(unit)
   end
   
   local height = 0
   local frameHeight = 0
   
   -- need to set this
   self.buttons[unit].frameHeight = 1
   
   -- update modules (bars first, because we need the height)
   for _, m in pairs(self.modules) do
      if (m:IsEnabled()) then
         -- update and get bar height
         if (m.isBar) then
            self:Call(m, "Update", unit)
                        
            local attachTo = m:GetAttachTo()
            if (attachTo == "Frame" or self.modules[attachTo].isBar) then
               frameHeight = frameHeight + m.frame[unit]:GetHeight()
            else
               height = height + m.frame[unit]:GetHeight()
            end
         end
      end
	end
	
	self.buttons[unit].height = height + frameHeight
	self.buttons[unit].frameHeight = frameHeight
	
	-- update button 
	self.buttons[unit]:SetScale(self.db.frameScale)
	self.buttons[unit]:SetWidth(self.db.barWidth)
   self.buttons[unit]:SetHeight(frameHeight)
   
   -- update modules (indicator)
   for _, m in pairs(self.modules) do
      if (m:IsEnabled() and not m.isBar) then
         self:Call(m, "Update", unit)
      end
	end
   
   -- set point
   self.buttons[unit]:ClearAllPoints()
   if (unit == "arena1" or not self.db.lockButtons) then
      if (not self.db.x[unit] and not self.db.y[unit]) then
         self.buttons[unit]:SetPoint("CENTER")
      else
         local scale = self.buttons[unit]:GetEffectiveScale()
         self.buttons[unit]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.x[unit] / scale, self.db.y[unit] / scale)
      end
   else
      local parent = string.match(unit, "^arena(.+)") - 1
      local parentButton = self.buttons["arena" .. parent] 
      if (not parentButton) then return end
      
      if (self.db.growUp) then
         self.buttons[unit]:SetPoint("BOTTOMLEFT", parentButton, "TOPLEFT", 0, self.db.bottomMargin)
      else
         self.buttons[unit]:SetPoint("TOPLEFT", parentButton, "BOTTOMLEFT", 0, -self.db.bottomMargin)
      end
   end	
   
   -- show the button
   self.buttons[unit]:Show()
   self.buttons[unit]:SetAlpha(0)
   
   -- update secure frame
   self.buttons[unit].secure:SetWidth(self.buttons[unit]:GetWidth())
   self.buttons[unit].secure:SetHeight(self.buttons[unit]:GetHeight())
   
   self.buttons[unit].secure:ClearAllPoints()
   self.buttons[unit].secure:SetAllPoints(self.buttons[unit])
   
   self.buttons[unit].secure:SetAttribute("unit", unit)
   self.buttons[unit].secure:SetAttribute("type1", "target")
   self.buttons[unit].secure:SetAttribute("type2", "focus")
   
   -- show the secure frame
   self.buttons[unit].secure:Show()
   self.buttons[unit].secure:SetAlpha(0)
end

function Gladius:ShowUnit(unit, testing)
   if (unit:find("pet")) then return end
   if (not self.buttons[unit]) then return end
   
   -- disable test mode, when there are real arena opponents (happens when entering arena and using /gladius test)
   local testing = testing or false
   if (not testing and self.test) then 
      -- reset frame
      self:HideFrame()
      
      -- disable test mode
      self.test = false 
   end
   
   self.buttons[unit]:SetAlpha(1)
   self.buttons[unit].secure:SetAlpha(1)
   
   for _, m in pairs(self.modules) do
      if (m:IsEnabled()) then
         self:Call(m, "Show", unit)
      end
   end
end

function Gladius:TestUnit(unit)
   if (unit:find("pet")) then return end
   
   -- disable secure frame in test mode so we can move the frame
   self.buttons[unit].secure:SetAlpha(0)
   
   -- test modules
   for _, m in pairs(self.modules) do
      if (m:IsEnabled()) then
         self:Call(m, "Test", unit)
      end
	end
	
	-- show frame
	self:ShowUnit(unit, true)
end

function Gladius:ResetUnit(unit)
   if (unit:find("pet")) then return end
   if (not self.buttons[unit]) then return end
   
   -- reset modules
   for _, m in pairs(self.modules) do
      if (m:IsEnabled()) then
         self:Call(m, "Reset", unit)
      end
	end
	
	-- reset auras
	self.buttons[unit].auras = {}
   
   -- hide the button
   self.buttons[unit]:SetAlpha(0)
   
   -- hide the secure frame
   self.buttons[unit].secure:SetAlpha(0)
end

function Gladius:UpdateAlpha(unit, alpha)
   -- update button alpha
   alpha = alpha and alpha or 0.25
   if (self.buttons[unit]) then 
      self.buttons[unit]:SetAlpha(alpha)
   end  
end

function Gladius:CreateButton(unit)
   local button = CreateFrame("Frame", "GladiusButtonFrame" .. unit, UIParent)
   button:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,})
	button:SetBackdropColor(0, 0, 0, 0.4)
	 
   button:SetClampedToScreen(true)
   button:EnableMouse(true)
	button:SetMovable(true)
	button:RegisterForDrag("LeftButton")
	
	button:SetScript("OnDragStart", function(f) 
		if (not InCombatLockdown() and not self.db.locked) then 
         local f = self.db.lockButtons and self.buttons["arena1"] or f
         f:StartMoving() 
      end 
	end)
    
	button:SetScript("OnDragStop", function(f)
      if (not InCombatLockdown()) then
         local f = self.db.lockButtons and self.buttons["arena1"] or f
         local unit = self.db.lockButtons and "arena1" or unit 
            
         f:StopMovingOrSizing()
         local scale = f:GetEffectiveScale()
         self.db.x[unit] = f:GetLeft() * scale
         self.db.y[unit] = f:GetTop() * scale
      end
   end)
    
   local secure = CreateFrame("Button", "GladiusButton" .. unit, button, "SecureActionButtonTemplate")
	secure:RegisterForClicks("AnyUp")
	   
   button.secure = secure
   self.buttons[unit] = button
end

function Gladius:UNIT_HEALTH(event, unit)
   if (not unit:find("arena") or unit:find("pet")) then return end

   -- update unit
   if (self.buttons[unit] and not self.buttons[unit]:IsVisible()) then
      self:ShowUnit(unit)
   end
end
