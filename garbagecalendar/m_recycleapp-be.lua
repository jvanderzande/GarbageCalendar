-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_recycleapp-be
-- Remarks:
----------------------------------------------------------------------------------------------------------------
ver = '20230225-1050'
websitemodule = 'm_recycleapp-be'
-- Link to https://www.recycleapp.be
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	-- function to process ThisYear and Lastyear JSON data
	function processdata(ophaaldata)
		aantal = ophaaldata.total
		ophaaldata = ophaaldata['items'] -- get the Datalist tabel for the coming scheduled pickups
		for i = 1, #ophaaldata do
			record = ophaaldata[i]
			if type(record) == 'table' then
				web_garbagetype = record.fraction.name.nl
				web_garbagedate = record.timestamp
				-- first match for each Type we save the date to capture the first next dates
				-- get the long description from the JSON data
				Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
				local dateformat = '????????'
				-- Get days diff
				dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
				if daysdiffdev == nil then
					Print_logfile('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
				end
				if (daysdiffdev >= 0) then
					garbagedata[#garbagedata + 1] = {}
					garbagedata[#garbagedata].garbagetype = web_garbagetype
					garbagedata[#garbagedata].garbagedate = dateformat
					-- field to be used when Web_Data contains a description
					-- garbagedata[#garbagedata].wdesc =
				end
			end
		end
	end

	Print_logfile('---- web update ----------------------------------------------------------------------------')
	-- Get Access token
	-- step 1: Get main js name from home page: <script src="/static/js/main.0b66adb4.chunk.js">
	local Web_Data
	Web_Data = genfuncs.perform_webquery('https://www.recycleapp.be')
	MainScript = Web_Data:match('<script src="(/static/js/main.-)">')
	Print_logfile(' MainScript:' .. (MainScript or '?')) -- MainScript:/static/js/main.0b66adb4.chunk.js
	-- step 2: retrieve main js and get code from source:
	--          var n="8a9pIQlfYpgmJZD15KdK70MCTR2xyD0EAvOmi9HCBfiBUY4n34ytxQmqo3AP2OET6tssYy6R4Be6N2M2GtiX3AcbiNxR8G7pOalN45dXPZ4emKE2c1nimx9B1YFciutJwFZHYHI2Qpzo0E0GCDHkg5",c="/api/v1/assets/<script src="/static/js/main.0b66adb4.chunk.js">
	Web_Data = genfuncs.perform_webquery('https://www.recycleapp.be' .. MainScript)
	secret = Web_Data:match('.+var n="(.-)",')
	Print_logfile(' secret:' .. (secret or '?'))
	headerdata = ' -H "x-secret: ' .. secret .. '"' .. ' -H "x-consumer: recycleapp.be"'
	-- step 3: Get access token:
	Web_Data = genfuncs.perform_webquery(headerdata .. ' https://www.recycleapp.be/api/app/v1/access-token')
	webdata = JSON:decode(Web_Data)
	accessToken = webdata.accessToken or ''
	if accessToken == '' then
		Print_logfile('### Error: No accessToken retrieved...  stopping execution.')
		return
	end
	Print_logfile('accessToken:' .. accessToken)
	headerdata = headerdata .. ' -H "Authorization:' .. accessToken .. '"'

	-- Step 4: Get zipcodeid
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "https://www.recycleapp.be/api/app/v1/zipcodes?q=' .. Zipcode .. '"')
	Web_Data = JSON:decode(Web_Data)
	postcode_id = Web_Data.items[1].id or ''
	if postcode_id == '' then
		Print_logfile('### Error: No postcode_id retrieved...  stopping execution.')
		return
	end
	Print_logfile('postcode_id:' .. postcode_id)

	-- Step 5: Get streetid
	Web_Data = genfuncs.perform_webquery(headerdata .. ' "https://www.recycleapp.be/api/app/v1/streets?q=' .. genfuncs.url_encode(Street) .. '&zipcodes=' .. postcode_id .. '"')
	Web_Data = JSON:decode(Web_Data)

	street_id = Web_Data.items[1].id or ''
	if street_id == '' then
		Print_logfile('### Error: No street_id retrieved...  stopping execution.')
		return
	end
	Print_logfile('street_id:' .. street_id)

	-- Step 6: Get calendar data
	startDate = os.date('%Y-%m-%d')
	endDate = os.date('%Y-%m-%d', os.time() + 28 * 24 * 60 * 60) -- 4 weken
	Web_Data = genfuncs.perform_webquery(headerdata ..
	' "https://www.recycleapp.be/api/app/v1/collections?zipcodeId=' .. postcode_id .. '&streetId=' .. street_id .. '&houseNumber=' .. Housenr .. '&fromDate=' .. startDate .. '&untilDate=' .. endDate .. '&size=100"')
	Web_Data = JSON:decode(Web_Data)
	-- get the ophaaldagen tabel for the coming scheduled pickups
	if type(Web_Data) ~= 'table' then
		Print_logfile('### Error: Empty Kalender .  stopping execution.')
		return
	end
	processdata(Web_Data)
end

-- End Functions =========================================================================

-- Start of logic ========================================================================
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
local chkfields = {'websitemodule',
	'Zipcode',
	'Housenr',
	--	"Housenrsuf",
	'Datafile',
	--	"Hostname",
	'Street',
	--	"Companycode"
}
local param_err = 0
-- Check whether the required parameters are specified.
for key, value in pairs(chkfields) do
	if (_G[value] or '') == '' then
		param_err = param_err + 1
		Print_logfile('!!! ' .. value .. ' not specified!', 1)
	end
end
-- =======================================================================================
-- Get the web info when all required parameters are defined
-- =======================================================================================
if param_err == 0 then
	Print_logfile('!!! perform web data update to ' .. Datafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf)
	Perform_Update()
	Print_logfile('=> Write data to ' .. Datafile)
	table.save(garbagedata, Datafile)
else
	Print_logfile('!!! Webupdate cancelled due to missing parameters!', 1)
end
