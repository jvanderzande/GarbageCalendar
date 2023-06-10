-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_montferland.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230225-1050'
websitemodule = 'm_montferland'
-- Link to WebSite:  http://www.montferland.afvalwijzer.net/introductie.aspx.
--

-- Start Functions =========================================================================
-------------------------------------------------------
-- Do the actual update retrieving data from the website and processing it
function Perform_Update()
	function processdata(ophaaldata)
		for i = 1, #ophaaldata do
			record = ophaaldata[i]
			if type(record) == 'table' then
				web_garbagetype = record['Soort']
				web_garbagedate = record['Datum']
				wnameType = ''
				Print_logfile('  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
				local dateformat = '????????'
				-- Get days diff
				dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'yyyy', 'mm', 'dd'})
				if daysdiffdev == nil then
					Print_logfile('Invalid date from web for : ' .. web_garbagetype .. '   date:' .. web_garbagedate)
					return
				end
				if (daysdiffdev >= 0) then
					garbagedata[#garbagedata + 1] = {}
					garbagedata[#garbagedata].garbagetype = web_garbagetype
					garbagedata[#garbagedata].garbagedate = dateformat
					-- field to be used when WebData contains a description
					-- garbagedata[#garbagedata].wdesc = ....
				end
			end
		end
	end

	Print_logfile('---- web update ----------------------------------------------------------------------------')
	local Web_Data
	-- Get the information for the specified address: AdresID and AdministratieID  (required for the subsequent call)
	Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/Login.ashx?Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&Postcode=' .. Zipcode .. '&Huisnummer=' .. Housenr .. '&Toevoeging=' .. Housenrsuf .. '"')
	if Web_Data == '' then
		return
	end
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Check your Zipcode and Housenr as we get an [] response.')
		return
	end
	adressdata = JSON:decode(Web_Data)
	-- Decode JSON table and find the appropriate address when there are multiple options when toevoeging is used like 10a
	AdresID = adressdata[1].AdresID
	AdministratieID = adressdata[1].AdministratieID
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
	Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' ..
	AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. os.date('%Y') .. '&Date=' .. os.date('%d/%m/%Y%%2001:00:00%p') .. '"')
	if (Web_Data:sub(1, 2) == '[]') then
		Print_logfile('### Error: Unable to retrieve the Kalender information for this address...  stopping execution.')
		return
	end
	jdata = JSON:decode(Web_Data)
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
		Web_Data = genfuncs.perform_webquery('"http://afvalwijzer.afvaloverzicht.nl/OphaalDatums.ashx?ADM_ID=' ..
		AdministratieID .. '&Username=GSD&Password=' .. genfuncs.url_encode('gsd$2014') .. '&ADR_ID=' .. AdresID .. '&Jaar=' .. nextyear .. '&Date=' .. os.date('%m/%d/%Y%%20%I:%M:%S%p') .. '"')
		if (Web_Data:sub(1, 2) == '[]') then
			Print_logfile('### Warning: no calendar data for next year.')
		else
			jdata = JSON:decode(Web_Data)
			Print_logfile('- start looping through next received data -----------------------------------------------------------')
			processdata(jdata)
		end
	end
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
	--	"Street",
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
