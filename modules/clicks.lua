local Gladius = _G.Gladius
if not Gladius then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Clicks"))
end
local L = Gladius.L

local Clicks = Gladius:NewModule("Clicks", "AceEvent-3.0")
Gladius:SetModule(Clicks, "Click Actions", false, false, {
   clickAttributes = {
      ["Left"] = { button = "1", modifier = "", action = "target", macro = ""},
      ["Right"] = { button = "2", modifier = "", action = "focus", macro = ""},
   },
})

function Clicks:OnEnable()
   -- Table that holds all of the secure frames to apply click actions to.
   self.secureFrames = {}
end

function Clicks:OnDisable()
   -- Iterate over all the secure frames and disable any attributes.
   for _,t in pairs(self.secureFrames) do
      for frame,_ in pairs(t) do
         for _,attr in pairs(Gladius.dbi.profile.clickAttributes) do
            frame:SetAttribute(attr.modifier .. "type" .. attr.button, nil)
         end
      end
   end
end

-- Needed to not throw Lua errors <,<
function Clicks:GetAttachTo()
   return ""
end

-- Registers a custom secure frame and immediately  applies
-- click actions to it.
function Clicks:RegisterSecureFrame(unit, frame)
   if (not self.secureFrames[unit]) then 
      self.secureFrames[unit] = {} 
   end
   self.secureFrames[unit][frame] = true
   self:ApplyAttributes(unit, frame)
end

-- Finds all the secure frames belonging to a specific unit
-- then adds them to self.secureFrames.
-- Only searches for secure frames located at module.frame[unit].secure
function Clicks:GetSecureFrames(unit)
   if (not self.secureFrames[unit]) then 
      self.secureFrames[unit] = {} 
   end
   
   -- Add the default secure frame
   if (not self.secureFrames[unit][Gladius.buttons[unit].secure]) then
      self.secureFrames[unit][Gladius.buttons[unit].secure] = true
   end
   
   -- Find secure frames in other modules
   for _,m in pairs(Gladius.modules) do
      if (m.frame and m.frame[unit] and m.frame[unit].secure and not self.secureFrames[m.frame[unit].secure]) then
         self.secureFrames[unit][m.frame[unit].secure] = true
      end
   end  
end

function Clicks:Update(unit)
   -- Update secure frame table
   self:GetSecureFrames(unit)
   
   -- Apply attributes to the frames
   for frame,_ in pairs(self.secureFrames[unit]) do
      self:ApplyAttributes(unit, frame)
   end
end

-- Applies attributes to a specific frame
function Clicks:ApplyAttributes(unit, frame)
   frame:SetAttribute("unit", "player")
   for _, attr in pairs(Gladius.dbi.profile.clickAttributes) do
      frame:SetAttribute(attr.modifier .. "type" .. attr.button, attr.action)
      if (attr.action == "macro" and attr.macro ~= "") then
         frame:SetAttribute(attr.modifier .. "macrotext" .. attr.button, string.gsub(attr.macro, "*unit", unit))
      elseif (attr.action == "spell" and attr.macro ~= "") then 
         frame:SetAttribute(attr.modifier .. "spell" .. attr.button, attr.macro)
      end
   end   
end

local function getOption(info)
   local key = info[#info - 2]
   return Gladius.dbi.profile.clickAttributes[key][info[#info]]
end

local function setOption(info, value)
   local key = info[#info - 2]
   Gladius.dbi.profile.clickAttributes[key][info[#info]] = value
   Gladius:UpdateFrame()
end

local CLICK_BUTTONS = {["1"] = L["Left"], ["2"] = L["Right"], ["3"] = L["Middle"], ["4"] = L["Button 4"], ["5"] = L["Button 5"]}
local CLICK_MODIFIERS = {[""] = L["None"], ["ctrl-"] = L["ctrl-"], ["shift-"] = L["shift-"], ["alt-"] = L["alt-"]}

function Clicks:GetOptions()
   local addAttrButton = "1"
   local addAttrMod = ""
   
   local options = {
      attributeList = {
         type="group",
         name=L["Click Actions"],
         order=1,
         args={
            add = {  
               type="group",
               name=L["Add click action"],
               inline=true,
               order=1,
               args = {
                  button = {
                     type="select",
                     name=L["Mouse button"],
                     desc=L["Select which mouse button this click action uses"],
                     values=CLICK_BUTTONS,
                     get=function(info) return addAttrButton end,
                     set=function(info, value) addAttrButton = value end,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  modifier = {
                     type="select",
                     name=L["Modifier"],
                     desc=L["Select a modifier for this click action"],
                     values=CLICK_MODIFIERS,
                     get=function(info) return addAttrMod end,
                     set=function(info, value) addAttrMod = value end,
                     disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  add = {
                     type="execute",
                     name=L["Add"],
                     func=function()
                        local attr = addAttrMod ~= "" and CLICK_MODIFIERS[addAttrMod] .. CLICK_BUTTONS[addAttrButton] or CLICK_BUTTONS[addAttrButton]
                        
                        if (not Gladius.db.clickAttributes[attr]) then                           
                           -- add to db
                           Gladius.db.clickAttributes[attr] = {
                              button = addAttrButton, 
                              modifier = addAttrButton, 
                              action = "target", 
                              macro = ""
                           }
                           
                           -- add to options
                           Gladius.options.args[self.name].args.attributeList.args[attr] = self:GetAttributeOptionTable(attr, order)
                           
                           -- update
                           Gladius:UpdateFrame()
                        end
                     end,
                     order=30,
                  },
               },
            }
         },
      }
   }
   
   -- attributes
   order = 1
   for attr,_ in pairs(Gladius.dbi.profile.clickAttributes) do 
      options.attributeList.args[attr] = self:GetAttributeOptionTable(attr, order)      
      order = order + 1
   end   

   return options
end

function Clicks:GetAttributeOptionTable(attribute, order)
   return {  
      type="group",
      name=attribute,
      childGroups="tree",
      order=order,
      disabled=function() return not Gladius.dbi.profile.modules[self.name] end,
      args = {
         delete = {
            type="execute",
            name=L["Delete Click Action"],
            func=function()
               -- remove from db
               Gladius.db.clickAttributes[attribute] = nil
               
               -- remove from options
               Gladius.options.args[self.name].args.attributeList.args[attribute] = nil           
               
               -- update
               Gladius:UpdateFrame()
            end,
            order=1,
         },
         action = {  
            type="group",
            name=L["Action"],
            inline=true,
            get=getOption,
            set=setOption,                
            order=2,
            args = {
               action = {
                  type="select",
                  name=L["Action"],
                  desc=L["Select what this Click Action does"],
                  values={["macro"] = MACRO, ["target"] = TARGET, ["focus"] = FOCUS, ["spell"] = L["Cast Spell"]},
                  order=10,
               },
               sep = {                     
                  type = "description",
                  name="",
                  width="full",
                  order=15,
               },
               macro = {
                  type="input",
                  multiline=true,
                  name=L["Spell Name / Macro Text"],
                  desc=L["Select what this Click Action does"],
                  width="double",
                  order=20,                            
               },
            },
         },
      },
   }  
end
