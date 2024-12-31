-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_mijnafvalwijzer_API.lua
----------------------------------------------------------------------------------------------------------------
M_ver = '20241231-1100'
websitemodule = 'm_mijnafvalwijzer_API'
-- Link to WebSite: https://api.mijnafvalwijzer.nl/webservices/appsinput/?apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&postcode=1234AB&street=&huisnummer=1&toevoeging=&app_name=afvalwijzer&platform=phone&mobiletype=android&afvaldata=2021-01-01&version=58&langs=nl
-- Also used for rova with config: Hostname=api.inzamelkalender.rova.nl
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
	if Hostname == '' then
		Hostname = 'api.mijnafvalwijzer.nl'  -- default
	end

	local Web_Data =
		genfuncs.perform_webquery(
		'"https://' .. Hostname .. '/webservices/appsinput/?apikey=5ef443e778f41c4f75c69459eea6e6ae0c2d92de729aa0fc61653815fbd6a8ca&method=postcodecheck&postcode=' ..
			Zipcode .. '&street=&huisnummer=' .. Housenr .. '&toevoeging=&app_name=afvalwijzer&platform=phone&mobiletype=android&afvaldata=' .. tostring(os.date('*t').year) .. '-01-01&version=58&langs=nl"'
	)
	if (Web_Data == '') then
		Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
		return
	end
	if (Web_Data:sub(1, 3) == 'NOK') then
		Print_logfile('### Error: Check your Postcode and Huisnummer as we get an NOK response.')
		return
	end
	if (Web_Data:find('ophaaldagen') == nil) then
		Print_logfile('### Error: returned information does not contain the ophaaldagen section. stopping process.')
		return
	end
	--
	-- Decode JSON table
	local decoded_response = JSON:decode(Web_Data)

	-- get the ophaaldagen tabel for the coming scheduled pickups for this year
	local rdata = decoded_response['ophaaldagen']
	if type(rdata) ~= 'table' then
		Print_logfile('### Error: Empty data.ophaaldagen table in JSON data...  stopping execution.')
		return
	end

	rdata = rdata['data']
	if type(rdata) ~= 'table' then
		Print_logfile('### Error: Empty ophaaldagen.data table in JSON data...  stopping execution.')
		return
	end
	Print_logfile('- start looping through this year received data -----------------------------------------------------------')
	processdata(rdata)
	-- only process nextyear data in case we do not have the requested number of next events
	if #garbagedata < 10 then
		-- get the ophaaldagen tabel for next year when needed
		rdataly = decoded_response['ophaaldagenNext']
		if type(rdataly) ~= 'table' then
			Print_logfile('@AFW: Empty data.ophaaldagen table in JSON data...  stopping execution.')
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
			--local wnameType = record['nameType']
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
			-- garbagedata[#garbagedata].wdesc = ....
			end
		end
	end
end
-- End Functions =========================================================================
