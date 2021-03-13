----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
MainRunModVersion = '20210313-1220'
-- Error handling function
function errhandler(x)
   return x .. '\n' .. debug.traceback()
end
-------------------------------------------------------
-- rdprint function to format log records
function rdprint(text)
   text = text or 'nil'
   local ptext = '' .. os.date('%X ') .. '_runmodule: ' .. text
   if afwlogfile == nil then
      print(ptext)
   else
      local file, err = io.open(afwlogfile, 'a')
      if not err then
         file:write(ptext .. '\n')
         file:close()
      end
      print(ptext)
   end
end
-- RunWebModule Function
function RunWebModule(arg)
   --print("Start RunWebModule .....")
   -------------------------------------------------------
   -- get script directory
   function Get_Scriptpath()
      return arg[0]:match('.*[/\\]') or './'
   end
   -- use Main scriptpath in case the lua script is ran in the foreground
   if (scriptpath == nil) then
      if arg ~= nil and arg[0] ~= nil then
         scriptpath = Get_Scriptpath()
      end
      --ensure the all path variables ends with /
      scriptpath = scriptpath:gsub('\\', '/')
      scriptpath = (scriptpath .. '/'):gsub('//', '/')
      rdprint('#1 scriptpath ' .. scriptpath)
   end
   -- only include when run in separate process
   local websitemodulescript
   if arg ~= nil and arg[6] ~= nil then
      if websitemodule == nil then
         return '', '!!!! Module name not provided. Ending run.'
      end
      afwlogfile = arg[6] or (scriptpath .. 'garbagecalendar_runmodule.log')
      rdprint('--> Start -- background _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') )
      -- add standard functions when ran in the background
      dofile(scriptpath .. 'generalfuncs.lua') --
      websitemodulescript = scriptpath .. websitemodule .. '.lua'
   else
      if websitemodule == nil then
         rdprint("!!!!! You can't run _runmodule just by itself.")
         return
      end
      afwlogfile = afwlogfile or (scriptpath .. 'garbagecalendar_runmodule.log')
      rdprint('--> Start -- foreground _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??'))
      websitemodulescript = scriptpath .. 'garbagecalendar/' .. websitemodule .. '.lua'
   end
   --print(websitemodulescript)
   --print(afwlogfile)
   dofile(websitemodulescript)
   datafile = datafile or arg[5] or "??"
   return '', '  - Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. datafile ..'. Look at ' .. afwlogfile .. ' for process details.'
end

-- Main script
-- Part to check if version of this script is equal to Main script when run in foreground
if arg[6] == nil and (MainScriptVersion or "??") ~= MainRunModVersion  then
   dprintlog('### Warning: Version of _runmodule.lua(v' .. (MainRunModVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
end
-- Don't do anything when variable is set true, use for version check
if OnlyCheckVersion or false then
   return
end
--
websitemodule = websitemodule or table.remove(arg, 1)
afwlogfile = weblogfile or arg[6]
local estatus, err, result = xpcall(RunWebModule, errhandler, arg)
if estatus then
   rdprint((err or '') .. (result or ''))
   if arg[6] == nil then dprintlog(result or '') end
else
   rdprint('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (afwlogfile or '') .. '\n' .. (err or ''))
   rdprint(afwlogfile or 'no logfile')
   rdprint('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
   rdprint(x)
   rdprint(debug.traceback())
   rdprint('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
end
rdprint('--< End module ' .. (websitemodule or '??') .. '.lua (v' .. (ver or '??') .. ')')
