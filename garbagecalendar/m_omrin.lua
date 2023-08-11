-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_omrin.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230811-0900'
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
	'Datafile'
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
	local thnr = Housenr .. Housenrsuf
	local data = "{'AppId': '" .. appId .. "' , 'AppVersion': '', 'OsVersion': '', 'Platform': 'HomeAssistant'}"
	local Web_Data = genfuncs.perform_webquery(' -H "Content-Type: application/json" -d "' .. data .. '" "https://api-omrin.freed.nl/Account/GetToken/"')
	Print_logfile('---- web data stripped -------------------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data ------------------------------------------------------------------------')
	local jdata = JSON:decode(Web_Data)
	-- get PublicKey
	if type(jdata) ~= 'table' then
		Print_logfile('### Error: Token not received, stopping execution.')
		return
	end
	if not jdata.PublicKey then
		Print_logfile('### Error: Unable to read the PublicKey field from received data...  stopping execution.')
		return
	end
	local PublicKey = jdata.PublicKey

	-- save publickey to file
	local file, err = io.open(Datafile .. '_tmp_token.tmp', 'w')
	if file then
		file:write('-----BEGIN PUBLIC KEY-----', '\n')
		file:write(PublicKey, '\n')
		file:write('-----END PUBLIC KEY-----', '\n')
		file:close()
	end

	-- create data json and save to file
	local requestBody = '{"a": false, "Email": null, "Password": null, "PostalCode": "' .. Zipcode .. '", "HouseNumber": "' .. thnr .. '"}'
	local file2, err2 = io.open(Datafile .. '_tmp_datain.tmp', 'w')
	if file2 then
		file2:write(requestBody)
		file2:close()
	else
		Print_logfile('### Error: Unable to read the encrypted data from file ' .. Datafile .. '_tmp_datain.tmp' .. '  ...  stopping execution.')
		return
	end

	-- Encrypt data file with the received publickey file
	Print_logfile('openssl pkeyutl -encrypt -pubin -inkey "' .. Datafile .. '_tmp_token.tmp" -in "' .. Datafile .. '_tmp_datain.tmp" -out "' .. Datafile .. '_tmp_dataout.tmp"')
	os.execute('openssl pkeyutl -encrypt -pubin -inkey "' .. Datafile .. '_tmp_token.tmp" -in "' .. Datafile .. '_tmp_datain.tmp" -out "' .. Datafile .. '_tmp_dataout.tmp"')

	-- read the ecncrypted data for POST request
	local ifile, ierr = io.open(Datafile .. '_tmp_dataout.tmp', 'rb')
	local encryptedRequest = ''
	if ifile then
		encryptedRequest = ifile:read('*all')
		ifile:close()
	end

	-- convert ecncrypted data to base64 and enclose in double quotes
	encryptedRequest = '"' .. base64.encode(encryptedRequest) .. '"'
	Print_logfile('encryptedRequest:' .. encryptedRequest)

	-- clean tempfiles
	os.remove(Datafile .. '_tmp_token.tmp')
	os.remove(Datafile .. '_tmp_datain.tmp')
	os.remove(Datafile .. '_tmp_dataout.tmp')

	Print_logfile('--- start web query ---')
	Web_Data = genfuncs.perform_webquery(" -H \"Content-Type: application/x-www-form-urlencoded\" -d '" .. encryptedRequest .. "' -X POST https://api-omrin.freed.nl/Account/FetchAccount/" .. appId .. '')

	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
		return
	end
	jdata = JSON:decode(Web_Data)
	-- check received data is JSON object table
	if type(jdata) ~= 'table' then
		Print_logfile('### Error: Empty Kalender found stopping execution.')
		return
	end
	-- check if CalendarV2 is part of the received data and is a table, as that contains the garbage collection information
	if type(jdata['CalendarV2']) ~= 'table' then
		Print_logfile('### Error: Empty jdata["CalendarV2"] table in JSON data...  stopping execution.')
		return
	end

	-- process the data
	processdata(jdata['CalendarV2'])
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			--[[
				"Aansluitingid":153148,
				"Datum":"2023-02-10T00:00:00+01:00",
				"Dagsoort":null,
				"Omschrijving":"Sortibak",
				"Info":"Zet je Sortibak op de aangegeven datum voor 7.30 uur aan de weg.",
				"Info2":"",
				"Afroepinzamel":null,
				"Type":3,
				"Image":"a4b09c79-5ae1-4238-84e9-1b7b53e76c89.png",
				"IsVast":false,
				"IsAfroepInzamel":false,
				"WelkAfval":"<p>\r\n\t.</p>\r\n",
				"WelkAfvalAfbeelding":"713f46f2-eb9b-4069-a7e9-0084a7559adb.png"
			]]
			local web_garbagetype = record['Omschrijving']
			local web_garbagedate = record['Datum']
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
