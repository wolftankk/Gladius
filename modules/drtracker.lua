local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "DRTracker"))
end
local L = Gladius.L
local LSM

local DRData = LibStub("DRData-1.0")

local DRTracker = Gladius:NewModule("DRTracker", "AceEvent-3.0")
Gladius:SetModule(DRTracker, "DRTracker", false, true, {
   drTrackerAttachTo = "ClassIcon",
   drTrackerAnchor = "TOPRIGHT",
   drTrackerRelativePoint = "TOPLEFT",
   drTrackerAdjustSize = true,
   drTrackerMargin = 5,
   drTrackerSize = 52,
   drTrackerOffsetX = 0,
   drTrackerOffsetY = 0,
   drTrackerFrameLevel = 2,
   drTrackerGloss = true,
   drTrackerGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   
   drFontSize = 12,
   drFontColor = { r = 0, g = 1, b = 0, a = 1 },
   
   drCategories = {},
})

function DRTracker:OnEnable()   
   self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   
   LSM = Gladius.LSM   
   
   if (not self.frame) then
      self.frame = {}
   end 
end

function DRTracker:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function DRTracker:GetAttachTo()
   return Gladius.db.drTrackerAttachTo
end

function DRTracker:GetFrame(unit)
   return self.frame[unit]
end

function DRTracker:DRFaded(unit, spellID)
	local drCat = DRData:GetSpellCategory(spellID)
	if (Gladius.db.drCategories[drCat] == false) then return end

	local tracked = self.frame[unit].tracker[drCat]

	if (not tracked) then
		tracked = CreateFrame("CheckButton", "Gladius" .. self.name .. "FrameCat" .. drCat .. unit, self.frame[unit], "ActionButtonTemplate")
		tracked:EnableMouse(false)
		tracked.reset = 0
		
		tracked:SetWidth(self.frame[unit]:GetHeight())
		tracked:SetHeight(self.frame[unit]:GetHeight())
		
		tracked:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
      tracked.texture = _G[tracked:GetName().."Icon"]
      tracked.normalTexture = _G[tracked:GetName().."NormalTexture"]
      tracked.cooldown = _G[tracked:GetName().."Cooldown"]
      tracked.cooldown:SetReverse(false)
      
      tracked.text = tracked:CreateFontString(nil, "OVERLAY")
		tracked.text:SetDrawLayer("OVERLAY")
		tracked.text:SetJustifyH("RIGHT")
		tracked.text:SetPoint("BOTTOMRIGHT", tracked)
		tracked.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont), Gladius.db.drFontSize)
		tracked.text:SetTextColor(Gladius.db.drFontColor.r, Gladius.db.drFontColor.g, Gladius.db.drFontColor.b, Gladius.db.drFontColor.a)
      
      -- style action button
      tracked.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
      tracked.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
      
      tracked.normalTexture:ClearAllPoints()
      tracked.normalTexture:SetPoint("CENTER", 0, 0)
      tracked:SetNormalTexture("Interface\\AddOns\\Gladius2\\images\\gloss")
      
      tracked.texture:ClearAllPoints()
      tracked.texture:SetPoint("TOPLEFT", tracked, "TOPLEFT")
      tracked.texture:SetPoint("BOTTOMRIGHT", tracked, "BOTTOMRIGHT")
      tracked.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      
      tracked.normalTexture:SetVertexColor(Gladius.db.trinketGlossColor.r, Gladius.db.trinketGlossColor.g, 
         Gladius.db.trinketGlossColor.b, Gladius.db.trinketGloss and Gladius.db.trinketGlossColor.a or 0)
	end
	
   tracked.active = true
   if (tracked and tracked.reset <= GetTime()) then
		tracked.diminished = 1.0
   else
      tracked.diminished = DRData:NextDR(tracked.diminished)
	end
	
	if (Gladius.test and tracked.diminished == 0) then
      tracked.diminished = 1.0
   end
	
	tracked.timeLeft = DRData:GetResetTime() * tracked.diminished
	tracked.reset = tracked.timeLeft + GetTime()
	
	tracked.text:SetText(tracked.diminished >= 0.25 and L[tracked.diminished * 100 .. " %"] or L["immune"])
	
	tracked.texture:SetTexture(GetSpellTexture(spellID))
	tracked.cooldown:SetCooldown(GetTime(), tracked.timeLeft)
	
	tracked:SetScript("OnUpdate", function(f, elapsed)
      f.timeLeft = f.timeLeft - elapsed
      if (f.timeLeft <= 0) then
         if (Gladius.test) then return end
         
         f.active = false
         f:SetAlpha(0)

         -- position icons
         self:SortIcons(unit)
      end	
   end)

   self.frame[unit].tracker[drCat] = tracked

	self:SortIcons(unit)
	tracked:SetAlpha(1)
