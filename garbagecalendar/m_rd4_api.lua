-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_rova_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230811-0900'
websitemodule = 'm_rd4_api'
-- Link to WebSite: https://data.rd4.nl/api/v1/waste-calendar?postalcode=1234aa&houseNumber=123&year=2025
--
-- This module tries to access the API that the RD4uses.
--
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--'Housenrsuf',
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
	local Web_Data = genfuncs.perform_webquery('"https://data.rd4.nl/api/v1/waste-calendar?postal_code=' .. Zipcode .. '&house_number=' .. Housenr .. '&house_number_extension=' .. (Housenrsuf or '') .. '&year=' .. os.date('%Y') .. '"')
	if (Web_Data == '') then
		Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
		return
	end
	--{"success":true,"code":0,"message":"Jouw kalender.","data":{"items":[[{"date":"2026-01-06","month":1,"type":"christmas_trees"},{"date":"2026-01-06","month":1,"type":"gft"},{"date":"2026-01-07","month":1,"type":"pmd"},{"date":"2026-01-10","month":1,"type":"paper"},{"date":"2026-01-13","month":1,"type":"christmas_trees"},{"date":"2026-01-13","month":1,"type":"gft"},{"date":"2026-01-13","month":1,"type":"residual_waste"},{"date":"2026-01-20","month":1,"type":"christmas_trees"},{"date":"2026-01-20","month":1,"type":"gft"},{"date":"2026-01-21","month":1,"type":"pmd"},{"date":"2026-01-27","month":1,"type":"christmas_trees"},{"date":"2026-01-27","month":1,"type":"gft"},{"date":"2026-01-27","month":1,"type":"residual_waste"},{"date":"2026-02-03","month":2,"type":"gft"},{"date":"2026-02-04","month":2,"type":"pmd"},{"date":"2026-02-08","month":2,"type":"paper"},{"date":"2026-02-10","month":2,"type":"gft"},{"date":"2026-02-10","month":2,"type":"residual_waste"},{"date":"2026-02-18","month":2,"type":"pmd"},{"date":"2026-02-21","month":2,"type":"gft"},{"date":"2026-02-24","month":2,"type":"gft"},{"date":"2026-02-24","month":2,"type":"residual_waste"},{"date":"2026-03-03","month":3,"type":"gft"},{"date":"2026-03-03","month":3,"type":"textile"},{"date":"2026-03-04","month":3,"type":"pmd"},{"date":"2026-03-10","month":3,"type":"gft"},{"date":"2026-03-10","month":3,"type":"residual_waste"},{"date":"2026-03-14","month":3,"type":"paper"},{"date":"2026-03-17","month":3,"type":"gft"},{"date":"2026-03-18","month":3,"type":"pmd"},{"date":"2026-03-24","month":3,"type":"gft"},{"date":"2026-03-24","month":3,"type":"residual_waste"},{"date":"2026-03-31","month":3,"type":"gft"},{"date":"2026-04-01","month":4,"type":"pmd"},{"date":"2026-04-07","month":4,"type":"gft"},{"date":"2026-04-07","month":4,"type":"residual_waste"},{"date":"2026-04-11","month":4,"type":"paper"},{"date":"2026-04-14","month":4,"type":"gft"},{"date":"2026-04-15","month":4,"type":"pmd"},{"date":"2026-04-21","month":4,"type":"gft"},{"date":"2026-04-21","month":4,"type":"residual_waste"},{"date":"2026-04-28","month":4,"type":"gft"},{"date":"2026-04-29","month":4,"type":"pmd"},{"date":"2026-05-05","month":5,"type":"gft"},{"date":"2026-05-05","month":5,"type":"residual_waste"},{"date":"2026-05-09","month":5,"type":"paper"},{"date":"2026-05-12","month":5,"type":"gft"},{"date":"2026-05-13","month":5,"type":"pmd"},{"date":"2026-05-19","month":5,"type":"gft"},{"date":"2026-05-19","month":5,"type":"residual_waste"},{"date":"2026-05-26","month":5,"type":"gft"},{"date":"2026-05-27","month":5,"type":"pmd"},{"date":"2026-06-02","month":6,"type":"gft"},{"date":"2026-06-02","month":6,"type":"residual_waste"},{"date":"2026-06-09","month":6,"type":"gft"},{"date":"2026-06-09","month":6,"type":"textile"},{"date":"2026-06-10","month":6,"type":"pmd"},{"date":"2026-06-13","month":6,"type":"paper"},{"date":"2026-06-16","month":6,"type":"gft"},{"date":"2026-06-16","month":6,"type":"residual_waste"},{"date":"2026-06-23","month":6,"type":"gft"},{"date":"2026-06-24","month":6,"type":"pmd"},{"date":"2026-06-30","month":6,"type":"gft"},{"date":"2026-06-30","month":6,"type":"residual_waste"},{"date":"2026-07-07","month":7,"type":"gft"},{"date":"2026-07-08","month":7,"type":"pmd"},{"date":"2026-07-11","month":7,"type":"paper"},{"date":"2026-07-14","month":7,"type":"gft"},{"date":"2026-07-14","month":7,"type":"residual_waste"},{"date":"2026-07-21","month":7,"type":"gft"},{"date":"2026-07-22","month":7,"type":"pmd"},{"date":"2026-07-28","month":7,"type":"gft"},{"date":"2026-07-28","month":7,"type":"residual_waste"},{"date":"2026-08-04","month":8,"type":"gft"},{"date":"2026-08-05","month":8,"type":"pmd"},{"date":"2026-08-08","month":8,"type":"paper"},{"date":"2026-08-11","month":8,"type":"gft"},{"date":"2026-08-11","month":8,"type":"residual_waste"},{"date":"2026-08-18","month":8,"type":"gft"},{"date":"2026-08-19","month":8,"type":"pmd"},{"date":"2026-08-25","month":8,"type":"gft"},{"date":"2026-08-25","month":8,"type":"residual_waste"},{"date":"2026-09-01","month":9,"type":"gft"},{"date":"2026-09-02","month":9,"type":"pmd"},{"date":"2026-09-08","month":9,"type":"gft"},{"date":"2026-09-08","month":9,"type":"residual_waste"},{"date":"2026-09-12","month":9,"type":"paper"},{"date":"2026-09-15","month":9,"type":"gft"},{"date":"2026-09-15","month":9,"type":"textile"},{"date":"2026-09-16","month":9,"type":"pmd"},{"date":"2026-09-22","month":9,"type":"gft"},{"date":"2026-09-22","month":9,"type":"residual_waste"},{"date":"2026-09-29","month":9,"type":"gft"},{"date":"2026-09-30","month":9,"type":"pmd"},{"date":"2026-10-06","month":10,"type":"gft"},{"date":"2026-10-06","month":10,"type":"residual_waste"},{"date":"2026-10-10","month":10,"type":"paper"},{"date":"2026-10-13","month":10,"type":"gft"},{"date":"2026-10-14","month":10,"type":"pmd"},{"date":"2026-10-20","month":10,"type":"gft"},{"date":"2026-10-20","month":10,"type":"residual_waste"},{"date":"2026-10-27","month":10,"type":"gft"},{"date":"2026-10-28","month":10,"type":"pmd"},{"date":"2026-11-03","month":11,"type":"gft"},{"date":"2026-11-03","month":11,"type":"residual_waste"},{"date":"2026-11-10","month":11,"type":"gft"},{"date":"2026-11-10","month":11,"type":"textile"},{"date":"2026-11-11","month":11,"type":"pmd"},{"date":"2026-11-14","month":11,"type":"paper"},{"date":"2026-11-17","month":11,"type":"gft"},{"date":"2026-11-17","month":11,"type":"residual_waste"},{"date":"2026-11-24","month":11,"type":"gft"},{"date":"2026-11-25","month":11,"type":"pmd"},{"date":"2026-12-01","month":12,"type":"gft"},{"date":"2026-12-01","month":12,"type":"residual_waste"},{"date":"2026-12-08","month":12,"type":"gft"},{"date":"2026-12-09","month":12,"type":"pmd"},{"date":"2026-12-12","month":12,"type":"paper"},{"date":"2026-12-15","month":12,"type":"gft"},{"date":"2026-12-15","month":12,"type":"residual_waste"},{"date":"2026-12-22","month":12,"type":"gft"},{"date":"2026-12-23","month":12,"type":"pmd"},{"date":"2026-12-29","month":12,"type":"gft"},{"date":"2026-12-29","month":12,"type":"residual_waste"}]],"info_text":""}}
	local decoded_response = JSON:decode(Web_Data)
	--
	if type(decoded_response['data']['items'][1]) ~= 'table' then
		Print_logfile('### Error: Empty data table in JSON data...  stopping execution.')
		return
	end
	Print_logfile('- start looping through this year received data -----------------------------------------------------------')
	processdata(decoded_response['data']['items'][1])
	-- only process nextyear data in case we do not have the requested number of next events
	if #garbagedata < 10 then
		-- get webinfo for next year
		local Web_Data = genfuncs.perform_webquery('"https://data.rd4.nl/api/v1/waste-calendar?postal_code=' .. Zipcode .. '&house_number=' .. Housenr .. '&house_number_extension='  .. (Housenrsuf or '') .. '&year=' .. (tonumber(os.date('%Y')) + 1) .. '"')
		if (Web_Data == '') then
			Print_logfile('### Error: Empty result from curl command. Please check whether curl.exe is installed.')
			return
		end
		local decoded_response = JSON:decode(Web_Data)
		if type(decoded_response['data']['items'][1]) ~= 'table' then
			Print_logfile('### Error: Empty data table in JSON data...  stopping execution.')
			return
		end
		Print_logfile('- start looping through next year received data -----------------------------------------------------------')
		processdata(decoded_response['data']['items'][1])
	end
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local web_garbagetype = record['type']
			local web_garbagedate = record['date'] -- 2026-01-20
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
				garbagedata[#garbagedata].wdesc = web_garbagetype
			end
		end
	end
end
-- End Functions =========================================================================
