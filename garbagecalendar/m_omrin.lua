-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_omrin.lua
----------------------------------------------------------------------------------------------------------------
M_ver = '20261117-1720'
websitemodule = 'm_omrin'
-- Link to WebSite: "https://www.omrin.nl/bij-mij-thuis/afval-regelen/afvalkalender"
--
-- ================================================================================================
-- These activated fields will be checked for being defined and the script will end when one isn't
-- ===========================================Print_logfile((Datafile=====================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--	'Housenrsuf',
	-- 'Datafile'
	--	'Hostname',
	--	'Street',
	--	'Companycode'
}

-- Load required extra module base64
status, base64 = pcall(genfuncs.loadlualib, 'base64')
if not status then
	Print_logfile('### Error: failed loading default base64.lua: ' .. domoticzjsonpath .. '.')
	Print_logfile('### Error: Please check your setup and try again.')
	return nil
end

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	-- function to process ThisYear and Lastyear JSON data
	--
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	--[[
		API information for Omrin found here:
		https://github.com/pippyn/Home-Assistant-Sensor-Afvalbeheer/blob/411fc963075fd98af9899e2bace34dd52151daac/custom_components/afvalbeheer/API.py
	]]
	-- Generate uuid()
	math.randomseed(os.time())
	local random = math.random
	local function uuid()
		local template = 'yyxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
		return string.gsub(
			template,
			'[xy]',
			function(c)
				local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
				return string.format('%x', v)
			end
		)
	end
	-- data required to get token
	local appId = uuid()
	if not Housenrsuf or Housenrsuf == "" then
		Housenrsuf = "null"
	end
	appId = "3f2b8c1e-5a4d-41ee-8c99-0242ac120002"

	local headers = ' -H "Content-Type: application/json"'
	local datacontents = '{"PostalCode":"' .. Zipcode .. '","HouseNumber":' .. Housenr .. ',"HouseNumberExtension":' .. Housenrsuf .. ',"DeviceId":"' .. appId .. '","Platform":"HomeAssistant","AppVersion":"4.0.0 458","OsVersion":"HomeAssistant","Email":null,"Password":null}'
	local data = ' --data-raw ' .. string.format('"%s"', datacontents:gsub('"', '\\"'))
	local Web_Data = genfuncs.perform_webquery(' -X POST ' .. data .. ' ' .. headers .. ' "https://api.omrinafvalapp.nl/api/auth/login"')
	Print_logfile('---- web data stripped -------------------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data ------------------------------------------------------------------------')
	local JSON_Web_Data = JSON:decode(Web_Data)
	-- get PublicKey
	if type(JSON_Web_Data) ~= 'table' then
		Print_logfile('### Error: Token not received, stopping execution.')
		return
	end
	if not JSON_Web_Data.data.accessToken then
		Print_logfile('### Error: Unable to read the accessToken field from received data...  stopping execution.')
		return
	end
	local accessToken = JSON_Web_Data.data.accessToken
	local refreshToken = JSON_Web_Data.data.refreshToken
	local expiresAt = JSON_Web_Data.data.expiresAt

	-- Login
	Print_logfile('--- start web query ---')
	local headers = ' -H "Content-Type: application/json"'
	headers = headers .. ' -H "User-Agent: GraphQL.Client/6.1.0.0"'
	headers = headers .. ' -H "Authorization: Bearer ' .. accessToken .. '"'
	local query = '{"query":"query FetchCalendar { fetchCalendar { id date type placingTime}}"}'
	local data = ' --data-raw ' .. string.format('"%s"', query:gsub('"', '\\"'))
	local Web_Data = genfuncs.perform_webquery(' -X POST  ' .. data .. ' ' .. headers .. ' "https://api.omrinafvalapp.nl/graphql" ')
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
		return
	end
	JSON_Web_Data = JSON:decode(Web_Data)
	-- check received data is JSON object table
	if type(JSON_Web_Data) ~= 'table' then
		Print_logfile('### Error: Empty Kalender found stopping execution.')
		return
	end
	-- check if CalendarV2 is part of the received data and is a table, as that contains the garbage collection information
	if type(JSON_Web_Data['data']) ~= 'table' then
		Print_logfile('### Error: Empty JSON_Web_Data["data"] table in JSON data...  stopping execution.')
		return
	end
	if type(JSON_Web_Data['data']['fetchCalendar']) ~= 'table' then
		Print_logfile('### Error: Empty JSON_Web_Data["data"]["fetchCalendar"] table in JSON data...  stopping execution.')
		return
	end

	-- process the data
	ProcessData(JSON_Web_Data['data']['fetchCalendar'])
end

function ProcessData(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local web_garbagetype = record['type']
			local web_garbagedate = record['date']
			-- first match for each Type we save the date to capture the first next dates
			-- get the long description from the JSON data
			Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
			-- Get days diff
			local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
			if daysdiffdev == nil then
				Print_logfile('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
			end
			if (daysdiffdev >= 0) then
				garbagedata[#garbagedata + 1] = {}
				garbagedata[#garbagedata].garbagetype = web_garbagetype
				garbagedata[#garbagedata].garbagedate = dateformat
				garbagedata[#garbagedata].diff = daysdiffdev
			end
		end
	end
end
-- End Functions =========================================================================
