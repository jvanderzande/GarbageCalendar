-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_montferland.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230630-1300'
websitemodule = 'm_montferland'
-- Link to WebSite:  http://www.montferland.afvalwijzer.net/introductie.aspx.
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
	Print_logfile('---- web update ----------------------------------------------------------------------------')
	-- Get the information for the specified address: AdresID and AdministratieID  (required for the subsequent call)
	local Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/Login.ashx?Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&Postcode=' .. Zipcode .. '&Huisnummer=' .. Housenr .. '&Toevoeging=' .. Housenrsuf .. '"')
	if Web_Data == '' then
		return
	end
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Check your Zipcode and Housenr as we get an [] response.')
		return
	end
	local adressdata = JSON:decode(Web_Data)
	-- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
	local AdresID = adressdata[1].AdresID
	local AdministratieID = adressdata[1].AdministratieID
	if AdresID == nil or AdresID == '' then
		Print_logfile('### Error: No AdresID retrieved...  stopping execution.')
		return
	end
	if AdministratieID == nil or AdministratieID == '' then
		Print_logfile('### Error: No AdministratieID retrieved...  stopping execution.')
		return
	end
	Print_logfile(' AdresID:' .. AdresID .. '  AdministratieID:' .. AdministratieID)

	-- get the Afvalstromen information for all possible garbagetypeid's for this address(AdministratieID)
	Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. os.date('%Y') .. '&Date=' .. os.date('%d/%m/%Y%%2001:00:00%p') .. '"')
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
		return
	end
	local jdata = JSON:decode(Web_Data)
	-- get the ophaaldagen tabel for the coming scheduled pickups
	if type(jdata) ~= 'table' then
		Print_logfile('### Error: Empty Kalender found stopping execution.')
		return
	end
	-- process the data
	Print_logfile('- start looping through received data -----------------------------------------------------------')
	processdata(jdata)

	-- also get nextyears data in november/december
	if tonumber(os.date('%m')) >= 11 then
		local nextyear = tostring(tonumber(os.date('%Y')) + 1)
		nextyear = nextyear:sub(0, 4)
		Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' .. AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. nextyear .. '&Date=' .. os.date('%m/%d/%Y%%20%I:%M:%S%p') .. '"')
		if (Web_Data:sub(1, 2) == '[]') then
			Print_logfile('### Warning: no calendar data for next year.')
		else
			jdata = JSON:decode(Web_Data)
			Print_logfile('- start looping through next received data -----------------------------------------------------------')
			processdata(jdata)
		end
	end
end

function processdata(ophaaldata)
	Print_logfile('ophaaldata records:' .. (#ophaaldata or '??'))
	for i = 1, #ophaaldata do
		local record = ophaaldata[i]
		if type(record) == 'table' then
			local web_garbagetype = record['Soort']
			local web_garbagedate = record['Datum']
			Print_logfile('  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
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
			-- field to be used when WebData contains a description
			-- garbagedata[#garbagedata].wdesc = ....
			end
		end
	end
end
-- End Functions =========================================================================
