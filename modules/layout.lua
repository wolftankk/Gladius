local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Layout"))
end
local L = Gladius.L
local LSM

local Layout = Gladius:NewModule("Layout", "AceEvent-3.0", "AceSerializer-3.0")
Gladius:SetModule(Layout, "Layout", false, false, {
})

function Layout:OnEnable()   
   LSM = Gladius.LSM   
end

function Layout:OnDisable()
   self:UnregisterAllEvents()
end

function Layout:GetAttachTo()
   return ""
end

function Layout:GetFrame(unit)
   return ""
end

local function SerializeTable(table, defaults)
   for key, value in pairs(table) do
      if (type(value) == "table") then
         if (defaults[key] ~= nil) then
            local t = SerializeTable(value, defaults[key])
            
            if (next(t) ~= nil) then
               table[key] = t
            else
               table[key] = nil
            end
         end
      else
         if (defaults[key] == value) then
            table[key] = nil
         end
      end
   end
   
   return table
end

function Layout:GetOptions()
   self.layout = ""

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
                  layoutInput = {
                     type="input",
                     name=L["Layout Code"],
                     desc=L["Code of your layout."],
                     get=function() return self.layout end,
                     set=function(info, value) self.layout = value end,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     multiline=true,
                     width="full",
                     order=5,
                  },
                  layoutImport = {
                     type="execute",
                     name=L["Import layout"],
                     desc=L["Import your layout code."],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     func=function()
                        local layout, err = loadstring(string.format([[return %s]], self.Deserialize(self.layout)))
                        
                        if (err) then
                           Gladius:Print(string.format(L["Error while importing layout: %s"], err))
                           return
                        end
                        
                        layout = layout()
                        
                        local currentLayout = Gladius.dbi:GetCurrentProfile()
                        Gladius.dbi:SetProfile("Import Backup")
                        Gladius.dbi:CopyProfile(currentLayout)
                        Gladius.dbi:SetProfile(currentLayout)
                        Gladius.dbi:ResetProfile()
                        
                        for key, data in pairs(layout) do
                           if (type(data) == "table") then
                              Gladius.dbi.profile[key] = CopyTable(data)
                           else
                              Gladius.dbi.profile[key] = data
                           end
                        end
							
                        Gladius:UpdateFrame()
                     end,
                     order=10,
                  },
                  layoutExport = {
                     type="execute",
                     name=L["Export layout"],
                     desc=L["Export your layout code."],
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     func=function()
                        local t = CopyTable(Gladius.dbi.profile)
                        self.layout = self:Serialize(SerializeTable(t, Gladius.defaults.profile)   )
                     end,
                     order=15,
                  },
               },
            },
         },
      },
   }
   
   return t
end
