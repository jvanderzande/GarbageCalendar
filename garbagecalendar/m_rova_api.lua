-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_rova_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230811-0900'
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
	local Web_Data = genfuncs.perform_webquery('"https://www.rova.nl/api/waste-calendar/year?postalcode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&addition=' .. Housenrsuf .. '&year=' .. os.date('%Y') .. '"')
	if (Web_Data == '') then
		Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
		return
	end
	local decoded_response = JSON:decode(Web_Data)
	--
	if type(decoded_response) ~= 'table' then
		Print_logfile('### Error: Empty data table in JSON data...  stopping execution.')
		return
	end
	Print_logfile('- start looping through this year received data -----------------------------------------------------------')
	processdata(decoded_response)
	-- only process nextyear data in case we do not have the requested number of next events
	if #garbagedata < 10 then
		-- get webinfo for next year
		local Web_Data = genfuncs.perform_webquery('"https://www.rova.nl/api/waste-calendar/year?postalcode=' .. Zipcode .. '&houseNumber=' .. Housenr .. '&addition=' .. Housenrsuf .. '&year=' .. (tonumber(os.date('%Y')) + 1) .. '"')
		if (Web_Data == '') then
			Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
			return
		end
		local decoded_response = JSON:decode(Web_Data)
		if type(decoded_response) ~= 'table' then
			Print_logfile('### Error: Empty data table in JSON data...  stopping execution.')
			return
		end
		Print_logfile('- start looping through next year received data -----------------------------------------------------------')
		processdata(decoded_response)
	end
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local wnameType = record['nameType']
			local web_garbagetype = record['wasteType'].code
			local web_garbagedate = record['date'] -- 2025-01-04T00:00:00Z
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
				garbagedata[#garbagedata].wdesc = record['wasteType'].title
			end
		end
	end
end
-- End Functions =========================================================================
