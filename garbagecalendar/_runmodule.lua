----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
local ver = "20201222-1200"
-- Error handling function
function errhandler(x)
   return x .. "\n" .. debug.traceback()
end
-------------------------------------------------------
-- rdprint function to format log records
function rdprint(text)
   text = text or "nil"
   if afwlogfile == nil then
      print("(" .. (websitemodule or "?") .. "):" .. (text or "?"))
   else
      ptext = "(" .. (websitemodule or "?") .. "): "
      file, err = io.open(afwlogfile, "a")
      if not err then
         file:write(ptext .. os.date("%X ") .. text .. "\n")
         file:close()
      end
      print(ptext .. os.date("%X ") .. text)
   end
end
-- RunWebModule Function
function RunWebModule(arg)
   --print("Start RunWebModule .....")
   -------------------------------------------------------
   -- get script directory
   function Get_Scriptpath()
      return arg[0]:match(".*[/\\]") or "./"
   end
   -- use Main scriptpath in case the lua script is ran in the foreground
   if (scriptpath == nil) then
      if arg ~= nil and arg[0] ~= nil then
         scriptpath = Get_Scriptpath()
      end
      scriptpath = scriptpath or "./"
   end
   -- only include when run in separate process
   local websitemodulescript
   if arg ~= nil and arg[6] ~= nil then
      if websitemodule == nil then
         return "", "!!!! Module name not provided. Ending run."
      end
      afwlogfile = arg[6] or (scriptpath .. "garbagecalendar_runmodule.log")
      rdprint("--> ### Start -- background _runmodule.au3 for garbage module " .. (websitemodule or "??") .. " (v" .. ver .. ")")
      -- add standard functions when ran in the background
      dofile(scriptpath .. "generalfuncs.lua") --
      websitemodulescript = scriptpath .. websitemodule .. ".lua"
   else
      afwlogfile = afwlogfile or (scriptpath .. "garbagecalendar_runmodule.log")
      rdprint("### Start -- foreground _runmodule.au3 for garbage module " .. (websitemodule or "??") .. " (v" .. ver .. ")")
      websitemodulescript = scriptpath .. "garbagecalendar/" .. websitemodule .. ".lua"
   end
   --print(websitemodulescript)
   --print(afwlogfile)
   dofile(websitemodulescript)
   return "", "Module " .. (websitemodule or "") .. " done."
end

-- Main script
websitemodule = websitemodule or table.remove(arg, 1)
afwlogfile = weblogfile or arg[6]
local estatus, err, result = xpcall(RunWebModule, errhandler, arg)
if estatus then
   rdprint((err or "") .. (result or ""))
else
   rdprint("!! Module " .. (websitemodule or "???") .. " had hard error. check log:" .. (afwlogfile or "") .. "\n" .. (err or ""))
   rdprint(afwlogfile or "no logfile")
   rdprint("\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
   rdprint(x)
   rdprint(debug.traceback())
   rdprint("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
end
rdprint("<-- ### End _runmodule.au3 for garbage module " .. (websitemodule or "??") .. " (v" .. ver .. ")")
