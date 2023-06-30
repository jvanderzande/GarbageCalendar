-----------------------------------------------------------------------------------------------------------------
-- garbagecalendar module script: m_deafvalapp.lua
----------------------------------------------------------------------------------------------------------------
ver = '20230630-1600'
websitemodule = 'm_deafvalapp'
-- Link to WebSite:  http://dataservice.deafvalapp.nl
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
	local Web_Data = genfuncs.perform_webquery('"https://dataservice.deafvalapp.nl/dataservice/DataServiceServlet?service=OPHAALSCHEMA&land=NL&postcode=' .. Zipcode .. '&straatId=0&huisnr=' .. Housenr .. '' .. Housenrsuf .. '"')
	if Web_Data == '' then
		Print_logfile('Error Web_Data is empty.')
		return
	elseif string.find(Web_Data, '{"error":true}') ~= nil then
		Print_logfile('Error check postcode   Web_Data:' .. Web_Data)
		return
	end
	-- Process received webdata.
	local i = 0
	-- loop through returned result
	Print_logfile('- start looping through received data ----------------------------------------------------')
	for web_garbagetype, web_garbagedates in string.gmatch(Web_Data, '(.-);(.-)[\r\n|$]') do
		Print_logfile(web_garbagetype)
		for web_garbagedate in string.gmatch(web_garbagedates, '(.-);') do
			if web_garbagetype ~= nil and web_garbagedate ~= nil then
				i = i + 1
				-- first match for each Type we save the date to capture the first next dates
				Print_logfile(i .. '  web_garbagetype:' .. web_garbagetype .. '   web_garbagedate:' .. web_garbagedate)
				local dateformat, daysdiffdev = genfuncs.GetDateFromInput(web_garbagedate, '(%d+)[-%s]+(%d+)[-%s]+(%d+)', {'dd', 'mm', 'yyyy'})
				-- When days is 0 or greater the date is today or in the future. Ignore any date in the past
				if (daysdiffdev >= 0) then
					garbagedata[#garbagedata + 1] = {}
					garbagedata[#garbagedata].garbagetype = web_garbagetype
					garbagedata[#garbagedata].garbagedate = dateformat
					garbagedata[#garbagedata].diff = daysdiffdev
				-- field to be used when Web_Data contains a description
				-- garbagedata[#garbagedata].wdesc = ....
				end
			end
		end
	end
end
-- End Functions =========================================================================
