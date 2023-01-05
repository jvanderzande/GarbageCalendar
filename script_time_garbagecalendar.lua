----------------------------------------------------------------------------------------------------------------
-- Event start script for  GarbageCalendar huisvuil script: script_time_garbagecalendar.lua
-- Works both in DzVents and Regular LUA time scripts
----------------------------------------------------------------------------------------------------------------
EventScriptVersion = '20230104-1705'

-- set variable to false=disable or true=enable the script
local GC_enabled=true

-- Get script path
function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return str:match('(.*[/\\])')
end
local GC_scriptpath = script_path() or './'

-- determine if this is a DzVents or Regular LUA time script
if (_G.scriptsFolderPath ~= nil) then
	return {
		active = GC_enabled,
		on = {
			timer = {'Every 1 minutes'}
		},
		execute = function(domoticz)
			-- save domotiz table to a global variable so we can use it in the main script
			GC_domoticz=domoticz
			dofile(GC_scriptpath.."garbagecalendar/garbagecalendar_main.lua")
			-- restore the modified table from the global variable to apply the changes
			domoticz=GC_domoticz
		end
	}
else
	-- Regular Time Event script
	commandArray = {}
		-- run the script when enabled (true)
		if GC_enabled then
			dofile(GC_scriptpath.."garbagecalendar/garbagecalendar_main.lua")
		end
	return commandArray
end
