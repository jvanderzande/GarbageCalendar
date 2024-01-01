-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet.lua
----------------------------------------------------------------------------------------------------------------
ver = '20240101-1930'
websitemodule = 'm_opzet'
-- Link to WebSite:  variable, needs to be defined in the garbagecalendarconfig.lua in field Hostname.
--
-- =======================================================================================
-- Check required fields for this module. The script will end when one is missing.
-- =======================================================================================
chkfields = {
	'websitemodule',
	'Zipcode',
	'Housenr',
	--	'Housenrsuf',
	'Datafile',
	'Hostname'
	--	'Street',
	--	'Companycode'
}

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	--[[ -- old way using an redirect
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	local Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/adres/' .. Zipcode .. ':' .. Housenr .. ':' .. Housenrsuf .. '"')
	if Web_Data == '' then
		Print_logfile('Error Web_Data is empty.')
		return
	elseif string.find(Web_Data, '{"error":true}') ~= nil then
		Print_logfile('Error check postcode   Web_Data:' .. Web_Data)
		return
	end
	-- retrieve bagId from address data web data
		-- retrieve bagId from address data web data
	-- --[[
	<script>
		let adres = '{"bagId":"0743200000013039","postcode":"5721GW","huisnummer":74,"huisletter":"a","toevoeging":"","description":"Kerkstraat 74a, 5721GW Asten","straat":"Kerkstraat","woonplaats":"Asten","woonplaatsId":2928,"gemeenteId":743,"latitude":51.39906,"longitude":5.750401}'
		if (adres==='') {
			window.location.href = "/"
		} else {
			window.localStorage.setItem('zcalendarAdresWidget-data', adres)
			window.location.href = "/overzicht"
		}
	</script>
	] ]

	Web_Data = Web_Data:match("let adres = '(.-)'")
	if Web_Data == nil or Web_Data == '' then
		Print_logfile('### Error: Could not find the ophaaldata section in the data.  skipping the rest of the logic.')
		return
	end
	Print_logfile('---- web data stripped -------------------------------------------------------------------')
	Print_logfile(Web_Data)
	Print_logfile('---- end web data ------------------------------------------------------------------------')
	-- Decode JSON table and get bagId
	local record = JSON:decode(Web_Data)
	local bagId = record['bagId'] or ''
	if bagId == nil or bagId == '' then
		Print_logfile('### Error: No bagId retrieved...  stopping execution.')
		return
	end
	Print_logfile('found bagId:' .. bagId)
	]]

	Print_logfile('---- web update ----------------------------------------------------------------------------')
	-- Get the information for the specified address specifically the bagId for the subsequent calls
	local Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. Zipcode .. '-' .. Housenr .. '"')
	if Web_Data == '' then
		return
	end
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Check your Zipcode and Housenr as we get an [] response.')
		return
	end
	local adressdata = JSON:decode(Web_Data)
	-- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
	local bagId = ''
	for i = 1, #adressdata do
		local record = adressdata[i]
		Print_logfile('Address options: ' .. record['huisletter'] .. '=' .. Housenrsuf .. '->' .. record['bagId'])
		if type(record) == 'table' then
			bagId = record['bagId']
			if Housenrsuf == record['huisletter'] then
				break
			end
		end
	end
	if bagId == nil or bagId == '' then
		Print_logfile('### Error: No bagId retrieved...  stopping execution.')
		return
	end
	Print_logfile('bagId:' .. bagId)

	-- Get Garbage Calendar info
	Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/ical/' .. bagId .. '"')
	if Web_Data == '' then
		Print_logfile('Error Web_Data is empty.')
		return
	elseif string.find(Web_Data, '{"error":true}') ~= nil then
		Print_logfile('Error check postcode   Web_Data:' .. Web_Data)
		return
	end

	-- Process received iCal data.
	local i = 0
	-- loop through returned result
	Print_logfile('- start looping through received data ----------------------------------------------------')
	for web_garbagedate, web_garbagetype in string.gmatch(Web_Data, 'DTSTART;VALUE=DATE:(.-)\n.-SUMMARY:(.-)\n') do
		-- trim garbagetype and strip escape characters
		web_garbagetype = web_garbagetype:match("^%s*(.*)%s*$")
		web_garbagetype = web_garbagetype:gsub('[\n\r\\]', '')
		i = i + 1
		Print_logfile(i .. ' web_garbagetype:' .. tostring(web_garbagetype) .. '   web_garbagedate:' .. tostring(web_garbagedate))
		if web_garbagetype ~= nil and web_garbagedate ~= nil then
			-- first match for each Type we save the date to capture the first next dates
			--Print_logfile( web_garbagetype,web_garbagedate)
			local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d%d%d%d)(%d%d)(%d%d)', {'yyyy', 'mm', 'dd'})
			-- When days is 0 or greater the date is today or in the future. Ignore any date in the past
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
