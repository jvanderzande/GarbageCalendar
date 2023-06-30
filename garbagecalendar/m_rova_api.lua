-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_rova_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230630-1300'
websitemodule = 'm_rova_api'
-- Link to WebSite: http://api.inzamelkalender.rova.nl/webservices/appsinput/?postcode=3828bc&street=&huisnummer=53&toevoeging=A&apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&platform=phone&langs=nl&mobiletype=android&version=3&app_name=rova
--
-- This module tries to access the API that the Rova App uses.
--
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--	'Housenrsuf',
	'Datafile'
	--	'Hostname',
	--	'Street',
	--	'Companycode'
}

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	-- function to process ThisYear and Lastyear JSON data
	--
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	local Web_Data =
		genfuncs.perform_webquery(
		'"http://api.inzamelkalender.rova.nl/webservices/appsinput/?postcode=' ..
			Zipcode .. '&street=&huisnummer=' .. Housenr .. '&toevoeging=' .. Housenrsuf .. '&apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&platform=phone&langs=nl&mobiletype=android&version=3&app_name=rova"'
	)
	if (Web_Data == '') then
		Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
		return
	end
	-- strip bulk data from "ophaaldagenNext" till the end, because this is causing some errors for some gemeentes
	if (Web_Data:find('ophaaldagenNext') == nil) then
		Print_logfile('### Error: returned information does not contain the ophaaldagenNext section. stopping process.')
		return
	end
	-- strip a larger chunk of the none used data for speed.
	Web_Data = Web_Data:match('(.-),"mededelingen":') .. '}}'
	-- Decode JSON table
	local decoded_response = JSON:decode(Web_Data)
	-- Get the data section
	local rdata = decoded_response['data']
	if type(rdata) ~= 'table' then
		Print_logfile('### Error: Empty data table in JSON data...  stopping execution.')
		return
	end
	if (decoded_response['response'] == 'NOK') then
		Print_logfile('### Error: Check your Postcode and Huisnummer as we get an NOK response.')
		return
	end
	-- get the description records into rdesc to retrieve the long description
	local rdesc = rdata['langs']
	rdesc = rdesc['data']
	-- get the ophaaldagen tabel for the coming scheduled pickups for this year
	local rdataty = rdata['ophaaldagen']
	if type(rdataty) ~= 'table' then
		Print_logfile('### Error: Empty data.ophaaldagen table in JSON data...  stopping execution.')
		return
	end
	rdataty = rdataty['data']
	if type(rdataty) ~= 'table' then
		Print_logfile('### Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.')
		return
	end
	Print_logfile('- start looping through this year received data -----------------------------------------------------------')
	processdata(rdataty)
	-- only process nextyear data in case we do not have the requested number of next events
	if #garbagedata < 10 then
		-- get the ophaaldagen tabel for next year when needed
		local rdataly = rdata['ophaaldagenNext']
		if type(rdataly) ~= 'table' then
			print('@AFW: Empty data.ophaaldagen table in JSON data...  stopping execution.')
		else
			rdataly = rdataly['data']
			if type(rdataly) ~= 'table' then
				Print_logfile('### Error: Empty data.ophaaldagen.data table in JSON data...  stopping execution.')
			else
				-- get the next number of ShowNextEvents
				Print_logfile('- start looping through next year received data -----------------------------------------------------------')
				processdata(rdataly)
			end
		end
	end
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local wnameType = record['nameType']
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
				-- field to be used when WebData contains a description
				garbagedata[#garbagedata].wdesc = rdesc[web_garbagetype:upper() .. '_L']
			end
		end
	end
end
-- End Functions =========================================================================
