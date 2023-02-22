----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
MainRunModVersion = '20230209-2000'
-- Don't do anything when variable is set true, use for version check
if (OnlyCheckVersion or false) then
	return
end

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

	-- Print_weblogfile('-> Start -- ' .. mtext .. ' _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') .. '  file:' .. (websitemodulescript or '??'))
	dofile(websitemodulescript)
	datafile = datafile or arg[4] or '??'
	return '', '  - Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. datafile .. '. Look at ' .. weblogfile .. ' for process details.'
end

-------------------------------------------------------
-- Print_weblogfile( function to format log records when in batch mode
function Print_weblogfile(text, always, prefix)
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

	--if (weblogfile or '') == '' then
		print(ptext)
	--[[
	else
		local file = io.open(weblogfile, 'a')
		if file then
			file:write(ptext .. '\n')
			file:close()
			if (always or false) then
				print(ptext)
			end
		else
			print(weblogfile)
			print(ptext)
		end
	end
	]]
end

-------------------------------------------------------
-- use Print_weblogfile when Print_logfile from Main script isn't there. happens when in background mode
if not Print_logfile then
	Print_logfile = Print_weblogfile
end

-- End Functions =========================================================================

-- #######################################################################################
-- Main script
-- #######################################################################################
GC_scriptpath = GC_scriptpath or script_path()
if (GC_scriptpath == '') then
	GC_scriptpath = script_path()
end

timenow = os.date('*t')

Run_Foreground = false
mtext = 'background'
-- define param as global var.
param = param
if param then
	Run_Foreground = true
	mtext = 'foreground'
end
Print_weblogfile('-> Start -- ' .. mtext .. ' _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') .. '  file:' .. (websitemodulescript or '??'))

weblogfile = ""
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
-- Get param's from the JSON parameter when in batch
if not Run_Foreground then
	-- string starting and ending single quote
	-- param = JSON:decode(arg[1] or '{}')
	datafilepath = arg[1] or (GC_scriptpath .. 'data/')
	Print_weblogfile("datafilepath=" .. (datafilepath or "?"))
	local paramfile = datafilepath .. 'garbagecalendar_params.tbl'
	param, perr = table.load(paramfile)
	if perr ~= 0 then
		--- when file doesn't exist
		Print_logfile('### Warning: paramfile not found:' .. paramfile .. '.')
	else
		Print_logfile('paramfile=' .. paramfile .. ' loaded.')
	end
end
--
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
Hostname = param.Hostname or ''
Street = param.Street or ''
companyCode = param.companyCode or ''
weblogfile = param.weblogfile or '??'

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
