﻿local L = Gladius.L

Gladius.defaults = {
   profile = {
      x = {},
      y = {},
      modules = {},
      locked = false,
      growUp = false,
      groupButtons = true,
      bottomMargin = 25,
      barWidth = 200,
      frameScale = 1,
   },
}

local textalign = {
   ["LEFT"] = L["LEFT"],
   ["CENTER"] = L["CENTER"],
   ["RIGHT"] = L["RIGHT"],
}

SLASH_GLADIUS1 = "/gladius"
SlashCmdList["GLADIUS"] = function(msg)
   if (msg:find("test")) then
      local test = tonumber(msg:match("^test (.+)"))
      if (not test or test > 5 or test < 2 or test == 4) then
         test = 5
      end
      
      Gladius.testCount = test
      Gladius.test = true      
      Gladius:HideFrame()
      
      -- create and update buttons on first launch
      for i=1, 5 do
         if (not Gladius.buttons["arena" .. i]) then
            Gladius:UpdateUnit("arena" .. i)
         end
      end
      
      -- update buttons, so every module should be fine
      Gladius:UpdateFrame()
   elseif (msg == "" or msg == "options" or msg == "config" or msg == "ui") then
      AceDialog = AceDialog or LibStub("AceConfigDialog-3.0")
      AceRegistry = AceRegistry or LibStub("AceConfigRegistry-3.0")
      
      if (not Gladius.options) then
         Gladius:SetupOptions()
         AceDialog:SetDefaultSize("Gladius", 640, 500)
      end
      
      AceDialog:Open("Gladius")
   elseif (msg == "hide") then
      -- hide buttons
      Gladius:HideFrame()
   end
end

local function getOption(info)
   return (info.arg and Gladius.dbi.profile[info.arg] or Gladius.dbi.profile[info[#info]])
end

local function setOption(info, value)
   local key = info.arg or info[#info]
   Gladius.dbi.profile[key] = value
   Gladius:UpdateFrame()
end

function Gladius:GetColorOption(info)
   local key = info.arg or info[#info]
   return self.dbi.profile[key].r, self.dbi.profile[key].g, self.dbi.profile[key].b, self.dbi.profile[key].a
end

function Gladius:SetColorOption(info, r, g, b, a) 
   local key = info.arg or info[#info]
   self.dbi.profile[key].r, self.dbi.profile[key].g, self.dbi.profile[key].b, self.dbi.profile[key].a = r, g, b, a
   self:UpdateFrame()
end

function Gladius:SetupModule(key, module, order)
   self.options.args[key] = {
      type="group",
      name=L[key],
      desc=L[key .. "Desc"],
      childGroups="tab",
      order=order,
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
      desc=L["Enable Module"],
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
      width="double",
      order=0,
   }
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
					groupButtons = {
						type="toggle",
						name=L["Group Buttons"],
						desc=L["If this is toggle buttons can be moved separately"],
						order=10,
					},
					bottomMargin = {
                  type="range",
                  name=L["Bottom Margin"],
                  desc=L["Margin between each button"],
                  min=0, max=100, step=1,
                  disabled=function() return not self.dbi.profile.groupButtons end,
                  order=15,
               },
					barWidth = {
                  type="range",
                  name=L["Bar width"],
                  desc=L["Width of the module bars"],
                  min=10, max=500, step=1,
                  order=20,
               },
					frameScale = {
						type="range",
						name=L["Frame scale"],
						desc=L["Scale of the frame"],
						min=.1,
						max=2,
						step=.1,
						order=25,
					},
            },
         },
      },
   }
   
   local order = 10
   for m, module in pairs(self.modules) do
      self:SetupModule(m, module, order)
      order = order + 1
   end
   
   self.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.dbi) }
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Gladius", self.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Gladius", "Gladius")
end
