-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_omrin_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230207-1331'
websitemodule = 'm_omrin'
-- Link to WebSite: "https://www.omrin.nl/bij-mij-thuis/afval-regelen/afvalkalender"
--
-------------------------------------------------------
-- get script directory
function script_path()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return (str:match('(.*[/\\])') or './'):gsub('\\', '/')
end
-- only include when run in separate process
if GC_scriptpath == nil then
   dofile(script_path() .. 'generalfuncs.lua') --
end
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	-- function to process ThisYear and Lastyear JSON data
	function processdata(ophaaldata)
		local i = 0
		local pickuptimes = {}
		print(#ophaaldata)
		for i = 1, #ophaaldata do
			record = ophaaldata[i]
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
				web_garbagetype = record['Omschrijving']
				web_garbagedate = record['Datum']
				-- first match for each Type we save the date to capture the first next dates
				-- get the long description from the JSON data
				dprint(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
				local dateformat = '????????'
				-- Get days diff
				dateformat, daysdiffdev = GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
				if daysdiffdev == nil then
					dprint('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
				end
				if (daysdiffdev >= 0) then
					garbagedata[#garbagedata + 1] = {}
					garbagedata[#garbagedata].garbagetype = web_garbagetype
					garbagedata[#garbagedata].garbagedate = dateformat
				end
			end
		end
		dprint('- Sorting records.' .. #pickuptimes)
		local eventcnt = 0
		for x = 0, 60, 1 do
			for mom in pairs(pickuptimes) do
				if pickuptimes[mom].diff == x then
					garbagedata[#garbagedata + 1] = {}
					garbagedata[#garbagedata].garbagetype = pickuptimes[mom].garbagetype
					garbagedata[#garbagedata].garbagedate = pickuptimes[mom].garbagedate
					-- field to be used when Web_Data contains a description
					garbagedata[#garbagedata].wdesc = pickuptimes[mom].wdesc
				end
			end
		end
	end
	--
	dprint('---- web update ----------------------------------------------------------------------------')
	local Web_Data
	local thnr = Housenr .. Housenrsuf

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
	appId = uuid()
	data = "{'AppId': '" .. appId .. "' , 'AppVersion': '', 'OsVersion': '', 'Platform': 'HomeAssistant'}"
	Web_Data = perform_webquery(' -H "Content-Type: application/json" -d "' .. data .. '" "https://api-omrin.freed.nl/Account/GetToken/"')
	dprint('---- web data stripped -------------------------------------------------------------------')
	dprint(Web_Data)
	dprint('---- end web data ------------------------------------------------------------------------')
	jdata = JSON:decode(Web_Data)
	-- get PublicKey
	if type(jdata) ~= 'table' then
		dprint('### Error: Token not received, stopping execution.')
		return
	end
	if not jdata.PublicKey then
		dprint('### Error: Unable to read the PublicKey field from received data...  stopping execution.')
		return
	end
	PublicKey = jdata.PublicKey

	-- save publickey to file
	local file, err = io.open(afwdatafile .. '_tmp_token.tmp', 'w')
	if not err then
		file:write('-----BEGIN PUBLIC KEY-----', '\n')
		file:write(PublicKey, '\n')
		file:write('-----END PUBLIC KEY-----', '\n')
		file:close()
	end

	-- create data json and save to file
	requestBody = '{"a": false, "Email": null, "Password": null, "PostalCode": "' .. Zipcode .. '", "HouseNumber": "' .. thnr .. '"}'
	local file, err = io.open(afwdatafile .. '_tmp_datain.tmp', 'w')
	if not err then
		file:write(requestBody)
		file:close()
	else
		dprint('### Error: Unable to read the encrypted data from file ' .. afwdatafile .. '_tmp_datain.tmp' .. '  ...  stopping execution.')
		return
	end

	-- Encrypt data file with the received publickey file
	os.execute('openssl pkeyutl -encrypt -pubin -inkey ' .. afwdatafile .. '_tmp_token.tmp -in ' .. afwdatafile .. '_tmp_datain.tmp -out ' .. afwdatafile .. '_tmp_dataout.tmp')

	-- read the ecncrypted data for POST request
	local ifile, ierr = io.open(afwdatafile .. '_tmp_dataout.tmp', 'rb')
	encryptedRequest = ''
	if not ierr then
		encryptedRequest = ifile:read('*all')
		ifile:close()
	end

	-- convert ecncrypted data to base64 and enclose in double quotes
	encryptedRequest = '"' .. base64.encode(encryptedRequest) .. '"'
	dprint('encryptedRequest:' .. encryptedRequest)

	-- clean tempfiles
	os.remove(afwdatafile .. '_tmp_token.tmp')
	os.remove(afwdatafile .. '_tmp_datain.tmp')
	os.remove(afwdatafile .. '_tmp_dataout.tmp')

	print('--- start web query ---')
	Web_Data = perform_webquery(" -H \"Content-Type: application/x-www-form-urlencoded\" -d '" .. encryptedRequest .. "' -X POST https://api-omrin.freed.nl/Account/FetchAccount/" .. appId .. '')

	if (Web_Data:sub(1, 2) == '[]') then
		dprint('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
		return
	end
	jdata = JSON:decode(Web_Data)
	-- check received data is JSON object table
	if type(jdata) ~= 'table' then
		dprint('### Error: Empty Kalender found stopping execution.')
		return
	end
	-- check if CalendarV2 is part of the received data and is a table, as that contains the garbage collection information
	if type(jdata['CalendarV2']) ~= 'table' then
		dprint('### Error: Empty jdata["CalendarV2"] table in JSON data...  stopping execution.')
		return
	end

	-- process the data
	processdata(jdata['CalendarV2'])
end
-- End Functions =========================================================================

-- Start of logic ========================================================================
timenow = os.date('*t')
-- get paramters from the commandline
Zipcode = Zipcode or arg[1]
Housenr = Housenr or arg[2]
Housenrsuf = Housenrsuf or arg[3] or '' -- optional
afwdatafile = datafile or arg[4]
afwlogfile = weblogfile or arg[5]
Hostname = (Hostname or arg[6]) or '' -- Not needed
Street = (Street or arg[7]) or '' -- Not needed
-- other variables
garbagedata = {} -- array to save information to which will be written to the data file

dprint('#### ' .. os.date('%c') .. ' ### Start garbagecalender module ' .. websitemodule .. ' (v' .. ver .. ')')
if Zipcode == nil then
   dprint('!!! Zipcode not specified!')
elseif Housenr == nil then
   dprint('!!! Housenr not specified!')
elseif Housenrsuf == nil then
   dprint('!!! Housenrsuf not specified!')
elseif afwdatafile == nil then
   dprint('!!! afwdatafile not specified!')
elseif afwlogfile == nil then
   dprint('!!! afwlogfile not specified!')
else
	local Load_Success = true
   if pcall(loaddefaultjson) then
      dprint('Loaded JSON.lua.')
   else
      dprint('### Error: failed loading default JSON.lua and Domoticz JSON.lua: ' .. GC_scriptpath .. '.')
      dprint('### Error: Please check your setup and try again.')
		Load_Success = false
	end
	-- Load base64.lua
	if pcall(loadbase64) then
		dprint('Loaded base64.lua.')
	else
		dprint('### Error: failed loading default base64.lua: ' .. domoticzjsonpath .. '.')
		dprint('### Error: Please check your setup and try again.')
		Load_Success = false
	end
	if Load_Success then
   dprint('!!! perform background update to ' .. afwdatafile .. ' for Zipcode ' .. Zipcode .. ' - ' .. Housenr .. Housenrsuf .. '  (optional) Hostname:' .. Hostname)
   Perform_Update()
   dprint('=> Write data to ' .. afwdatafile)
   table.save(garbagedata, afwdatafile)
	end
end
