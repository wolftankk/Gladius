﻿local L = Gladius.L

Gladius.defaults = {
   profile = {
      x = {},
      y = {},
      modules = {
         ["*"] = true,
         ["Auras"] = false,
         ["TargetBar"] = false,
      },
      locked = false,
      growUp = false,
      groupButtons = true,
      advancedOptions = false,
      backgroundColor = { r = 0, g = 0, b = 0, a = 0.4 },
      backgroundPadding = 5,
      bottomMargin = 20,
      useGlobalFontSize = true,
      globalFontSize = 11,
      globalFont = "Friz Quadrata TT",
      barWidth = 200,
      frameScale = 1,      
   },
}

function pairsByKeys(t, f)
   local a = {}
   for n in pairs(t) do table.insert(a, n) end
   table.sort(a, f)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
   end
   return iter
end

Gladius.templates = {
   "Gladius Classic",
   "Gladius Light",
   "Gladius Advanced",
}

function Gladius:SetTemplate(template)
   if (template == 1) then
      -- classic Gladius1 template
      print("Gladius:", "Template not available!")   
   elseif (template == 2) then
      -- reset to default
      for k, v in pairs(self.defaults) do
         self.db[k] = v
      end
   else
      -- enable all features
      print("Gladius:", "Template not available!")      
   end   
end

SLASH_GLADIUS1 = "/gladius"
SlashCmdList["GLADIUS"] = function(msg)
   if (msg:find("test") and not Gladius.test) then       
      local test = tonumber(msg:match("^test (.+)"))
      if (not test or test > 5 or test < 2 or test == 4) then
         test = 5
      end
      
      Gladius.testCount = test
      Gladius.test = true      
      Gladius:HideFrame()
      
      -- create and update buttons on first launch
      for i=1, test do
         if (not Gladius.buttons["arena" .. i]) then
            Gladius:UpdateUnit("arena" .. i)
         end
         
         if (Gladius.buttons["arena" .. i]) then
            Gladius.buttons["arena" .. i]:RegisterForDrag("LeftButton")
            Gladius.buttons["arena" .. i]:Show()
         end
      end
      
      -- update buttons, so every module should be fine
      Gladius:UpdateFrame()
   elseif (msg == "" or msg == "options" or msg == "config" or msg == "ui") then
      AceDialog = AceDialog or LibStub("AceConfigDialog-3.0")
      AceRegistry = AceRegistry or LibStub("AceConfigRegistry-3.0")
      
      if (not Gladius.options) then
         Gladius:SetupOptions()
         AceDialog:SetDefaultSize("Gladius", 830, 530)
      end
      
      AceDialog:Open("Gladius")
   elseif (msg == "hide" or (msg:find("test") and Gladius.test)) then
      -- reset test environment
      Gladius.testCount = 0
      Gladius.test = false
      
      for i=1, 5 do
         if (Gladius.buttons["arena" .. i]) then
            Gladius.buttons["arena" .. i]:RegisterForDrag()
            Gladius.buttons["arena" .. i]:Hide()
         end
      end
      
      -- hide buttons      
      Gladius:HideFrame()
   elseif (msg == "reset") then
      -- reset profile      
      Gladius.dbi:ResetProfile()   
   end
end

