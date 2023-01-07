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
	local ontime = 30

	if RunbyDzVents then
		-- ##############################################################
		-- DzVents logic part will only run when implemented in DzVents
		-- ##############################################################
		print('DzVents ' .. (Notify_Gtype or '') .. ' ')
		if Notify_Gtype == 'green' then
			print('Turn ' .. lamp .. ' on green for '..ontime..' seconds')
			--## Turn on lamp xx percent
			domoticz.devices(lamp).switchOn()

			--##  setColor(r, g, b, br, cw, ww, m, t)
			domoticz.devices(lamp).setColor(0, 255, 0, 50, 0, 0, 3, 0)

			--## Reset to WarmWhite after xx seconds
			domoticz.devices(lamp).setColor(0, 0, 0, 20, 0, 0, 2, 255) .afterSec(ontime-5)

			--## Turn off lamp after xx seconds
			--domoticz.devices(lamp).switchOff().afterSec(ontime)
		end
	else
		-- ##############################################################
		-- LUA Time Event script, will only run when Lua Time Script
		-- ##############################################################
		print('LUA Time|' .. (Notify_Gtype or '') .. '|')
		if Notify_Gtype == 'green' then
			print('Turn ' .. lamp .. ' green on for '..ontime..' seconds')
			idx=otherdevices_idx[lamp]
			--## Turn on lamp
			commandArray[#commandArray + 1] = {[lamp] = 'On'}

			--## Set color via URL
			url = 'http://127.0.0.1:8080/json.htm?type=command&param=setcolbrightnessvalue&idx='..idx..'&color={"m":3,"t":0,"r":0,"g":255,"b":0,"cw":0,"ww":0}&brightness=50'
			commandArray[#commandArray + 1] = {["OpenURL"] = url}

			--## Reset color after xx seconds via URL
			url = 'http://127.0.0.1:8080/json.htm?type=command&param=setcolbrightnessvalue&idx='..idx..'&color={"m":2,"t":255,"r":0,"g":0,"b":0,"cw":0,"ww":0}&brightness=20'
			url = url .. ' AFTER '..ontime
			commandArray[#commandArray + 1] = {["OpenURL"] = url}

			--## Turn off lamp after xx seconds
			--commandArray[#commandArray + 1] = {[lamp] = 'Off AFTER '..ontime}
		end
	end
end
