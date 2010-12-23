local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Timer"))
end
local L = Gladius.L
local LSM

local Timer = Gladius:NewModule("Timer", "AceEvent-3.0")
Gladius:SetModule(Timer, "Timer", false, false, {
   timerSoonFontSize = 18,   
   timerSoonFontColor = { r = 1, g = 0, b = 0, a = 1 },
   
   timerSecondsFontSize = 16,   
   timerSecondsFontColor = { r = 1, g = 1, b = 0, a = 1 },
   
   timerMinutesFontSize = 14,   
   timerMinutesFontColor = { r = 0, g = 1, b = 0, a = 1 },
})

function Timer:OnEnable()   
   LSM = Gladius.LSM   

   -- cooldown frames
   self.frames = {}
end

function Timer:OnDisable()
   self:UnregisterAllEvents()
   
   for frame in pairs(self.frames) do
      self.frames[frame]:SetAlpha(0)
   end
end

function Timer:GetAttachTo()
   return ""
end

function Timer:GetFrame(unit)
   return ""
end

function Timer:SetFormattedNumber(frame, number)        
   local minutes = math.floor(number / 60)
   
   if (minutes > 0) then
      local seconds = number - minutes * 60
      
      frame:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont), Gladius.db.timerMinutesFontSize)
      frame:SetTextColor(Gladius.db.timerMinutesFontColor.r, Gladius.db.timerMinutesFontColor.g, Gladius.db.timerMinutesFontColor.b, Gladius.db.timerMinutesFontColor.a)
      
      frame:SetText(string.format("%s %.0f", minutes, seconds))
   else
      if (number > 5) then
         frame:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont), Gladius.db.timerSecondsFontSize)
         frame:SetTextColor(Gladius.db.timerSecondsFontColor.r, Gladius.db.timerSecondsFontColor.g, Gladius.db.timerSecondsFontColor.b, Gladius.db.timerSecondsFontColor.a)
      
         frame:SetText(string.format("%.0f", number))
      else
         frame:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont), Gladius.db.timerSoonFontSize)
         frame:SetTextColor(Gladius.db.timerSoonFontColor.r, Gladius.db.timerSoonFontColor.g, Gladius.db.timerSoonFontColor.b, Gladius.db.timerSoonFontColor.a)
      
         frame:SetText(string.format("%.1f", number))
      end
   end  
end

function Timer:SetTimer(frame, duration)
   local frameName = frame:GetName()

   if (not self.frames[frameName]) then
      self:RegisterTimer(frame)
   end
   
   self:SetFormattedNumber(self.frames[frameName].text, duration)
   
   self.frames[frameName].duration = duration
   self.frames[frameName].text:SetAlpha(1)
   
   self.frames[frameName]:SetScript("OnUpdate", function(f, elapsed)
      f.duration = f.duration - elapsed
      
      if (f.duration <= 0) then
         f.text:SetAlpha(0)
         f:SetScript("OnUpdate", nil)
      else
         self:SetFormattedNumber(f.text, f.duration)
      end
   end)
end

function Timer:HideTimer(frame)
   local frameName = frame:GetName()
   
   if (self.frames[frameName]) then
      self.frames[frameName].text:SetAlpha(0)
      self.frames[frameName]:SetScript("OnUpdate", nil)
   end
end

function Timer:RegisterTimer(frame)    
   local frameName = frame:GetName()
   _G[frameName .. "Cooldown"].noCooldownCount = true

   if (not self.frames[frameName]) then
      self.frames[frameName] = CreateFrame("Frame", "Gladius" .. self.name .. frameName)
      self.frames[frameName].name = frameName
      self.frames[frameName].text = frame:CreateFontString("Gladius" .. self.name .. frameName .. "Text", "OVERLAY")
   end
      
   -- update frame   
   self.frames[frameName].text:ClearAllPoints()
   self.frames[frameName].text:SetPoint("CENTER", frame)
      
   self.frames[frameName].text:SetParent(frame)

   self.frames[frameName].text:SetShadowOffset(1, -1)
   self.frames[frameName].text:SetShadowColor(0, 0, 0, 1)
   
   -- hide
   self.frames[frameName].text:SetAlpha(0)
end

function Timer:GetOptions()
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
                  timerSoonFontColor = {
                     type="color",
                     name=L["Timer Soon Color"],
                     desc=L["Color of the timer when timeleft is less than 5 seconds."],
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b) return Gladius:SetColorOption(info, r, g, b, 1) end,
                     hasAlpha=false,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  timerSoonFontSize = {
                     type="range",
                     name=L["Timer Soon Size"],
                     desc=L["Text size of the timer when timeleft is less than 5 seconds."],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     min=1, max=20, step=1,
                     order=10,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  timerSecondsFontColor = {
                     type="color",
                     name=L["Timer Seconds Color"],
                     desc=L["Color of the timer when timeleft is less than 60 seconds."],
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b) return Gladius:SetColorOption(info, r, g, b, 1) end,
                     hasAlpha=false,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  timerSecondsFontSize = {
                     type="range",
                     name=L["Timer Seconds Size"],
                     desc=L["Text size of the timer when timeleft is less than 60 seconds."],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     min=1, max=20, step=1,
                     order=20,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=23,
                  },
                  timerMinutesFontColor = {
                     type="color",
                     name=L["Timer Minutes Color"],
                     desc=L["Color of the timer when timeleft is greater than 60 seconds."],
                     get=function(info) return Gladius:GetColorOption(info) end,
                     set=function(info, r, g, b) return Gladius:SetColorOption(info, r, g, b, 1) end,
                     hasAlpha=false,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=25,
                  },
                  timerMinutesFontSize = {
                     type="range",
                     name=L["Timer Minutes Size"],
                     desc=L["Text size of the timer when timeleft is greater than 60 seconds."],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     min=1, max=20, step=1,
                     order=30,
                  },
               },
            },
         },
      },
   }
end
