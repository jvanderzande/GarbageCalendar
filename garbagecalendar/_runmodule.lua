----------------------------------------------------------------------------------------------------------------
-- GarbageCalendar run module script: runmodule.lua
--
-- This script is used to run all modules in the background and ensures to capture any hard errors.
-- The information wil be logged to the garbagecalendar_we_modulename.log file.
----------------------------------------------------------------------------------------------------------------
MainRunModVersion = '20230207-1242'
GC_scriptpath = GC_scriptpath or '?'
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
function RunWebModule()
	--print("Start RunWebModule .....")
	-------------------------------------------------------
	-- get script directory
	if (GC_scriptpath ~= '?') then
		-- use Main GC_scriptpath in case the lua script is ran in the foreground
		rdprint('Foreground GC_scriptpath ' .. GC_scriptpath)
	else
		-- list arg array for debugging
		rdprint('> RunWebModule Input arg table:')
		if arg ~= nil then
			for key, value in pairs(arg) do --pseudocode
				rdprint('> arg:' .. key .. '=' .. value)
			end
		end
		-- When for some reason the arg[0] isn't provided then try a diffferent way to get the GC_scriptpath
		function script_path()
			local str = debug.getinfo(2, 'S').source:sub(2)
			return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
		end
		-- Set Script_path
		GC_scriptpath = script_path() or './'
		rdprint('#1 GC_scriptpath ' .. GC_scriptpath)
	end
	-- only include when run in separate process
	local websitemodulescript
	if arg ~= nil and arg[5] ~= nil then
		if websitemodule == nil then
			return '', '!!!! Module name not provided. Ending run.'
		end
		afwlogfile = arg[5] or (GC_scriptpath .. 'garbagecalendar_runmodule.log')
		rdprint('--> Start -- background _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??'))
		-- add standard functions when ran in the background
		dofile(GC_scriptpath .. 'generalfuncs.lua') --
		websitemodulescript = GC_scriptpath .. websitemodule .. '.lua'
	else
		if websitemodule == nil then
			rdprint("!!!!! You can't run _runmodule just by itself.")
			return
		end
		afwlogfile = afwlogfile or (GC_scriptpath .. 'garbagecalendar_runmodule.log')
		websitemodulescript = GC_scriptpath .. '' .. websitemodule .. '.lua'
		rdprint('--> Start -- foreground _runmodule.lua (v' .. MainRunModVersion .. ') for garbage module ' .. (websitemodule or '??') .. '  file:' .. (websitemodulescript or '??'))
	end
	--print(websitemodulescript)
	--print(afwlogfile)
	dofile(websitemodulescript)
	datafile = datafile or arg[4] or '??'
	return '', '  - Module ' .. (websitemodule or '') .. ' done. Saved ' .. (#garbagedata or 0) .. ' records to data file ' .. datafile .. '. Look at ' .. afwlogfile .. ' for process details.'
end

-- Main script
-- Part to check if version of this script is equal to Main script when run in foreground
if arg == nil and (MainScriptVersion or '??') ~= MainRunModVersion then
	dprintlog('### Warning: Version of _runmodule.lua(v' .. (MainRunModVersion or '??') .. ') is different from the main script! (v' .. (MainScriptVersion or '??') .. ')')
end
-- Don't do anything when variable is set true, use for version check
if OnlyCheckVersion or false then
	return
end
--
websitemodule = websitemodule or table.remove(arg, 1)
afwlogfile = weblogfile or arg[5]
-- list arg array for debugging
rdprint('> Input arg table:')
if arg ~= nil then
	for key, value in pairs(arg) do --pseudocode
		rdprint('> arg:' .. key .. '=' .. value)
	end
end
--
local estatus, err, result = xpcall(RunWebModule, errhandler)
if estatus then
	rdprint((err or '') .. (result or ''))
	if arg == nil then
		dprintlog(result or '')
	end
else
	rdprint('!! Module ' .. (websitemodule or '???') .. ' had hard error. check log:' .. (afwlogfile or '') .. '\n' .. (err or ''))
	rdprint(afwlogfile or 'no logfile')
	rdprint('\n%%%%% LUA Hardcrash log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
	rdprint(estatus)
	rdprint(err)
	rdprint(debug.traceback())
	rdprint('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
end
rdprint('--< End module ' .. (websitemodule or '??') .. '.lua (v' .. (ver or '??') .. ')')