end

function DRTracker:SortIcons(unit)
   local lastFrame = self.frame[unit]

   for cat, frame in pairs(self.frame[unit].tracker) do
      if (frame.active) then
         frame:ClearAllPoints()
         frame:SetPoint(Gladius.db.drTrackerAnchor, lastFrame, lastFrame == self.frame[unit] and Gladius.db.drTrackerAnchor or Gladius.db.drTrackerRelativePoint, Gladius.db.drTrackerAnchor:find("LEFT") and Gladius.db.drTrackerMargin or -Gladius.db.drTrackerMargin, 0)
         lastFrame = frame
      end
   end
end

function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
   local unit
   for u, _ in pairs(Gladius.buttons) do
      if (UnitGUID(u) == destGUID) then
         unit = u
      end
   end   
   if (not unit) then return end
	
	-- Enemy had a debuff refreshed before it faded, so fade + gain it quickly
	if (eventType == "SPELL_AURA_REFRESH") then
		if (auraType == "DEBUFF" and DRData:GetSpellCategory(spellID)) then
			self:DRFaded(unit, spellID)
		end
	-- Buff or debuff faded from an enemy
	elseif (eventType == "SPELL_AURA_REMOVED") then
		if (auraType == "DEBUFF" and DRData:GetSpellCategory(spellID)) then
			self:DRFaded(unit, spellID)
		end
   end
end

function DRTracker:CreateFrame(unit)
   local button = Gladius.buttons[unit]
   if (not button) then return end       
   
   -- create frame
   self.frame[unit] = CreateFrame("Frame", "Gladius" .. self.name .. "Frame" .. unit, button, "ActionButtonTemplate")
end

function DRTracker:Update(unit)   
   -- create frame
   if (not self.frame[unit]) then 
      self:CreateFrame(unit)
   end
   
   -- update frame   
   self.frame[unit]:ClearAllPoints()
   
   -- anchor point 
   local parent = Gladius:GetParent(unit, Gladius.db.drTrackerAttachTo)     
   self.frame[unit]:SetPoint(Gladius.db.drTrackerAnchor, parent, Gladius.db.drTrackerRelativePoint, Gladius.db.drTrackerOffsetX, Gladius.db.drTrackerOffsetY)
   
   -- frame level
   self.frame[unit]:SetFrameLevel(Gladius.db.drTrackerFrameLevel)
   
   if (Gladius.db.drTrackerAdjustSize) then
      if (self:GetAttachTo() == "Frame") then   
         local height = false
         --[[ need to rethink that
         for _, module in pairs(Gladius.modules) do
            if (module:GetAttachTo() == self.name) then
               height = false
            end
         end]]
         
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
      self.frame[unit]:SetWidth(Gladius.db.drTrackerSize)         
      self.frame[unit]:SetHeight(Gladius.db.drTrackerSize)  
   end 
   
   -- update icons
   if (not self.frame[unit].tracker) then
      self.frame[unit].tracker = {}
   else
      for _, frame in pairs(self.frame[unit].tracker) do
         frame:SetWidth(self.frame[unit]:GetHeight())         
         frame:SetHeight(self.frame[unit]:GetHeight()) 
         
         frame.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
         frame.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
      end
      
      self:SortIcons(unit)
   end
      
   -- hide
   self.frame[unit]:SetAlpha(0)
end

function DRTracker:Show(unit)
   local testing = Gladius.test
  
   -- show frame
   self.frame[unit]:SetAlpha(1)
end

function DRTracker:Reset(unit)
   -- hide icons
   for _, frame in pairs(self.frame[unit].tracker) do
      frame:SetAlpha(0)
   end
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function DRTracker:Test(unit)
   if (not self.frame[unit].tracker[DRData:GetSpellCategory(64058)] or self.frame[unit].tracker[DRData:GetSpellCategory(64058)].active == false) then
      self:DRFaded(unit, 64058)
      self:DRFaded(unit, 118)
   end
   
   if (not self.frame[unit].tracker[DRData:GetSpellCategory(33786)] or self.frame[unit].tracker[DRData:GetSpellCategory(33786)].active == false) then
      self:DRFaded(unit, 33786)
      self:DRFaded(unit, 33786)
   end
