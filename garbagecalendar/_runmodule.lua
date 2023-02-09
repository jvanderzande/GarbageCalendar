----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
MainRunModVersion = '20230209-2000'

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

	Print_weblogfile('-> Start -- ' .. mtext .. ' _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') .. '  file:' .. (websitemodulescript or '??'))
	dofile(websitemodulescript)
	datafile = datafile or arg[4] or '??'
	return '', '  - Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. datafile .. '. Look at ' .. weblogfile .. ' for process details.'
end

-------------------------------------------------------
-- Print_weblogfile( function to format log records when in batch mode
function Print_weblogfile(text, always)
	---------------------------------
	-- this fucntion will find the LUA filename&linenr that called this func
	function traceback()
		local level = 1
		while true do
			local info = debug.getinfo(level, 'Slfn')
			if not info then
				break
			end
			--if info.what ~= 'C' and not info.short_src:match('generalfuncs.lua') then
			if info.what ~= 'C' then
				calledfrom = info.short_src:match('.*[/\\](.*)%.lua')
				calledline = (info.linedefined or '?')
				--print(string.format('[%s]:%d %s ->%s', calledfrom, info.currentline, info.name, info.short_src))
				break
			end
			level = level + 1
		end
	end
	calledfrom = '??'
	traceback()
	ShortFileNames = {garbagecalendar_main = 'GC Main', _runmodule = 'Run Mod'}
	calledfrom = ShortFileNames[calledfrom] or calledfrom
	text = text or 'nil'
	local ptext = '' .. os.date('%X ') .. calledfrom .. ':'..calledline.. ": " .. (websitemodule or '?') .. ': ' .. text
	--print(weblogfile,'||',text,'||',always)
	if (weblogfile or '') == '' then
		print(ptext)
	else
		local file = io.open(weblogfile, 'a')
		file:write(ptext .. '\n')
		file:close()
		if (always or false) then
			print(ptext)
		end
	end
end

-------------------------------------------------------
-- Print_Mainlogfile() Allows to so information in the mainlog and console when in foreground
function Print_Mainlogfile(text, always, prefix)
	if Print_logfile then
		Print_logfile(text, always, prefix)
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
-- set temp log to capture the initial log messages in until the final logfile is known
weblogfile = weblogfile or (GC_scriptpath .. 'data/garbagecalendar_web_templog.log')
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
		Print_weblogfile('### Error: failed loading generalfuncs.lua from : ' .. GC_scriptpath .. '', 1)
		Print_weblogfile('### Error: Please check the path in variable "GC_scriptpath= "  in your setup and try again.', 1)
		Print_weblogfile('!!! LUA Error: ' .. genfuncs)
		return
	else
		Print_weblogfile('Loaded ' .. GC_scriptpath .. 'generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ')')
		if (MainRunModVersion or '??') ~= MainGenUtilsVersion then
			Print_weblogfile('### Warning: Version of generalfuncs.lua (v' .. (MainGenUtilsVersion or '??') .. ') is different from the _Runmodule script! (v' .. (MainRunModVersion or '??') .. ')')
		end
	end
end
-- =======================================================
-- Load JSON module when in background mode
-- =======================================================
if not JSON then
	JSON = genfuncs.loadlualib('JSON')
	if not JSON then
		return
	end
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
	-- string starting and ending single quote
	param = JSON:decode(arg[1] or '{}')
end
--
-- list param array for debugging
if param ~= nil then
	Print_weblogfile('> Input param table:')
	for key, value in pairs(param) do
		Print_weblogfile('  -> param:' .. key .. ' => ' .. value)
	end
else
	Print_weblogfile('> Input param table missing?')
	return
end
--
websitemodule = param.websitemodule or ''
Zipcode = param.Zipcode or ''
Housenr = param.Housenr or ''
Housenrsuf = param.Housenrsuf or ''
afwdatafile = param.datafile or ''
-- copy temp runlog to the provided name and remove again
if (weblogfile == (GC_scriptpath .. 'data/garbagecalendar_web_templog.log') and (param.weblogfile or '') ~= '') then
	local ifile, ierr = io.open(weblogfile, 'r')
	if not ierr then
		local loginfo = ifile:read('*all')
		ifile:close()
		local ofile, oerr = io.open(param.weblogfile, 'a')
		if not oerr then
			--print('== templog start ========================================================')
			--print(loginfo)
			--print('== templog end   ========================================================')
			--print('=> copied to:', param.weblogfile)
			ofile:write(loginfo)
			ofile:close()
			os.remove(GC_scriptpath .. 'data/garbagecalendar_web_templog.log')
		end
	end
end
weblogfile = param.weblogfile or ''
Hostname = param.Hostname or ''
Street = param.Street or ''
companyCode = param.companyCode or ''

-- Part to check if version of this script is equal to Main script when run in foreground
if Run_Foreground and (MainScriptVersion or '??') ~= MainRunModVersion then
	Print_weblogfile('### Warning: Version of _runmodule.lua(v' .. (MainRunModVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
end
-- Don't do anything when variable is set true, use for version check
if OnlyCheckVersion or false then
	return
end

--
local estatus, err, result = xpcall(RunWebModule, errhandler)
--print(estatus, '|', err, '|', result)
if estatus then
	Print_weblogfile((err or '') .. (result or ''))
	if Run_Foreground then
		Print_logfile((err or '') .. (result or ''))
	end
else
	Print_weblogfile('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (weblogfile or '') .. '\n' .. (err or ''))
	Print_weblogfile(weblogfile or 'no logfile')
	Print_weblogfile('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
	Print_weblogfile(estatus)
	Print_weblogfile(err)
	Print_weblogfile(debug.traceback())
	if Run_Foreground then
		Print_logfile('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
		Print_logfile('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (weblogfile or '') .. '\n' .. (err or ''))
		Print_logfile(weblogfile or 'no logfile')
		Print_logfile('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
		Print_logfile(estatus)
		Print_logfile(err)
		Print_logfile(debug.traceback())
		Print_logfile('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
	end
end
Print_weblogfile('-< End module ' .. (websitemodule or '??') .. '.lua (v' .. (ver or '??') .. ')')
