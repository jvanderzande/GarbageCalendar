-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_recycleapp-be
-- Remarks:
----------------------------------------------------------------------------------------------------------------
M_ver = '20241231-1100'
websitemodule = 'm_recycleapp-be'
-- Link to https://www.recycleapp.be
--
-- ================================================================================================
-- These activated fields will be checked for being defined and the script will end when one isn't
-- ================================================================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--	'Housenrsuf',
	'Datafile',
	--	'Hostname',
	'Street'
	--	'Companycode'
}

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	-- Get Data for the Website
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	-- Get Access token
	local host = 'https://api.fostplus.be'
	local baseUrl = host .. '/recycle-public/app/v1'
	local consumer = 'recycleapp.be'
	local secret = 'Op2tDi2pBmh1wzeC5TaN2U3knZan7ATcfOQgxh4vqC0mDKmnPP2qzoQusmInpglfIkxx8SZrasBqi5zgMSvyHggK9j6xCQNQ8xwPFY2o03GCcQfcXVOyKsvGWLze7iwcfcgk2Ujpl0dmrt3hSJMCDqzAlvTrsvAEiaSzC9hKRwhijQAFHuFIhJssnHtDSB76vnFQeTCCvwVB27DjSVpDmq8fWQKEmjEncdLqIsRnfxLcOjGIVwX5V0LBntVbeiBvcjyKF2nQ08rIxqHHGXNJ6SbnAmTgsPTg7k6Ejqa7dVfTmGtEPdftezDbuEc8DdK66KDecqnxwOOPSJIN0zaJ6k2Ye2tgMSxxf16gxAmaOUqHS0i7dtG5PgPSINti3qlDdw6DTKEPni7X0rxM'
	local headerdata = ' -H "x-secret: ' .. secret .. '"' .. ' -H "x-consumer: ' .. consumer .. '"'
	local Web_Data = ''

	-- Step 1: Get access token:
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "' .. baseUrl .. '/access-token"')
	local jswebdata = JSON:decode(Web_Data)
	local accessToken = jswebdata.accessToken or ''
	if accessToken == '' then
		Print_logfile('### Error: No accessToken retrieved...  stopping execution.')
		return
	end
	Print_logfile('accessToken:' .. accessToken)
	headerdata = headerdata .. ' -H "Authorization:' .. accessToken .. '"'

	-- Step 2: Get zipcodeid
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "' .. baseUrl .. '/zipcodes?q=' .. Zipcode .. '"')
	Web_Data = JSON:decode(Web_Data)
	local postcode_id = Web_Data.items[1].id or ''
	if postcode_id == '' then
		Print_logfile('### Error: No postcode_id retrieved...  stopping execution.')
		return
	end
	Print_logfile('postcode_id:' .. postcode_id)

	-- Step 3: Get streetid
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "' .. baseUrl .. '/streets?q=' .. genfuncs.url_encode(Street) .. '&zipcodes=' .. postcode_id .. '"')
	Web_Data = JSON:decode(Web_Data)

	local street_id = Web_Data.items[1].id or ''
	if street_id == '' then
		Print_logfile('### Error: No street_id retrieved...  stopping execution.')
		return
	end
	Print_logfile('street_id:' .. street_id)

	-- Step 4: Get calendar data
	local startDate = os.date('%Y-%m-%d')
	local endDate = os.date('%Y-%m-%d', os.time() + 28 * 24 * 60 * 60) -- 4 weken
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "' .. baseUrl .. '/collections?zipcodeId=' .. postcode_id .. '&streetId=' .. street_id .. '&houseNumber=' .. Housenr .. '&fromDate=' .. startDate .. '&untilDate=' .. endDate .. '&size=100"')
	Web_Data = JSON:decode(Web_Data)
	-- get the ophaaldagen tabel for the coming scheduled pickups
	if type(Web_Data) ~= 'table' then
		Print_logfile('### Error: Empty Kalender .  stopping execution.')
		return
	end
	processdata(Web_Data)
end

function processdata(ophaaldata)
	ophaaldata = ophaaldata['items'] -- get the Datalist tabel for the coming scheduled pickups
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local web_garbagetype = record.fraction.name.nl
			local web_garbagedate = record.timestamp
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
			-- field to be used when Web_Data contains a description
			-- garbagedata[#garbagedata].wdesc =
			end
		end
	end
end
-- End Functions =========================================================================
