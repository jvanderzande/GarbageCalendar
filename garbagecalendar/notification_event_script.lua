function notification_event(RunbyDzVents, commandArray, domoticz)
	-----------------------------------------------------------------------------------------------------------------
	-- garbagecalendar notification script
	-- Example script which will Switch a light on with specified color in case of a garbagecalendar notification
	-----------------------------------------------------------------------------------------------------------------
	local lamp = 'TVLampje'

	if RunbyDzVents then
		-- ################################
		-- DzVents logic part
		-- ################################
		print('DzVents |' .. (Notify_Gtype or '') .. '|')
		-- Turn on lamp full
		--domoticz.devices(lamp).setLevel(50)
		-- set level to 15 after 5 seconds
		--domoticz.devices(lamp).setLevel(15).afterSec(5)
		-- Turn off lamp after 10 seconds
		--domoticz.devices(lamp).switchOff().afterSec(10)
	else
		-- ################################
		-- DzVents logic part
		-- ################################
		--[[
		Use this sections when garbagecalendar is running as regular time event script
		=== Available variables from the mainscript :
		Notify_text
		Notify_Gdate
		Notify_Gtype
		Notify_Gtext
		Notify_Reminder
	]]
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