local function getOption(info)
   return (info.arg and Gladius.dbi.profile[info.arg] or Gladius.dbi.profile[info[#info]])
end

local function setOption(info, value)
   local key = info[#info]
   Gladius.dbi.profile[key] = value
   
   info = info.arg and info.arg or info[1]  
   
   if (info == "general") then
      Gladius:UpdateFrame()
   else
      Gladius:UpdateFrame(info)
   end
end

function Gladius:GetColorOption(info)
   local key = info.arg or info[#info]
   return self.dbi.profile[key].r, self.dbi.profile[key].g, self.dbi.profile[key].b, self.dbi.profile[key].a
end

function Gladius:SetColorOption(info, r, g, b, a) 
   local key = info.arg or info[#info]
   self.dbi.profile[key].r, self.dbi.profile[key].g, self.dbi.profile[key].b, self.dbi.profile[key].a = r, g, b, a
   
   if (info[1] == "general") then
      Gladius:UpdateFrame()
   else
      Gladius:UpdateFrame(info[1])
   end
end

function Gladius:GetPositions()
   return {
      ["TOPLEFT"] = L["Top Left"],
      ["TOPRIGHT"] = L["Top Right"],
      ["LEFT"] = L["Center Left"],
      ["RIGHT"] = L["Center Right"],
      ["BOTTOMLEFT"] = L["Bottom Left"],
      ["BOTTOMRIGHT"] = L["Bottom Right"],
   }
end

function Gladius:SetupModule(key, module, order)
   self.options.args[key] = {
      type="group",
      name=L[key],
      desc=L[key .. " settings"],
      childGroups="tab",
      order=order,
      args={},
   }
   
   -- set additional module options
   local options = module:GetOptions()
   
   if (type(options) == "table") then
      self.options.args[key].args = options
   end
   
   -- set enable module option
   self.options.args[key].args.enable = {
      type="toggle",
      name=L["Enable Module"],
      set=function(info, v) 
         local module = info[1]
         self.dbi.profile.modules[module] = v
         
         if (v) then
            self:EnableModule(module)
         else
            self:DisableModule(module)
         end 
         
         self:UpdateFrame()
      end, 
      get=function(info) 
         local module = info[1]
         return self.dbi.profile.modules[module]
      end,
      order=0,
   }
   
   -- set reset module option
   self.options.args[key].args.reset = {
      type="execute",
      name=L["Reset Module"],
      func=function()
         for k,v in pairs(module.defaults) do
            self.dbi.profile[k] = v
         end
         
         Gladius:UpdateFrame()
      end,
      order=0.5,
   }
   
   -- set template module option
   if (module.templates) then
      self.options.args[key].args.templates = {
         type="select",
         name=L["Module Templates"],
         values=function() return module.templates end,
         set=function(info, value)                       
            Gladius:Call(module, "SetTemplate", value)
            Gladius:UpdateFrame()
         end,
         order=0.3,
      }
   end
end

function Gladius:SetupOptions()
   self.options = {
      type = "group",
      name = "Gladius",
      plugins = {},
      get=getOption,
      set=setOption,
      args = {
         general = {
            type="group",
            name=L["General"],
            desc=L["General settings"],
            order=1,
            args = {
               general = {
                  type="group",
                  name=L["General"],
                  desc=L["General settings"],  
                  inline=true,                
                  order=1,
                  args = {
                     locked = {
                        type="toggle",
                        name=L["Lock frame"],
                        desc=L["Toggle if the frame can be moved"],
                        order=1,
                     },
                     growUp = {
                        type="toggle",
                        name=L["Grow frame upwards"],
                        desc=L["If this is toggled the frame will grow upwards instead of downwards."],
                        disabled=function() return not self.dbi.profile.groupButtons end,
                        order=5,
                     },
                     sep = {                     
                        type = "description",
                        name="",
                        width="full",                     
                        order=7,
                     }, 
                     groupButtons = {
                        type="toggle",
                        name=L["Group Buttons"],
                        desc=L["If this is toggle buttons can be moved separately"],
                        order=10,
                     },
                     advancedOptions = {
                        type="toggle",
                        name=L["Advanced Options"],
                        desc=L["Toggle advanced options"],
                        order=15,
                     },
                  },
               },               
               frame = {
                  type="group",
                  name=L["Frame"],
                  desc=L["Frame settings"],  
                  inline=true,                
                  order=2,
                  args = {
                     backgroundColor = {
                        type="color",
                        name=L["Background Color"],
                        desc=L["Color of the frame background"],
                        hasAlpha=true,
                        get=function(info) return Gladius:GetColorOption(info) end,
                        set=function(info, r, g, b, a) return Gladius:SetColorOption(info, r, g, b, a) end,
                        disabled=function() return not self.dbi.profile.groupButtons end,
                        order=1,
                     },                     
                     backgroundPadding = {
                        type="range",
                        name=L["Background Padding"],
                        desc=L["Padding of the background"],
                        min=0, max=100, step=1,
                        disabled=function() return not self.dbi.profile.groupButtons end,
                        order=5,
                     },
                     sep = {                     
                        type = "description",
                        name="",
                        width="full",
                        order=7,
                     },
                     bottomMargin = {
                        type="range",
                        name=L["Bottom Margin"],
                        desc=L["Margin between each button"],
                        min=0, max=300, step=1,
                        disabled=function() return not self.dbi.profile.groupButtons end,
                        width="double",
                        order=10,
                     },
                  },
					},		
               size = {
                  type="group",
                  name=L["Size"],
                  desc=L["Size settings"],  
                  inline=true,                
                  order=3,
                  args = {
                     barWidth = {
                        type="range",
                        name=L["Bar width"],
                        desc=L["Width of the module bars"],
                        min=10, max=500, step=1,
                        order=1,
                     },
                     frameScale = {
                        type="range",
                        name=L["Frame scale"],
                        desc=L["Scale of the frame"],
                        min=.1,
                        max=2,
                        step=.1,
                        order=5,
                     },
                  },
					},
               font = {
                  type="group",
                  name=L["Font"],
                  desc=L["Font settings"], 
                  inline=true,                 
                  order=4,
                  args = {
                     globalFont = {
                        type="select",
                        name=L["Global Font"],
                        desc=L["Global font, used by the modules"],
                        dialogControl = "LSM30_Font",
                        values = AceGUIWidgetLSMlists.font,
                        order=1,					
                     },
                     globalFontSize = {
                        type="range",
                        name=L["Global Font Size"],
                        desc=L["Text size of the power info text"],
                        disabled=function() return not self.db.useGlobalFontSize end,
                        min=1, max=20, step=1,
                        order=5,
                     },
                     sep = {                     
                        type = "description",
                        name="",
                        width="full",
                        order=7,
                     },
                     sep2 = {                     
                        type = "toggle",
                        name="NYI",
                        disabled=true,
                        order=8,
                     },
                     useGlobalFontSize = {
                        type="toggle",
                        name=L["Use Global Font Size"],
                        desc=L["Toggle if you want to use the global font size"],
                        order=10,
                     },
                  },
               },		
               templates = {
                  type="group",
                  name=L["Global Templates"],
                  desc=L["Global templates"],  
                  inline=true,                
                  order=5,
                  args = {    
                     templates = {
                        type="select",
                        name=L["Global Templates"],
                        values=function() return self.templates end,
                        set=function(info, value)                       
                           self:SetTemplate(value)
                           self:UpdateFrame()
                        end,
                        order=1,
                     },
                  },
               },
            },
         },
      },
   }
   
   local order = 10
   for moduleName, module in pairsByKeys(self.modules) do
      self:SetupModule(moduleName, module, order)
      order = order + 5
   end
   
   for _,module in pairs(self.modules) do
      self:Call(module, "OptionsLoad")
   end
   
   self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.dbi) }
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Gladius", self.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Gladius", "Gladius")
end
