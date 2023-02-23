-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar external notification script
-- example for this setting which will switch on a CCT (RGB&CC/CW) lightbulb on a selected color at notification time:
--   Notificationscript = 'lua notification_extenal_scrint.lua "@GARBAGETYPE@" > /tmp/GCexternal.log'
-----------------------------------------------------------------------------------------------------------------
--=============================================================
-- get general functions script directory
function script_path()
	return arg[0]:match('.*[/\\]') or './'
end
print(script_path() or '')
-- include generalfunctions library
dofile((script_path() or '') .. 'gc_generalfuncs.lua') --

-- Variables
local domoticzurl = 'http://127.0.0.1:8080' 	-- define the url for domoticz
local idx = 439 								      -- define the IDX of the Light
local red = 0 -- Red color 0-255
local green = 0 -- Green color 0-255
local blue = 0 -- Blue color 0-255

-- Get first commandline parameter => garbagetype
local garbagetype = arg[1] or ''
print('garbagetype:' .. (garbagetype or ''))

-- Start logic
if garbagetype == 'paper' then
	-- Turn on lamp and set color to blue
	blue = 255
elseif garbagetype == 'gft' then
	-- Turn on lamp and set color to green
	green = 255
end

-- Proces when a color was defined
if red ~= 0 or green ~= 0 or blue ~= 0 then
	print('Colors (r g b):', red, green, blue)

	-- Set lamp to the defined color and brightness
	-- See the Wiki for the proper definition you might require for your lightbulbs:
	-- https://www.domoticz.com/wiki/Domoticz_API/JSON_URL's#Set_a_light_to_a_certain_color_or_color_temperature
	brightness = 100 -- (0-100%)
	url = " --data-urlencode 'color={\"m\":3,\"t\":0,\"r\":" .. red .. ',"g":' .. green .. ',"b":' .. blue .. "}' "
	url = url .. ' "' .. domoticzurl .. '/json.htm?type=command&param=setcolbrightnessvalue&idx=' .. idx .. '&brightness=' .. brightness .. '"'
	print(url)
	print(genfuncs.perform_webquery(url, true))

	-- sleep xx seconds
	os.execute('sleep 10')

	-- Set lamp back to regular color and brightness
	brightness = 20 -- (0-100%)
	url = " --data-urlencode 'color={\"m\":2,\"t\":0,\"r\":0,\"g\":0,\"b\":0,\"cw\":0,\"ww\":255}' "
	url = url .. ' "' .. domoticzurl .. '/json.htm?type=command&param=setcolbrightnessvalue&idx=' .. idx .. '&brightness=' .. brightness .. '"'
	print(url)
	print(genfuncs.perform_webquery(url, true))

	-- Switch Off the light when required
	url = '"' .. domoticzurl .. '/json.htm?type=command&param=switchlight&idx=' .. idx .. '&switchcmd=Off"'
	print(url)
	print(genfuncs.perform_webquery(url, true))
end
