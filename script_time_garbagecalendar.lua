----------------------------------------------------------------------------------------------------------------
-- Event start script for  GarbageCalendar huisvuil script: script_time_garbagecalendar.lua
-- Works both in DzVents and Regular LUA time scripts
----------------------------------------------------------------------------------------------------------------
EventScriptVersion = '20230630-1600'

-- set variable to false=disable or true=enable the script
local GC_enabled = true

-- Get script path
function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return str:match('(.*[/\\])')
end
local GC_scriptpath = script_path() or './'

-- run the script and check for errors.
function run_garbagecalendar(GC_scriptpath, commandArray, domoticz)
	dofile(GC_scriptpath .. 'garbagecalendar/gc_main.lua')
	local rc, errmsg = pcall(gc_main, commandArray, domoticz)
	if not rc then
		print('-----done with error', errmsg)
	end
end

-- determine if this is a DzVents or Regular LUA time script
if (_G.scriptsFolderPath ~= nil) then
	return {
		active = GC_enabled,
		on = {
			timer = {'Every 1 minutes'}
		},
		execute = function(domoticz)
			-- run the script when enabled (true)
			run_garbagecalendar(GC_scriptpath, nil, domoticz)
		end
	}
else
	-- Regular Time Event script
	commandArray = {}
	-- run the script when enabled (true)
	if GC_enabled then
		run_garbagecalendar(GC_scriptpath, commandArray, nil)
	end
	return commandArray
end
