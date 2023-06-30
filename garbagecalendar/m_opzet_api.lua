-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_opzet_api.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230630-1300'
websitemodule = 'm_opzet_api'
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

	-- get the Afvalstromen information for all possible garbagetypeid's with their ophaaldatum info for this address(bagId)
	Web_Data = genfuncs.perform_webquery('"https://' .. Hostname .. '/rest/adressen/' .. bagId .. '/afvalstromen"')
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Unable to retrieve Afvalstromen information...  stopping execution.')
		return
	end

	-- process the data
	Print_logfile('- start looping through received data -----------------------------------------------------------')
	processdata(JSON:decode(Web_Data))
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for record, data in pairs(ophaaldata) do
		if type(data) == 'table' then
			local web_garbagetype = data.title
			local web_garbagedate = data.ophaaldatum
			if web_garbagedate == nil then
				-- this is a type that is not collected and has no ophaaldag defined
				Print_logfile(' Not collected web_garbagetype : ' .. (web_garbagetype or '?????'))
			else
				Print_logfile(' web_garbagetype : ' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
				-- Get days diff
				local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
				if daysdiffdev == nil then
					Print_logfile('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
					return
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
end

-- End Functions =========================================================================
