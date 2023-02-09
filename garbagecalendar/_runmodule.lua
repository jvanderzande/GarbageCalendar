----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
MainRunModVersion = '20230209-1315'

-- Start Functions =========================================================================
-------------------------------------------------------
-- Get script path function
local function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
end

-------------------------------------------------------
-- Error handling function
function errhandler(x)
	return x .. '\n' .. debug.traceback()
end

-------------------------------------------------------
-- RunWebModule Function
function RunWebModule()
	-------------------------------------------------------
	-- Check module provided
	if (websitemodule or '') == '' then
		return '', '!!!! Module name not provided. Ending run.'
	end
	local websitemodulescript = GC_scriptpath .. websitemodule .. '.lua'

	-- other variables
	garbagedata = {} -- array to save information to which will be written to the data file

	Print_RunModuleLog('--> Start -- ' .. mtext .. ' _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') .. '  file:' .. (websitemodulescript or '??'))
	dofile(websitemodulescript)
	datafile = datafile or arg[4] or '??'
	return '', '  - Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. datafile .. '. Look at ' .. afwlogfile .. ' for process details.'
end

-------------------------------------------------------
-- rdprint function to format log records
function Print_RunModuleLog(text, console)
	text = '_runmodule: ' .. text or ''
	if genfuncs.Print_afwlogfile then
		genfuncs.Print_afwlogfile(text, console)
	else
		print(">>>>",text)
	end
end
-- End Functions =========================================================================

-- #######################################################################################
-- Main script
-- #######################################################################################
GC_scriptpath = GC_scriptpath or script_path()
if (GC_scriptpath == '') then
	GC_scriptpath = script_path()
end

-- =======================================================
-- Load General functions module
-- =======================================================
-- Load general functions in case in batchmode
if not genfuncs then
	if not (package.path):match(GC_scriptpath .. '%?.lua;') then
		package.path = GC_scriptpath .. '?.lua;' .. package.path
	end
	status, genfuncs = pcall(require, 'generalfuncs')
	if not status then
		Print_RunModuleLog('### Error: failed loading generalfuncs.lua from : ' .. GC_scriptpath .. '', 1)
		Print_RunModuleLog('### Error: Please check the path in variable "GC_scriptpath= "  in your setup and try again.', 1)
		Print_RunModuleLog('!!! LUA Error: ' .. genfuncs)
		return
	else
		Print_RunModuleLog('Loaded ' .. GC_scriptpath .. 'generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ')')
		if (MainRunModVersion or '??') ~= MainGenUtilsVersion then
			Print_RunModuleLog('### Warning: Version of generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ') is different from the _Runmodule script! (v' .. (MainRunModVersion or '??') .. ')')
		end
	end
end
-- =======================================================
-- Load JSON module
-- =======================================================
JSON = genfuncs.loadlualib('JSON')
if not JSON then
	return
end

-- =======================================================
-- set variable from commandline when batch
-- =======================================================
timenow = os.date('*t')

Run_Foreground = false
mtext = 'background'
if param then
	Run_Foreground = true
	mtext = 'foreground'
end

-- Get param's from the JSON parameter when in batch
if not Run_Foreground then
	param = JSON:decode(arg[1] or '{}')
end
--
-- list param array for debugging
if param ~= nil then
	Print_RunModuleLog('> Input param table:')
	for key, value in pairs(param) do
		Print_RunModuleLog('  -> param:' .. key .. ' => ' .. value)
	end
else
	Print_RunModuleLog('> Input param table missing?')
	return
end
--
websitemodule = param.websitemodule or ''
Zipcode = param.Zipcode or ''
Housenr = param.Housenr or ''
Housenrsuf = param.Housenrsuf or ''
afwdatafile = param.datafile or ''
afwlogfile = param.weblogfile or ''
Hostname = param.Hostname or ''
Street = param.Street or ''
companyCode = param.companyCode or ''

-- Part to check if version of this script is equal to Main script when run in foreground
if Run_Foreground and (MainScriptVersion or '??') ~= MainRunModVersion then
	Print_runlogfile('### Warning: Version of _runmodule.lua(v' .. (MainRunModVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
end
-- Don't do anything when variable is set true, use for version check
if OnlyCheckVersion or false then
	return
end

--
local estatus, err, result = xpcall(RunWebModule, errhandler)
-- print(estatus,"|", err,"|", result)
if estatus then
	Print_RunModuleLog((err or '') .. (result or ''))
else
	Print_RunModuleLog('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (afwlogfile or '') .. '\n' .. (err or ''))
	Print_RunModuleLog(afwlogfile or 'no logfile')
	Print_RunModuleLog('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
	Print_RunModuleLog(estatus)
	Print_RunModuleLog(err)
	Print_RunModuleLog(debug.traceback())
	Print_RunModuleLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
end
Print_RunModuleLog('--< End module ' .. (websitemodule or '??') .. '.lua (v' .. (ver or '??') .. ')')
