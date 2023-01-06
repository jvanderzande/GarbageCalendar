function notification_event(RunbyDzVents, commandArray, domoticz)
	-----------------------------------------------------------------------------------------------------------------
	-- garbagecalendar notification script
	-- Example script which will Switch a light on with specified color in case of a garbagecalendar notification
	--[[=== Available variables from the mainscript :
			Notify_text
			Notify_Gdate
			Notify_Gtype
			Notify_Gtext
			Notify_Reminder
	]]
	-- ensure they are all initialised to avoid errors.
	Notify_text = Notify_text or ""
	Notify_Gdate = Notify_Gdate or ""
	Notify_Gtype = Notify_Gtype or ""
	Notify_Gtext = Notify_Gtext or ""
	Notify_Reminder = Notify_Reminder or ""
	-----------------------------------------------------------------------------------------------------------------
	-- Start you logic here in the appropriate section
	-----------------------------------------------------------------------------------------------------------------
	local lamp = 'TestLight'

	if RunbyDzVents then
		-- ##############################################################
		-- DzVents logic part will only run when implemented in DzVents
		-- ##############################################################
		print('DzVents ' .. (Notify_Gtype or '') .. ' ')
		-- Turn on lamp full
		--domoticz.devices(lamp).setLevel(50)
		-- set level to 15 after 5 seconds
		--domoticz.devices(lamp).setLevel(15).afterSec(5)
		-- Turn off lamp after 10 seconds
		--domoticz.devices(lamp).switchOff().afterSec(10)
	else
		-- ##############################################################
		-- LUA Time Event script, will only run when Lua Time Script
		-- ##############################################################
		print('LUA Time|' .. (Notify_Gtype or '') .. '|')
		if Notify_Gtype == 'grey' then
			print('Turn ' .. lamp .. ' on for 30 seconds')
			-- Turn on lamp full
			--commandArray[#commandArray + 1] = {[lamp] = 'Set Level 100'}
			-- set level to 15 after 5 seconds
			--commandArray[#commandArray + 1] = {[lamp] = 'Set Level 15 AFTER 5'}
			-- Turn off lamp after 10 seconds
			--commandArray[#commandArray + 1] = {[lamp] = 'Off AFTER 10'}
		end
	end
end