end

function DRTracker:GetOptions()
   local t = {
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
                  drTrackerMargin = {
                     type="range",
                     name=L["DRTracker Space"],
                     desc=L["Space between the icons"],
                     min=0, max=100, step=1,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  drTrackerGloss = {
                     type="toggle",
                     name=L["DRTracker Gloss"],
                     desc=L["Toggle gloss on the drTracker icon"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=15,
                  },
                  drTrackerGlossColor = {
                     type="color",
                     name=L["DRTracker Gloss Color"],
                     desc=L["Color of the drTracker icon gloss"],
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                     hasAlpha=true,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=20,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     hidden=function() return not Gladius.db.advancedOptions end,
                     order=23,
                  },
                  drTrackerFrameLevel = {
                     type="range",
                     name=L["DRTracker Frame Level"],
                     desc=L["Frame level of the drTracker"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     hidden=function() return not Gladius.db.advancedOptions end,
                     min=1, max=5, step=1,
                     width="double",
                     order=25,
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
                  drTrackerAdjustSize = {
                     type="toggle",
                     name=L["DRTracker Adjust Size"],
                     desc=L["Adjust drTracker size to the frame size"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  drTrackerSize = {
                     type="range",
                     name=L["DRTracker Size"],
                     desc=L["Size of the drTracker"],
                     min=10, max=100, step=1,
                     disabled=function() return Gladius.dbi.profile.drTrackerAdjustSize or not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },               
               },
            },
            font = {
               type="group",
               name=L["Font"],
               desc=L["Font settings"],  
               inline=true,   
               hidden=function() return not Gladius.db.advancedOptions end,             
               order=3,
               args = {
                  drFontColor = {
                     type="color",
                     name=L["Cast Text Color"],
                     desc=L["Text color of the cast text"],
                     hasAlpha=true,
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  drFontSize = {
                     type="range",
                     name=L["Cast Text Size"],
                     desc=L["Text size of the cast text"],
                     min=1, max=20, step=1,
                     disabled=function() return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name] end,
                     order=15,
                  },                
               },
            },            
            position = {
               type="group",
               name=L["Position"],
               desc=L["Position settings"],  
               inline=true,                
               hidden=function() return not Gladius.db.advancedOptions end,
               order=4,
               args = {
                  drTrackerAttachTo = {
                     type="select",
                     name=L["DRTracker Attach To"],
                     desc=L["Attach drTracker to the given frame"],
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
                  drTrackerAnchor = {
                     type="select",
                     name=L["DRTracker Anchor"],
                     desc=L["Anchor of the drTracker"],
                     values=function() return Gladius:GetPositions() end,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  drTrackerRelativePoint = {
                     type="select",
                     name=L["DRTracker Relative Point"],
                     desc=L["Relative point of the drTracker"],
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
                  drTrackerOffsetX = {
                     type="range",
                     name=L["DRTracker Offset X"],
                     desc=L["X offset of the drTracker"],
                     min=-100, max=100, step=1,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  drTrackerOffsetY = {
                     type="range",
                     name=L["DRTracker Offset Y"],
                     desc=L["Y  offset of the drTracker"],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     min=-50, max=50, step=1,
                     order=25,
                  },
               },
            },
         },
      },
   }
   
   t.categories = {
      type="group",
      name=L["Categories"],
      order=2,
      args = {
         categories = {
            type="group",
            name=L["Categories"],
            desc=L["Category settings"],  
            inline=true,                
            order=1,
            args = {
            },
         },
      },      
   } 
   
   local index = 1
   for key, name in pairs(DRData.categoryNames) do   
      t.categories.args.categories.args[key] = {
         type="toggle",
         name=name,
         get=function(info)
            if (Gladius.dbi.profile.drCategories[info[#info]] == nil) then
               return true
            else
               return Gladius.dbi.profile.drCategories[info[#info]]
            end
         end,
         set=function(info, value)
            Gladius.dbi.profile.drCategories[info[#info]] = value
         end,
         disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
         order=index * 5,
      }
      
      index = index + 1
   end
   
   return t
end
