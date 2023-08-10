function Notification_Event(RunbyDzVents, commandArray, domoticz)
	-----------------------------------------------------------------------------------------------------------------
	-- garbagecalendar notification script
	-- Example script which will Switch a light on with specified color in case of a garbagecalendar notification
	--[[=== Available variables from the mainscript :
			Notify_type     = GarbageType as defined as key in "garbagetype_cfg" and coming from the internet.
			Notify_text     = Formed text sentence using the settings from the "notificationtext" field
			Notify_date     = Formatted notification date using the config variable "notificationdate"
			Notify_mtitle   = Formatted Title sentence using the settings from the "notificationtitle" field
			Notify_mtext    = Description from "garbagetype_cfg" "text" field
			Notify_reminder = Formatted content for the config variable "notificationreminder"
	]]

	--##### To enable the script you have to remove/comment the next line ####
	if 1==1 then return end

	-- ensure they are all initialised to avoid errors.
	Notify_type = Notify_type or ""
	Notify_text = Notify_text or ""
	Notify_date = Notify_date or ""
	Notify_mtitle = Notify_mtitle or ""
	Notify_mtext = Notify_mtext or ""
	Notify_reminder = Notify_reminder or ""
	-----------------------------------------------------------------------------------------------------------------
	-- Start you logic here in the appropriate section
	-----------------------------------------------------------------------------------------------------------------
	local lamp = 'TestLight'
	local ontime = 30
	-- Start logic

	-- ##############################################################
	-- DzVents logic part will only run when implemented in DzVents
	-- ##############################################################
	if RunbyDzVents then
		print('DzVents Type:' .. Notify_type ..
		' text:' .. Notify_text ..
		' Date:' .. Notify_date ..
		' message title:' .. Notify_mtitle ..
		' message text:' .. Notify_mtext ..
		' Reminder:' .. Notify_reminder
		)

		print('Turn ' .. lamp .. ' on with a Color on for '..ontime..' seconds')
		--## Turn on lamp xx percent
		domoticz.devices(lamp).switchOn()
		--##  setColor(r, g, b, br, cw, ww, m, t)
		if Notify_type == 'gft' then	--green
			domoticz.devices(lamp).setColor(0, 255, 0, 50, 0, 0, 3, 0)
		elseif Notify_type == 'papier' then --blue
			domoticz.devices(lamp).setColor(0, 0, 255, 50, 0, 0, 3, 0)
		elseif Notify_type == 'pmd' then -- yellow
			domoticz.devices(lamp).setColor(255, 255, 0, 50, 0, 0, 3, 0)
		elseif Notify_type == 'restafval' then --
			domoticz.devices(lamp).setColor(128, 128, 128, 100, 0, 0, 3, 0)
		else -- purple
			domoticz.devices(lamp).setColor(128, 0, 128, 50, 0, 0, 3, 0)
		end

		--## Reset to WarmWhite after xx seconds
		domoticz.devices(lamp).setColor(0, 0, 0, 20, 0, 0, 2, 255) .afterSec(ontime)

		--## Turn off lamp after xx seconds when it is currently off
		if domoticz.devices(lamp).state == "Off" then
			domoticz.devices(lamp).switchOff().afterSec(ontime+1)
		end
		return
	end

	-- ##############################################################
	-- LUA TimeEvent script logic
	-- ##############################################################
	if not RunbyDzVents then
		print('LUA Time:' .. Notify_type ..
		' text:' .. Notify_text ..
		' Date:' .. Notify_date ..
		' message title:' .. Notify_mtitle ..
		' message text:' .. Notify_mtext ..
		' Reminder:' .. Notify_reminder
		)
		print('Turn ' .. lamp .. ' on with a Color on for '..ontime..' seconds')
		--## get idx for lamp
		idx=otherdevices_idx[lamp]
		--## Turn on lamp
		commandArray[#commandArray + 1] = {[lamp] = 'On'}

		--## Turn off lamp after xx +1 seconds when it is currently off
		if otherdevices[lamp] == "Off" then
			commandArray[#commandArray + 1] = {[lamp] = 'Off AFTER '..ontime+1}
		end

		--##  setColor(r, g, b, br, cw, ww, m, t)
		url = DomoticzURL .. '/json.htm?type=command&param=setcolbrightnessvalue&idx='..idx
		if Notify_type == 'gft' then	--green
			url = url .. '&color={"m":3,"t":0,"r":0,"g":255,"b":0,"cw":0,"ww":0}&brightness=50'
		elseif Notify_type == 'papier' then --blue
			url = url .. '&color={"m":3,"t":0,"r":0,"g":0,"b":255,"cw":0,"ww":0}&brightness=50'
		elseif Notify_type == 'pmd' then -- yellow
			url = url .. '&color={"m":3,"t":0,"r":255,"g":255,"b":0,"cw":0,"ww":0}&brightness=50'
		elseif Notify_type == 'restafval' then --
			url = url .. '&color={"m":3,"t":0,"r":128,"g":128,"b":128,"cw":0,"ww":0}&brightness=50'
		else -- purple
			url = url .. '&color={"m":3,"t":0,"r":128,"g":0,"b":128,"cw":0,"ww":0}&brightness=50'
		end
		commandArray[#commandArray + 1] = {["OpenURL"] = url}

		--## Reset color after xx seconds via URL
		url = DomoticzURL .. '/json.htm?type=command&param=setcolbrightnessvalue&idx='..idx
		url = url .. '&color={"m":2,"t":0,"r":0,"g":0,"b":0,"cw":0,"ww":255}&brightness=20'
		url = url .. ' AFTER '..ontime
		commandArray[#commandArray + 1] = {["OpenURL"] = url}
	end
end
